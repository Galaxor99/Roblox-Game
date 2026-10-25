# Anime Nexus development roadmap

## Product direction

Hybrid card collector with stat-based automated challenges, exploration and cosmetic favourite displays. No direct action combat or playable character transformations. Expand a coherent, tested milestone before adding another system. Continue in this existing checkout; no separate worktree is needed. Do not generate Studio builds unless the user changes that preference.

Status means **implemented in source**, not Roblox playtested or released. Nothing is published by this repository.

| Milestone | Status | Acceptance and remaining work |
| --- | --- | --- |
| Import supplied foundation | Implemented | Summons, existing collection, potions, luck, expeditions and favourites preserved in source. |
| Configurable roster expansion | Implemented | 204 definitions, 30 franchise groups, stable IDs, identity overrides, summon eligibility metadata and collection descriptions. No custom franchise art/models. |
| Summons and variants | Implemented | Six rarities, pity, normalized odds, 5 variant tiers; variant boundaries covered exhaustively. Reveal UI needs Studio review. |
| Collection interface | Implemented; engine review pending | Search name/universe/faction/trait, owned filter, rarity filter, 12 cards/page, close/reopen, small-screen layouts. |
| Team building | Implemented and rule-tested | Manual five unique allies or auto-best team, four factions, 5%/15% synergy. |
| Card advancement | Implemented and rule-tested | 100 levels, duplicate upgrades/recycling, variant preservation, last-copy protection, mastery ranks and deliberate awakening. Individual card serials remain future work. |
| World progression | Implemented; engine review pending | Sanctuary, Neon Citadel, Astral Expanse; raised floors, themed geometry, realm guides, gates, nine memory sites and three story chapters. Final art and terrain remain future work. |
| Stat-based challenges | Implemented and rule-tested | Three routes per offline expedition, useful traits, speed shortening, three bosses favoring defense/speed/energy, hidden results until claim. Random encounter tables remain future work. |
| Quests and collection goals | Implemented and rule-tested | Three guaranteed-card quests, seven achievements, four collection sets with luck bonuses. |
| Daily rewards | Implemented and rule-tested | Once per UTC day, 7-day reward cycle, resets after missed day. |
| Cosmetic showcase | Implemented; engine review pending | Up to three followers, three progression-gated formations, frame-rate independent following. Models remain placeholders. |
| Weekly events | Implemented and rule-tested | Three rotating themes, UTC schedule, earned points and once-per-week rewards. Server telemetry and live editing remain future work. |
| Cooperative challenge | Implemented and adapter-tested | A shared daily boss uses durable per-player contributions across servers and atomic, single-claim profile rewards. Real multi-server and outage testing remains. |
| Rankings | Implemented and adapter-tested | Current-server ranks plus global OrderedDataStore top tens with write limits, read cache and outage fallback. Live DataStore checks and seasons remain future work. |
| Data safety | Implemented and adapter-tested | Lease ownership, autosave, failed-load protection, receipt retries, duplicate reward prevention. Live DataStore fault tests pending. |

## Next milestone: prove the playable loop

- [ ] Execute the Studio checklist in `docs/VALIDATION.md`, including two-client testing and mobile emulation.
- [ ] Playtest an entire first-hour progression path; record coins/minute, unlock times, duplicate rates and failed-boss recovery.
- [ ] Tune economy from measured results; current costs/weights are initial balance.
- [ ] Replace themed primitive geometry with authored terrain, card portraits, readable visual silhouettes, effects and sound.
- [x] Wire portrait IDs and optional follower models into renderers with procedural fallbacks.
- [ ] Verify authored asset loading and placement in Studio.
- [ ] Test low-end-device frame time with maximum followers and a large populated collection.

## Next systems, each requiring implementation and validation

1. **Collection depth:** individual card serials, provenance, mastery objectives and artwork for deliberate awakenings. Mastery ranks and awakening recipes exist.
2. **World quests:** authored dialogue, NPCs and branching narrative. Current chapters use exploration memories, expedition milestones and guaranteed cards.
3. **Expedition depth:** random encounter tables, branching results and longer late-game missions. Three route choices and trait effects exist.
4. **Trading:** two-party offers, inventory locks, explicit confirmations, cooldowns, disconnect recovery, durable transaction journal and replay protection. Do not ship trades by independently saving two inventories: that can duplicate or lose cards.
5. **Cooperative events:** expand the shared daily boss with phases, multiple difficulty tiers, social objectives and live server metrics. The first shared challenge and single-claim rewards exist.
6. **Rankings:** live verification, seasons, historical results and pagination. The global top ten and current-server scores exist.
7. **Guilds:** membership/invite permissions, persistent contributions, group challenges and recoverable administrative changes.
8. **Live operations:** rotating banners, server-controlled reward tables, economy metrics and rollback procedures. Weekly event rotation exists.

## Release quality gates

- [ ] Engine-tested UI, input, respawns, portals, followers and multiplayer behavior.
- [ ] Data migration rehearsal and real failure/disconnect tests; lease expiry and receipt ambiguity exercise.
- [ ] Global data recovery plan before trading or monetization.
- [ ] Reviewed roster/assets for intended release; Public mode alone does not clear a place.
- [ ] Accessibility review: text size, contrast, reduced motion, controller navigation and non-color rarity cues.
- [ ] Performance measurements and asset budget on low-end devices.
- [ ] Paid systems remain off until enabled deliberately and tested with applicable Roblox policies and receipts.

Do not mark roadmap items done because a configuration entry or placeholder exists. Advanced trading, guilds, authored art, multi-server testing and global rankings validation remain outstanding.
