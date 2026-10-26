local count=0
local function test(name,fn)
 local ok,err=pcall(fn);if not ok then error('FAIL '..name..': '..tostring(err),0) end
 count+=1;print('PASS '..name)
end
local rules=P.new(Config)
local function profile(collection)
 local p={Coins=10000,Essence=1000,Crystals=0,Collection=collection or {recruit=4,spark=2},Completed=0,Rolls=0}
 p.Progression=rules.sanitize(nil,p.Collection);return p
end
local function total(t)local n=0;for _,v in pairs(t) do n+=v end;return n end

test('roster stable identities and valid rarity pools',function()
 local ids={};local originals=0;local fiction=0
 for id,c in pairs(Config.Cards) do
  assert(not ids[id]);ids[id]=true
  assert(table.find(Config.Rarities,c.Rarity));assert(Config.Factions[c.Faction])
  assert(c.Power>0 and c.Speed>0 and c.Energy>0 and c.Defense>0)
  assert(c.Identity and c.Identity.DisplayName==c.Name)
  assert(type(c.Lore)=='string' and #c.Lore>20)
  if c.Universe then fiction+=1 else originals+=1 end
 end
 assert(originals==36,originals);assert(fiction>=150,fiction)
 print('Roster: '..originals..' originals + '..fiction..' configurable fiction identities')
end)
test('pack weights total 100 and every rarity has candidates',function()
 for _,pack in pairs(Config.Packs) do
  assert(math.abs(total(pack.Weights)-100)<.000001)
  for rarity,w in pairs(pack.Weights) do if w>0 then
   local n=0;for _,c in pairs(Config.Cards) do if c.Rarity==rarity and c.Enabled~=false then n+=1 end end;assert(n>0)
  end end
 end
end)
test('summon reel lands on the server winner and uses active pack cards',function()
 local visual=SummonVisual.new(Config)
 local rng={NextNumber=function(_,low,high)return (low+high)*.5 end,NextInteger=function(_,low,high)return high end}
 for packId,pack in pairs(Config.Packs) do
  local winner
  for id,card in pairs(Config.Cards) do if card.Enabled~=false and (pack.Weights[card.Rarity] or 0)>0 then winner=id;break end end
  local reel,target=visual.sequence(packId,winner,rng)
  assert(#reel==38 and target==34 and reel[target]==winner)
  for _,id in ipairs(reel) do local card=Config.Cards[id];assert(card.Enabled~=false and (pack.Weights[card.Rarity] or 0)>0) end
 end
 assert(not visual.sequence('missing','recruit',rng))
 assert(not visual.sequence('basic','missing',rng))
end)
test('portrait atlases map every character once',function()
 local seen={}
 for id,card in pairs(Config.Cards) do
  local cell=card.Identity.PortraitAtlasCell
  local atlas=card.Identity.PortraitAtlas
  assert(cell and atlas and atlas>=1 and atlas<=23 and cell>=1 and cell<=9)
  local key=atlas..':'..cell;assert(not seen[key]);seen[key]=id
 end
 for atlas=1,4 do for cell=1,9 do assert(seen[atlas..':'..cell]) end end
 for atlas=5,22 do for cell=1,9 do assert(seen[atlas..':'..cell]) end end
 for cell=1,6 do assert(seen['23:'..cell]) end
end)
test('public roster mode disables unverified summons without deleting identities',function()
 local copy=table.clone(Config);copy.Cards={};copy.RosterMode='Public';roster.apply(copy)
 for _,c in pairs(copy.Cards) do assert(c.Enabled==false) end
 assert(next(copy.Cards))
end)
test('legacy collection migrates to normal variants and automatic team',function()
 local p=profile();assert(p.Progression.Variants.recruit.Normal==4)
 local power,team=rules.team(p);assert(power>0 and #team==2)
end)
test('sanitization removes unknowns, duplicate team slots and invalid levels',function()
 local s=rules.sanitize({Team={'recruit','recruit','missing','spark'},Levels={recruit=999,spark=-2,missing=10},Worlds={missing=true},Claims={fake=true}},{recruit=1,spark=1})
 assert(#s.Team==2 and s.Levels.recruit==100 and s.Levels.spark==1)
 assert(s.Worlds.hub and not s.Worlds.missing and not s.Claims.fake)
end)
test('manual teams enforce ownership and five unique slots',function()
 local c={};local ids={};for id in pairs(Config.Cards) do if #ids<6 then c[id]=1;table.insert(ids,id) end end
 local p=profile(c)
 for i=1,5 do assert(rules.act(p,'Team',ids[i],0)) end
 assert(not rules.act(p,'Team',ids[6],0));assert(not rules.act(p,'Team','missing',0))
 assert(rules.act(p,'Team',ids[1],0));assert(#p.Progression.Team==4)
end)
test('faction synergy applies 5% for two and 15% for three',function()
 local p=profile({spark=1,sentinel=1,thunder=1})
 p.Progression.Team={'spark','sentinel'};local _,_,bonus=rules.team(p);assert(bonus==.05)
 table.insert(p.Progression.Team,'thunder');local _,_,three=rules.team(p);assert(three==.15)
end)
test('upgrade atomically spends exact resources and one normal duplicate',function()
 local p=profile();local before=rules.cardPower(p,'recruit');local cost=rules.upgradeCost(p,'recruit')
 local coins,essence=p.Coins,p.Essence
 assert(rules.act(p,'Upgrade','recruit',0));assert(p.Collection.recruit==3)
 assert(p.Coins==coins-cost.Coins and p.Essence==essence-cost.Essence)
 assert(p.Progression.Levels.recruit==2 and rules.cardPower(p,'recruit')>before)
 assert(p.Progression.Variants.recruit.Normal==3)
end)
test('insufficient upgrade cannot spend or destroy cards',function()
 local p=profile();p.Essence=0;local coins=p.Coins
 assert(not rules.act(p,'Upgrade','recruit',0));assert(p.Coins==coins and p.Collection.recruit==4)
end)
test('last card and rare variants cannot be recycled accidentally',function()
 local p=profile({recruit=1});assert(not rules.act(p,'Salvage','recruit',0))
 rules.addCard(p,'recruit','Shiny');assert(rules.act(p,'Salvage','recruit',0))
 assert(p.Collection.recruit==1 and p.Progression.Variants.recruit.Shiny==1)
 rules.addCard(p,'recruit','Corrupted');assert(not rules.act(p,'Upgrade','recruit',0));assert(not rules.act(p,'Salvage','recruit',0))
end)
test('variant roll boundaries and exact population match configured weights',function()
 local tally={}
 for i=0,9999 do local v=rules.rollVariant(i+.5);tally[v]=(tally[v] or 0)+1 end
 for name,def in pairs(Config.Variants) do assert(tally[name]==def.Weight,name) end
end)
test('best owned variant increases effective power once',function()
 local p=profile({recruit=1});local base=rules.cardPower(p,'recruit')
 rules.addCard(p,'recruit','Celestial');assert(rules.cardPower(p,'recruit')>=base*1.49)
 rules.addCard(p,'recruit','Celestial');local power=rules.cardPower(p,'recruit');assert(power<base*1.51)
end)
test('variant migration cannot mint extra copies',function()
 local s=rules.sanitize({Variants={recruit={Celestial=999,Shiny=999}}},{recruit=3})
 assert(total(s.Variants.recruit)==3 and s.Variants.recruit.Celestial==3)
end)
test('daily rewards are once per UTC day and streak resets after a gap',function()
 local p=profile();assert(rules.act(p,'Daily',nil,10*86400));local coins=p.Coins
 assert(not rules.act(p,'Daily',nil,10*86400+86399));assert(p.Coins==coins)
 assert(rules.act(p,'Daily',nil,11*86400));assert(p.Progression.DailyStreak==2)
 assert(rules.act(p,'Daily',nil,13*86400));assert(p.Progression.DailyStreak==1)
 for day=14,20 do assert(rules.act(p,'Daily',nil,day*86400)) end
 assert(p.Progression.DailyStreak==1)
end)
test('achievement requires progress and cannot be double claimed',function()
 local p=profile();assert(not rules.act(p,'Achievement','first_summon',0))
 p.Rolls=1;assert(rules.act(p,'Achievement','first_summon',0));local coins=p.Coins
 assert(not rules.act(p,'Achievement','first_summon',0));assert(p.Coins==coins)
end)
test('world unlock requires milestones and spends once',function()
 local p=profile();assert(not rules.act(p,'UnlockWorld','neon',0));p.Completed=5
 local coins=p.Coins;assert(rules.act(p,'UnlockWorld','neon',0));assert(p.Coins==coins-500 and p.Progression.Worlds.neon)
 assert(not rules.act(p,'UnlockWorld','neon',0));assert(not rules.act(p,'UnlockWorld','bad',0))
end)
test('boss gates, timers, rewards and hidden outcomes',function()
 local p=profile();assert(not rules.startBoss(p,'overseer',100,0))
 assert(rules.startBoss(p,'guardian',100,0));assert(not rules.startBoss(p,'guardian',100,0))
 assert(rules.public(p).Challenge.Success==nil)
 assert(not rules.act(p,'ClaimBoss',nil,144));assert(rules.act(p,'ClaimBoss',nil,145))
 assert(p.Progression.BossWins==1 and p.Crystals==1)
 assert(not rules.act(p,'ClaimBoss',nil,200))
end)
test('failed boss grants consolation but no win or materials',function()
 local p=profile();local coins=p.Coins;assert(rules.startBoss(p,'guardian',0,1))
 assert(rules.act(p,'ClaimBoss',nil,45));assert(p.Progression.BossWins==0 and p.Crystals==0 and p.Coins==coins+18)
end)
test('public progression tables cannot mutate authoritative state',function()
 local p=profile();local public=rules.public(p);public.Variants.recruit.Normal=999;public.Worlds.astral=true;table.insert(public.Team,'spark')
 assert(p.Progression.Variants.recruit.Normal==4 and not p.Progression.Worlds.astral and #p.Progression.Team==0)
end)
local function fakeStore()
 local store={data={},fail=false}
 function store:GetAsync(key)
  if self.fail then error('Simulated outage') end
  return self.data[key]
 end
 function store:UpdateAsync(key,fn)
  if self.fail then error('Simulated outage') end
  local result=fn(self.data[key]);if result~=nil then self.data[key]=result end;return result
 end
 return store
end
test('persistence lease excludes another active server and releases on exit',function()
 local store=fakeStore();local time=100
 local a=Persistence.new(store,'a',function()return time end);local b=Persistence.new(store,'b',function()return time end)
 assert(a.load(1));local data,err=b.load(1);assert(not data and err=='locked')
 assert(a.save(1,{Coins=500,Receipts={}},true));assert(b.load(1).Coins==500)
 assert(not a.save(1,{Coins=0},false))
end)
test('expired lease is recoverable and former server cannot overwrite',function()
 local store=fakeStore();local time=0
 local a=Persistence.new(store,'a',function()return time end);local b=Persistence.new(store,'b',function()return time end)
 assert(a.load(1));time=181;assert(b.load(1));assert(not a.save(1,{Coins=0},false))
end)
test('failed load cannot later save a temporary profile',function()
 local store=fakeStore();store.data.user_1={Coins=777};store.fail=true
 local a=Persistence.new(store,'a',function()return 0 end)
 assert(not a.load(1));store.fail=false;assert(not a.save(1,{Coins=0},false));assert(store.data.user_1.Coins==777)
end)
test('save failure preserves state and receipt history survives later save',function()
 local store=fakeStore();local a=Persistence.new(store,'a',function()return 0 end);assert(a.load(1))
 assert(a.save(1,{Coins=600,Receipts={paid=true}},false));store.fail=true
 assert(not a.save(1,{Coins=0},false));store.fail=false;assert(store.data.user_1.Coins==600)
 assert(a.save(1,{Coins=800,Receipts={}},false));assert(store.data.user_1.Receipts.paid==true)
end)
test('quest awards a guaranteed card once and keeps variant counts consistent',function()
 local p=profile();assert(not rules.act(p,'Quest','first_steps',0));p.Completed=2
 assert(rules.act(p,'Quest','first_steps',0));assert(p.Collection.sentinel==1 and p.Progression.Variants.sentinel.Normal==1)
 assert(not rules.act(p,'Quest','first_steps',0));assert(not rules.act(p,'Quest','missing',0))
end)
test('collection bonuses require all set cards and rewards are single claim',function()
 local p=profile({recruit=1,spark=1,sentinel=1})
 assert(rules.collectionLuck(p)==0 and not rules.act(p,'CollectionSet','first_alliance',0))
 rules.addCard(p,'ember','Normal');assert(rules.collectionLuck(p)==.02)
 assert(rules.act(p,'CollectionSet','first_alliance',0));assert(not rules.act(p,'CollectionSet','first_alliance',0))
end)
test('formations have progression gates',function()
 local p=profile();assert(not rules.act(p,'Formation','Orbit',0));assert(not rules.act(p,'Formation','bad',0))
 p.Completed=15;assert(rules.act(p,'Formation','Orbit',0));assert(p.Progression.Formation=='Orbit')
end)
test('purchase transaction is idempotent and retains session ownership',function()
 local store=fakeStore();local a=Persistence.new(store,'a',function()return 0 end);assert(a.load(1))
 local payload={Coins=600,Potions={},Receipts={}}
 local first=a.purchase(1,payload,'receipt-1','minor');assert(first.Potions.minor==1)
 local second=a.purchase(1,payload,'receipt-1','minor');assert(second.Potions.minor==1 and second.Receipts['receipt-1'])
 assert(a.save(1,second,true));assert(store.data.user_1._Session==nil)
end)
test('purchase denial and outage cannot report a grant',function()
 local store=fakeStore();local a=Persistence.new(store,'a',function()return 0 end)
 assert(not a.purchase(1,{Potions={},Receipts={}},'r','minor'));assert(a.load(1))
 store.fail=true;assert(not a.purchase(1,{Potions={},Receipts={}},'r','minor'))
end)
test('mastery follows expedition team and awakening is earned deliberately',function()
 local p=profile({recruit=2,spark=1})
 local base=rules.cardPower(p,'recruit')
 rules.grantMastery(p,{'recruit','recruit','spark'},250)
 assert(p.Progression.MasteryXp.recruit==250 and p.Progression.MasteryXp.spark==250)
 local rank=rules.masteryRank(p,'recruit');assert(rank>=3)
 assert(not rules.act(p,'Awaken','recruit',0))
 p.Progression.Levels.recruit=25;p.Progression.MasteryXp.recruit=500;p.Progression.BossWins=3
 assert(not rules.act(p,'Awaken','recruit',0))
 p.Progression.MasteryXp.recruit=600;p.Crystals=Config.Awakening.Crystals
 assert(rules.act(p,'Awaken','recruit',0))
 assert(p.Progression.Awakened.recruit and not rules.act(p,'Awaken','recruit',0))
 assert(rules.cardPower(p,'recruit')>base*2)
end)
test('route planning honors selected cards, risk and speed',function()
 local p=profile()
 local steady=rules.expeditionPlan(p,'scouting','steady')
 local swift=rules.expeditionPlan(p,'scouting','swift')
 local perilous=rules.expeditionPlan(p,'scouting','perilous')
 assert(steady and swift and perilous and not rules.expeditionPlan(p,'scouting','missing'))
 assert(swift.Duration<steady.Duration and perilous.Reward>steady.Reward)
 assert(perilous.Chance<=steady.Chance and #steady.Team>0)
 assert(steady.TraitBonus>0 and swift.TraitBonus>0)
 for _,card in pairs(Config.Cards) do assert(Config.TraitEffects[card.Trait]) end
end)
test('memory discoveries are unique and chapter rewards require prior story',function()
 local p=profile();p.Completed=30;p.Progression.BossWins=5
 assert(not rules.act(p,'Chapter','fracture',0))
 for _,id in ipairs(Config.Discoveries.hub) do assert(rules.act(p,'Discover',id,0));assert(not rules.act(p,'Discover',id,0)) end
 local count=p.Collection.warden or 0
 assert(rules.act(p,'Chapter','fracture',0));assert(p.Collection.warden==count+1)
 assert(not rules.act(p,'Chapter','fracture',0))
 for _,id in ipairs(Config.Discoveries.neon) do assert(not rules.act(p,'Discover',id,0)) end
 assert(rules.act(p,'UnlockWorld','neon',0))
 for _,id in ipairs(Config.Discoveries.neon) do assert(rules.act(p,'Discover',id,0)) end
 assert(rules.act(p,'Chapter','neon',0));assert(p.Collection.gunslinger==1)
end)
test('new progression fields survive migration and public snapshots are isolated',function()
 local p=profile({recruit=1})
 p.Progression.MasteryXp.recruit=600;p.Progression.Awakened.recruit=true
 p.Progression.Discoveries.hub_archive=true;p.Progression.Chapters.fracture=true
 local restored=rules.sanitize(p.Progression,p.Collection)
 assert(restored.MasteryXp.recruit==600 and restored.Awakened.recruit)
 assert(restored.Discoveries.hub_archive and restored.Chapters.fracture)
 local public=rules.public(p);public.MasteryXp.recruit=0;public.Discoveries.hub_archive=false
 assert(p.Progression.MasteryXp.recruit==600 and p.Progression.Discoveries.hub_archive)
end)
test('weekly event points rotate on UTC boundaries and rewards claim once',function()
 local p=profile();local first=rules.event(0)
 assert(first==Config.WeeklyEvents[1])
 rules.addEventPoints(p,10,5)
 assert(rules.eventProgress(p,10).Points==5)
 local before=p.Coins
 assert(rules.act(p,'EventClaim','first',10))
 assert(p.Coins==before+200 and not rules.act(p,'EventClaim','first',10))
 assert(rules.eventProgress(p,604800).Points==0)
 assert(not rules.act(p,'EventClaim','first',604800))
 rules.addEventPoints(p,604800,35)
 assert(rules.act(p,'EventClaim','final',604800))
 local event=rules.event(604800)
 assert(p.Collection[event.Card]==1 and p.Progression.Variants[event.Card].Normal==1)
end)
test('daily and boss claims grant weekly points without exposing boss result',function()
 local p=profile();assert(rules.act(p,'Daily',nil,100))
 assert(rules.public(p,100).Weekly.Points==1)
 assert(rules.startBoss(p,'guardian',100,0))
 assert(rules.public(p,100).Challenge.Success==nil)
 assert(rules.act(p,'ClaimBoss',nil,145))
 assert(rules.public(p,145).Weekly.Points==4)
end)
test('global rankings write bounded scores and cache top ten reads',function()
 local now=0;local boards={}
 local service={GetOrderedDataStore=function(_,name)
  local db={data={},reads=0,writes=0}
  function db:SetAsync(key,value)self.data[key]=value;self.writes+=1 end
  function db:GetSortedAsync(ascending,limit)
   self.reads+=1;local rows={}
   for key,value in pairs(self.data) do table.insert(rows,{key=key,value=value}) end
   table.sort(rows,function(a,b)return ascending and a.value<b.value or a.value>b.value end)
   while #rows>limit do table.remove(rows) end
   return {GetCurrentPage=function()return rows end}
  end
  boards[name]=db;return db
 end}
 local players={GetNameFromUserIdAsync=function(_,id)return 'Player'..id end}
 local ranks=Rankings.new(service,players,function()return now end)
 assert(ranks.update(7,{Cards=3,Power=500,Bosses=1}))
 assert(boards.AnimeNexusPower_v1.data['7']==500)
 assert(ranks.update(7,{Cards=5,Power=600,Bosses=2}))
 assert(boards.AnimeNexusPower_v1.data['7']==500)
 local rows=ranks.top('Power');assert(rows[1].Name=='Player7' and rows[1].Score==500)
 assert(ranks.top('Power')[1].Score==500 and boards.AnimeNexusPower_v1.reads==1)
 now=301;assert(ranks.update(7,{Cards=5,Power=600,Bosses=2}))
 assert(ranks.top('Power')[1].Score==600)
 assert(not ranks.top('invalid'))
end)
test('ranking read outage serves cached scores without claiming fresh data',function()
 local now=0;local broken=false;local board={}
 function board:SetAsync()end
 function board:GetSortedAsync()
  if broken then error('outage') end
  return {GetCurrentPage=function()return {{key='4',value=10}} end}
 end
 local service={GetOrderedDataStore=function()return board end}
 local players={GetNameFromUserIdAsync=function()return 'Ada' end}
 local ranks=Rankings.new(service,players,function()return now end)
 assert(ranks.top('Cards')[1].Name=='Ada')
 broken=true;now=61
 local rows,notice=ranks.top('Cards');assert(rows and rows[1].Score==10 and notice)
end)
test('shared boss counts each player once across servers',function()
 local store=fakeStore();local now=10
 local service={GetDataStore=function()return store end}
 local a=Coop.new(service,function()return now end)
 local b=Coop.new(service,function()return now end)
 assert(a.contribute(0,11,500)==500)
 assert(a.status(0,11).Total==500)
 assert(b.contribute(0,11,900)==500)
 assert(b.contribute(0,12,1000)==1000)
 local status=b.status(0,11)
 assert(status.Total==1500 and status.Participants==2 and status.Contribution==500)
 assert(not a.contribute(-1,11,500))
 now=86400;assert(not a.contribute(0,15,300))
 local ended=a.status(0,12);assert(ended.Ended and not ended.Complete and ended.Total==1500)
 assert(ended.Contribution==1000)
end)
test('shared boss rejects incomplete reads and never grants a fictional win',function()
 local store=fakeStore();local service={GetDataStore=function()return store end}
 local coop=Coop.new(service,function()return 86400 end)
 store.fail=true;assert(not coop.status(0,1))
 store.fail=false;assert(coop.status(0,1).Total==0)
 assert(not coop.status(-8,1))
end)
test('shared reward uses an atomic and idempotent profile transaction',function()
 local store=fakeStore();local persistence=Persistence.new(store,'coop-owner',function()return 86400 end)
 assert(persistence.load(22))
 local payload={Coins=100,Essence=2,Crystals=0,Progression={CoopClaims={}},Receipts={}}
 local reward={Coins=50,Essence=5,Crystals=0}
 local first=persistence.claimCoop(22,payload,0,reward)
 assert(first.Coins==150 and first.Progression.CoopClaims['0'])
 local replay=persistence.claimCoop(22,payload,0,reward)
 assert(replay.Coins==150 and replay.Essence==7)
end)
