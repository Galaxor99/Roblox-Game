-- Configurable development identities. No portraits, likenesses, audio or models bundled.
-- Public mode excludes entries without confirmed rights metadata.
local Roster={}
local groups={
 {Universe='Dragon Ball',Faction='Astral',Names={'Goku','Vegeta','Gohan','Piccolo','Trunks','Broly','Frieza','Beerus','Whis','Android 18'}},
 {Universe='Naruto',Faction='Arcane',Names={'Naruto Uzumaki','Sasuke Uchiha','Kakashi Hatake','Sakura Haruno','Itachi Uchiha','Madara Uchiha','Gaara','Rock Lee','Minato Namikaze','Hinata Hyuga'}},
 {Universe='One Piece',Faction='Rift',Names={'Monkey D. Luffy','Roronoa Zoro','Nami','Sanji','Trafalgar Law','Shanks','Nico Robin','Portgas D. Ace','Jinbe','Tony Tony Chopper'}},
 {Universe='Bleach',Faction='Arcane',Names={'Ichigo Kurosaki','Rukia Kuchiki','Renji Abarai','Byakuya Kuchiki','Sosuke Aizen','Kisuke Urahara'}},
 {Universe='Jujutsu Kaisen',Faction='Arcane',Names={'Yuji Itadori','Megumi Fushiguro','Nobara Kugisaki','Satoru Gojo','Ryomen Sukuna','Yuta Okkotsu'}},
 {Universe='Demon Slayer',Faction='Rift',Names={'Tanjiro Kamado','Nezuko Kamado','Zenitsu Agatsuma','Inosuke Hashibira','Kyojuro Rengoku','Shinobu Kocho'}},
 {Universe='My Hero Academia',Faction='Neon',Names={'Izuku Midoriya','Katsuki Bakugo','Shoto Todoroki','All Might','Ochaco Uraraka','Hawks'}},
 {Universe='Hunter x Hunter',Faction='Rift',Names={'Gon Freecss','Killua Zoldyck','Kurapika','Leorio','Hisoka','Meruem'}},
 {Universe='Solo Leveling',Faction='Arcane',Names={'Sung Jinwoo','Cha Hae-In','Igris','Beru'}},
 {Universe='Attack on Titan',Faction='Rift',Names={'Eren Yeager','Mikasa Ackerman','Armin Arlert','Levi Ackerman'}},
 {Universe='Fullmetal Alchemist',Faction='Arcane',Names={'Edward Elric','Alphonse Elric','Roy Mustang','Riza Hawkeye'}},
 {Universe='DC',Faction='Neon',Names={'Superman','Batman','Wonder Woman','The Flash','Green Lantern','Aquaman','Raven','Cyborg','Supergirl','Nightwing'}},
 {Universe='Marvel',Faction='Neon',Names={'Spider-Man','Iron Man','Captain America','Thor','Hulk','Black Panther','Doctor Strange','Scarlet Witch','Wolverine','Storm'}},
 {Universe='Star Wars',Faction='Astral',Names={'Luke Skywalker','Darth Vader','Leia Organa','Obi-Wan Kenobi','Ahsoka Tano','Yoda','Din Djarin','Rey'}},
 {Universe='The Lord of the Rings',Faction='Arcane',Names={'Gandalf','Aragorn','Legolas','Gimli','Frodo Baggins','Galadriel'}},
 {Universe='Avatar: The Last Airbender',Faction='Rift',Names={'Aang','Katara','Zuko','Toph Beifong','Sokka','Azula'}},
 {Universe='Arcane',Faction='Neon',Names={'Vi','Jinx','Caitlyn','Ekko'}},
 {Universe='The Matrix',Faction='Neon',Names={'Neo','Trinity','Morpheus','Agent Smith'}},
 {Universe='Harry Potter',Faction='Arcane',Names={'Harry Potter','Hermione Granger','Ron Weasley','Albus Dumbledore'}},
 {Universe='Devil May Cry',Faction='Arcane',Names={'Dante','Vergil','Nero','Lady'}},
 {Universe='Final Fantasy',Faction='Astral',Names={'Cloud Strife','Tifa Lockhart','Aerith Gainsborough','Sephiroth'}},
 {Universe='God of War',Faction='Rift',Names={'Kratos','Atreus','Freya','Mimir'}},
 {Universe='Sonic the Hedgehog',Faction='Neon',Names={'Sonic','Shadow','Knuckles','Tails'}},
 {Universe='The Legend of Zelda',Faction='Arcane',Names={'Link','Zelda','Ganondorf','Midna'}},
 {Universe='Street Fighter',Faction='Rift',Names={'Ryu','Chun-Li','Ken Masters','Akuma'}},
 {Universe='Halo',Faction='Astral',Names={'Master Chief','Cortana','The Arbiter','Sergeant Johnson'}},
 {Universe='Metroid',Faction='Astral',Names={'Samus Aran','Dark Samus','Ridley','Raven Beak'}},
 {Universe='Chainsaw Man',Faction='Rift',Names={'Denji','Power','Aki Hayakawa','Makima'}},
 {Universe='One-Punch Man',Faction='Neon',Names={'Saitama','Genos','Tatsumaki','Garou'}},
 {Universe='Frieren',Faction='Arcane',Names={'Frieren','Fern','Stark','Himmel'}},
}
local function slug(s) return string.lower(s):gsub('[^%w]+','_'):gsub('_$','') end
function Roster.apply(config)
 local rarities={'Rare','Epic','Legendary','Mythic','Rare','Epic','Legendary','Celestial','Common','Rare'}
 local bases={Common=90,Rare=175,Epic=310,Legendary=600,Mythic=1050,Celestial=2200}
 local traits={'Precision','Momentum','Guardian','Foresight','Reliable','Surge'}
 local portraitIndex=0
 for groupIndex,group in ipairs(groups) do for i,name in ipairs(group.Names) do
  portraitIndex+=1
  local id='fiction_'..slug(group.Universe)..'_'..slug(name)
  local override=config.IdentityOverrides[id] or {}
  local eligible=override.PublicEligible==true
  do
   local rarity=override.Rarity or rarities[(i+groupIndex-2)%#rarities+1]
   local base=bases[rarity];local tilt=((i*7+groupIndex*3)%9-4)/20
   local display=override.DisplayName or name
   config.Cards[id]={Enabled=config.RosterMode=='Development' or eligible,Name=display,Rarity=rarity,Power=math.floor(base*(1+tilt)),Speed=math.floor(base*(1-tilt)),Defense=math.floor(base*.85),Energy=math.floor(base*1.1),Trait=traits[(i-1)%#traits+1],Faction=group.Faction,Universe=group.Universe,Lore="An echo from "..group.Universe..". Its "..string.lower(traits[(i-1)%#traits+1]).." style can change an expedition.",Color=config.RarityColors[rarity],Identity={DisplayName=display,CanonicalName=name,Universe=group.Universe,ModelName=override.ModelName or id,PortraitAssetId=override.PortraitAssetId or 0,PortraitAtlas=4+math.ceil(portraitIndex/9),PortraitAtlasCell=(portraitIndex-1)%9+1,LicenseStatus=override.LicenseStatus or 'Unverified',PublicEligible=eligible}}
  end
 end end
end
return Roster
