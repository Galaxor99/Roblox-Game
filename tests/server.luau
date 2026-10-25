-- Run the actual server entry point with deterministic Roblox service adapters.
local clock=1000
local actualOS=os
local os={clock=function()return clock end,time=function()return math.floor(clock) end}
local events={}
local function signal()
 local s={handlers={}}
 function s:Connect(fn)table.insert(self.handlers,fn);return {Disconnect=function()end} end
 function s:Fire(...)for _,fn in ipairs(self.handlers) do fn(...) end end
 return s
end
local byName={}
local Instance={new=function(class)
 local obj={ClassName=class}
 function obj:FireClient(player,data)table.insert(events,{Player=player,Data=data,Name=self.Name}) end
 return setmetatable(obj,{__newindex=function(t,k,v)rawset(t,k,v);if k=='Name' then byName[v]=t end end})
end}
local store=fakeStore()
local ordered={}
local function orderedStore(name)
 if ordered[name] then return ordered[name] end
 local db={data={}}
 function db:SetAsync(key,value)self.data[key]=value end
 function db:GetSortedAsync(ascending,limit)
  local page={};for key,value in pairs(self.data) do table.insert(page,{key=key,value=value}) end
  table.sort(page,function(a,b)return ascending and a.value<b.value or a.value>b.value end)
  while #page>limit do table.remove(page) end
  return {GetCurrentPage=function()return page end}
 end
 ordered[name]=db;return db
end
store.data.user_42={Coins=10000,Essence=1000,Crystals=100,Collection={recruit=4,spark=3,sentinel=2},Favorites={},Completed=20,Rolls=5}
local Players={PlayerAdded=signal(),PlayerRemoving=signal(),list={},GetNameFromUserIdAsync=function(_,id)return 'Test'..id end}
function Players:GetPlayers()return self.list end
function Players:GetPlayerByUserId(id)for _,p in ipairs(self.list) do if p.UserId==id then return p end end end
local Marketplace={PromptGamePassPurchaseFinished=signal()}
local run={Heartbeat=signal(),IsStudio=function()return true end}
local services={
 Players=Players,ReplicatedStorage={WaitForChild=function(_,name)return name end},
 DataStoreService={GetDataStore=function()return store end,GetOrderedDataStore=function(_,name)return orderedStore(name) end},RunService=run,MarketplaceService=Marketplace,
 PolicyService={GetPolicyInfoForPlayerAsync=function()return {ArePaidRandomItemsRestricted=false}end},
 HttpService={GenerateGUID=function()return 'test-guid' end},
}
local game={JobId='server-test',GetService=function(_,name)assert(services[name],name);return services[name] end,BindToClose=function(_,fn)end}
local script={Parent={WaitForChild=function(_,name)return name end}}
local rollUpper=false
local Random={new=function()return {NextNumber=function(_,min,max)return rollUpper and (max or 1) or (min or 0) end,NextInteger=function(_,min,max)return min end}end}
local Enum={ProductPurchaseDecision={NotProcessedYet='pending',PurchaseGranted='granted'}}
local task={spawn=function()end,wait=function()end}
local warn=function()end
local workspace={}
local discoverInWorld
local function require(name)
 if name=='NexusConfig' then return Config end
 if name=='NexusProgression' then return P end
 if name=='NexusPersistence' then return Persistence end
 if name=='NexusRankings' then return Rankings end
 if name=='NexusCoop' then return Coop end
 if name=='NexusWorld' then return {create=function(config,canVisit,notify,onDiscover)discoverInWorld=onDiscover;return {travel=function(player,id)if canVisit(player,id) then return true,'Arrived' end;return false,'Locked' end}end} end
 error('Unexpected module '..name)
end
-- SERVER_SOURCE_INSERT
local function player(id)
 local p={UserId=id,Name='Test'..id,Parent=Players,CharacterAdded=signal()}
 function p:FindFirstChild(name)return nil end
 function p:Kick(reason)self.Kicked=reason end
 table.insert(Players.list,p);Players.PlayerAdded:Fire(p);return p
end
local p=player(42)
local function request(action,arg,who)
 clock+=1;return byName.Request.OnServerInvoke(who or p,action,arg)
end
test('actual server loads legacy profile and keeps expedition outcome private',function()
 local r=request('Get');assert(r.Ok and r.Profile.Coins==10000)
 assert(request('StartExpedition','scouting').Ok)
 local profile=request('Get').Profile;assert(profile.Expedition and profile.Expedition.Success==nil)
 assert(not request('ClaimExpedition').Ok);clock+=40
 assert(request('ClaimExpedition').Ok);assert(not request('ClaimExpedition').Ok)
end)
test('actual server rejects malformed remote arguments and unowned favorites',function()
 assert(not request({},{}).Ok);assert(not request('Favorite',{}).Ok)
 assert(not request('Favorite','missing').Ok)
 assert(not request('a'..string.rep('x',100)).Ok)
end)
test('actual server rejects rapid request replay',function()
 clock+=1;assert(byName.Request.OnServerInvoke(p,'Get').Ok)
 assert(not byName.Request.OnServerInvoke(p,'Get').Ok)
end)
test('actual summon spends once, adds one variant and resets pity only on high rarity',function()
 local before=request('Get').Profile
 local r=request('Open','basic');assert(r.Ok and r.Variant=='Normal')
 local after=r.Profile;assert(after.Coins==before.Coins-100 and after.Rolls==before.Rolls+1)
 assert(after.Collection[r.Id]==(before.Collection[r.Id] or 0)+1)
 assert(after.Progression.Variants[r.Id].Normal>=1)
 assert(after.Pity.basic==1)
end)
test('zero endpoint cannot summon a zero-weight rarity',function()
 local r=request('Open','cosmic');assert(r.Ok and r.Rarity=='Epic',r.Rarity)
 rollUpper=true
 local upper=request('Open','cosmic');assert(upper.Ok and upper.Rarity=='Celestial',upper.Rarity)
 rollUpper=false
end)
test('actual server upgrades and recycles only owned normal duplicates',function()
 local before=request('Get').Profile
 assert(request('Upgrade','recruit').Ok)
 local after=request('Get').Profile;assert(after.Progression.Levels.recruit==2 and after.Collection.recruit==before.Collection.recruit-1)
 assert(request('Salvage','recruit').Ok);assert(request('Salvage','recruit').Ok)
 assert(not request('Salvage','recruit').Ok)
end)
test('actual server gates worlds and permits unlocked travel',function()
 assert(not request('StartExpedition','citadel').Ok)
 assert(not request('Travel','neon').Ok)
 assert(request('UnlockWorld','neon').Ok)
 assert(request('Travel','neon').Ok)
 assert(request('StartExpedition','citadel').Ok)
 clock+=120;assert(request('ClaimExpedition').Ok)
end)
test('actual server boss result is hidden and can only be claimed once',function()
 assert(request('StartBoss','guardian').Ok)
 assert(request('Get').Profile.Progression.Challenge.Success==nil)
 assert(not request('ClaimBoss').Ok);clock+=50
 assert(request('ClaimBoss').Ok);assert(not request('ClaimBoss').Ok)
end)
test('actual server routes retain selected plan and award mastery at claim',function()
 local before=request('Get').Profile.Progression.MasteryXp.recruit or 0
 local started=request('StartExpedition','scouting|swift')
 assert(started.Ok and started.Profile.Expedition.Route=='swift')
 assert(not request('StartExpedition','scouting|unknown').Ok)
 clock+=100
 assert(request('ClaimExpedition').Ok)
 local after=request('Get').Profile.Progression.MasteryXp.recruit or 0
 assert(after>before)
end)
test('memory locations grant rewards while remote discovery is rejected',function()
 assert(not request('Discover','hub_archive').Ok)
 local before=request('Get').Profile.Coins
 assert(discoverInWorld(p,'hub_archive'))
 assert(not discoverInWorld(p,'hub_archive'))
 assert(request('Get').Profile.Coins==before+20)
end)
test('actual server records a shared contribution and claims once after UTC day',function()
 local current=request('CoopStatus','0');assert(current.Ok and current.Status.Total==0)
 assert(request('CoopContribute').Ok)
 local status=request('CoopStatus','0').Status
 assert(status.Participants==1 and status.Contribution>0)
 assert(not request('CoopClaim','0').Ok)
 clock=86401
 assert(request('CoopClaim','0').Ok)
 assert(not request('CoopClaim','0').Ok)
 assert(request('Get').Profile.Progression.CoopClaims['0'])
end)
test('actual server persists complete private state and releases the lease',function()
 Players.PlayerRemoving:Fire(p)
 local saved=store.data.user_42
 assert(saved.Progression.Levels.recruit==2 and saved.Progression.Worlds.neon)
 assert(saved.Expedition==nil and saved._Session==nil)
 assert(ordered['AnimeNexusCards_v1'].data['42']>0)
end)
test('Studio failed load remains session-only and never overwrites real save',function()
 store.data.user_99={Coins=999};store.fail=true;local temp=player(99);store.fail=false
 local r=request('Get',nil,temp);assert(r.Ok and r.Profile.SessionOnly)
 local ranking=request('Leaderboard','Cards',temp);assert(ranking.Ok and ranking.Rows[1].Name=='Test42')
 Players.PlayerRemoving:Fire(temp);assert(store.data.user_99.Coins==999)
end)
test('legacy profiles with only zero-count cards regain a starter card',function()
 store.data.user_55={Coins=3,Collection={recruit=0,spark=0}}
 local starter=player(55)
 assert(request('Get',nil,starter).Profile.Collection.recruit==1)
 Players.PlayerRemoving:Fire(starter)
end)
print('Completed '..count..' tests including actual server entry point')
