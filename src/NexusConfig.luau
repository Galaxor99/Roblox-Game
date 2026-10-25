local C = {}
C.Version = 4
C.Rarities = {"Common", "Rare", "Epic", "Legendary", "Mythic", "Celestial"}
C.RarityColors = {Common=Color3.fromRGB(165,165,175), Rare=Color3.fromRGB(80,155,255), Epic=Color3.fromRGB(190,90,250), Legendary=Color3.fromRGB(255,186,45), Mythic=Color3.fromRGB(255,70,100), Celestial=Color3.fromRGB(80,240,240)}
C.Cards = {
  recruit={Name="Rift Recruit",Rarity="Common",Power=90,Speed=75,Defense=100,Energy=70,Trait="Reliable",Color=Color3.fromRGB(125,160,210)},
  spark={Name="Spark Runner",Rarity="Common",Power=80,Speed=125,Defense=70,Energy=90,Trait="Swift",Color=Color3.fromRGB(80,205,250)},
  sentinel={Name="Iron Sentinel",Rarity="Rare",Power=155,Speed=65,Defense=210,Energy=115,Trait="Guardian",Color=Color3.fromRGB(155,190,220)},
  ember={Name="Ember Ronin",Rarity="Rare",Power=200,Speed=155,Defense=95,Energy=125,Trait="Blazing",Color=Color3.fromRGB(255,140,70)},
  frost={Name="Frost Warden",Rarity="Epic",Power=290,Speed=180,Defense=260,Energy=210,Trait="Chill",Color=Color3.fromRGB(110,215,255)},
  thunder={Name="Thunder Vanguard",Rarity="Epic",Power=340,Speed=350,Defense=165,Energy=275,Trait="Surge",Color=Color3.fromRGB(170,100,250)},
  eclipse={Name="Eclipse Knight",Rarity="Legendary",Power=620,Speed=420,Defense=470,Energy=550,Trait="Eclipse",Color=Color3.fromRGB(180,90,235)},
  comet={Name="Comet Drifter",Rarity="Legendary",Power=540,Speed=710,Defense=250,Energy=600,Trait="Momentum",Color=Color3.fromRGB(240,110,130)},
  sovereign={Name="Shadow Sovereign",Rarity="Mythic",Power=1120,Speed=750,Defense=680,Energy=1270,Trait="Legion",Color=Color3.fromRGB(105,90,200)},
  oracle={Name="Chrono Oracle",Rarity="Mythic",Power=850,Speed=1240,Defense=630,Energy=1380,Trait="Foresight",Color=Color3.fromRGB(90,220,220)},
  astral={Name="Astral Monarch",Rarity="Celestial",Power=2250,Speed=1450,Defense=1700,Energy=2400,Trait="Transcendent",Color=Color3.fromRGB(240,215,100)},
}
-- Weights are percentages, total 100. Each pack has its own pool and pity threshold.
C.Packs = {
  basic={Name="Rift Pack",Price=100,Weights={Common=55,Rare=25,Epic=12,Legendary=6,Mythic=1.8,Celestial=0.2},Pity=30,Description="Balanced starter summons"},
  elite={Name="Ascendant Pack",Price=350,Weights={Common=0,Rare=45,Epic=34,Legendary=16,Mythic=4.5,Celestial=0.5},Pity=18,Description="Rare or better guaranteed"},
  cosmic={Name="Cosmic Pack",Price=1000,Weights={Common=0,Rare=0,Epic=55,Legendary=30,Mythic=13,Celestial=2},Pity=10,Description="Epic or better guaranteed"},
}
C.Expeditions = {
  scouting={Name="Rift Scouting",Duration=30,RequiredPower=250,Reward=125,Unlock=0},
  citadel={Name="Broken Citadel",Duration=90,RequiredPower=1250,Reward=450,Unlock=5},
  abyss={Name="Astral Abyss",Duration=180,RequiredPower=4000,Reward=1400,Unlock=15},
}
-- Increasing permanent luck costs and expedition milestones.
C.LuckUpgradeCosts={1000,2500,5000,9000,15000,24000,37000,55000,80000,120000}
C.LuckExpeditionRequirements={2,5,10,18,30,45,65,90,125,170}
C.LuckCost = 1000 -- legacy compatibility
C.LuckMaxLevel = 10
C.LuckBonusPerLevel = 0.08 -- multiplies Epic+ weights; automatically renormalised
C.FreeStarterCoins = 600
C.Monetization={
 LuckPassId=0, -- Add an actual GAME PASS ID after creating it in Creator Hub.
 PotionProductIds={minor=0,major=0}, -- Actual DEVELOPER PRODUCT IDs.
}
C.Potions={
 minor={Name="Lucky Draught",Bonus=0.25,Duration=600,Ingredients={Essence=8,Crystals=2}},
 major={Name="Astral Elixir",Bonus=0.75,Duration=900,Ingredients={Essence=24,Crystals=8}},
}
-- Luck factors multiply Epic+ rarity weights (not guaranteed probabilities).
-- 2x Game Pass doubles the entire base-plus-permanent-plus-potion boost factor.
-- Boosts do not stack with themselves; strongest potion wins.


-- Release 4 roster: original characters grouped into expedition factions.
C.Factions={Rift="Riftborn",Neon="Neon Vanguard",Arcane="Arcane Covenant",Astral="Astral Court"}
local factions={recruit="Rift",spark="Neon",sentinel="Neon",ember="Rift",frost="Arcane",thunder="Neon",eclipse="Arcane",comet="Astral",sovereign="Arcane",oracle="Astral",astral="Astral"}
for id,faction in pairs(factions) do C.Cards[id].Faction=faction end
local additions={
 {"tide","Tide Apprentice","Common",85,90,80,95,"Flow","Arcane",70,190,220},
 {"scout","Rooftop Scout","Common",75,130,65,95,"Agile","Neon",120,230,160},
 {"warden","Grove Warden","Rare",140,90,230,140,"Roots","Rift",95,190,110},
 {"gunslinger","Nova Gunslinger","Rare",190,180,90,130,"Precision","Astral",235,165,90},
 {"phantom","Phantom Courier","Epic",310,370,140,265,"Phase","Neon",135,110,245},
 {"witch","Glass Witch","Epic",300,205,200,360,"Prism","Arcane",220,140,230},
 {"titan","Verdant Titan","Legendary",560,220,850,440,"Bastion","Rift",90,200,130},
 {"captain","Solar Corsair","Legendary",600,550,360,610,"Broadside","Astral",245,165,65},
 {"archon","Neon Archon","Mythic",1000,1150,550,1100,"Overdrive","Neon",70,230,235},
 {"seraph","Dawn Seraph","Mythic",970,800,950,1120,"Renewal","Rift",250,210,145},
 {"weaver","Fate Weaver","Celestial",2050,1800,1450,2500,"Destiny","Arcane",215,160,250},
 {"leviathan","Star Leviathan","Celestial",2400,1000,2200,2150,"Gravity","Astral",95,175,250},
}
for _,v in ipairs(additions) do
 C.Cards[v[1]]={Name=v[2],Rarity=v[3],Power=v[4],Speed=v[5],Defense=v[6],Energy=v[7],Trait=v[8],Faction=v[9],Color=Color3.fromRGB(v[10],v[11],v[12])}
end
C.Achievements={
 {Id="first_summon",Name="A Rift Awakens",Stat="Rolls",Target=1,Coins=100,Essence=2},
 {Id="ten_summons",Name="Summoner in Training",Stat="Rolls",Target=10,Coins=250,Essence=8},
 {Id="fifty_summons",Name="Nexus Collector",Stat="Rolls",Target=50,Coins=800,Essence=20},
 {Id="first_journey",Name="Beyond the Gate",Stat="Completed",Target=1,Coins=125,Essence=3},
 {Id="ten_journeys",Name="Rift Pathfinder",Stat="Completed",Target=10,Coins=500,Essence=15},
 {Id="five_cards",Name="A Growing Alliance",Stat="Unique",Target=5,Coins=200,Essence=5},
 {Id="fifteen_cards",Name="Worlds United",Stat="Unique",Target=15,Coins=1000,Essence=30},
}


-- Identity fields are data only; no franchise assets are bundled.
local expanded={
 {"velocity","Velocity Zero","Mythic",1100,1500,400,900,"Momentum","Neon",255,90,100},
 {"aegis","Aegis Inventor","Epic",330,240,280,330,"Overclock","Neon",220,100,75},
 {"blade","Silent Blade","Rare",210,190,95,85,"Precision","Arcane",150,160,230},
 {"dune","Dune Wanderer","Common",100,85,110,55,"Endurance","Rift",220,180,120},
 {"ocean","Ocean Regent","Legendary",570,350,650,580,"Tidal","Rift",65,165,215},
 {"raven","Raven Tactician","Epic",260,300,260,370,"Strategy","Neon",130,125,185},
 {"sunforge","Sunforge Knight","Legendary",650,310,700,440,"Bulwark","Arcane",245,195,80},
 {"dream","Dream Cartographer","Rare",120,150,110,230,"Insight","Astral",175,130,230},
 {"moss","Moss Sprite","Common",65,95,80,135,"Renewal","Rift",125,210,140},
 {"ghost","Ghost Navigator","Epic",240,340,180,410,"Phase","Astral",130,220,220},
 {"crown","Crowned Paradox","Celestial",2100,2000,1400,2400,"Causality","Astral",240,160,230},
 {"lunar","Lunar Huntress","Rare",180,200,100,130,"Tracking","Arcane",120,150,220},
 {"atlas","Atlas Engine","Mythic",1200,450,1450,900,"Fortress","Neon",170,185,205},
}
for _,v in ipairs(expanded) do
 C.Cards[v[1]]={Name=v[2],Rarity=v[3],Power=v[4],Speed=v[5],Defense=v[6],Energy=v[7],Trait=v[8],Faction=v[9],Color=Color3.fromRGB(v[10],v[11],v[12])}
end
for id,card in pairs(C.Cards) do
 card.Identity={DisplayName=card.Name,ModelName=id,PortraitAssetId=0,LicenseStatus="Original",PublicEligible=true}
end
C.CardLore={
 recruit="The first volunteer to map the broken gates. Steady hands make dangerous routes feel possible.",
 spark="A courier who once crossed the Sanctuary in a heartbeat. Swift teams reach their destination sooner.",
 sentinel="An old city defender rebuilt to shelter Riftwalkers from the unknown.",
 ember="A wandering blade who follows the glow of unstable gateways.",
 frost="Guardian of the northern archives, where frozen memories remain intact.",
 thunder="A restless Vanguard who turns the Citadel's storm into a path forward.",
 eclipse="An oathbound knight searching for the moment the sky went dark.",
 comet="A pilot who reads star trails as maps through broken realities.",
 sovereign="Commander of a vanished host, remembered by the shadows it left behind.",
 oracle="A keeper of future fragments who sees several endings at once.",
 astral="The last monarch to hear the original signal from beyond the Fracture.",
 tide="A patient apprentice who listens to the currents flowing between realms.",
 scout="A rooftop runner who knows every hidden approach to the Neon Citadel.",
 warden="The grove's quiet protector, rooted beside its oldest memory.",
 gunslinger="An explorer who keeps one bright flare for the darkest rift.",
 phantom="A messenger who slips through the static before a signal fades.",
 witch="A prism scholar who splits a single clue into many possible truths.",
 titan="A living shelter grown where the Sanctuary's defenses failed.",
 captain="A solar navigator charting courses through impossible skies.",
 archon="The Citadel's forgotten engine given will and purpose.",
 seraph="A dawn watcher who promises that lost worlds can bloom again.",
 weaver="An artisan of uncertain fates, collecting the threads between memories.",
 leviathan="A vast traveler sleeping beneath the light of the Astral Expanse.",
 velocity="A messenger who treats every second as a door to another path.",
 aegis="A maker of protective devices for journeys no map can predict.",
 blade="A quiet duelist who learns more from a pause than from a strike.",
 dune="A survivor who crossed the silent wastes after the first fracture.",
 ocean="A ruler who guards the tides that connect scattered shores.",
 raven="A strategist tracing the pattern hidden in the Citadel's blackouts.",
 sunforge="A shield bearer forged in the last warm light of a dying world.",
 dream="A cartographer drawing routes remembered only in sleep.",
 moss="A small spirit proving that even a broken realm can regrow.",
 ghost="A guide who follows the faint signals of lost travelers.",
 crown="A paradox given form at the edge of every possible ending.",
 lunar="A patient tracker who reads the night for traces of the Rift.",
 atlas="A walking citadel built to carry a city's last hope.",
}
for id,lore in pairs(C.CardLore) do C.Cards[id].Lore=lore end
C.WorldOrder={"hub","neon","astral"}
C.Worlds={
 hub={Name="Nexus Sanctuary",Completed=0,Cost=0,Color=Color3.fromRGB(90,150,210)},
 neon={Name="Neon Citadel",Completed=5,Cost=500,Color=Color3.fromRGB(180,90,245)},
 astral={Name="Astral Expanse",Completed=15,Cost=1800,Color=Color3.fromRGB(80,215,205)},
}
C.Expeditions.scouting.World="hub";C.Expeditions.citadel.World="neon";C.Expeditions.abyss.World="astral"
C.BossOrder={"guardian","overseer","fracture"}
C.Bosses={
 guardian={Name="The Rift Guardian",World="hub",Power=900,Reward=180,Essence=6,Crystals=1,Stat="Defense",Duration=45},
 overseer={Name="Neon Overseer",World="neon",Power=4500,Reward=550,Essence=15,Crystals=3,Stat="Speed",Duration=75},
 fracture={Name="Heart of the Fracture",World="astral",Power=14000,Reward=1500,Essence=35,Crystals=8,Stat="Energy",Duration=120},
}
C.VariantOrder={"Normal","Shiny","Corrupted","Awakened","Celestial"}
C.Variants={
 Normal={Weight=9700,Multiplier=1},Shiny={Weight=250,Multiplier=1.10},Corrupted={Weight=40,Multiplier=1.20},Awakened={Weight=9,Multiplier=1.35},Celestial={Weight=1,Multiplier=1.50},
}
C.CardMaxLevel=100
C.Formations={Line={Completed=0},Arc={Completed=5},Orbit={Completed=15}}
C.MasteryMaxRank=10
C.Awakening={Level=25,MasteryRank=5,BossWins=3,Essence=250,Crystals=12,PowerMultiplier=1.25}
C.ExpeditionRoutes={
 steady={Name="Steady Passage",Chance=1,Reward=1,Duration=1,Stat="Defense",Description="Reliable route that favors a durable team"},
 swift={Name="Swift Passage",Chance=.92,Reward=1.2,Duration=.7,Stat="Speed",Description="Shorter journey with a speed advantage"},
 perilous={Name="Perilous Passage",Chance=.72,Reward=1.65,Duration=1.15,Stat="Energy",Description="Hard route with greater rewards"},
}
C.Bosses.guardian.WeaknessTraits={Guardian=true,Bulwark=true,Bastion=true}
C.Bosses.overseer.WeaknessTraits={Swift=true,Agile=true,Overdrive=true}
C.Bosses.fracture.WeaknessTraits={Foresight=true,Destiny=true,Insight=true}
C.Discoveries={
 hub={"hub_archive","hub_observatory","hub_garden"},
 neon={"neon_workshop","neon_transit","neon_signal"},
 astral={"astral_vault","astral_spire","astral_echo"},
}
C.DiscoveryNames={
 hub_archive="Rift Archive",hub_observatory="Fracture Observatory",hub_garden="Memory Garden",
 neon_workshop="Signal Workshop",neon_transit="Skyrail Terminal",neon_signal="Lost Broadcast",
 astral_vault="Starlit Vault",astral_spire="Celestial Spire",astral_echo="Origin Echo",
}
C.ChapterOrder={"fracture","neon","astral"}
C.Chapters={
 fracture={Name="Chapter I: The Fracture",World="hub",Completed=2,BossWins=0,Card="warden",Coins=400,Essence=15,Story="The sky above the Sanctuary cracked without a sound. Three memories remain among the groves; recover them to trace the first Riftwalker."},
 neon={Name="Chapter II: Broken Signals",World="neon",Completed=8,BossWins=1,Card="gunslinger",Coins=750,Essence=35,Story="The Citadel's lights still answer a signal sent before the Fracture. Find its workshop, transit line and final broadcast to learn who opened the gate."},
 astral={Name="Chapter III: The Origin Echo",World="astral",Completed=20,BossWins=4,Card="oracle",Coins=1800,Essence=75,Story="Beyond the city, an echo repeats every fate the Nexus might have followed. Reach the vault, the spire and the origin to restore the first memory."},
}
C.WeeklyEvents={
 {Id="rift_memory",Name="Rift Memory Week",Description="Recover echoes of the first fracture",Card="frost"},
 {Id="neon_signal",Name="Neon Signal Week",Description="Reconnect the broken city",Card="thunder"},
 {Id="astral_convergence",Name="Astral Convergence Week",Description="Trace the origin of the Nexus",Card="comet"},
}
C.WeeklyMilestones={
 {Id="first",Points=5,Coins=200,Essence=5},
 {Id="second",Points=15,Coins=550,Essence=18},
 {Id="final",Points=35,Coins=1000,Essence=40,EventCard=true},
}
C.QuestOrder={"first_steps","neon_path","astral_path"}
C.Quests={
 first_steps={Name="Answer the Nexus",Stat="Completed",Target=2,Card="sentinel",Coins=150},
 neon_path={Name="A Spark of Hope",Stat="Completed",Target=8,Card="phantom",Coins=350},
 astral_path={Name="Beyond the Fracture",Stat="BossWins",Target=5,Card="comet",Coins=700},
}
C.CollectionSets={
 {Id="first_alliance",Name="First Alliance",Cards={"recruit","spark","sentinel","ember"},Coins=250,Essence=10},
 {Id="rift_guardians",Name="Guardians of the Rift",Cards={"warden","titan","seraph","ocean"},Coins=600,Essence=25},
 {Id="neon_legends",Name="Neon Legends",Cards={"phantom","archon","velocity","atlas"},Coins=1200,Essence=40},
 {Id="astral_court",Name="Astral Court",Cards={"comet","oracle","astral","leviathan"},Coins=1500,Essence=50},
}
C.RosterMode="Development" -- Public mode excludes unverified identities from summons; stored collections remain intact.
C.IdentityOverrides={} -- Stable card ID -> identity fields; keep IDs to preserve collections.
require(script.Parent:WaitForChild("NexusRoster")).apply(C)
C.TraitEffects={}
local function trait(route,bonus,names)
 for _,name in ipairs(names) do C.TraitEffects[name]={Route=route,ChanceBonus=bonus} end
end
trait("steady",.05,{"Reliable","Guardian","Chill","Roots","Bastion","Renewal","Endurance","Bulwark","Fortress","Tidal"})
trait("swift",.06,{"Swift","Momentum","Phase","Agile","Tracking","Precision","Flow"})
trait("perilous",.06,{"Blazing","Surge","Eclipse","Legion","Foresight","Transcendent","Prism","Broadside","Overdrive","Destiny","Gravity","Strategy","Insight"})
for _,card in pairs(C.Cards) do if not C.TraitEffects[card.Trait] then C.TraitEffects[card.Trait]={Route="steady",ChanceBonus=.03} end end
return C
