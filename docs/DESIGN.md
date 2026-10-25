# Design record

Source of direction: user-pasted “Build Roblox Game” conversation and the supplied UI-fixed place. The shared conversation URL was inaccessible (HTTP 403); the pasted requirements were read directly.

## Confirmed direction

- Public-facing ambition, multiverse theme, long-term collection progression.
- Hybrid RNG/card RPG; characters are cards with stats, not directly controlled fighters.
- Up to three favourites appear behind the avatar as cosmetic displays.
- Power, speed, defense and energy determine automated activities.
- Summons use Common 55%, Rare 25%, Epic 12%, Legendary 6%, Mythic 1.8%, Celestial 0.2% as the initial basic-pack balance.
- Pity, duplicate utility, rare variants, guaranteed unlock routes and meaningful lower-rarity team utility.
- Central hub with three initial unlockable worlds; expandable roster across anime, films, shows and games.
- Continue source and roadmap development; do not generate another Studio build.

## Milestone design assumptions

- Highest five effective unique cards form the automatic team; manual selection supports up to five.
- Variant bonus applies once using the strongest owned variant, never per duplicate.
- A card's level applies across all copies and variants of that card ID.
- Two same-faction allies grant 5% team power; three or more grant 15%; bonuses do not add across factions.
- Duplicate upgrades/recycling consume normal copies only and preserve the last total copy.
- Expedition speed reduction caps at 25%; boss favored-stat adjustment caps at 25%.
- Boss outcomes are rolled at start, stored privately and revealed only at claim. Maximum success chance is 98%; minimum 5%.
- Collection sets add 2% each to Epic+ weights, before normalization; not two percentage points of final probability.
- Daily rewards use UTC day boundaries and a seven-day streak cycle.
- Active expedition and boss teams earn mastery when the outcome is claimed. Deliberate awakening needs level 25, mastery rank 5, three boss wins and materials; it is separate from a randomly rolled Awakened variant.
- Expeditions lock route, team and outcome at start. Steady, Swift and Perilous routes vary time, reward and success chance; named card traits improve their matching route.
- Each realm has three discoverable memories. Story chapters require exploration and prior chapter completion and grant a known card.
- Weekly events rotate by UTC week and grant milestone rewards once per week. A weekly event is distinct from a shared multiplayer boss.
- Global rankings read OrderedDataStores only when their short server cache expires and write after a successful profile save. The profile remains authoritative if a ranking write fails.
- The shared daily boss stores one contribution per player and UTC day in 16 durable shards. A later claim reads the shared total and uses an atomic update on the player's profile. During a storage outage it does not assume success or award a reward. The claim window is seven days.
- Unverified franchise definitions are configurable development identities with placeholder assets. Stats are generated balance templates, not individually authored movesets.

## Variant odds

| Variant | Chance | Power multiplier |
| --- | --- | --- |
| Normal | 97% | 1.00 |
| Shiny | 2.5% | 1.10 |
| Corrupted | 0.4% | 1.20 |
| Awakened | 0.09% | 1.35 |
| Celestial | 0.01% | 1.50 |

These rolls are independent of rarity and are not affected by luck or rarity pity. A random Awakened variant is not a completed awakening quest system.

## Architecture

`NexusConfig` holds balancing, world/quest definitions and identity overrides. `NexusRoster` supplies expanded franchise data. `NexusProgression` is a pure rules module shared by server and client for display calculations; only server mutations count. `NexusPersistence` manages exclusive leases, atomic per-profile receipts and shared reward claims. `NexusRankings` manages global top tens. `NexusCoop` manages durable shared contributions. `NexusWorld` creates themed realms and proximity-validated memory prompts. `NexusServer` validates RPCs and owns rewards, clocks, RNG and saves. `NexusClient` renders public snapshots and sends bounded action requests.

No offline process is required for expeditions: persisted finish timestamps are compared against the server clock when the player claims. Claimed rewards and progression must then be saved; there is still a potential rollback window between a reward and the next successful autosave after an abrupt server crash. Trading requires stronger transactional guarantees before it can be introduced.
