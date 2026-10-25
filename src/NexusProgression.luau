-- Pure progression rules: no Instances, clocks, network calls or persistence.
local P = {}
function P.new(config)
 local self = {}
 local ranks = {}; for i,r in ipairs(config.Rarities) do ranks[r]=i end
 function self.sanitize(raw, collection)
  raw=type(raw)=='table' and raw or {}
  local state={Team={},Levels={},Claims={},DailyDay=-1,DailyStreak=0,Worlds={hub=true},BossWins=0,Challenge=nil,Variants={},Quests={},Sets={},Formation="Line"}
  local seen={}
  if type(raw.Team)=='table' then for _,id in ipairs(raw.Team) do
   if #state.Team<5 and config.Cards[id] and (collection[id] or 0)>0 and not seen[id] then table.insert(state.Team,id); seen[id]=true end
  end end
  if type(raw.Levels)=='table' then for id,level in pairs(raw.Levels) do
   if config.Cards[id] and type(level)=='number' and level==level then state.Levels[id]=math.clamp(math.floor(level),1,config.CardMaxLevel) end
  end end
  if type(raw.Claims)=='table' then for _,goal in ipairs(config.Achievements) do if raw.Claims[goal.Id]==true then state.Claims[goal.Id]=true end end end
  for _,key in ipairs({'DailyDay','DailyStreak'}) do
   local n=raw[key]; if type(n)=='number' and n==n then state[key]=math.clamp(math.floor(n),key=='DailyDay' and -1 or 0,1000000) end
  end
  if config.Formations[raw.Formation] then state.Formation=raw.Formation end
  if type(raw.Quests)=='table' then for id in pairs(config.Quests) do if raw.Quests[id]==true then state.Quests[id]=true end end end
  if type(raw.Sets)=='table' then for _,set in ipairs(config.CollectionSets) do if raw.Sets[set.Id]==true then state.Sets[set.Id]=true end end end
  if type(raw.Worlds)=='table' then for id in pairs(config.Worlds) do if raw.Worlds[id]==true then state.Worlds[id]=true end end end
  if type(raw.BossWins)=='number' and raw.BossWins==raw.BossWins then state.BossWins=math.clamp(math.floor(raw.BossWins),0,1000000) end
  if type(raw.Challenge)=='table' and config.Bosses[raw.Challenge.Id] and type(raw.Challenge.EndsAt)=='number' and type(raw.Challenge.Success)=='boolean' then state.Challenge={Id=raw.Challenge.Id,EndsAt=raw.Challenge.EndsAt,Success=raw.Challenge.Success} end
  for id,count in pairs(collection) do if config.Cards[id] and count>0 then
   local variants={};local remaining=count
   local saved=type(raw.Variants)=='table' and raw.Variants[id]
   if type(saved)=='table' then
    for i=#config.VariantOrder,2,-1 do
     local name=config.VariantOrder[i];local n=saved[name]
     if type(n)=='number' and n==n then local valid=math.clamp(math.floor(n),0,remaining);if valid>0 then variants[name]=valid;remaining-=valid end end
    end
   end
   variants.Normal=remaining;state.Variants[id]=variants
  end end
  return state
 end
 function self.cardPower(p,id)
  local c=config.Cards[id]; if not c then return 0 end
  local level=p.Progression.Levels[id] or 1
  local variant=1
  for name,count in pairs(p.Progression.Variants[id] or {}) do if count>0 then variant=math.max(variant,config.Variants[name].Multiplier) end end
  return math.floor(variant*(c.Power+c.Speed*.35+c.Defense*.35+c.Energy*.3)*(1+(level-1)*.06))
 end
 function self.team(p)
  local team=table.clone(p.Progression.Team)
  if #team==0 then
   for id,n in pairs(p.Collection) do if n>0 and config.Cards[id] then table.insert(team,id) end end
   table.sort(team,function(a,b) local x,y=self.cardPower(p,a),self.cardPower(p,b); return x==y and a<b or x>y end)
   while #team>5 do table.remove(team) end
  end
  local total=0; local factions={}
  for _,id in ipairs(team) do
   total+=self.cardPower(p,id)
   local faction=config.Cards[id].Faction or 'Rift'; factions[faction]=(factions[faction] or 0)+1
  end
  local synergy=0
  for _,count in pairs(factions) do if count>=3 then synergy=math.max(synergy,.15) elseif count>=2 then synergy=math.max(synergy,.05) end end
  return math.floor(total*(1+synergy)),team,synergy
 end
 function self.upgradeCost(p,id)
  local card=config.Cards[id]; if not card then return nil end
  local level=p.Progression.Levels[id] or 1
  if level>=config.CardMaxLevel then return nil end
  return {Coins=75*level*(ranks[card.Rarity] or 1),Essence=level*2,Duplicates=1}
 end
 function self.addCard(p,id,variant)
  p.Collection[id]=(p.Collection[id] or 0)+1
  local variants=p.Progression.Variants[id] or {};p.Progression.Variants[id]=variants
  variants[variant]=(variants[variant] or 0)+1
 end
 function self.consumeDuplicate(p,id)
  local variants=p.Progression.Variants[id] or {}
  -- Only normal duplicates are consumed automatically. Rare variants are protected.
  if (variants.Normal or 0)<1 or p.Collection[id]<2 then return false end
  variants.Normal-=1;p.Collection[id]-=1;return true
 end
 function self.rollVariant(number)
  local total=0
  for _,name in ipairs(config.VariantOrder) do total+=config.Variants[name].Weight;if number<total then return name end end
  return 'Normal'
 end
 function self.bossChance(p,id)
  local boss=config.Bosses[id];if not boss then return 0 end
  local power,team=self.team(p);local stat=0
  for _,cardId in ipairs(team) do stat+=config.Cards[cardId][boss.Stat] or 0 end
  local affinity=math.min(.25,stat/(boss.Power*2))
  return math.clamp(power/boss.Power*(1+affinity),.05,.98)
 end
 function self.startBoss(p,id,now,roll)
  local boss=type(id)=='string' and config.Bosses[id]
  if not boss then return false,'Unknown boss' end
  if not p.Progression.Worlds[boss.World] then return false,'Unlock this world first' end
  if p.Progression.Challenge then return false,'Claim the current boss challenge first' end
  p.Progression.Challenge={Id=id,EndsAt=now+boss.Duration,Success=roll<self.bossChance(p,id)}
  return true,'Boss challenge started. Results are calculated by your card team.'
 end
 function self.setProgress(p,set)
  local owned=0;for _,id in ipairs(set.Cards) do if (p.Collection[id] or 0)>0 then owned+=1 end end
  return owned,#set.Cards
 end
 function self.collectionLuck(p)
  local bonus=0
  for _,set in ipairs(config.CollectionSets) do local owned,needed=self.setProgress(p,set);if owned==needed then bonus+=.02 end end
  return bonus
 end
 function self.public(p)
  local s=p.Progression
  local variants={};for id,v in pairs(s.Variants) do variants[id]=table.clone(v) end
  return {Quests=table.clone(s.Quests),Sets=table.clone(s.Sets),Formation=s.Formation,Team=table.clone(s.Team),Levels=table.clone(s.Levels),Claims=table.clone(s.Claims),DailyDay=s.DailyDay,DailyStreak=s.DailyStreak,Worlds=table.clone(s.Worlds),BossWins=s.BossWins,Variants=variants,Challenge=s.Challenge and {Id=s.Challenge.Id,EndsAt=s.Challenge.EndsAt} or nil}
 end
 function self.act(p,action,arg,now)
  local s=p.Progression
  if action=='Team' then
   if type(arg)~='string' or not config.Cards[arg] or (p.Collection[arg] or 0)<1 then return false,'Card not owned' end
   local index=table.find(s.Team,arg)
   if index then table.remove(s.Team,index)
   elseif #s.Team<5 then table.insert(s.Team,arg)
   else return false,'Your team has five cards. Remove one first.' end
   return true,#s.Team==0 and 'Automatic best team enabled' or 'Expedition team updated'
  elseif action=='Upgrade' then
   if type(arg)~='string' or not config.Cards[arg] or (p.Collection[arg] or 0)<1 then return false,'Card not owned' end
   local cost=self.upgradeCost(p,arg)
   if not cost then return false,'Maximum card level reached' end
   if p.Collection[arg]<2 or ((s.Variants[arg] or {}).Normal or 0)<1 then return false,'Upgrade needs a normal duplicate. Rare variants and your last copy are protected.' end
   if p.Coins<cost.Coins or p.Essence<cost.Essence then return false,'Not enough coins or essence' end
   self.consumeDuplicate(p,arg); p.Coins-=cost.Coins; p.Essence-=cost.Essence
   s.Levels[arg]=(s.Levels[arg] or 1)+1
   return true,config.Cards[arg].Name..' upgraded to level '..s.Levels[arg]
  elseif action=='Salvage' then
   if type(arg)~='string' or not config.Cards[arg] or (p.Collection[arg] or 0)<2 then return false,'Only duplicates can be recycled' end
   if not self.consumeDuplicate(p,arg) then return false,'Only normal duplicates can be recycled. Rare variants are protected.' end
   local reward=(ranks[config.Cards[arg].Rarity] or 1)*3
   p.Essence+=reward
   return true,'Duplicate recycled: +'..reward..' essence'
  elseif action=='Formation' then
   local def=type(arg)=='string' and config.Formations[arg]
   if not def then return false,'Unknown formation' end
   if p.Completed<def.Completed then return false,'Complete '..def.Completed..' expeditions to unlock this formation' end
   s.Formation=arg;return true,'Showcase formation: '..arg
  elseif action=='Quest' then
   local quest=type(arg)=='string' and config.Quests[arg]
   if not quest then return false,'Unknown quest' end
   if s.Quests[arg] then return false,'Quest already claimed' end
   local value=quest.Stat=='BossWins' and s.BossWins or (p[quest.Stat] or 0)
   if value<quest.Target then return false,'Quest objective incomplete' end
   s.Quests[arg]=true;p.Coins+=quest.Coins;self.addCard(p,quest.Card,'Normal')
   return true,'Quest complete! Guaranteed '..config.Cards[quest.Card].Name
  elseif action=='CollectionSet' then
   local found;for _,set in ipairs(config.CollectionSets) do if set.Id==arg then found=set end end
   if not found then return false,'Unknown collection set' end
   if s.Sets[found.Id] then return false,'Set reward already claimed' end
   local owned,needed=self.setProgress(p,found)
   if owned<needed then return false,'Discover every card in this set first' end
   s.Sets[found.Id]=true;p.Coins+=found.Coins;p.Essence+=found.Essence
   return true,'Collection set completed: '..found.Name
  elseif action=='UnlockWorld' then
   local world=type(arg)=='string' and config.Worlds[arg]
   if not world then return false,'Unknown world' end
   if s.Worlds[arg] then return false,'World already unlocked' end
   if p.Completed<world.Completed then return false,'Complete '..world.Completed..' expeditions first' end
   if p.Coins<world.Cost then return false,'Not enough coins' end
   p.Coins-=world.Cost;s.Worlds[arg]=true;return true,world.Name..' unlocked!'
  elseif action=='ClaimBoss' then
   local challenge=s.Challenge
   if not challenge then return false,'No boss challenge active' end
   if now<challenge.EndsAt then return false,'Challenge is still running' end
   local boss=config.Bosses[challenge.Id];s.Challenge=nil
   if challenge.Success then
    s.BossWins+=1;p.Coins+=boss.Reward;p.Essence+=boss.Essence;p.Crystals+=boss.Crystals
    return true,'Boss defeated! +'..boss.Reward..' coins, materials awarded'
   end
   p.Coins+=math.floor(boss.Reward*.1);return true,'Challenge failed. Consolation coins awarded; improve your team and retry.'
  elseif action=='Daily' then
   local day=math.floor(now/86400)
   if s.DailyDay>=day then return false,'Daily reward already claimed. Resets at 00:00 UTC.' end
   s.DailyStreak=s.DailyDay==day-1 and s.DailyStreak%7+1 or 1
   s.DailyDay=day
   local reward=100+s.DailyStreak*25; p.Coins+=reward; p.Essence+=s.DailyStreak
   return true,'Daily day '..s.DailyStreak..': +'..reward..' coins, +'..s.DailyStreak..' essence'
  elseif action=='Achievement' then
   local goal
   for _,g in ipairs(config.Achievements) do if g.Id==arg then goal=g; break end end
   if not goal then return false,'Unknown achievement' end
   if s.Claims[goal.Id] then return false,'Reward already claimed' end
   local value=p[goal.Stat] or 0
   if goal.Stat=='Unique' then value=0; for _,n in pairs(p.Collection) do if n>0 then value+=1 end end end
   if value<goal.Target then return false,'Achievement not complete' end
   s.Claims[goal.Id]=true; p.Coins+=goal.Coins; p.Essence+=goal.Essence
   return true,'Achievement claimed: '..goal.Name
  end
  return nil
 end
 return self
end
return P
