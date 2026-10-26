-- Anime Nexus Hybrid MVP. All rolls, progression and rewards are SERVER authoritative.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local DataStoreService=game:GetService("DataStoreService")
local RunService=game:GetService("RunService")
local MarketplaceService=game:GetService("MarketplaceService")
local PolicyService=game:GetService("PolicyService")
local Config=require(ReplicatedStorage:WaitForChild("NexusConfig"))
local storeAvailable,store=pcall(function()return DataStoreService:GetDataStore("AnimeNexusHybrid_v2")end)
if not storeAvailable then
 warn("ANIME NEXUS: DataStore cannot start here; Studio will use unsaved test profiles:",store)
 store={UpdateAsync=function()error("DataStore unavailable")end}
end
local Progression=require(ReplicatedStorage:WaitForChild("NexusProgression")).new(Config)
local rankingService
local rankingOk,rankingResult=pcall(function()return require(script.Parent:WaitForChild("NexusRankings")).new(DataStoreService,Players,os.time)end)
if rankingOk then rankingService=rankingResult else warn("Anime Nexus rankings unavailable:",rankingResult) end
local coopService
local coopOk,coopResult=pcall(function()return require(script.Parent:WaitForChild("NexusCoop")).new(DataStoreService,os.time)end)
if coopOk then coopService=coopResult else warn("Anime Nexus shared challenge unavailable:",coopResult) end
local HttpService=game:GetService("HttpService")
local persistence=require(script.Parent:WaitForChild("NexusPersistence")).new(store,game.JobId..HttpService:GenerateGUID(false),os.time)
local reconciling={}
local saving={}; local writable={}; local closing={};local closeRunning={}
local rng=Random.new()
local folder=Instance.new("Folder");folder.Name="NexusRemotes";folder.Parent=ReplicatedStorage
local function remote(name,kind)
 local r=Instance.new(kind);r.Name=name;r.Parent=folder;return r
end
local Request=remote("Request","RemoteFunction")
local Updated=remote("Updated","RemoteEvent")
local Notify=remote("Notify","RemoteEvent")
local World
local profiles={};local throttles={};local displays={};local busy={}
local policyRestricted={}; local passOwners={}
local function refreshEntitlements(player)
 local allowed=false
 local ok,pol=pcall(function()return PolicyService:GetPolicyInfoForPlayerAsync(player)end)
 -- Fail closed if policy lookup fails.
 if ok and type(pol)=="table" then allowed=pol.ArePaidRandomItemsRestricted==false end
 policyRestricted[player]=not allowed
 local passId=Config.Monetization.LuckPassId
 local owns=false
 if passId>0 and allowed then
  local good,result=pcall(function()return MarketplaceService:UserOwnsGamePassAsync(player.UserId,passId)end)
  owns=good and result==true
 end
 passOwners[player]=owns
end
local function luckFactor(p,player)
 local potion=p.ActivePotion
 local bonus=(potion and potion.EndsAt>os.time() and Config.Potions[potion.Id].Bonus) or 0
 local f=1+p.Luck*Config.LuckBonusPerLevel+bonus+Progression.collectionLuck(p)
 return f*(passOwners[player] and 2 or 1)
end
local function packOdds(pack,p,player)
 local factor=luckFactor(p,player)
 local w={};local sum=0
 for _,r in ipairs(Config.Rarities) do
  local high=(r=="Epic" or r=="Legendary" or r=="Mythic" or r=="Celestial")
  w[r]=(pack.Weights[r] or 0)*(high and factor or 1);sum+=w[r]
 end
 for r,v in pairs(w) do w[r]=(v/sum)*100 end
 return w
end
local function defaultProfile()
 return {Coins=Config.FreeStarterCoins,Luck=0,Collection={recruit=1},Favorites={"recruit"},Pity={},Expedition=nil,Completed=0,Rolls=0,Essence=0,Crystals=0,Potions={},ActivePotion=nil,Receipts={},Progression=Progression.sanitize(nil,{recruit=1},os.time())}
end
local function sanitize(raw)
 local p=defaultProfile()
 if type(raw)~="table" then return p end
 p.Coins=math.clamp(math.floor(tonumber(raw.Coins) or p.Coins),0,1000000000)
 p.Luck=math.clamp(math.floor(tonumber(raw.Luck) or 0),0,Config.LuckMaxLevel)
 p.Essence=math.clamp(math.floor(tonumber(raw.Essence) or 0),0,10000000)
 p.Crystals=math.clamp(math.floor(tonumber(raw.Crystals) or 0),0,10000000)
 p.Potions={}
 if type(raw.Potions)=="table" then for id in pairs(Config.Potions) do p.Potions[id]=math.clamp(math.floor(tonumber(raw.Potions[id]) or 0),0,100000) end end
 if type(raw.ActivePotion)=="table" and Config.Potions[raw.ActivePotion.Id] then
  local a=raw.ActivePotion
  if type(a.EndsAt)=="number" then p.ActivePotion={Id=a.Id,EndsAt=math.floor(a.EndsAt)} end
 end
 p.Receipts={}
 if type(raw.Receipts)=="table" then for k,v in pairs(raw.Receipts) do if type(k)=="string" and v==true then p.Receipts[k]=true end end end
 p.Completed=math.clamp(math.floor(tonumber(raw.Completed) or 0),0,1000000)
 p.Rolls=math.clamp(math.floor(tonumber(raw.Rolls) or 0),0,100000000)
 p.Collection={}
 if type(raw.Collection)=="table" then for id,count in pairs(raw.Collection) do
  if Config.Cards[id] and type(count)=="number" and count==count then p.Collection[id]=math.clamp(math.floor(count),0,100000) end
 end end
 local hasCard=false;for _,count in pairs(p.Collection) do if count>0 then hasCard=true;break end end
 if not hasCard then p.Collection.recruit=1 end
 p.Favorites={}
 if type(raw.Favorites)=="table" then local seen={};for _,id in ipairs(raw.Favorites) do
  if #p.Favorites>=3 then break end
  if Config.Cards[id] and (p.Collection[id] or 0)>0 and not seen[id] then table.insert(p.Favorites,id);seen[id]=true end
 end end
 p.Pity={}
 if type(raw.Pity)=="table" then for id in pairs(Config.Packs) do p.Pity[id]=math.clamp(math.floor(tonumber(raw.Pity[id]) or 0),0,10000) end end
 if type(raw.Expedition)=="table" and Config.Expeditions[raw.Expedition.Id] then
  local e=raw.Expedition
  if type(e.EndsAt)=="number" and type(e.Success)=="boolean" then
   local team={};local seen={}
   if type(e.Team)=="table" then for _,id in ipairs(e.Team) do if #team<5 and Config.Cards[id] and not seen[id] then table.insert(team,id);seen[id]=true end end end
   local route=Config.ExpeditionRoutes[e.Route] and e.Route or "steady"
   p.Expedition={Id=e.Id,EndsAt=math.floor(e.EndsAt),Success=e.Success,Route=route,Team=team}
  end
 end
 p.Progression=Progression.sanitize(raw.Progression,p.Collection,os.time())
 return p
end
local function public(p,player)
 local power,team,synergy=Progression.team(p)
 local expedition=p.Expedition and {Id=p.Expedition.Id,EndsAt=p.Expedition.EndsAt,Route=p.Expedition.Route} or nil
 return {Progression=Progression.public(p,os.time()),TeamPower=power,EffectiveTeam=team,Synergy=synergy,SessionOnly=player and not writable[player] or false,Coins=p.Coins,Luck=p.Luck,Collection=table.clone(p.Collection),Favorites=table.clone(p.Favorites),Pity=table.clone(p.Pity),Expedition=expedition,Completed=p.Completed,Rolls=p.Rolls,Essence=p.Essence,Crystals=p.Crystals,Potions=table.clone(p.Potions),ActivePotion=p.ActivePotion and table.clone(p.ActivePotion) or nil,HasLuckPass=player and passOwners[player] or false,PaidLuckAvailable=player and not policyRestricted[player] or false,Odds=player and {basic=packOdds(Config.Packs.basic,p,player),elite=packOdds(Config.Packs.elite,p,player),cosmic=packOdds(Config.Packs.cosmic,p,player)} or {}}
end
local function push(player)
 local p=profiles[player];if p then
  local stats=player:FindFirstChild("leaderstats")
  if stats then
   local unique=0;for _,n in pairs(p.Collection) do if n>0 then unique+=1 end end
   stats.Cards.Value=unique;stats.Power.Value=Progression.team(p);stats.Bosses.Value=p.Progression.BossWins
  end
  Updated:FireClient(player,public(p,player))
 end
end
local function message(player,s) Notify:FireClient(player,s) end
local function teamPower(p) return Progression.team(p) end
local function luckWeights(pack,p,player)
 local w={};local sum=0;local factor=luckFactor(p,player)
 for r,v in pairs(pack.Weights) do
  local high=(r=="Epic" or r=="Legendary" or r=="Mythic" or r=="Celestial")
  local adjusted=v*(high and factor or 1)
  w[r]=adjusted;sum+=adjusted
 end
 return w,sum
end
local function roll(p,packId,player)
 local pack=Config.Packs[packId]
 local pity=p.Pity[packId] or 0
 local rarity
 if pity+1>=pack.Pity then
  local better={};for _,r in ipairs({"Legendary","Mythic","Celestial"}) do if (pack.Weights[r] or 0)>0 then table.insert(better,r) end end
  rarity=better[rng:NextInteger(1,#better)] -- guaranteed Legendary+ on pity
 else
  local weights,sum=luckWeights(pack,p,player)
  local pick=rng:NextNumber(0,sum);local cumulative=0
  for _,r in ipairs(Config.Rarities) do cumulative+=weights[r] or 0;if pick<cumulative then rarity=r;break end end
  if not rarity then for i=#Config.Rarities,1,-1 do
   local candidate=Config.Rarities[i]
   if (weights[candidate] or 0)>0 then rarity=candidate;break end
  end end
 end
 local candidates={};for id,c in pairs(Config.Cards) do if c.Rarity==rarity and c.Enabled~=false then table.insert(candidates,id) end end
 table.sort(candidates)
 local id=candidates[rng:NextInteger(1,#candidates)]
 p.Pity[packId]=(rarity=="Legendary" or rarity=="Mythic" or rarity=="Celestial") and 0 or pity+1
 return id,rarity
end
local function removeDisplay(player)
 if displays[player] then displays[player]:Destroy();displays[player]=nil end
end
local function displayModel(id,index)
 local card=Config.Cards[id]
 local library=ReplicatedStorage:FindFirstChild("NexusModels")
 local authored=library and library:FindFirstChild(card.Identity.ModelName or id)
 if authored and authored:IsA("Model") then
  local m=authored:Clone();m.Name=id
  local root=m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart",true)
  if root then
   m.PrimaryPart=root
   for _,descendant in ipairs(m:GetDescendants()) do
    if descendant:IsA("BasePart") then
     descendant.Anchored=true;descendant.CanCollide=false;descendant.CanTouch=false;descendant.CanQuery=false
    end
   end
   local bill=Instance.new("BillboardGui");bill.Name="NameTag";bill.Size=UDim2.fromOffset(190,50);bill.StudsOffset=Vector3.new(0,4.65,0);bill.AlwaysOnTop=true;bill.Parent=root
   local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Text=card.Name.."\n"..card.Rarity
   label.TextColor3=card.Color;label.TextStrokeTransparency=0;label.Font=Enum.Font.GothamBold;label.TextScaled=true;label.Parent=bill
   return m
  end
  m:Destroy()
 end
 local m=Instance.new("Model");m.Name=id
 local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Size=Vector3.new(1,1,1);root.Transparency=1;root.Anchored=true;root.CanCollide=false;root.CanTouch=false;root.CanQuery=false;root.Parent=m;m.PrimaryPart=root
 local function part(n,size,pos,color,shape)
  local x=Instance.new("Part");x.Name=n;x.Size=size;x.CFrame=CFrame.new(pos);x.Color=color;x.Material=Enum.Material.Neon;x.Anchored=true;x.CanCollide=false;x.CanTouch=false;x.CanQuery=false
  if shape then x.Shape=shape end;x.Parent=m;return x
 end
 part("Body",Vector3.new(1.5,2,0.75),Vector3.new(0,1.8,0),card.Color)
 part("Head",Vector3.new(1.05,1.05,1.05),Vector3.new(0,3.4,0),card.Color,Enum.PartType.Ball)
 part("LeftArm",Vector3.new(.45,1.8,.55),Vector3.new(-1,1.8,0),card.Color)
 part("RightArm",Vector3.new(.45,1.8,.55),Vector3.new(1,1.8,0),card.Color)
 part("LeftLeg",Vector3.new(.55,1.6,.6),Vector3.new(-.45,.15,0),card.Color)
 part("RightLeg",Vector3.new(.55,1.6,.6),Vector3.new(.45,.15,0),card.Color)
 local bill=Instance.new("BillboardGui");bill.Name="NameTag";bill.Size=UDim2.fromOffset(190,50);bill.StudsOffset=Vector3.new(0,4.65,0);bill.AlwaysOnTop=true;bill.Parent=root
 local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Text=card.Name.."\n"..card.Rarity;label.TextColor3=card.Color;label.TextStrokeTransparency=0;label.Font=Enum.Font.GothamBold;label.TextScaled=true;label.Parent=bill
 return m
end
local function refreshDisplay(player)
 removeDisplay(player)
 local p=profiles[player];if not p or not player.Character then return end
 local group=Instance.new("Folder");group.Name="NexusFavoriteDisplays";group.Parent=workspace;displays[player]=group
 for i,id in ipairs(p.Favorites) do if Config.Cards[id] then
  local m=displayModel(id,i);m.Parent=group
  local tag=m.PrimaryPart:FindFirstChild("NameTag")
  if tag then local title=tag:FindFirstChildOfClass("TextLabel");if title then title.Text=Config.Cards[id].Name.." • Lv "..(p.Progression.Levels[id] or 1).."\n"..Config.Cards[id].Rarity end end
  local v=Instance.new("ObjectValue");v.Name="Owner";v.Value=player;v.Parent=m
  m:SetAttribute("Slot",i)
 end end
end
RunService.Heartbeat:Connect(function(dt)
 for player,group in pairs(displays) do
  local char=player.Character;local root=char and char:FindFirstChild("HumanoidRootPart")
  if root and group.Parent then
   for _,m in ipairs(group:GetChildren()) do
    if m:IsA("Model") and m.PrimaryPart then
     local slot=m:GetAttribute("Slot") or 1
     local formation=profiles[player] and profiles[player].Progression.Formation or "Line"
     local lateral=(slot-2)*3.0
     if #group:GetChildren()==1 then lateral=0 end
     local offset=Vector3.new(lateral,1.8,4.6)
     if formation=="Arc" then offset=Vector3.new(lateral*1.3,1.8,4.6-math.abs(lateral)*.3)
     elseif formation=="Orbit" then local a=os.clock()*.45+slot*math.pi*2/math.max(1,#group:GetChildren());offset=Vector3.new(math.cos(a)*5,2.5,math.sin(a)*5) end
     local target=root.CFrame*CFrame.new(offset)
     m:PivotTo(m:GetPivot():Lerp(target,1-math.exp(-10*dt)))
    end
   end
  end
 end
end)
local function save(player,release)
 if not writable[player] then return true end
 if reconciling[player] then return false end
 if saving[player] then return false end
 saving[player]=true
 local p=profiles[player]
 if not p then saving[player]=nil; return false end
 local copy=sanitize(p)
 local success=false
 for attempt=1,3 do
  local ok,err=persistence.save(player.UserId,copy,release)
  if ok then success=true; break end
  warn("Anime Nexus save failed:",player.UserId,err)
  if err=="Session ownership lost" then
   writable[player]=nil; closing[player]=true
   player:Kick("Your collection session changed. Please rejoin."); break
  end
  task.wait(attempt)
 end
 if success and rankingService then
  local unique=0;for _,n in pairs(p.Collection) do if n>0 then unique+=1 end end
  local ok,err=rankingService.update(player.UserId,{Cards=unique,Power=Progression.team(p),Bosses=p.Progression.BossWins},release)
  if not ok then warn("Anime Nexus rankings update failed:",err) end
 end
 saving[player]=nil
 return success
end
Players.PlayerAdded:Connect(function(player)
 local data,loadError=persistence.load(player.UserId)
 if not data then
  if RunService:IsStudio() and loadError=="unavailable" then
   warn("ANIME NEXUS: DataStore unavailable in Studio; using temporary unsaved test profile for",player.Name)
   data=nil
  else
   warn("Data load failed for",player.Name,"- session will not permit changes")
   player:Kick("Unable to load your saved collection. Please rejoin to avoid data loss.");return
  end
 end
 if not player.Parent then if data then persistence.save(player.UserId,data,true) end;return end
 writable[player]=data~=nil
 profiles[player]=sanitize(data)
 local stats=Instance.new("Folder");stats.Name="leaderstats";stats.Parent=player
 for _,name in ipairs({"Cards","Power","Bosses"}) do local v=Instance.new("IntValue");v.Name=name;v.Parent=stats end
 refreshEntitlements(player)
 player.CharacterAdded:Connect(function() task.wait(1);refreshDisplay(player) end)
 if player.Character then refreshDisplay(player) end
 push(player)
end)
local function closePlayer(player)
 if closeRunning[player] then while closeRunning[player] do task.wait(.05) end;return end
 closeRunning[player]=true
 if closing[player] and not profiles[player] then closeRunning[player]=nil;return end
 closing[player]=true
 while saving[player] or busy[player] do task.wait(.05) end
 save(player,true)
 removeDisplay(player);profiles[player]=nil;throttles[player]=nil;busy[player]=nil;policyRestricted[player]=nil;passOwners[player]=nil;writable[player]=nil;reconciling[player]=nil;closeRunning[player]=nil
end
Players.PlayerRemoving:Connect(closePlayer)
task.spawn(function()
 while task.wait(45) do
  for player in pairs(profiles) do if not closing[player] and not busy[player] then task.spawn(save,player,false) end end
 end
end)
game:BindToClose(function()
 local pending=0
 for player in pairs(profiles) do pending+=1;task.spawn(function() closePlayer(player);pending-=1 end) end
 local deadline=os.clock()+25
 while pending>0 and os.clock()<deadline do task.wait(.1) end
end)
Request.OnServerInvoke=function(player,action,arg)
 local p=profiles[player];if not p or closing[player] then return {Ok=false,Message="Profile loading or closing"} end
 if type(action)~="string" or #action>32 or (arg~=nil and (type(arg)~="string" or #arg>64)) then return {Ok=false,Message="Invalid request"} end
 local now=os.clock();local t=throttles[player] or 0
 if now-t<0.15 then return {Ok=false,Message="Please slow down"} end
 throttles[player]=now
 if reconciling[player] and (reconciling[player]~="coop" or action~="CoopClaim") then return {Ok=false,Message="Reward verification pending; please retry shortly"} end
 if busy[player] or saving[player] then return {Ok=false,Message="Request processing"} end
 busy[player]=true
 local ok,result=pcall(function()
  if action=="Travel" then
   if not World or type(arg)~="string" then return {Ok=false,Message="World unavailable"} end
   local ok,notice=World.travel(player,arg)
   return {Ok=ok,Message=notice,Profile=public(p,player)}
  end
  if action=="StartBoss" then
   local handled,notice=Progression.startBoss(p,arg,os.time(),rng:NextNumber())
   if handled then push(player) end
   return {Ok=handled,Message=notice,Profile=public(p,player)}
  end
  if action=="Discover" then return {Ok=false,Message="Explore the world to discover memories"} end
  local handled,notice=Progression.act(p,action,arg,os.time())
  if handled~=nil then
   if handled then if action=="Upgrade" or action=="Awaken" then refreshDisplay(player) end;push(player) end
   return {Ok=handled,Message=notice,Profile=public(p,player)}
  end
  if action=="Get" then return {Ok=true,Profile=public(p,player),TeamPower=teamPower(p)} end
  if action=="CoopStatus" then
   if not coopService then return {Ok=false,Message="Shared challenge is temporarily unavailable"} end
   local day=arg and tonumber(arg) or coopService.day()
   local status,notice=coopService.status(day,player.UserId)
   if not status then return {Ok=false,Message=notice} end
   return {Ok=true,Status=status}
  elseif action=="CoopContribute" then
   if not writable[player] or not coopService then return {Ok=false,Message="Shared challenge needs a saved profile and working storage"} end
   local score,notice=coopService.contribute(coopService.day(),player.UserId,Progression.team(p))
   if not score then return {Ok=false,Message=notice} end
   local status=coopService.status(coopService.day(),player.UserId)
   return {Ok=true,Status=status,Message="Your team contributed "..score.." power to the shared challenge"}
  elseif action=="CoopClaim" then
   if not writable[player] or not coopService then return {Ok=false,Message="Shared challenge is unavailable"} end
   local day=arg and tonumber(arg)
   local status,notice=coopService.status(day,player.UserId)
   if not status then return {Ok=false,Message=notice} end
   if not status.Ended or status.Contribution<=0 then return {Ok=false,Message="Contribute during the challenge and return after it ends"} end
   local key=tostring(day)
   if p.Progression.CoopClaims[key] then return {Ok=false,Message="Shared reward already claimed"} end
   local reward=status.Complete and {Coins=300,Essence=20,Crystals=2} or {Coins=50,Essence=5,Crystals=0}
   local committed=persistence.claimCoop(player.UserId,sanitize(p),day,reward)
   if not committed then
    reconciling[player]="coop"
    return {Ok=false,Message="Reward verification pending; retry this claim shortly"}
   end
   reconciling[player]=nil;profiles[player]=sanitize(committed);push(player)
   return {Ok=true,Profile=public(profiles[player],player),Message=status.Complete and "Shared boss defeated! Team reward claimed" or "Shared challenge ended. Participation reward claimed"}
  end
  if action=="Leaderboard" then
   if not rankingService then return {Ok=false,Message="Rankings are temporarily unavailable"} end
   local rows,notice=rankingService.top(arg)
   if not rows then return {Ok=false,Message=notice} end
   return {Ok=true,Rows=rows,Message=notice}
  end
  if action=="Open" then
   if type(arg)~="string" or not Config.Packs[arg] then return {Ok=false,Message="Invalid pack"} end
   local pack=Config.Packs[arg]
   if p.Coins<pack.Price then return {Ok=false,Message="Not enough Rift Coins"} end
   p.Coins-=pack.Price
   local id,rarity=roll(p,arg,player);local variant=Progression.rollVariant(rng:NextNumber(0,10000));Progression.addCard(p,id,variant);p.Rolls+=1
   push(player);return {Ok=true,Id=id,Rarity=rarity,Variant=variant,Profile=public(p,player),TeamPower=teamPower(p)}
  elseif action=="Favorite" then
   if type(arg)~="string" or not Config.Cards[arg] or (p.Collection[arg] or 0)<=0 then return {Ok=false,Message="Card not owned"} end
   local at=table.find(p.Favorites,arg)
   if at then table.remove(p.Favorites,at) elseif #p.Favorites<3 then table.insert(p.Favorites,arg)
   else return {Ok=false,Message="Maximum three favourites"} end
   refreshDisplay(player);push(player);return {Ok=true,Profile=public(p,player)}
  elseif action=="Luck" then
   if p.Luck>=Config.LuckMaxLevel then return {Ok=false,Message="Maximum luck reached"} end
   local cost=Config.LuckUpgradeCosts[p.Luck+1]
   local required=Config.LuckExpeditionRequirements[p.Luck+1]
   if p.Completed<required then return {Ok=false,Message="Complete "..required.." expeditions to unlock"} end
   if p.Coins<cost then return {Ok=false,Message="Need "..cost.." coins"} end
   p.Coins-=cost;p.Luck+=1;push(player);return {Ok=true,Profile=public(p,player)}
  elseif action=="CraftPotion" then
   local def=type(arg)=="string" and Config.Potions[arg] or nil
   if not def then return {Ok=false,Message="Unknown recipe"} end
   if p.Essence<def.Ingredients.Essence or p.Crystals<def.Ingredients.Crystals then return {Ok=false,Message="Not enough crafting materials"} end
   p.Essence-=def.Ingredients.Essence;p.Crystals-=def.Ingredients.Crystals
   p.Potions[arg]=(p.Potions[arg] or 0)+1;push(player)
   return {Ok=true,Profile=public(p,player),Message="Potion crafted"}
  elseif action=="UsePotion" then
   if type(arg)~="string" or not Config.Potions[arg] or (p.Potions[arg] or 0)<1 then return {Ok=false,Message="Potion not owned"} end
   if p.ActivePotion and p.ActivePotion.EndsAt>os.time() then return {Ok=false,Message="A potion is already active"} end
   p.Potions[arg]-=1;p.ActivePotion={Id=arg,EndsAt=os.time()+Config.Potions[arg].Duration}
   push(player);return {Ok=true,Profile=public(p,player),Message="Potion activated"}
  elseif action=="RefreshPass" then
   refreshEntitlements(player);push(player)
   return {Ok=true,Profile=public(p,player)}
  elseif action=="StartExpedition" then
   if type(arg)~="string" then return {Ok=false,Message="Invalid expedition"} end
   local expeditionId,routeId=string.match(arg,"^([%w_]+)|([%w_]+)$")
   expeditionId=expeditionId or arg;routeId=routeId or "steady"
   if not Config.Expeditions[expeditionId] or not Config.ExpeditionRoutes[routeId] then return {Ok=false,Message="Invalid expedition route"} end
   if p.Expedition then return {Ok=false,Message="Finish current expedition first"} end
   local e=Config.Expeditions[expeditionId]
   if not p.Progression.Worlds[e.World] then return {Ok=false,Message="Unlock this world first"} end
   if p.Completed<e.Unlock then return {Ok=false,Message="Complete "..e.Unlock.." expeditions to unlock"} end
   local plan=Progression.expeditionPlan(p,expeditionId,routeId)
   p.Expedition={Id=expeditionId,EndsAt=os.time()+plan.Duration,Success=rng:NextNumber()<plan.Chance,Route=routeId,Team=plan.Team}
   push(player);return {Ok=true,Profile=public(p,player),Message="Expedition started"}
  elseif action=="ClaimExpedition" then
   local current=p.Expedition
   if not current then return {Ok=false,Message="No active expedition"} end
   if os.time()<current.EndsAt then return {Ok=false,Message="Expedition not finished"} end
   local e=Config.Expeditions[current.Id]
   local route=Config.ExpeditionRoutes[current.Route] or Config.ExpeditionRoutes.steady
   local base=math.floor(e.Reward*route.Reward)
   local reward=current.Success and base or math.floor(base*0.2)
   p.Coins+=reward;p.Completed+=1;p.Expedition=nil
   p.Essence+=current.Success and (base//65+1) or 1
   p.Crystals+=current.Success and math.max(1,base//400) or 0
   Progression.grantMastery(p,current.Team,current.Success and math.max(10,base//12) or 3)
   Progression.addEventPoints(p,os.time(),current.Success and 2 or 1)
   push(player);return {Ok=true,Profile=public(p,player),Message=(current.Success and "Success! +" or "Partial rewards +")..reward.." coins"}
  end
  return {Ok=false,Message="Unknown action"}
 end)
 busy[player]=nil
 if not ok then warn("Anime Nexus request error:",result);return {Ok=false,Message="Server error"} end
 return result
end
World=require(script.Parent:WaitForChild("NexusWorld")).create(Config,function(player,id)
 local p=profiles[player];return p and not closing[player] and p.Progression.Worlds[id]==true
end,message,function(player,id)
 local p=profiles[player]
 if not p or closing[player] or busy[player] or saving[player] or reconciling[player] then return false,"Please wait for your profile to finish updating" end
 local ok,result=Progression.act(p,"Discover",id,os.time())
 if ok then push(player) end
 return ok,result
end)

-- Developer products: each receipt granted at most once, using a DataStore transaction.
-- Only one ProcessReceipt handler should exist across the entire game.
local productToPotion={}
for potionId,productId in pairs(Config.Monetization.PotionProductIds) do
 if type(productId)=="number" and productId>0 then productToPotion[productId]=potionId end
end
MarketplaceService.ProcessReceipt=function(receipt)
 local potionId=productToPotion[receipt.ProductId]
 if not potionId then return Enum.ProductPurchaseDecision.NotProcessedYet end
 local player=Players:GetPlayerByUserId(receipt.PlayerId)
 if not player or not profiles[player] or busy[player] or saving[player] or closing[player] or not writable[player] or policyRestricted[player] or (reconciling[player] and reconciling[player]~="purchase") then return Enum.ProductPurchaseDecision.NotProcessedYet end
 busy[player]=true
 local p=profiles[player]
 if p.Receipts[receipt.PurchaseId] then busy[player]=nil;return Enum.ProductPurchaseDecision.PurchaseGranted end
 local snapshot=sanitize(p)
 local committed=persistence.purchase(player.UserId,snapshot,receipt.PurchaseId,potionId)
 local ok=committed~=nil
 if ok then reconciling[player]=nil;profiles[player]=sanitize(committed);push(player)
 else reconciling[player]="purchase";message(player,"Purchase pending verification. Your progress is temporarily paused to protect your collection.") end
 busy[player]=nil
 return ok and Enum.ProductPurchaseDecision.PurchaseGranted or Enum.ProductPurchaseDecision.NotProcessedYet
end
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player,passId,wasPurchased)
 if wasPurchased and passId==Config.Monetization.LuckPassId then refreshEntitlements(player);push(player) end
end)
