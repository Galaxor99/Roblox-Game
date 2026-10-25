-- Three navigable realm scenes assembled from native Studio primitives.
local World={}
function World.create(config,canVisit,notify,onDiscover)
 local folder=Instance.new('Folder');folder.Name='AnimeNexusRealms';folder.Parent=workspace
 local centers={hub=Vector3.new(0,0,0),neon=Vector3.new(200,0,0),astral=Vector3.new(-200,0,0)}
 local api={}
 local function part(name,size,pos,color,material,parent)
  local p=Instance.new('Part');p.Name=name;p.Size=size;p.Position=pos;p.Color=color;p.Anchored=true;p.Material=material or Enum.Material.SmoothPlastic
  p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent or folder;return p
 end
 local function sign(p,title)
  local bill=Instance.new('BillboardGui');bill.Size=UDim2.fromOffset(220,54);bill.StudsOffset=Vector3.new(0,5,0);bill.MaxDistance=90;bill.AlwaysOnTop=true;bill.Parent=p
  local t=Instance.new('TextLabel');t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Font=Enum.Font.GothamBold;t.TextSize=17;t.TextWrapped=true;t.Text=title
  t.TextColor3=Color3.fromRGB(230,245,255);t.TextStrokeTransparency=.4;t.Parent=bill
 end
 local function ornament(p)
  p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
  return p
 end
 local function promptAt(p,action,object,callback)
  local prompt=Instance.new('ProximityPrompt');prompt.ActionText=action;prompt.ObjectText=object;prompt.HoldDuration=.3;prompt.MaxActivationDistance=11;prompt.RequiresLineOfSight=false;prompt.Parent=p
  prompt.Triggered:Connect(function(player)
   local character=player.Character;local root=character and character:FindFirstChild('HumanoidRootPart')
   local hum=character and character:FindFirstChildOfClass('Humanoid')
   if not root or not hum or hum.Health<=0 or (root.Position-p.Position).Magnitude>16 then return end
   callback(player)
  end)
 end
 function api.travel(player,id)
  if not centers[id] or not canVisit(player,id) then return false,'Unlock this world in the Worlds menu first' end
  local character=player.Character;local hum=character and character:FindFirstChildOfClass('Humanoid')
  if not character or not hum or hum.Health<=0 then return false,'Wait for your avatar to respawn' end
  character:PivotTo(CFrame.new(centers[id]+Vector3.new(0,6,8)))
  return true,'Arrived at '..config.Worlds[id].Name
 end
 for _,id in ipairs(config.WorldOrder) do
  local def=config.Worlds[id];local center=centers[id]
  local realm=Instance.new('Folder');realm.Name=def.Name;realm.Parent=folder
  -- Top surface at y=1, above the static baseplate in the supplied place.
  part('IslandFoundation',Vector3.new(132,10,132),center+Vector3.new(0,-4,0),Color3.fromRGB(23,30,49),Enum.Material.Slate,realm)
  part('CentralPlaza',Vector3.new(60,1,60),center+Vector3.new(0,1,0),Color3.fromRGB(43,50,75),Enum.Material.Marble,realm)
  for i=1,4 do
   local a=(i-1)*math.pi/2
   local path=part('Promenade',Vector3.new(12,.3,32),center+Vector3.new(math.sin(a)*43,1.16,math.cos(a)*43),Color3.fromRGB(59,67,93),Enum.Material.Slate,realm)
   path.CFrame*=CFrame.Angles(0,a,0)
  end
  for i=1,12 do
   local angle=i*math.pi/6;local pos=center+Vector3.new(math.cos(angle)*51,0,math.sin(angle)*51)
   if id=='hub' then
    part('GroveTrunk',Vector3.new(2,9,2),pos+Vector3.new(0,5.5,0),Color3.fromRGB(84,64,60),Enum.Material.Wood,realm)
    local crown=ornament(part('GroveCanopy',Vector3.new(12,12,12),pos+Vector3.new(0,15,0),Color3.fromRGB(64,125,140),Enum.Material.SmoothPlastic,realm));crown.Shape=Enum.PartType.Ball
    ornament(part('Lantern',Vector3.new(1,1,1),pos+Vector3.new(0,10,0),def.Color,Enum.Material.Neon,realm))
   elseif id=='neon' then
    local height=14+(i%4)*7
    part('CityTower',Vector3.new(9,height,9),pos+Vector3.new(0,height/2+1,0),Color3.fromRGB(39,34,67),Enum.Material.Metal,realm)
    ornament(part('TowerTrim',Vector3.new(9.4,.7,9.4),pos+Vector3.new(0,height+1,0),def.Color,Enum.Material.Neon,realm))
    ornament(part('WindowBand',Vector3.new(9.2,.3,9.2),pos+Vector3.new(0,height*.55,0),Color3.fromRGB(74,205,235),Enum.Material.Neon,realm))
   else
    local crystal=ornament(part('AstralCrystal',Vector3.new(5,15,5),pos+Vector3.new(0,9,0),def.Color,Enum.Material.Glass,realm))
    crystal.CFrame*=CFrame.Angles(0,angle,math.rad(18));crystal.Transparency=.18
    ornament(part('CrystalHalo',Vector3.new(8,.7,8),pos+Vector3.new(0,3,0),Color3.fromRGB(160,180,245),Enum.Material.Neon,realm))
   end
  end
  local beacon=part('RealmBeacon',Vector3.new(5,13,5),center+Vector3.new(0,8,-18),def.Color,Enum.Material.Neon,realm)
  sign(beacon,def.Name..'\nTHE FRACTURE REMAINS')
  local discoveryList=config.Discoveries[id]
  for index,memoryId in ipairs(discoveryList) do
   local angle=index*math.pi*2/3+.4
   local pos=center+Vector3.new(math.cos(angle)*35,1,math.sin(angle)*35)
   local pedestal=part('MemoryPedestal',Vector3.new(6,2,6),pos+Vector3.new(0,1,0),Color3.fromRGB(42,52,72),Enum.Material.Marble,realm)
   local orb=ornament(part('Memory_'..memoryId,Vector3.new(3.5,3.5,3.5),pos+Vector3.new(0,5,0),def.Color,Enum.Material.Neon,realm));orb.Shape=Enum.PartType.Ball
   ornament(part('MemoryRing',Vector3.new(7,.4,7),pos+Vector3.new(0,2.2,0),def.Color,Enum.Material.Neon,realm))
   sign(orb,config.DiscoveryNames[memoryId])
   promptAt(pedestal,'Discover',config.DiscoveryNames[memoryId],function(player)
    if not canVisit(player,id) then notify(player,'Unlock this world first');return end
    local _,message=onDiscover(player,memoryId);notify(player,message)
   end)
  end
  for n,destination in ipairs(config.WorldOrder) do if destination~=id then
   local pos=center+Vector3.new((n-2)*22,6,32)
   part('GateLeft',Vector3.new(2,10,2),pos+Vector3.new(-5,0,0),config.Worlds[destination].Color,Enum.Material.Neon,realm)
   part('GateRight',Vector3.new(2,10,2),pos+Vector3.new(5,0,0),config.Worlds[destination].Color,Enum.Material.Neon,realm)
   ornament(part('GateLintel',Vector3.new(12,2,2),pos+Vector3.new(0,5,0),config.Worlds[destination].Color,Enum.Material.Neon,realm))
   local gate=part('Gate',Vector3.new(8,8,1),pos,config.Worlds[destination].Color,Enum.Material.ForceField,realm);gate.CanCollide=false;gate.Transparency=.45
   sign(gate,config.Worlds[destination].Name)
   promptAt(gate,'Travel',config.Worlds[destination].Name,function(player)
    local _,message=api.travel(player,destination);notify(player,message)
   end)
  end end
 end
 local spawn=Instance.new('SpawnLocation');spawn.Name='NexusSpawn';spawn.Anchored=true;spawn.Size=Vector3.new(8,1,8);spawn.Position=Vector3.new(0,2.3,8);spawn.Neutral=true;spawn.Duration=0;spawn.Color=config.Worlds.hub.Color;spawn.Parent=folder
 local oldSpawn=workspace:FindFirstChild('SpawnLocation')
 if oldSpawn and oldSpawn:IsA('SpawnLocation') then oldSpawn.Enabled=false end
 return api
end
return World
