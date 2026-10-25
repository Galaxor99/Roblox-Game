# Anime Nexus — Shattered Realities

A hybrid card-collection RPG based on the supplied `AnimeNexus_UI_Fixed_Studio_Build.rbxlx`. Characters do not fight directly: players summon cards, compose stat-based teams, progress through automated challenges, and display up to three cosmetic followers.

This repository contains the development source. **No new Roblox Studio build has been generated**, as requested. This is an expanded development milestone, not a finished or published game.

## Current milestone

- 204 configurable cards: 36 originals and 168 fictional identities across 30 franchises.
- Three earnable-currency packs, six rarities, per-pack Legendary+ pity, exact per-card odds, and summon reveal panels.
- Normal, Shiny, Corrupted, Awakened and Celestial variants; higher variants increase effective card power. Variant and rarity are independent.
- Collection search, rarity filters, owned-only view, pagination, and a mobile-oriented scrolling interface.
- Five-card manual or automatic teams, four factions, and two/three-card synergy bonuses.
- Levels 1–100; upgrades spend coins, essence and a normal duplicate. Recycling and upgrades protect the final copy and never automatically consume rare variants.
- Three unlockable realms with generated placeholder environments and gated travel portals.
- Offline expeditions with speed-based duration reduction; three automated bosses with stat affinities.
- Guaranteed-card quests, achievements, collection sets, daily streak rewards and collection luck bonuses.
- Three cosmetic followers; Line, Arc and Orbit formations; current-server Cards/Power/Bosses rankings.
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
| StarterPlayer / StarterPlayerScripts | LocalScript `NexusClient` | `src/NexusClient.client.luau` |

`default.project.json` supplies the equivalent Rojo source mapping for developers who already use Rojo. Rojo synchronization has not been exercised here. No Studio file is built by `npm test`.

The server creates the realms and network objects at runtime. The uploaded place's static baseplate may remain; remove that only if it interferes with your authored terrain. There is no external asset dependency for the placeholder world or followers.

Persistence uses the existing `AnimeNexusHybrid_v2` DataStore and `user_<UserId>` keys. Old collections migrate in place, including normal variants for existing copies. Shut down servers running the old script before deploying this version: old code does not respect the new lease. Test migration in a separate test experience before touching production data. Failed Studio loads remain unsaved; the HUD explicitly says so.

## Configure the roster

`NexusRoster` defines the franchise identities; `NexusConfig.IdentityOverrides` can replace names, rarity, model and portrait IDs, and rights metadata without changing persistent card IDs. Franchise cards currently use placeholder visuals and balanced generated stats, not bespoke abilities. Model/portrait IDs are metadata for future asset integration; the current renderer uses procedural models.

`RosterMode = "Development"` makes all identities summonable. `"Public"` excludes unverified identities from new summons while retaining existing stored collections. This is a summon filter, not a complete public-release asset or UI audit. No franchise rights are asserted by this source. Monetization IDs remain zero, and the UI contains no purchase prompts.

The [roadmap](ROADMAP.md) records completed source work, unverified work, and future systems. [Design decisions](docs/DESIGN.md) capture the direction from the pasted conversation.
