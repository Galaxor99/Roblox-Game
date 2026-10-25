# Anime Nexus development roadmap

## Product direction

Hybrid card collector with stat-based automated challenges, exploration and cosmetic favourite displays. No direct action combat or playable character transformations. Expand a coherent, tested milestone before adding another system. Continue in this existing checkout; no separate worktree is needed. Do not generate Studio builds unless the user changes that preference.

Status means **implemented in source**, not Roblox playtested or released. Nothing is published by this repository.

| Milestone | Status | Acceptance and remaining work |
| --- | --- | --- |
| Import supplied foundation | Implemented | Summons, existing collection, potions, luck, expeditions and favourites preserved in source. |
| Configurable roster expansion | Implemented | 204 definitions, 30 franchise groups, stable IDs, identity overrides, summon eligibility metadata. No custom franchise art/models. |
| Summons and variants | Implemented | Six rarities, pity, normalized odds, 5 variant tiers; variant boundaries covered exhaustively. Reveal UI needs Studio review. |
| Collection interface | Implemented; engine review pending | Search name/universe/faction/trait, owned filter, rarity filter, 12 cards/page, close/reopen, small-screen layouts. |
| Team building | Implemented and rule-tested | Manual five unique allies or auto-best team, four factions, 5%/15% synergy. |
| Card advancement | Implemented and rule-tested | 100 levels, duplicate upgrades/recycling, variant preservation, last-copy protection. |
| World progression | Implemented; engine review pending | Sanctuary, Neon Citadel, Astral Expanse; unlock milestones/costs, travel gates, distinct placeholder environments. |
| Stat-based challenges | Implemented and rule-tested | Offline expeditions, speed shortening, three bosses favoring defense/speed/energy, hidden results until claim. |
| Quests and collection goals | Implemented and rule-tested | Three guaranteed-card quests, seven achievements, four collection sets with luck bonuses. |
| Daily rewards | Implemented and rule-tested | Once per UTC day, 7-day reward cycle, resets after missed day. |
| Cosmetic showcase | Implemented; engine review pending | Up to three followers, three progression-gated formations, frame-rate independent following. Models remain placeholders. |
| Rankings | Current-server rankings implemented | Global/cross-server ordered leaderboards remain future work. |
| Data safety | Implemented and adapter-tested | Lease ownership, autosave, failed-load protection, receipt retries, duplicate reward prevention. Live DataStore fault tests pending. |

## Next milestone: prove the playable loop

- [ ] Execute the Studio checklist in `docs/VALIDATION.md`, including two-client testing and mobile emulation.
- [ ] Playtest an entire first-hour progression path; record coins/minute, unlock times, duplicate rates and failed-boss recovery.
- [ ] Tune economy from measured results; current costs/weights are initial balance.
- [ ] Add authored realm geometry, card portraits, readable visual silhouettes, effects and sound with configurable asset IDs.
- [ ] Wire portrait/model asset metadata into renderers with load-failure fallbacks.
- [ ] Test low-end-device frame time with maximum followers and a large populated collection.

## Next systems, each requiring implementation and validation

1. **Collection depth:** persistent per-card mastery objectives, deliberate awakening recipes, collection serials and provenance; distinct from randomly rolled Awakened variants.
2. **World quests:** multi-step narrative chains, exploration discoveries, interactable NPCs and deterministic rare-card unlock routes. Current quests are milestone claims.
3. **Expedition depth:** encounter tables, trait effects, branching routes, speed/defense/energy objectives and longer late-game missions. Current trait labels are descriptive.
4. **Trading:** two-party offers, inventory locks, explicit confirmations, cooldowns, disconnect recovery, durable transaction journal and replay protection. Do not ship trades by independently saving two inventories: that can duplicate or lose cards.
5. **Cooperative events:** shared boss contribution accounting, synchronized windows, participation gates and idempotent reward claims. Current bosses are individual timed stat challenges.
6. **Global rankings:** ordered leaderboards with bounded writes, stable pagination, rate limits and season resets. Current rankings show active players only.
7. **Guilds:** membership/invite permissions, persistent contributions, group challenges and recoverable administrative changes.
8. **Live operations:** rotating banners, event schedules, server-controlled reward tables, economy metrics and rollback procedures.

## Release quality gates

- [ ] Engine-tested UI, input, respawns, portals, followers and multiplayer behavior.
- [ ] Data migration rehearsal and real failure/disconnect tests; lease expiry and receipt ambiguity exercise.
- [ ] Global data recovery plan before trading or monetization.
- [ ] Reviewed roster/assets for intended release; Public mode alone does not clear a place.
- [ ] Accessibility review: text size, contrast, reduced motion, controller navigation and non-color rarity cues.
- [ ] Performance measurements and asset budget on low-end devices.
- [ ] Paid systems remain off until enabled deliberately and tested with applicable Roblox policies and receipts.

Do not mark roadmap items done because a configuration entry or placeholder exists. Advanced trading, guilds, co-op events, authored art and global leaderboards are not implemented in this milestone.
