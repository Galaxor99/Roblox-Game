# Validation record

## Executed in cloud

`npm ci --ignore-scripts --cache /workspace/.npm-cache` and `npm test`.

The test runner compiles all nine source files in a Luau WebAssembly runtime. It executes 54 tests covering:

- Roster IDs, stats, faction/rarity validity, summon pools and restricted summon eligibility.
- Team ownership, slot limits, synergy, levels, duplicate consumption and protected variants.
- Exhaustive variant roll buckets (10,000 points), migration and non-stacking power bonuses.
- Daily day/streak boundaries, single-claim achievements, guaranteed quests and collection-set rewards.
- World gates, boss timestamps, hidden outcomes and duplicate-claim rejection.
- Expedition route timing and rewards, mastery, awakening, memory discovery and chapter order.
- Weekly UTC rotation, single-claim event rewards, global ranking cache and failure fallback.
- Durable shared contributions across server adapters, stale-cache refresh, storage failure behavior and an atomic reward claim.
- Session exclusivity/expiry/release, failed loads, save outages and receipt idempotency.
- The actual `NexusServer` entry point with deterministic Roblox service adapters: profile load, summons including zero-weight boundaries, throttling, bad RPC arguments, upgrades, world travel, expeditions, boss results and persistence.
- The unpublished Studio startup path: DataStore access fails at service initialization, the server still creates its remotes, and the player receives an unsaved test profile.

The adapters do not represent a Roblox engine or real cloud storage. No visual, network-latency, live purchase, live DataStore or performance claims are made.

## Required Roblox Studio checks — not executed here

1. Open `build/AnimeNexus_Test.rbxlx`, or install the nine scripts under the exact paths in README. Run only one server script and one client script.
2. Press Play: verify Overview loads and the temporary/saved state label is accurate. Check Output for errors.
3. Claim daily twice; open all three pack types; verify coin costs, displayed card odds, pity counters and reveal dismissal. Simulate the guarantee threshold in an isolated test profile.
4. Search by universe and name, cycle rarity and owned filters, and page through the index. Test narrow phone, landscape, tablet and desktop sizes with keyboard and touch emulation.
5. Favorite/unfavorite three cards; reject a fourth. Close the menu, walk and respawn; check followers and all three formations. Ensure they do not collide with the avatar.
6. Select a team, compare power with auto selection, test two/three matching factions, upgrade/recycle duplicates, and verify the final copy and rare variants are protected.
7. Complete all three Scouting routes, leave before another finishes, rejoin and claim exactly once. Check mastery on the original team. Unlock each world; verify locked portal rejection, realm guide dialogue, memory prompts, chapters and travel in both directions. Confirm the original spawn does not place a player inside the new plaza floor.
8. Start each boss challenge, reject early claims, verify outcome and rewards, then reject duplicate claims. Check guaranteed-card quests and collection-set luck changes.
9. With two local clients, verify independent inventories and followers, server rankings, and no cross-player reward mutation. Check the weekly event and claim limits.
10. In a published test experience, start servers in parallel. Verify that a contribution from each server appears in the same daily total, that a repeat contribution does not add power, and that a next-day reward claims once despite disconnects and retries.
11. In a separate published test experience, enable API access and verify migration, autosave, normal exit, server shutdown, fast rejoin, active-session rejection and recovery after the 180-second lease expiry.
12. Check global OrderedDataStore rankings in a published test place, including a storage outage and fallback. Simulate save failures and ambiguous receipt commits before enabling any products. IDs remain zero and client purchase buttons are absent.
13. Measure performance at the intended player count and collection size. Review the first-hour economy and replace placeholder art before considering release.
14. Open each pack and verify the reel decelerates to the exact server-awarded card, including rare variants. Tap Skip and confirm it cannot award a second card.
15. After importing portrait atlases and configuring their Roblox image asset IDs, inspect original and fiction cards, the pack reel, and the reveal. Confirm the atlas cells line up with the intended names on desktop and mobile.
16. If cards still show initials, check Studio Output for `Portrait asset unavailable` lines. Each line identifies an image ID that Roblox could not fetch for this experience; verify approval, ownership, and the number used in `NexusPortraitAssets.Value`.

The `build/AnimeNexus_Test.rbxlx` export is a Studio test place generated from the unchanged original and current source. The cloud checks validate its XML and embedded sources; actual Studio loading and playtesting remain for the Studio checklist above.
