-- Responsive collection interface. Every mutation is validated by the server.
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local TweenService=game:GetService('TweenService')
local me=Players.LocalPlayer
local gui=Instance.new('ScreenGui');gui.Name='AnimeNexusGui';gui.ResetOnSpawn=false;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Parent=me:WaitForChild('PlayerGui')
local function make(class,parent,props)
 local o=Instance.new(class);for k,v in pairs(props or {}) do o[k]=v end;o.Parent=parent;return o
end
local palette={bg=Color3.fromRGB(14,18,31),surface=Color3.fromRGB(25,32,52),muted=Color3.fromRGB(159,177,202),accent=Color3.fromRGB(101,218,229),text=Color3.fromRGB(236,242,255),button=Color3.fromRGB(48,68,110)}
local function corner(o,r) make('UICorner',o,{CornerRadius=UDim.new(0,r or 10)}) end
local main=make('Frame',gui,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.new(1,-24,1,-24),BackgroundColor3=palette.bg,BorderSizePixel=0});corner(main,16)
make('UISizeConstraint',main,{MaxSize=Vector2.new(1100,850)})
make('UIStroke',main,{Color=Color3.fromRGB(55,82,115),Thickness=1})
make('TextLabel',main,{Position=UDim2.fromOffset(18,12),Size=UDim2.new(1,-75,0,28),Text='ANIME NEXUS',TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.GothamBlack,TextSize=23,TextColor3=palette.text,BackgroundTransparency=1})
local wallet=make('TextLabel',main,{Position=UDim2.fromOffset(18,44),Size=UDim2.new(1,-36,0,24),Text='Connecting to the Nexus…',TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.Gotham,TextSize=13,TextColor3=palette.accent,BackgroundTransparency=1})
local tabs=make('ScrollingFrame',main,{Position=UDim2.fromOffset(12,78),Size=UDim2.new(1,-24,0,42),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.X,ScrollingDirection=Enum.ScrollingDirection.X,ScrollBarThickness=2})
make('UIListLayout',tabs,{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder})
local panel=make('ScrollingFrame',main,{Position=UDim2.fromOffset(12,132),Size=UDim2.new(1,-24,1,-200),BackgroundColor3=palette.surface,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=4});corner(panel)
make('UIPadding',panel,{PaddingTop=UDim.new(0,12),PaddingBottom=UDim.new(0,18),PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)})
make('UIListLayout',panel,{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
local toast=make('TextLabel',main,{Position=UDim2.new(0,18,1,-62),Size=UDim2.new(1,-36,0,50),Text='Welcome to the Nexus',TextWrapped=true,TextColor3=palette.accent,BackgroundTransparency=1,Font=Enum.Font.GothamMedium,TextSize=13})
local toggle=make('TextButton',gui,{Position=UDim2.fromOffset(12,12),Size=UDim2.fromOffset(145,38),Text='OPEN NEXUS',Visible=false,BackgroundColor3=palette.button,TextColor3=palette.text,Font=Enum.Font.GothamBold,TextSize=14});corner(toggle)
local close=make('TextButton',main,{Position=UDim2.new(1,-48,0,12),Size=UDim2.fromOffset(32,30),Text='×',TextSize=25,BackgroundTransparency=1,TextColor3=palette.muted})
close.Activated:Connect(function()main.Visible=false;toggle.Visible=true end)
toggle.Activated:Connect(function()main.Visible=true;toggle.Visible=false end)
local Config,Rules,Remote,state
local tab='Overview';local locked=false;local render;local tabButtons={};local rarityFilter='All';local confirmSalvage=nil;local timers={};local searchQuery='';local page=1;local ownedOnly=false
local search=make('TextBox',main,{Position=UDim2.fromOffset(12,128),Size=UDim2.new(1,-24,0,36),PlaceholderText='Search name, universe, faction or trait…',ClearTextOnFocus=false,Text='',TextColor3=palette.text,PlaceholderColor3=palette.muted,BackgroundColor3=palette.surface,Font=Enum.Font.Gotham,TextSize=14,Visible=false});corner(search,7)
local function text(msg,height,color)
 return make('TextLabel',panel,{Size=UDim2.new(1,-8,0,height or 42),Text=msg,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1,TextColor3=color or palette.text,Font=Enum.Font.Gotham,TextSize=14})
end
local function heading(msg) return text(msg,32,palette.accent) end
local function button(msg,callback,enabled)
 local b=make('TextButton',panel,{Size=UDim2.new(1,-8,0,42),Text=msg,TextWrapped=true,BackgroundColor3=enabled==false and Color3.fromRGB(46,49,62) or palette.button,TextColor3=enabled==false and palette.muted or palette.text,Font=Enum.Font.GothamBold,TextSize=13,AutoButtonColor=enabled~=false,BorderSizePixel=0});corner(b,7)
 b.Activated:Connect(function()if enabled~=false then callback() end end);return b
end
local function request(action,arg)
 if locked or not Remote then return nil end
 locked=true
 local ok,result=pcall(function()return Remote:InvokeServer(action,arg)end)
 locked=false
 if not ok then toast.Text='Connection interrupted. Please try again.';return nil end
 if type(result)~='table' then toast.Text='Invalid server response';return nil end
 if result.Profile then state=result.Profile end
 if result.Message then toast.Text=result.Message end
 return result
end
local function reveal(id,variant)
 local c=Config.Cards[id];if not c then return end
 local cover=make('TextButton',gui,{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.25,Text='',ZIndex=20})
 local card=make('Frame',cover,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(230,290),BackgroundColor3=palette.surface,ZIndex=21});corner(card,18)
 make('UIStroke',card,{Color=c.Color,Thickness=3})
 local function line(y,h,msg,size,color)
  make('TextLabel',card,{Position=UDim2.new(0,12,0,y),Size=UDim2.new(1,-24,0,h),Text=msg,TextWrapped=true,Font=Enum.Font.GothamBold,TextSize=size,TextColor3=color or palette.text,BackgroundTransparency=1,ZIndex=22})
 end
 line(16,28,(variant~='Normal' and (variant..' • ') or '')..c.Rarity:upper(),16,c.Color)
 line(52,80,c.Name,27)
 line(140,34,Config.Factions[c.Faction or 'Rift'],15,palette.accent)
 line(180,44,'PWR '..c.Power..'  •  SPD '..c.Speed..'\nDEF '..c.Defense..'  •  EN '..c.Energy,13)
 line(245,30,'Tap anywhere to continue',12,palette.muted)
 TweenService:Create(card,TweenInfo.new(.3,Enum.EasingStyle.Back),{Size=UDim2.fromOffset(260,320)}):Play()
 cover.Activated:Connect(function()cover:Destroy()end)
end
local function action(name,arg)
 local r=request(name,arg)
 if r and r.Ok and name=='Open' then reveal(r.Id,r.Variant or 'Normal') end
 if render then render() end
end
local function uniqueCount()
 local n=0;for _,count in pairs(state.Collection) do if count>0 then n+=1 end end;return n
end
local function orderedCards()
 local ids={};for id,c in pairs(Config.Cards) do if c.Enabled~=false or (state and (state.Collection[id] or 0)>0) then table.insert(ids,id) end end
 table.sort(ids,function(a,b)
  local ra=table.find(Config.Rarities,Config.Cards[a].Rarity);local rb=table.find(Config.Rarities,Config.Cards[b].Rarity)
  if ra~=rb then return ra>rb end;return Config.Cards[a].Name<Config.Cards[b].Name
 end);return ids
end
render=function(reset)
 local scroll=reset and Vector2.zero or panel.CanvasPosition
 timers={}
 search.Visible=tab=='Cards'
 panel.Position=UDim2.fromOffset(12,tab=='Cards' and 176 or 132)
 panel.Size=UDim2.new(1,-24,1,tab=='Cards' and -244 or -200)
 for _,c in ipairs(panel:GetChildren()) do if c:IsA('GuiObject') then c:Destroy() end end
 for name,b in pairs(tabButtons) do b.BackgroundColor3=name==tab and Color3.fromRGB(46,108,124) or palette.button end
 if not state then text('Loading your collection. You can explore the hub when the game connects.',70);return end
 wallet.Text=string.format('◈ %d coins   ·   %d essence   ·   %d crystals%s',state.Coins,state.Essence,state.Crystals,state.SessionOnly and '   ·   UNSAVED TEST SESSION' or '')
 if tab=='Overview' then
  heading('YOUR NEXT ADVENTURE')
  text('Summon allies, build a faction team and send them through the rifts. Recycle duplicates or use them to upgrade your strongest cards.',70)
  text(string.format('%d / %d cards discovered  •  %d summons  •  %d expeditions',uniqueCount(),#orderedCards(),state.Rolls,state.Completed),50)
  heading('DAILY REWARD')
  text('Day '..state.Progression.DailyStreak..' of the seven-day cycle. Claim once per UTC day; consecutive days improve rewards.',54)
  local claimed=state.Progression.DailyDay>=math.floor(os.time()/86400)
  button(claimed and 'CLAIMED • resets at 00:00 UTC' or 'CLAIM DAILY REWARD',function()action('Daily')end,not claimed)
  heading('GETTING STARTED')
  text('1. Open Rift Packs with your starter coins.\n2. Visit Team and choose up to five unique allies.\n3. Start Rift Scouting, then claim its rewards.\n4. Claim Goals and spend essence on upgrades or potions.',100)
  text('Everything in this release is earned through play. Card art and character models are placeholders.',54,palette.muted)
 elseif tab=='Packs' then
  heading('SUMMON THROUGH THE RIFT')
  text('Odds include your current luck. Individual cards in a rarity are equally likely. At pity, Legendary / Mythic / Celestial tiers are equally likely (one third each).',76)
  for _,id in ipairs({'basic','elite','cosmic'}) do
   local pack=Config.Packs[id];heading(pack.Name..' • '..pack.Price..' coins')
   local odds=state.Odds[id] or pack.Weights;local lines={}
   for _,rarity in ipairs(Config.Rarities) do
    if (odds[rarity] or 0)>0 then
     local n=0;for _,c in pairs(Config.Cards) do if c.Rarity==rarity and c.Enabled~=false then n+=1 end end
     table.insert(lines,string.format('%s %.3f%% · each card %.3f%%',rarity,odds[rarity],odds[rarity]/n))
    end
   end
   text(table.concat(lines,'\n'),#lines*22,palette.muted)
   text('Legendary+ guarantee in '..(pack.Pity-(state.Pity[id] or 0))..' pulls. Any Legendary+ resets this pack’s counter.',50)
   button('OPEN '..pack.Name:upper(),function()action('Open',id)end,state.Coins>=pack.Price)
  end
 elseif tab=='Cards' then
  heading('COLLECTION • '..uniqueCount()..' discovered')
  button('FILTER: '..rarityFilter..' • tap to cycle',function()
   local list={'All',table.unpack(Config.Rarities)};rarityFilter=list[(table.find(list,rarityFilter) or 1)%#list+1];confirmSalvage=nil;page=1;render(true)
  end)
  button(ownedOnly and 'SHOWING OWNED • tap for full index' or 'SHOWING ALL • tap for owned only',function()ownedOnly=not ownedOnly;page=1;render(true)end)
  local filtered={}
  for _,id in ipairs(orderedCards()) do
   local c=Config.Cards[id];local count=state.Collection[id] or 0
   local haystack=string.lower(c.Name..' '..(c.Universe or 'Anime Nexus')..' '..(c.Faction or 'Rift')..' '..c.Trait)
   if (rarityFilter=='All' or c.Rarity==rarityFilter) and (not ownedOnly or count>0) and string.find(haystack,searchQuery,1,true) then table.insert(filtered,id) end
  end
  local pages=math.max(1,math.ceil(#filtered/12));page=math.clamp(page,1,pages)
  text(#filtered..' results • page '..page..' / '..pages,28,palette.muted)
  if page>1 then button('← PREVIOUS PAGE',function()page-=1;render(true)end) end
  for index=(page-1)*12+1,math.min(page*12,#filtered) do
   local id=filtered[index];local c=Config.Cards[id];local count=state.Collection[id] or 0
   do
    heading((count>0 and c.Name or 'Undiscovered: '..c.Name)..' • '..c.Rarity)
    text((c.Universe or 'Anime Nexus')..' • '..Config.Factions[c.Faction or 'Rift']..' • '..c.Trait..' • owned '..count..' • level '..(state.Progression.Levels[id] or 1)..' / '..Config.CardMaxLevel,58,c.Color)
    if count>0 then
     text(string.format('PWR %d  SPD %d  DEF %d  ENERGY %d\nEffective expedition power: %d',c.Power,c.Speed,c.Defense,c.Energy,Rules.cardPower(state,id)),52)
     button(table.find(state.Favorites,id) and '★ REMOVE SHOWCASE FOLLOWER' or '☆ SHOWCASE FOLLOWER',function()action('Favorite',id)end)
     local variants={};for _,name in ipairs(Config.VariantOrder) do local n=(state.Progression.Variants[id] or {})[name] or 0;if n>0 then table.insert(variants,name..' ×'..n) end end
     text(table.concat(variants,' • '),42,palette.muted)
     local normal=(state.Progression.Variants[id] or {}).Normal or 0
     local cost=Rules.upgradeCost(state,id)
     if cost then button('UPGRADE • '..cost.Coins..' coins + '..cost.Essence..' essence + 1 duplicate',function()action('Upgrade',id)end,count>1 and normal>0 and state.Coins>=cost.Coins and state.Essence>=cost.Essence)
     else text('MAXIMUM LEVEL',28,palette.accent) end
     button(confirmSalvage==id and 'CONFIRM RECYCLE • consumes one duplicate' or 'RECYCLE DUPLICATE → ESSENCE',function()
      if confirmSalvage==id then confirmSalvage=nil;action('Salvage',id) else confirmSalvage=id;render() end
     end,count>1 and normal>0)
    end
   end
  end
  if page<pages then button('NEXT PAGE →',function()page+=1;render(true)end) end
 elseif tab=='Worlds' then
  heading('SHATTERED REALITIES')
  text('Restore access to three realms through expedition milestones. World unlocks open new expedition routes and stat-based boss challenges.',70)
  for _,id in ipairs(Config.WorldOrder) do
   local w=Config.Worlds[id];heading(w.Name)
   if state.Progression.Worlds[id] then
    text('UNLOCKED',28,palette.accent)
    button('TRAVEL TO '..w.Name:upper(),function()action('Travel',id)end)
   else
    text(w.Completed..' expedition completions + '..w.Cost..' coins to unlock.',48)
    button('RESTORE WORLD GATE',function()action('UnlockWorld',id)end,state.Completed>=w.Completed and state.Coins>=w.Cost)
   end
  end
 elseif tab=='Bosses' then
  heading('AUTOMATED BOSS CHALLENGES')
  text('Your selected cards challenge a boss using team power and its highlighted stat. Favourites remain cosmetic. No direct combat is required.',70)
  if state.Progression.Challenge then
   local active=state.Progression.Challenge;heading(Config.Bosses[active.Id].Name)
   local t=text('',42);table.insert(timers,{Label=t,EndsAt=active.EndsAt,Prefix='Challenge resolves in '})
   button('REVEAL RESULT & CLAIM',function()action('ClaimBoss')end)
  else
   for _,id in ipairs(Config.BossOrder) do
    local b=Config.Bosses[id];heading(b.Name)
    text(string.format('%s • favors %s • %ds\nWin chance %.0f%% • %d coins + %d essence + %d crystals',Config.Worlds[b.World].Name,b.Stat,b.Duration,Rules.bossChance(state,id)*100,b.Reward,b.Essence,b.Crystals),68)
    button('START CHALLENGE',function()action('StartBoss',id)end,state.Progression.Worlds[b.World]==true)
   end
  end
 elseif tab=='Team' then
  heading('EXPEDITION SQUAD • '..state.TeamPower..' POWER')
  text('Pick up to five unique cards. An empty selection uses your five strongest cards automatically. Two same-faction allies give +5% team power; three give +15%. Bonuses do not stack.',85)
  text('Mode: '..(#state.Progression.Team==0 and 'Automatic strongest team' or 'Manual selection')..' • Synergy +'..math.floor(state.Synergy*100+.5)..'%',42,palette.accent)
  for _,id in ipairs(orderedCards()) do if (state.Collection[id] or 0)>0 then
   local selected=table.find(state.Progression.Team,id)
   local c=Config.Cards[id]
   button((selected and '✓ ' or '+ ')..c.Name..' • '..Rules.cardPower(state,id)..' • '..Config.Factions[c.Faction or 'Rift'],function()action('Team',id)end)
  end end
 elseif tab=='Expeditions' then
  heading('RIFT EXPEDITIONS • POWER '..state.TeamPower)
  text('Team power is locked in when you start. Expeditions finish while offline. Results are revealed when claimed.',60)
  if state.Expedition then
   local e=Config.Expeditions[state.Expedition.Id];heading(e.Name)
   local t=text('',40);table.insert(timers,{Label=t,EndsAt=state.Expedition.EndsAt,Prefix='Ready to claim in '})
   button('CLAIM EXPEDITION',function()action('ClaimExpedition')end)
  else
   for _,id in ipairs({'scouting','citadel','abyss'}) do
    local e=Config.Expeditions[id];heading(e.Name)
    text(string.format('%ds • recommended power %d • %d coins on success\nSuccess chance %.0f%% • requires %d completions',e.Duration,e.RequiredPower,e.Reward,math.clamp(state.TeamPower/e.RequiredPower,.2,1)*100,e.Unlock),60)
    button('START EXPEDITION',function()action('StartExpedition',id)end,state.Completed>=e.Unlock and state.Progression.Worlds[e.World]==true)
   end
  end
 elseif tab=='Showcase' then
  heading('YOUR FAVOURITE CHARACTERS')
  text('Choose up to three favourites from Cards. They follow your avatar as cosmetic displays, independently of your expedition team.',65)
  text('Current formation: '..state.Progression.Formation,32,palette.accent)
  for _,name in ipairs({'Line','Arc','Orbit'}) do
   local def=Config.Formations[name]
   button(name:upper()..' FORMATION • '..def.Completed..' completions',function()action('Formation',name)end,state.Completed>=def.Completed)
  end
  text('Models currently use colored procedural placeholders. Portrait and model asset IDs are configurable for future authored artwork.',68,palette.muted)
 elseif tab=='Goals' then
  heading('STORY QUESTS • GUARANTEED ALLIES')
  for _,id in ipairs(Config.QuestOrder) do
   local q=Config.Quests[id];local value=q.Stat=='BossWins' and state.Progression.BossWins or state[q.Stat]
   heading(q.Name..' • '..math.min(value,q.Target)..' / '..q.Target)
   text('Objective: '..q.Stat..' • Reward: '..Config.Cards[q.Card].Name..' + '..q.Coins..' coins',52)
   button(state.Progression.Quests[id] and 'CLAIMED' or 'CLAIM QUEST',function()action('Quest',id)end,not state.Progression.Quests[id] and value>=q.Target)
  end
  heading('COLLECTION SETS • EACH COMPLETE SET ADDS +2% EPIC+ WEIGHT')
  for _,set in ipairs(Config.CollectionSets) do
   local owned,needed=Rules.setProgress(state,set);heading(set.Name..' • '..owned..' / '..needed)
   local names={};for _,id in ipairs(set.Cards) do table.insert(names,((state.Collection[id] or 0)>0 and '✓ ' or '○ ')..Config.Cards[id].Name) end
   text(table.concat(names,' • '),65,palette.muted)
   button(state.Progression.Sets[set.Id] and 'CLAIMED' or ('CLAIM '..set.Coins..' COINS + '..set.Essence..' ESSENCE'),function()action('CollectionSet',set.Id)end,owned==needed and not state.Progression.Sets[set.Id])
  end
  heading('ACHIEVEMENTS • PERMANENT MILESTONES')
  for _,goal in ipairs(Config.Achievements) do
   local value=goal.Stat=='Unique' and uniqueCount() or state[goal.Stat]
   local claimed=state.Progression.Claims[goal.Id]
   heading(goal.Name..' • '..math.min(value,goal.Target)..' / '..goal.Target)
   text('Reward: '..goal.Coins..' coins + '..goal.Essence..' essence',32,palette.muted)
   button(claimed and 'CLAIMED' or 'CLAIM REWARD',function()action('Achievement',goal.Id)end,not claimed and value>=goal.Target)
  end
 elseif tab=='Potions' then
  heading('ALCHEMY • CRAFT YOUR LUCK')
  text('Expeditions and duplicate recycling grant crafting materials. Only one potion can be active at once.',60)
  if state.ActivePotion and state.ActivePotion.EndsAt>os.time() then
   local t=text('',42,palette.accent);table.insert(timers,{Label=t,EndsAt=state.ActivePotion.EndsAt,Prefix=Config.Potions[state.ActivePotion.Id].Name..' • '})
  end
  for _,id in ipairs({'minor','major'}) do
   local def=Config.Potions[id];heading(def.Name..' • owned '..(state.Potions[id] or 0))
   text('+'..math.floor(def.Bonus*100)..'% Epic+ weight factor for '..def.Duration/60 ..' minutes. This is a relative weight boost, not a guaranteed rarity.',60)
   button('CRAFT • '..def.Ingredients.Essence..' essence + '..def.Ingredients.Crystals..' crystals',function()action('CraftPotion',id)end,state.Essence>=def.Ingredients.Essence and state.Crystals>=def.Ingredients.Crystals)
   button('USE POTION',function()action('UsePotion',id)end,(state.Potions[id] or 0)>0 and not (state.ActivePotion and state.ActivePotion.EndsAt>os.time()))
  end
 elseif tab=='Luck' then
  heading('PERMANENT LUCK • '..state.Luck..' / '..Config.LuckMaxLevel)
  text('Base Epic+ weight multiplier ×'..string.format('%.2f',1+state.Luck*Config.LuckBonusPerLevel)..'. Weights are normalized after boosts; actual probabilities appear in Packs.',75)
  local cost=Config.LuckUpgradeCosts[state.Luck+1];local need=Config.LuckExpeditionRequirements[state.Luck+1]
  if cost then
   text('Requires '..need..' completed expeditions. You have '..state.Completed..'.',44)
   button('UPGRADE • '..cost..' COINS',function()action('Luck')end,state.Coins>=cost and state.Completed>=need)
  else text('Maximum permanent luck reached.',40,palette.accent) end
  text('Collection-set bonus: +'..math.floor(Rules.collectionLuck(state)*100+.5)..'% Epic+ weight.',42,palette.accent)
  text('Paid purchases are disabled in this release. No Robux purchase prompts are shown.',55,palette.muted)
 end
 task.defer(function()if panel.Parent then panel.CanvasPosition=scroll end end)
end
for i,name in ipairs({'Overview','Packs','Cards','Team','Expeditions','Goals','Worlds','Bosses','Showcase','Potions','Luck'}) do
 local b=make('TextButton',tabs,{Size=UDim2.fromOffset(110,36),Text=name,LayoutOrder=i,BackgroundColor3=palette.button,TextColor3=palette.text,TextSize=13,Font=Enum.Font.GothamBold,BorderSizePixel=0});corner(b,7);tabButtons[name]=b
 b.Activated:Connect(function()tab=name;confirmSalvage=nil;render(true)end)
end
local searchRevision=0
search:GetPropertyChangedSignal('Text'):Connect(function()
 searchRevision+=1;local current=searchRevision
 task.delay(.2,function()if current==searchRevision then searchQuery=string.lower(search.Text);page=1;if tab=='Cards' then render(true) end end end)
end)
render()
task.spawn(function()
 local configModule=RS:WaitForChild('NexusConfig',20);local rulesModule=RS:WaitForChild('NexusProgression',20);local remotes=RS:WaitForChild('NexusRemotes',20)
 if not configModule or not rulesModule or not remotes then toast.Text='Game modules are missing. Check the source installation guide.';return end
 local ok,err=pcall(function()Config=require(configModule);Rules=require(rulesModule).new(Config)end)
 if not ok then toast.Text='Game configuration failed to load. Check Output.';warn(err);return end
 Remote=remotes:WaitForChild('Request',15);local updated=remotes:WaitForChild('Updated',15);local notify=remotes:WaitForChild('Notify',15)
 if not Remote or not updated or not notify then toast.Text='Server did not finish starting. Check Output.';return end
 updated.OnClientEvent:Connect(function(profile)state=profile;render()end)
 notify.OnClientEvent:Connect(function(message)toast.Text=message end)
 for _=1,30 do
  local result=request('Get')
  if result and result.Ok then state=result.Profile;render();toast.Text='Your journey begins. Claim your daily reward, then open a Rift Pack.';return end
  task.wait(1)
 end
 toast.Text='Your profile could not load. Please rejoin or check Studio Output.'
end)
task.spawn(function()
 while gui.Parent do
  for _,timer in ipairs(timers) do if timer.Label.Parent then
   local seconds=math.max(0,timer.EndsAt-os.time())
   timer.Label.Text=seconds==0 and 'Ready! Refresh this tab or claim your reward.' or timer.Prefix..string.format('%02d:%02d',seconds//60,seconds%60)
  end end
  task.wait(.5)
 end
end)
