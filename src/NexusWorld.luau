-- Procedural placeholder environments; authored art can replace this module later.
local World={}
function World.create(config,canVisit,notify)
 local folder=Instance.new('Folder');folder.Name='AnimeNexusRealms';folder.Parent=workspace
 local centers={hub=Vector3.new(0,0,0),neon=Vector3.new(200,0,0),astral=Vector3.new(-200,0,0)}
 local api={}
 local function part(name,size,pos,color,material,parent)
  local p=Instance.new('Part');p.Name=name;p.Size=size;p.Position=pos;p.Color=color;p.Anchored=true;p.Material=material or Enum.Material.SmoothPlastic;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent or folder;return p
 end
 local function sign(p,title)
  local bill=Instance.new('BillboardGui');bill.Size=UDim2.fromOffset(220,54);bill.StudsOffset=Vector3.new(0,5,0);bill.MaxDistance=90;bill.Parent=p
  local t=Instance.new('TextLabel');t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Font=Enum.Font.GothamBold;t.TextSize=17;t.Text=title;t.TextColor3=Color3.fromRGB(230,245,255);t.TextStrokeTransparency=.4;t.Parent=bill
 end
 function api.travel(player,id)
  if not centers[id] or not canVisit(player,id) then return false,'Unlock this world in the Worlds menu first' end
  local c=player.Character;local hum=c and c:FindFirstChildOfClass('Humanoid')
  if not c or not hum or hum.Health<=0 then return false,'Wait for your avatar to respawn' end
  c:PivotTo(CFrame.new(centers[id]+Vector3.new(0,5,8)))
  return true,'Arrived at '..config.Worlds[id].Name
 end
 for _,id in ipairs(config.WorldOrder) do
  local def=config.Worlds[id];local center=centers[id]
  part(def.Name,Vector3.new(130,8,130),center+Vector3.new(0,-5,0),Color3.fromRGB(23,30,49),Enum.Material.Slate)
  part('Plaza',Vector3.new(58,1,58),center+Vector3.new(0,-.5,0),Color3.fromRGB(40,49,72),Enum.Material.Marble)
  for _,x in ipairs({-30,30}) do part('LightStrip',Vector3.new(1,.2,60),center+Vector3.new(x,.15,0),def.Color,Enum.Material.Neon) end
  for i=1,12 do
   local angle=i*math.pi/6;local pos=center+Vector3.new(math.cos(angle)*50,0,math.sin(angle)*50)
   if id=='hub' then
    part('TreeTrunk',Vector3.new(2,8,2),pos+Vector3.new(0,3,0),Color3.fromRGB(84,64,60),Enum.Material.Wood)
    local crown=part('TreeCrown',Vector3.new(11,11,11),pos+Vector3.new(0,11,0),Color3.fromRGB(70,130,135));crown.Shape=Enum.PartType.Ball
   elseif id=='neon' then
    local height=12+(i%4)*7
    part('Skyline',Vector3.new(9,height,9),pos+Vector3.new(0,height/2,0),Color3.fromRGB(38,33,65),Enum.Material.Metal)
    part('SkylineTrim',Vector3.new(9.2,.7,9.2),pos+Vector3.new(0,height,0),def.Color,Enum.Material.Neon)
   else
    local crystal=part('AstralCrystal',Vector3.new(5,14,5),pos+Vector3.new(0,8,0),def.Color,Enum.Material.Glass);crystal.CFrame*=CFrame.Angles(0,angle,math.rad(20));crystal.Transparency=.2
   end
  end
  local monument=part('RealmBeacon',Vector3.new(5,12,5),center+Vector3.new(0,6,-18),def.Color,Enum.Material.Neon);sign(monument,def.Name..'\nCOLLECT • EXPLORE • ASCEND')
  for n,destination in ipairs(config.WorldOrder) do if destination~=id then
   local pos=center+Vector3.new((n-2)*22,5,32)
   part('GateLeft',Vector3.new(2,10,2),pos+Vector3.new(-5,0,0),config.Worlds[destination].Color,Enum.Material.Neon)
   part('GateRight',Vector3.new(2,10,2),pos+Vector3.new(5,0,0),config.Worlds[destination].Color,Enum.Material.Neon)
   local gate=part('Gate',Vector3.new(8,8,1),pos,config.Worlds[destination].Color,Enum.Material.ForceField);gate.CanCollide=false;gate.Transparency=.4
   sign(gate,config.Worlds[destination].Name)
   local prompt=Instance.new('ProximityPrompt');prompt.ActionText='Travel';prompt.ObjectText=config.Worlds[destination].Name;prompt.HoldDuration=.25;prompt.MaxActivationDistance=10;prompt.Parent=gate
   prompt.Triggered:Connect(function(player)
    local char=player.Character;local root=char and char:FindFirstChild('HumanoidRootPart')
    if not root or (root.Position-gate.Position).Magnitude>15 then return end
    local _,message=api.travel(player,destination);notify(player,message)
   end)
  end end
 end
 local spawn=Instance.new('SpawnLocation');spawn.Name='NexusSpawn';spawn.Anchored=true;spawn.Size=Vector3.new(8,1,8);spawn.Position=Vector3.new(0,1,8);spawn.Neutral=true;spawn.Duration=0;spawn.Color=config.Worlds.hub.Color;spawn.Parent=folder
 return api
end
return World
