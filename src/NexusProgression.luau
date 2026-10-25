-- Pure progression rules: no Instances, clocks, network calls or persistence.
local P = {}
function P.new(config)
 local self = {}
 local ranks = {}; for i,r in ipairs(config.Rarities) do ranks[r]=i end
 function self.sanitize(raw, collection, now)
  raw=type(raw)=='table' and raw or {}
  local state={Team={},Levels={},Claims={},DailyDay=-1,DailyStreak=0,Worlds={hub=true},BossWins=0,Challenge=nil,Variants={},Quests={},Sets={},Formation="Line",MasteryXp={},Awakened={},Discoveries={},Chapters={},Weekly={Week=-1,Points=0,Claims={}},CoopClaims={}}
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
  if type(raw.Chapters)=='table' then for id in pairs(config.Chapters) do if raw.Chapters[id]==true then state.Chapters[id]=true end end end
  if type(raw.Weekly)=='table' and type(raw.Weekly.Week)=='number' and raw.Weekly.Week==raw.Weekly.Week then
   state.Weekly.Week=math.clamp(math.floor(raw.Weekly.Week),-1,1000000)
   if type(raw.Weekly.Points)=='number' and raw.Weekly.Points==raw.Weekly.Points then state.Weekly.Points=math.clamp(math.floor(raw.Weekly.Points),0,1000000) end
   if type(raw.Weekly.Claims)=='table' then for _,milestone in ipairs(config.WeeklyMilestones) do if raw.Weekly.Claims[milestone.Id]==true then state.Weekly.Claims[milestone.Id]=true end end end
  end
  if type(raw.CoopClaims)=='table' then
   local today=math.floor((now or os.time())/86400)
   for key,value in pairs(raw.CoopClaims) do
    local day=tonumber(key)
    if type(key)=='string' and day and day==math.floor(day) and day>=today-14 and day<=today and value==true then state.CoopClaims[key]=true end
   end
  end
  if type(raw.Discoveries)=='table' then for _,list in pairs(config.Discoveries) do for _,id in ipairs(list) do if raw.Discoveries[id]==true then state.Discoveries[id]=true end end end end
  if type(raw.Worlds)=='table' then for id in pairs(config.Worlds) do if raw.Worlds[id]==true then state.Worlds[id]=true end end end
  if type(raw.BossWins)=='number' and raw.BossWins==raw.BossWins then state.BossWins=math.clamp(math.floor(raw.BossWins),0,1000000) end
  if type(raw.Challenge)=='table' and config.Bosses[raw.Challenge.Id] and type(raw.Challenge.EndsAt)=='number' and type(raw.Challenge.Success)=='boolean' then
   local team={};local seen={}
   if type(raw.Challenge.Team)=='table' then for _,id in ipairs(raw.Challenge.Team) do if #team<5 and config.Cards[id] and not seen[id] then table.insert(team,id);seen[id]=true end end end
   state.Challenge={Id=raw.Challenge.Id,EndsAt=math.floor(raw.Challenge.EndsAt),Success=raw.Challenge.Success,Team=team}
  end
  for id,count in pairs(collection) do if config.Cards[id] and count>0 then
   if type(raw.MasteryXp)=='table' then local xp=raw.MasteryXp[id];if type(xp)=='number' and xp==xp then state.MasteryXp[id]=math.clamp(math.floor(xp),0,100000) end end
   if type(raw.Awakened)=='table' and raw.Awakened[id]==true then state.Awakened[id]=true end
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
 function self.masteryRank(p,id)
  local xp=p.Progression.MasteryXp[id] or 0
  local rank=1
  while rank<config.MasteryMaxRank and xp>=rank*50 do xp-=rank*50;rank+=1 end
  return rank,xp,rank<config.MasteryMaxRank and rank*50 or 0
 end
 function self.grantMastery(p,team,amount)
  local seen={}
  for _,id in ipairs(team or {}) do
   if not seen[id] and config.Cards[id] and (p.Collection[id] or 0)>0 then
    seen[id]=true;p.Progression.MasteryXp[id]=math.min(100000,(p.Progression.MasteryXp[id] or 0)+amount)
   end
  end
 end
 function self.event(now)
  local week=math.floor(now/604800)
  return config.WeeklyEvents[(week%#config.WeeklyEvents)+1],week,(week+1)*604800
 end
 function self.eventProgress(p,now)
  local _,week=self.event(now)
  local saved=p.Progression.Weekly
  if saved.Week~=week then return {Week=week,Points=0,Claims={}} end
  return {Week=week,Points=saved.Points,Claims=table.clone(saved.Claims)}
 end
 function self.addEventPoints(p,now,points)
  local _,week=self.event(now)
  local weekly=p.Progression.Weekly
  if weekly.Week~=week then weekly.Week=week;weekly.Points=0;weekly.Claims={} end
  weekly.Points=math.min(1000000,weekly.Points+points)
 end
 function self.cardPower(p,id)
  local c=config.Cards[id]; if not c then return 0 end
  local level=p.Progression.Levels[id] or 1
  local variant=1
  for name,count in pairs(p.Progression.Variants[id] or {}) do if count>0 then variant=math.max(variant,config.Variants[name].Multiplier) end end
  local awakened=p.Progression.Awakened[id] and config.Awakening.PowerMultiplier or 1
  return math.floor(awakened*variant*(c.Power+c.Speed*.35+c.Defense*.35+c.Energy*.3)*(1+(level-1)*.06))
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
  local power,team=self.team(p);local stat=0;local traitBonus=0
  for _,cardId in ipairs(team) do
   local card=config.Cards[cardId];stat+=card[boss.Stat] or 0
   if boss.WeaknessTraits and boss.WeaknessTraits[card.Trait] then traitBonus+=.04 end
  end
  local affinity=math.min(.25,stat/(boss.Power*2))
  return math.clamp(power/boss.Power*(1+affinity+math.min(.12,traitBonus)),.05,.98)
 end
 function self.expeditionPlan(p,id,routeId)
  local expedition=config.Expeditions[id]
  local route=config.ExpeditionRoutes[routeId]
  if not expedition or not route then return nil end
  local power,team=self.team(p)
  local speed=0;local favored=0;local traitBonus=0
  for _,cardId in ipairs(team) do
   local card=config.Cards[cardId];speed+=card.Speed
   favored+=card[route.Stat] or 0
   local effect=config.TraitEffects[card.Trait]
   if effect and effect.Route==routeId then traitBonus+=effect.ChanceBonus end
  end
  local statBonus=math.min(.18,favored/(expedition.RequiredPower*3))
  local chance=math.clamp((power/expedition.RequiredPower)*(1+statBonus+math.min(.15,traitBonus))*route.Chance,.2,.98)
  local duration=math.max(10,math.ceil(expedition.Duration*route.Duration*(1-math.min(.25,speed/10000))))
  local reward=math.floor(expedition.Reward*route.Reward)
  return {Chance=chance,Duration=duration,Reward=reward,Team=team,Route=routeId,TraitBonus=math.min(.15,traitBonus)}
 end
 function self.startBoss(p,id,now,roll)
  local boss=type(id)=='string' and config.Bosses[id]
  if not boss then return false,'Unknown boss' end
  if not p.Progression.Worlds[boss.World] then return false,'Unlock this world first' end
  if p.Progression.Challenge then return false,'Claim the current boss challenge first' end
  local _,team=self.team(p)
  p.Progression.Challenge={Id=id,EndsAt=now+boss.Duration,Success=roll<self.bossChance(p,id),Team=team}
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
 function self.public(p,now)
  local s=p.Progression
  local variants={};for id,v in pairs(s.Variants) do variants[id]=table.clone(v) end
  return {Quests=table.clone(s.Quests),Sets=table.clone(s.Sets),Formation=s.Formation,Team=table.clone(s.Team),Levels=table.clone(s.Levels),Claims=table.clone(s.Claims),DailyDay=s.DailyDay,DailyStreak=s.DailyStreak,Worlds=table.clone(s.Worlds),BossWins=s.BossWins,Variants=variants,Challenge=s.Challenge and {Id=s.Challenge.Id,EndsAt=s.Challenge.EndsAt} or nil,MasteryXp=table.clone(s.MasteryXp),Awakened=table.clone(s.Awakened),Discoveries=table.clone(s.Discoveries),Chapters=table.clone(s.Chapters),Weekly=self.eventProgress(p,now or os.time()),CoopClaims=table.clone(s.CoopClaims)}
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
  elseif action=='Awaken' then
   if type(arg)~='string' or not config.Cards[arg] or (p.Collection[arg] or 0)<1 then return false,'Card not owned' end
   if s.Awakened[arg] then return false,'Card already awakened' end
   local recipe=config.Awakening
   if (s.Levels[arg] or 1)<recipe.Level or self.masteryRank(p,arg)<recipe.MasteryRank or s.BossWins<recipe.BossWins then return false,'Reach card level 25, mastery rank 5 and three boss victories' end
   if p.Essence<recipe.Essence or p.Crystals<recipe.Crystals then return false,'Not enough awakening materials' end
   p.Essence-=recipe.Essence;p.Crystals-=recipe.Crystals;s.Awakened[arg]=true
   return true,config.Cards[arg].Name..' awakened!'
  elseif action=='Discover' then
   local known=false
   for world,list in pairs(config.Discoveries) do
    for _,id in ipairs(list) do if id==arg and s.Worlds[world] then known=true end end
   end
   if not known then return false,'This memory cannot be reached yet' end
   if s.Discoveries[arg] then return false,'Memory already discovered' end
   s.Discoveries[arg]=true;p.Coins+=20;p.Essence+=2
   return true,'Memory discovered: '..config.DiscoveryNames[arg]..' (+20 coins, +2 essence)'
  elseif action=='Chapter' then
   local chapter=type(arg)=='string' and config.Chapters[arg]
   if not chapter then return false,'Unknown chapter' end
   if s.Chapters[arg] then return false,'Chapter already completed' end
   local index=table.find(config.ChapterOrder,arg)
   if index>1 and not s.Chapters[config.ChapterOrder[index-1]] then return false,'Finish the previous chapter first' end
   if not s.Worlds[chapter.World] or p.Completed<chapter.Completed or s.BossWins<chapter.BossWins then return false,'Chapter objectives incomplete' end
   for _,id in ipairs(config.Discoveries[chapter.World]) do if not s.Discoveries[id] then return false,'Explore every memory in this world' end end
   s.Chapters[arg]=true;p.Coins+=chapter.Coins;p.Essence+=chapter.Essence;self.addCard(p,chapter.Card,'Normal')
   return true,chapter.Name..' complete! Guaranteed '..config.Cards[chapter.Card].Name
  elseif action=='EventClaim' then
   local milestone
   for _,candidate in ipairs(config.WeeklyMilestones) do if candidate.Id==arg then milestone=candidate end end
   if not milestone then return false,'Unknown weekly reward' end
   local event,week=self.event(now)
   local weekly=s.Weekly
   if weekly.Week~=week or weekly.Points<milestone.Points then return false,'Earn more weekly points first' end
   if weekly.Claims[arg] then return false,'Weekly reward already claimed' end
   weekly.Claims[arg]=true;p.Coins+=milestone.Coins;p.Essence+=milestone.Essence
   if milestone.EventCard then self.addCard(p,event.Card,'Normal') end
   return true,milestone.EventCard and ('Weekly reward claimed! Guaranteed '..config.Cards[event.Card].Name) or 'Weekly reward claimed!'
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
   self.grantMastery(p,challenge.Team,challenge.Success and 50 or 12)
   self.addEventPoints(p,now,challenge.Success and 3 or 1)
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
   self.addEventPoints(p,now,1)
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
