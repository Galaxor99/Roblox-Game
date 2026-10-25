# Anime Nexus — Shattered Realities

A hybrid card collection RPG based on the supplied [original place](reference/AnimeNexus_UI_Fixed_Studio_Build.original.rbxlx). Characters do not fight directly: players summon cards, compose stat based teams, progress through automated challenges, and display up to three cosmetic followers. The original place is preserved byte for byte for reference.

This repository contains the development source. **No new Roblox Studio build has been generated**, as requested. This is an expanded development milestone, not a finished or published game.

## Current milestone

- 204 configurable cards: 36 originals and 168 fictional identities across 30 franchises.
- Original card descriptions and realm guides explain the Fracture story; every card has collection text.
- Three earnable-currency packs, six rarities, per-pack Legendary+ pity, exact per-card odds, and summon reveal panels.
- Normal, Shiny, Corrupted, Awakened and Celestial variants; higher variants increase effective card power. Variant and rarity are independent.
- Collection search, rarity filters, owned-only view, pagination, and a mobile-oriented scrolling interface.
- Five-card manual or automatic teams, four factions, and two/three-card synergy bonuses.
- Levels 1–100; upgrades spend coins, essence and a normal duplicate. Recycling and upgrades protect the final copy and never automatically consume rare variants.
- Three unlockable realms with themed geometry, gated portals, nine discoverable memories and three story chapters.
- Three routes per offline expedition, useful card traits and stat affinities; three automated bosses.
- Persistent per-card mastery earned by active teams, with deliberate awakening at level 25 and mastery rank 5.
- Guaranteed-card quests, achievements, collection sets, daily streak rewards and collection luck bonuses.
- Rotating weekly events with earned points and guaranteed final card rewards.
- A shared daily Rift Guardian: players across servers contribute team power once, then claim the result during the next seven days.
- Three cosmetic followers; Line, Arc and Orbit formations; current-server and global Cards/Power/Bosses rankings.
- Session leases, periodic saves, guarded shutdown, Studio session-only fallback, RPC validation and receipt reconciliation support.

## Develop and validate

Node 24.19.0 was used in the cloud environment. Python is not required.

```sh
cd /workspace/Roblox-Game
npm ci --ignore-scripts --cache /workspace/.npm-cache
npm test
```

The tests compile every Luau source using a Luau WebAssembly runtime, run progression and persistence scenarios, and exercise the actual server entry point through deterministic service adapters. They do **not** execute the Roblox engine, render the interface, run live DataStores, or prove multiplayer performance. See [validation](docs/VALIDATION.md).

## Update your existing Studio project

Keep a backup of your place. Install the following source files under these exact names. Replace the old `NexusServer`, `NexusClient` and `NexusConfig`; do not run both versions concurrently.

| Studio location | Instance type and name | Source |
| --- | --- | --- |
| ReplicatedStorage | ModuleScript `NexusConfig` | `src/NexusConfig.luau` |
| ReplicatedStorage | ModuleScript `NexusRoster` | `src/NexusRoster.luau` |
| ReplicatedStorage | ModuleScript `NexusProgression` | `src/NexusProgression.luau` |
| ServerScriptService | Script `NexusServer` | `src/NexusServer.server.luau` |
| ServerScriptService | ModuleScript `NexusPersistence` | `src/NexusPersistence.luau` |
| ServerScriptService | ModuleScript `NexusWorld` | `src/NexusWorld.luau` |
| ServerScriptService | ModuleScript `NexusRankings` | `src/NexusRankings.luau` |
| ServerScriptService | ModuleScript `NexusCoop` | `src/NexusCoop.luau` |
| StarterPlayer / StarterPlayerScripts | LocalScript `NexusClient` | `src/NexusClient.client.luau` |

`default.project.json` supplies the equivalent Rojo source mapping for developers who already use Rojo. Rojo synchronization has not been exercised here. No Studio file is built by `npm test`.

The server creates the realms and network objects at runtime. The uploaded place's static baseplate may remain; remove that only if it interferes with your authored terrain. There is no external asset dependency for the placeholder world or followers.

Persistence uses the existing `AnimeNexusHybrid_v2` DataStore and `user_<UserId>` keys. Old collections migrate in place, including normal variants for existing copies. Shut down servers running the old script before deploying this version: old code does not respect the new lease. Test migration in a separate test experience before touching production data. Failed Studio loads remain unsaved; the HUD explicitly says so.

Global rankings use three OrderedDataStores. The shared daily boss uses a separate `AnimeNexusCoop_v1` DataStore with 16 contribution shards. Each player can contribute once per UTC day. Rewards are claimed from the following day and remain available for seven days; a successful shared goal pays 300 coins, 20 essence and 2 crystals, and participation after a missed goal pays 50 coins and 5 essence. The shared challenge requires working DataStores; it fails closed during an outage. Its profile reward claim uses an atomic update to prevent duplicate awards.

## Configure the roster

`NexusRoster` defines the franchise identities; `NexusConfig.IdentityOverrides` can replace names, rarity, portrait IDs, model names and rights metadata without changing persistent card IDs. Franchise cards currently use placeholder visuals and balanced generated stats, not bespoke abilities. A positive `PortraitAssetId` is used for a summon reveal. To use an authored follower, place a vetted `Model` with a `BasePart` under `ReplicatedStorage/NexusModels` named after the stable card ID (or the configured `ModelName`). The procedural follower remains the fallback.

`RosterMode = "Development"` makes all identities summonable. `"Public"` excludes unverified identities from new summons while retaining existing stored collections. This is a summon filter, not a complete public-release asset or UI audit. No franchise rights are asserted by this source. Monetization IDs remain zero, and the UI contains no purchase prompts.

The [roadmap](ROADMAP.md) records completed source work, unverified work, and future systems. [Design decisions](docs/DESIGN.md) capture the direction from the pasted conversation.
