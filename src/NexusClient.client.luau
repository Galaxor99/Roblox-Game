-- Responsive collection interface. Every mutation is validated by the server.
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local TweenService=game:GetService('TweenService')
local me=Players.LocalPlayer
local gui=Instance.new('ScreenGui');gui.Name='AnimeNexusGui';gui.ResetOnSpawn=false;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Parent=me:WaitForChild('PlayerGui')
local function make(class,parent,props)
 local o=Instance.new(class);for k,v in pairs(props or {}) do o[k]=v end;o.Parent=parent;return o
end
local palette={bg=Color3.fromRGB(9,13,27),surface=Color3.fromRGB(20,27,48),muted=Color3.fromRGB(153,170,198),accent=Color3.fromRGB(93,225,236),text=Color3.fromRGB(241,246,255),button=Color3.fromRGB(39,53,86)}
local function corner(o,r) make('UICorner',o,{CornerRadius=UDim.new(0,r or 10)}) end
local main=make('Frame',gui,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.new(1,-24,1,-24),BackgroundColor3=palette.bg,BorderSizePixel=0});corner(main,16)
make('UISizeConstraint',main,{MaxSize=Vector2.new(1100,850)})
make('UIStroke',main,{Color=Color3.fromRGB(72,107,151),Thickness=2})
make('UIGradient',main,{Rotation=90,Color=ColorSequence.new(Color3.fromRGB(19,30,58),palette.bg)})
make('Frame',main,{Position=UDim2.fromOffset(18,70),Size=UDim2.new(1,-36,0,2),BackgroundColor3=palette.accent,BorderSizePixel=0})
make('TextLabel',main,{Position=UDim2.fromOffset(18,10),Size=UDim2.new(1,-75,0,28),Text='✦  ANIME NEXUS',TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.GothamBlack,TextSize=21,TextColor3=palette.text,BackgroundTransparency=1})
local wallet=make('TextLabel',main,{Position=UDim2.fromOffset(18,44),Size=UDim2.new(1,-36,0,24),Text='Connecting to the Nexus…',TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.Gotham,TextSize=13,TextColor3=palette.accent,BackgroundTransparency=1})
local tabs=make('ScrollingFrame',main,{Position=UDim2.fromOffset(12,78),Size=UDim2.new(1,-24,0,42),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.X,ScrollingDirection=Enum.ScrollingDirection.X,ScrollBarThickness=2})
make('UIListLayout',tabs,{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder})
local sidebar=make('ScrollingFrame',main,{Position=UDim2.fromOffset(12,82),Size=UDim2.new(0,154,1,-148),BackgroundColor3=palette.surface,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=2,ScrollBarImageColor3=palette.accent,Visible=false});corner(sidebar,10)
make('UIListLayout',sidebar,{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder})
make('UIPadding',sidebar,{PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8),PaddingLeft=UDim.new(0,6),PaddingRight=UDim.new(0,6)})
local panel=make('ScrollingFrame',main,{Position=UDim2.fromOffset(12,132),Size=UDim2.new(1,-24,1,-200),BackgroundColor3=palette.surface,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=4,ScrollBarImageColor3=palette.accent});corner(panel)
make('UIStroke',panel,{Color=Color3.fromRGB(52,74,109),Thickness=1})
make('UIPadding',panel,{PaddingTop=UDim.new(0,12),PaddingBottom=UDim.new(0,18),PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)})
make('UIListLayout',panel,{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
local toast=make('TextLabel',main,{Position=UDim2.new(0,18,1,-62),Size=UDim2.new(1,-36,0,50),Text='Welcome to the Nexus',TextWrapped=true,TextColor3=palette.accent,BackgroundTransparency=1,Font=Enum.Font.GothamMedium,TextSize=13})
local toggle=make('TextButton',gui,{Position=UDim2.fromOffset(12,12),Size=UDim2.fromOffset(145,38),Text='✦  OPEN NEXUS',Visible=false,BackgroundColor3=palette.button,TextColor3=palette.text,Font=Enum.Font.GothamBold,TextSize=13});corner(toggle)
local close=make('TextButton',main,{Position=UDim2.new(1,-48,0,12),Size=UDim2.fromOffset(32,30),Text='×',TextSize=25,BackgroundTransparency=1,TextColor3=palette.muted})
close.Activated:Connect(function()main.Visible=false;toggle.Visible=true end)
toggle.Activated:Connect(function()main.Visible=true;toggle.Visible=false end)
local Config,Rules,Visual,Remote,state
local tab='Overview';local locked=false;local render;local tabButtons={};local rarityFilter='All';local confirmSalvage=nil;local timers={};local searchQuery='';local page=1;local ownedOnly=false;local rankingMetric='Power';local rankingRows={};local coopDay=math.floor(os.time()/86400);local coopStatus
local search=make('TextBox',main,{Position=UDim2.fromOffset(12,128),Size=UDim2.new(1,-24,0,36),PlaceholderText='Search name, universe, faction or trait…',ClearTextOnFocus=false,Text='',TextColor3=palette.text,PlaceholderColor3=palette.muted,BackgroundColor3=palette.surface,Font=Enum.Font.Gotham,TextSize=14,Visible=false});corner(search,7)
local function layout()
 local wide=main.AbsoluteSize.X>=780
 sidebar.Visible=wide;tabs.Visible=not wide
 local x=wide and 178 or 12
 local width=wide and -190 or -24
 local y=wide and 82 or 132
 search.Position=UDim2.fromOffset(x,y)
 search.Size=UDim2.new(1,width,0,36)
 panel.Position=UDim2.fromOffset(x,y+(tab=='Cards' and 44 or 0))
 panel.Size=UDim2.new(1,width,1,-(y+(tab=='Cards' and 112 or 68)))
end
main:GetPropertyChangedSignal('AbsoluteSize'):Connect(layout)
local function text(msg,height,color)
 return make('TextLabel',panel,{Size=UDim2.new(1,-8,0,height or 42),Text=msg,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1,TextColor3=color or palette.text,Font=Enum.Font.Gotham,TextSize=12})
end
local function heading(msg) local label=text(msg,28,palette.accent);label.Font=Enum.Font.GothamBold;label.TextSize=12;return label end
local function button(msg,callback,enabled)
 local b=make('TextButton',panel,{Size=UDim2.new(1,-8,0,38),Text=msg,TextWrapped=true,BackgroundColor3=enabled==false and Color3.fromRGB(36,40,56) or palette.button,TextColor3=enabled==false and palette.muted or palette.text,Font=Enum.Font.GothamBold,TextSize=12,AutoButtonColor=enabled~=false,BorderSizePixel=0});corner(b,7)
 if enabled~=false then
  b.MouseEnter:Connect(function()TweenService:Create(b,TweenInfo.new(.12),{BackgroundColor3=Color3.fromRGB(56,91,137)}):Play()end)
  b.MouseLeave:Connect(function()TweenService:Create(b,TweenInfo.new(.12),{BackgroundColor3=palette.button}):Play()end)
 end
 b.Activated:Connect(function()if enabled~=false then callback() end end);return b
end
local function portrait(parent,id,size,x,y,z)
 local c=Config.Cards[id];local identity=c.Identity or {}
 local imageId=identity.PortraitAssetId or 0
 local cell=identity.PortraitAtlasCell
 local atlasId=(Config.PortraitAtlases or {})[identity.PortraitAtlas or 0] or 0
 if imageId>0 or (cell and atlasId>0) then
  local props={Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(size,size),BackgroundColor3=c.Color,BorderSizePixel=0,ScaleType=Enum.ScaleType.Crop,Image='rbxassetid://'..(imageId>0 and imageId or atlasId),ZIndex=z}
  if imageId==0 then props.ImageRectSize=Vector2.new(418,418);props.ImageRectOffset=Vector2.new(((cell-1)%3)*418,math.floor((cell-1)/3)*418) end
  local image=make('ImageLabel',parent,props);corner(image,8);return image
 end
 local tile=make('Frame',parent,{Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(size,size),BackgroundColor3=c.Color,BorderSizePixel=0,ZIndex=z});corner(tile,8)
 make('UIGradient',tile,{Rotation=45,Color=ColorSequence.new(Color3.fromRGB(11,19,39),c.Color)})
 make('TextLabel',tile,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text=string.sub(c.Name,1,1),TextColor3=palette.text,TextSize=math.floor(size*.55),Font=Enum.Font.GothamBlack,ZIndex=z+1})
 return tile
end
local function showOdds(packId)
 local pack=Config.Packs[packId];local odds=state.Odds[packId] or pack.Weights
 local cover=make('TextButton',gui,{Size=UDim2.fromScale(1,1),Text='',BackgroundColor3=Color3.fromRGB(3,7,16),BackgroundTransparency=.15,ZIndex=20})
 local box=make('Frame',cover,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.new(.9,0,0,430),BackgroundColor3=palette.surface,BorderSizePixel=0,ZIndex=21});corner(box,14)
 make('UISizeConstraint',box,{MaxSize=Vector2.new(390,430)})
 make('UIStroke',box,{Color=palette.accent,Thickness=1})
 make('TextLabel',box,{Position=UDim2.fromOffset(15,12),Size=UDim2.new(1,-30,0,28),Text=pack.Name:upper()..' · ODDS',TextColor3=palette.text,Font=Enum.Font.GothamBlack,TextSize=18,BackgroundTransparency=1,ZIndex=22})
 for i,rarity in ipairs(Config.Rarities) do
  local chance=odds[rarity] or 0
  local y=48+(i-1)*52
  make('TextLabel',box,{Position=UDim2.fromOffset(16,y),Size=UDim2.new(1,-32,0,22),Text=rarity..'   '..string.format('%.3f%%',chance),TextXAlignment=Enum.TextXAlignment.Left,TextColor3=Config.RarityColors[rarity],Font=Enum.Font.GothamBold,TextSize=12,BackgroundTransparency=1,ZIndex=22})
  local base=make('Frame',box,{Position=UDim2.fromOffset(16,y+27),Size=UDim2.new(1,-32,0,8),BackgroundColor3=palette.bg,BorderSizePixel=0,ZIndex=22});corner(base,4)
  local fill=make('Frame',base,{Size=UDim2.fromScale(math.clamp(chance/55,0,1),1),BackgroundColor3=Config.RarityColors[rarity],BorderSizePixel=0,ZIndex=23});corner(fill,4)
 end
 make('TextLabel',box,{Position=UDim2.fromOffset(16,365),Size=UDim2.new(1,-32,0,42),Text='Pity in '..(pack.Pity-(state.Pity[packId] or 0))..' pulls · odds reflect your current luck',TextWrapped=true,TextColor3=palette.muted,Font=Enum.Font.Gotham,TextSize=12,BackgroundTransparency=1,ZIndex=22})
 cover.Activated:Connect(function()cover:Destroy()end)
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
 portrait(card,id,96,82,101,23)
 line(180,44,'PWR '..c.Power..'  •  SPD '..c.Speed..'\nDEF '..c.Defense..'  •  EN '..c.Energy,13)
 line(245,30,'Tap anywhere to continue',12,palette.muted)
 TweenService:Create(card,TweenInfo.new(.3,Enum.EasingStyle.Back),{Size=UDim2.fromOffset(260,320)}):Play()
 cover.Activated:Connect(function()cover:Destroy()end)
end
local opening=false
local function spin(packId,winnerId,variant)
 local ids,target=Visual.sequence(packId,winnerId,Random.new())
 if not ids then reveal(winnerId,variant);return end
 opening=true
 local cover=make('Frame',gui,{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(4,8,18),BackgroundTransparency=.08,ZIndex=30})
 local box=make('Frame',cover,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.new(.92,0,0,270),BackgroundColor3=palette.surface,BorderSizePixel=0,ZIndex=31});corner(box,18)
 make('UISizeConstraint',box,{MaxSize=Vector2.new(690,270)})
 make('UIStroke',box,{Color=palette.accent,Thickness=2})
 make('TextLabel',box,{Position=UDim2.fromOffset(18,12),Size=UDim2.new(1,-36,0,28),Text='RIFT OPENING',TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.GothamBlack,TextSize=19,TextColor3=palette.text,BackgroundTransparency=1,ZIndex=32})
 local view=make('Frame',box,{Position=UDim2.fromOffset(12,50),Size=UDim2.new(1,-24,0,144),ClipsDescendants=true,BackgroundColor3=palette.bg,BorderSizePixel=0,ZIndex=32});corner(view,12)
 local track=make('Frame',view,{Size=UDim2.fromOffset(#ids*108,136),Position=UDim2.fromOffset(0,4),BackgroundTransparency=1,ZIndex=33})
 for index,id in ipairs(ids) do
  local c=Config.Cards[id];local tile=make('Frame',track,{Position=UDim2.fromOffset((index-1)*108,0),Size=UDim2.fromOffset(100,136),BackgroundColor3=palette.surface,BorderSizePixel=0,ZIndex=34});corner(tile,9)
  make('UIStroke',tile,{Color=c.Color,Thickness=2})
  portrait(tile,id,88,6,5,35)
  make('TextLabel',tile,{Position=UDim2.fromOffset(4,96),Size=UDim2.fromOffset(92,34),Text=c.Name,TextWrapped=true,TextColor3=palette.text,TextSize=11,Font=Enum.Font.GothamBold,BackgroundTransparency=1,ZIndex=36})
 end
 make('Frame',box,{AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,46),Size=UDim2.fromOffset(4,152),BackgroundColor3=palette.accent,BorderSizePixel=0,ZIndex=40})
 local status=make('TextLabel',box,{Position=UDim2.fromOffset(14,205),Size=UDim2.new(1,-145,0,44),Text='Opening the rift…',TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,Font=Enum.Font.GothamBold,TextSize=15,TextColor3=palette.text,BackgroundTransparency=1,ZIndex=33})
 local skip=make('TextButton',box,{Position=UDim2.new(1,-116,0,209),Size=UDim2.fromOffset(100,35),Text='SKIP',Font=Enum.Font.GothamBold,TextSize=13,TextColor3=palette.text,BackgroundColor3=palette.button,BorderSizePixel=0,ZIndex=34});corner(skip,8)
 task.defer(function()
  if not cover.Parent then return end
  local width=view.AbsoluteSize.X
  local start=width*.5-50
  local finish=width*.5-50-(target-1)*108
  track.Position=UDim2.fromOffset(start,4)
  local done=false;local tween
  local function complete()
   if done then return end;done=true
   if tween then tween:Cancel() end
   track.Position=UDim2.fromOffset(finish,4)
   local winner=Config.Cards[winnerId]
   status.Text=(variant~='Normal' and variant..' • ' or '')..winner.Name..'  ·  '..winner.Rarity
   status.TextColor3=winner.Color
   skip.Text='CLOSE'
  end
  tween=TweenService:Create(track,TweenInfo.new(5.4,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=UDim2.fromOffset(finish,4)})
  tween.Completed:Connect(complete);tween:Play()
  skip.Activated:Connect(function()
   if not done then complete() else cover:Destroy();opening=false end
  end)
 end)
end
local function action(name,arg)
 if name=='Open' and opening then return end
 local r=request(name,arg)
 if r and r.Ok and name=='Open' then spin(arg,r.Id,r.Variant or 'Normal') end
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
local function inspectCard(id)
 local c=Config.Cards[id];local count=state.Collection[id] or 0
 local cover=make('TextButton',gui,{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(3,7,16),BackgroundTransparency=.18,Text='',ZIndex=20})
 local detail=make('ScrollingFrame',cover,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.new(.9,0,.86,0),BackgroundColor3=palette.surface,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=4,ZIndex=21});corner(detail,14)
 make('UISizeConstraint',detail,{MaxSize=Vector2.new(420,620)})
 make('UIPadding',detail,{PaddingTop=UDim.new(0,14),PaddingBottom=UDim.new(0,16),PaddingLeft=UDim.new(0,14),PaddingRight=UDim.new(0,14)})
 make('UIListLayout',detail,{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
 local function label(value,height,color,size)
  return make('TextLabel',detail,{Size=UDim2.new(1,-8,0,height),Text=value,TextWrapped=true,TextColor3=color or palette.text,Font=Enum.Font.GothamMedium,TextSize=size or 13,BackgroundTransparency=1,ZIndex=22})
 end
 local function choice(value,fn,enabled)
  local b=make('TextButton',detail,{Size=UDim2.new(1,-8,0,37),Text=value,TextWrapped=true,TextColor3=enabled==false and palette.muted or palette.text,Font=Enum.Font.GothamBold,TextSize=12,BackgroundColor3=enabled==false and Color3.fromRGB(34,39,58) or palette.button,BorderSizePixel=0,ZIndex=22});corner(b,7)
  b.Activated:Connect(function()if enabled~=false then cover:Destroy();fn() end end)
 end
 label(c.Name,32,c.Color,21)
 label(c.Rarity:upper()..'  ·  '..(c.Universe or 'Anime Nexus')..'  ·  '..Config.Factions[c.Faction or 'Rift'],32,palette.accent,12)
 local art=make('Frame',detail,{Size=UDim2.new(1,-8,0,168),BackgroundColor3=palette.bg,BorderSizePixel=0,ZIndex=22});corner(art,9)
 local portraitTile=portrait(art,id,160,0,4,23);portraitTile.AnchorPoint=Vector2.new(.5,0);portraitTile.Position=UDim2.new(.5,0,0,4)
 label(c.Lore or '',46,palette.muted,12)
 label('PWR '..c.Power..'    SPD '..c.Speed..'    DEF '..c.Defense..'    EN '..c.Energy,42,palette.text,12)
 if count>0 then
  label('Owned ×'..count..'    ·    Level '..(state.Progression.Levels[id] or 1)..' / '..Config.CardMaxLevel..'    ·    Team power '..Rules.cardPower(state,id),36)
  choice(table.find(state.Favorites,id) and '★ REMOVE FROM SHOWCASE' or '☆ ADD TO SHOWCASE',function()action('Favorite',id)end)
  local cost=Rules.upgradeCost(state,id);local normal=(state.Progression.Variants[id] or {}).Normal or 0
  if cost then choice('⬆ UPGRADE · '..cost.Coins..' coins · '..cost.Essence..' essence',function()action('Upgrade',id)end,count>1 and normal>0 and state.Coins>=cost.Coins and state.Essence>=cost.Essence) end
  local rank,progress,nextRank=Rules.masteryRank(state,id)
  label('Mastery '..rank..' / '..Config.MasteryMaxRank..(nextRank>0 and ' · '..progress..' / '..nextRank..' XP' or ' · complete'),32,palette.accent)
  if not state.Progression.Awakened[id] then
   local recipe=Config.Awakening
   choice('✦ AWAKEN · Lv '..recipe.Level..' · Mastery '..recipe.MasteryRank, function()action('Awaken',id)end,(state.Progression.Levels[id] or 1)>=recipe.Level and rank>=recipe.MasteryRank and state.Progression.BossWins>=recipe.BossWins and state.Essence>=recipe.Essence and state.Crystals>=recipe.Crystals)
  end
  choice(confirmSalvage==id and 'CONFIRM RECYCLE DUPLICATE' or '♻ RECYCLE DUPLICATE',function()
   if confirmSalvage==id then confirmSalvage=nil;action('Salvage',id) else confirmSalvage=id;inspectCard(id) end
  end,count>1 and normal>0)
 end
 choice('CLOSE',function()end)
 cover.Activated:Connect(function()cover:Destroy()end)
end
render=function(reset)
 local scroll=reset and Vector2.zero or panel.CanvasPosition
 timers={}
 search.Visible=tab=='Cards'
 layout()
 for _,c in ipairs(panel:GetChildren()) do if c:IsA('GuiObject') then c:Destroy() end end
 for name,buttons in pairs(tabButtons) do
  for _,b in ipairs(buttons) do
   b.BackgroundColor3=name==tab and Color3.fromRGB(40,103,127) or palette.button
   b.TextColor3=name==tab and palette.accent or palette.text
  end
 end
 if not state then text('Loading your collection. You can explore the hub when the game connects.',70);return end
 wallet.Text=string.format('◈ %d coins   ·   %d essence   ·   %d crystals%s',state.Coins,state.Essence,state.Crystals,state.SessionOnly and '   ·   UNSAVED TEST SESSION' or '')
 if tab=='Overview' then
  heading('RIFTWALKER DASHBOARD')
  text(string.format('%d / %d discovered     ◈ %d summons     ◆ %d expeditions',uniqueCount(),#orderedCards(),state.Rolls,state.Completed),34)
  for _,shortcut in ipairs({{'✦  OPEN PACKS','Packs'},{'▣  MY CARDS','Cards'},{'◆  EXPEDITIONS','Expeditions'},{'★  SHOWCASE','Showcase'}}) do
   button(shortcut[1]..'     →',function()tab=shortcut[2];render(true)end)
  end
  heading('DAILY DROP · DAY '..state.Progression.DailyStreak)
  local claimed=state.Progression.DailyDay>=math.floor(os.time()/86400)
  button(claimed and 'CLAIMED · resets at 00:00 UTC' or 'CLAIM DAILY REWARD  →',function()action('Daily')end,not claimed)
  text('Build a squad, send expeditions, and collect rare variants. Your favourites appear behind your avatar.',50,palette.muted)
 elseif tab=='Packs' then
  heading('SUMMON GATE')
  text('Choose a pack. Odds and pity update with your current luck.',34,palette.muted)
  for _,id in ipairs({'basic','elite','cosmic'}) do
   local pack=Config.Packs[id];heading(pack.Name:upper()..'  ·  '..pack.Price..' COINS')
   text(pack.Description..'   •   Legendary+ pity in '..(pack.Pity-(state.Pity[id] or 0))..' pulls',40,palette.muted)
   button('✦  OPEN '..pack.Name:upper()..'     →',function()action('Open',id)end,state.Coins>=pack.Price)
   button('VIEW '..pack.Name:upper()..' ODDS',function()showOdds(id)end)
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
   local tile=make('TextButton',panel,{Size=UDim2.new(1,-8,0,80),Text='',BackgroundColor3=palette.bg,BorderSizePixel=0});corner(tile,9)
   make('UIStroke',tile,{Color=c.Color,Thickness=1,Transparency=.35})
   portrait(tile,id,68,6,6,2)
   make('TextLabel',tile,{Position=UDim2.fromOffset(84,7),Size=UDim2.new(1,-94,0,26),Text=c.Name,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,TextColor3=palette.text,Font=Enum.Font.GothamBold,TextSize=15,BackgroundTransparency=1})
   make('TextLabel',tile,{Position=UDim2.fromOffset(84,35),Size=UDim2.new(1,-94,0,34),Text=c.Rarity:upper()..'  ·  '..c.Trait..'  ·  '..(count>0 and ('OWNED ×'..count) or 'UNDISCOVERED')..'   →',TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,TextColor3=c.Color,Font=Enum.Font.GothamMedium,TextSize=11,BackgroundTransparency=1})
   tile.Activated:Connect(function()inspectCard(id)end)
  end
  if page<pages then button('NEXT PAGE →',function()page+=1;render(true)end) end
 elseif tab=='Worlds' then
  heading('SHATTERED REALITIES')
  text('Restore three realms, visit their memory sites and finish the story chapters. World unlocks also open expedition routes and boss challenges.',70)
  for _,id in ipairs(Config.WorldOrder) do
   local w=Config.Worlds[id];heading(w.Name)
   if state.Progression.Worlds[id] then
    text('UNLOCKED',28,palette.accent)
    button('TRAVEL TO '..w.Name:upper(),function()action('Travel',id)end)
   else
    text(w.Completed..' expedition completions + '..w.Cost..' coins to unlock.',48)
    button('RESTORE WORLD GATE',function()action('UnlockWorld',id)end,state.Completed>=w.Completed and state.Coins>=w.Cost)
   end
   local known=0
   for _,memoryId in ipairs(Config.Discoveries[id]) do if state.Progression.Discoveries[memoryId] then known+=1 end end
   text('Memories found: '..known..' / '..#Config.Discoveries[id]..' • '..table.concat((function()
    local names={};for _,memoryId in ipairs(Config.Discoveries[id]) do table.insert(names,(state.Progression.Discoveries[memoryId] and '✓ ' or '○ ')..Config.DiscoveryNames[memoryId]) end
    return names
   end)(),' · '),72,palette.muted)
  end
  heading('THE FRACTURE STORY')
  for _,chapterId in ipairs(Config.ChapterOrder) do
   local chapter=Config.Chapters[chapterId];local known=0
   for _,memoryId in ipairs(Config.Discoveries[chapter.World]) do if state.Progression.Discoveries[memoryId] then known+=1 end end
   local ready=state.Progression.Worlds[chapter.World] and state.Completed>=chapter.Completed and state.Progression.BossWins>=chapter.BossWins and known==#Config.Discoveries[chapter.World]
   heading(chapter.Name)
   text(chapter.Story,75,palette.muted)
   text('Explore '..Config.Worlds[chapter.World].Name..' • '..known..' / 3 memories • '..state.Completed..' / '..chapter.Completed..' expeditions • '..state.Progression.BossWins..' / '..chapter.BossWins..' boss wins',72)
   button(state.Progression.Chapters[chapterId] and 'CHAPTER COMPLETED' or 'RESTORE CHAPTER • '..Config.Cards[chapter.Card].Name, function()action('Chapter',chapterId)end,ready and not state.Progression.Chapters[chapterId])
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
   local e=Config.Expeditions[state.Expedition.Id];heading(e.Name..' • '..Config.ExpeditionRoutes[state.Expedition.Route or 'steady'].Name)
   local t=text('',40);table.insert(timers,{Label=t,EndsAt=state.Expedition.EndsAt,Prefix='Ready to claim in '})
   button('CLAIM EXPEDITION',function()action('ClaimExpedition')end)
  else
   for _,id in ipairs({'scouting','citadel','abyss'}) do
    local e=Config.Expeditions[id];heading(e.Name)
    for _,routeId in ipairs({'steady','swift','perilous'}) do
     local route=Config.ExpeditionRoutes[routeId]
     local plan=Rules.expeditionPlan(state,id,routeId)
     text(string.format('%s • %ds • %d coins • %.0f%% success\n%s • +%.0f%% team trait bonus',route.Name,plan.Duration,plan.Reward,plan.Chance*100,route.Description,plan.TraitBonus*100),70)
     button('START '..route.Name:upper(),function()action('StartExpedition',id..'|'..routeId)end,state.Completed>=e.Unlock and state.Progression.Worlds[e.World]==true)
    end
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
  text('Favourite displays follow your avatar. Portrait artwork appears in cards and summons after the atlas asset IDs are set.',56,palette.muted)
 elseif tab=='Events' then
  local event,_,endsAt=Rules.event(os.time())
  heading(event.Name:upper())
  text(event.Description..'. Earn points by claiming expeditions, boss challenges and daily rewards. A new event starts every seven UTC days.',76)
  text('Weekly points: '..state.Progression.Weekly.Points,34,palette.accent)
  local countdown=text('',42);table.insert(timers,{Label=countdown,EndsAt=endsAt,Prefix='Event rotates in '})
  for _,milestone in ipairs(Config.WeeklyMilestones) do
   heading(milestone.Points..' POINTS')
   local reward=milestone.Coins..' coins + '..milestone.Essence..' essence'
   if milestone.EventCard then reward=reward..' + '..Config.Cards[event.Card].Name end
   text(reward,34,palette.muted)
   local claimed=state.Progression.Weekly.Claims[milestone.Id]
   button(claimed and 'CLAIMED THIS WEEK' or 'CLAIM WEEKLY REWARD',function()action('EventClaim',milestone.Id)end,not claimed and state.Progression.Weekly.Points>=milestone.Points)
  end
 elseif tab=='Co-op' then
  heading('SHARED RIFT GUARDIAN')
  text('Contribute your card team once per UTC day. Players across servers combine their power. Return after the day ends to claim the outcome. Claims stay available for seven days.',85)
  button('TODAY • CONTRIBUTE',function()
   coopDay=math.floor(os.time()/86400)
   local result=request('CoopStatus',tostring(coopDay))
   if result and result.Ok then coopStatus=result.Status end
   render(true)
  end)
  for daysAgo=1,7 do
   button(daysAgo==1 and 'YESTERDAY • REWARDS' or (daysAgo..' DAYS AGO'),function()
    coopDay=math.floor(os.time()/86400)-daysAgo
    local result=request('CoopStatus',tostring(coopDay))
    if result and result.Ok then coopStatus=result.Status end
    render(true)
   end)
  end
  if coopStatus and coopStatus.Day==coopDay then
   heading(coopStatus.Ended and 'COMPLETED DAY' or 'TODAY’S CHALLENGE')
   text(coopStatus.Total..' / '..coopStatus.Target..' shared power • '..coopStatus.Participants..' contributors',45,palette.accent)
   text('Your contribution: '..coopStatus.Contribution..' power',36)
   if not coopStatus.Ended then
    local countdown=text('',42);table.insert(timers,{Label=countdown,EndsAt=coopStatus.EndsAt,Prefix='Challenge ends in '})
    button(coopStatus.Contribution>0 and 'YOUR TEAM HAS CONTRIBUTED' or 'CONTRIBUTE CURRENT TEAM',function()
     local result=request('CoopContribute')
     if result and result.Ok and result.Status then coopDay=result.Status.Day;coopStatus=result.Status end
     render()
    end,coopStatus.Contribution==0 and not state.SessionOnly)
   else
    text(coopStatus.Complete and 'Guardian defeated • 300 coins, 20 essence, 2 crystals' or 'Participation reward • 50 coins, 5 essence',50)
    local claimed=state.Progression.CoopClaims[tostring(coopDay)]
    button(claimed and 'ALREADY CLAIMED' or 'CLAIM SHARED REWARD',function()
     local result=request('CoopClaim',tostring(coopDay))
     if result and result.Ok then coopStatus=nil end
     render()
    end,coopStatus.Contribution>0 and not claimed and not state.SessionOnly)
   end
  else text('Select a day to view contributions and rewards.',42,palette.muted) end
  button('REFRESH SHARED STATUS',function()
   local result=request('CoopStatus',tostring(coopDay))
   if result and result.Ok then coopStatus=result.Status end
   render()
  end)
 elseif tab=='Rankings' then
  heading('NEXUS RANKINGS • GLOBAL TOP 10')
  text('Rankings update after successful profile saves. Your current server scores are shown on Roblox’s player list.',60)
  for _,metric in ipairs({'Power','Cards','Bosses'}) do
   button((metric==rankingMetric and '✓ ' or '')..metric:upper(),function()
    rankingMetric=metric
    local result=request('Leaderboard',metric)
    if result and result.Ok then rankingRows[metric]=result.Rows end
    render(true)
   end)
  end
  local rows=rankingRows[rankingMetric]
  if rows then
   if #rows==0 then text('No saved scores yet.',42,palette.muted) end
   for position,row in ipairs(rows) do
    text(position..'.  '..row.Name..'    '..row.Score..' '..rankingMetric:lower(),42,position<=3 and palette.accent or palette.text)
   end
  else text('Select a ranking to load its top players.',42,palette.muted) end
  button('REFRESH RANKINGS',function()
   local result=request('Leaderboard',rankingMetric)
   if result and result.Ok then rankingRows[rankingMetric]=result.Rows end
   render()
  end)
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
local tabIcons={Overview='⌂',Packs='✦',Cards='▣',Team='◆',Expeditions='➤',Goals='✓',Worlds='◈',Bosses='♜',Showcase='★',Events='◉',['Co-op']='✚',Rankings='♛',Potions='⚗',Luck='✧'}
for i,name in ipairs({'Overview','Packs','Cards','Team','Expeditions','Goals','Worlds','Bosses','Showcase','Events','Co-op','Rankings','Potions','Luck'}) do
 tabButtons[name]={}
 for _,nav in ipairs({tabs,sidebar}) do
 local b=make('TextButton',nav,{Size=nav==sidebar and UDim2.new(1,-12,0,37) or UDim2.fromOffset(name=='Expeditions' and 130 or 108,36),Text=(tabIcons[name] or '•')..'  '..name,LayoutOrder=i,BackgroundColor3=palette.button,TextColor3=palette.text,TextSize=12,Font=Enum.Font.GothamBold,BorderSizePixel=0});corner(b,8);table.insert(tabButtons[name],b)
 make('UIStroke',b,{Color=Color3.fromRGB(61,80,117),Thickness=1})
 b.Activated:Connect(function()
  tab=name;confirmSalvage=nil
  if name=='Rankings' and not rankingRows[rankingMetric] then
   local result=request('Leaderboard',rankingMetric)
   if result and result.Ok then rankingRows[rankingMetric]=result.Rows end
  end
  if name=='Co-op' then
   coopDay=math.floor(os.time()/86400)
   local result=request('CoopStatus',tostring(coopDay))
   if result and result.Ok then coopStatus=result.Status end
  end
  render(true)
 end)
 end
end
local searchRevision=0
search:GetPropertyChangedSignal('Text'):Connect(function()
 searchRevision+=1;local current=searchRevision
 task.delay(.2,function()if current==searchRevision then searchQuery=string.lower(search.Text);page=1;if tab=='Cards' then render(true) end end end)
end)
render()
task.spawn(function()
 local configModule=RS:WaitForChild('NexusConfig',20);local rulesModule=RS:WaitForChild('NexusProgression',20);local visualModule=RS:WaitForChild('NexusSummonVisual',20);local remotes=RS:WaitForChild('NexusRemotes',20)
 if not configModule or not rulesModule or not visualModule or not remotes then toast.Text='Game modules are missing. Check the source installation guide.';return end
 local ok,err=pcall(function()Config=require(configModule);Rules=require(rulesModule).new(Config);Visual=require(visualModule).new(Config)end)
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
