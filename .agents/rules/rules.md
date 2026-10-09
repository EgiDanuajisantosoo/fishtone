---
trigger: always_on
---

# FISH!TUNE — Project Rules

**Project:** Roblox multiplayer Fishing × Rhythm × Collection  
**Repository:** https://github.com/EgiDanuajisantosoo/fishtone  
**Master Notion:** https://app.notion.com/p/3e94606b1b7e815f8418fd53e70fdff9?pvs=204  
**Task Cards:** https://app.notion.com/p/f1048dc4c1cc467eabd73912687491b2

## 1. Source of truth

1. Approved Master Notion and Technical Design decisions define intended behavior.
2. Task Cards define scope, owner, dependencies, acceptance criteria, and status.
3. GitHub `main` shows actual implementation; it does not automatically mean production-ready.
4. This file consolidates current rules. If it conflicts with a newer approved decision, record the conflict and update the documents—never silently choose.

Do not silently change gameplay, RemoteEvent contracts, DataStore schemas, rarity weights, XP formulas, economy values, or progression. New ideas go to backlog. Material changes require a Change Request documenting reason, impact, affected tasks/files, migration, and approval.

## 2. Core game rule

**Skill increases probability; RNG determines the outcome.**

FISH!TUNE combines fishing, rhythm mini-games, and collection. The instrument/rod determines the rhythm mechanic. The island does not.

- Piano Rod → Piano rhythm / precision
- Guitar Rod → Guitar rhythm / pattern or sequence
- Drum Rod → Drum rhythm / reaction and timing

Islands/fishing zones determine fish pool, environment, and approved difficulty modifiers. They may change tempo, timing windows, or pattern length, but must not replace the selected rhythm mechanic.

Canonical routing:

`EquippedInstrument/Rod → validated rhythmType → RhythmController → Piano/Guitar/Drum module`

## 3. Fishing lifecycle

Target server state machine:

`IDLE → CASTING → WAITING → BITE → CHALLENGE → RESULT → REWARD → IDLE`

Each attempt must have a unique `sessionId`, owner, validated instrument/rhythm type, start time, status, challenge configuration/seed, and submission state. A player must not have multiple active sessions unless an approved design changes this. Reject invalid transitions, expired sessions, foreign session IDs, and duplicate submissions. Cancel/timeout must safely clear session state. Player sessions must be isolated in multiplayer.

## 4. Blind fishing

- Hide fish identity and rarity during waiting and rhythm challenge.
- Never send `rolledRarity`, fish identity, or final reward data to the client before the approved reveal moment.
- Keep the hidden roll in server-only session data.
- Reveal name, rarity, stars, weight, visuals, and reward only after successful catch.
- Failure reveals no hidden reward.

**Known gap:** current `FishingServer.server.lua` sends `rolledRarity` in `SessionStarted`; remove this disclosure.

## 5. Client/server authority

**Client requests; server decides.**

Client handles input, UI, animation, VFX, SFX, and presentation. Server owns session state, instrument validation, performance validation, Luck, rarity roll, pity, fish selection, rewards, inventory, coins, XP, progression, persistence, and anti-exploit checks.

Never trust client-supplied score, accuracy, combo, rarity, fish name, weight, coins, XP, or reward as authoritative. Validate session owner/state, instrument, payload types/ranges, timing/input counts, submission uniqueness, item ownership, and remote rate. Client UI locks are not security boundaries. Do not put secrets or authoritative mutable player data in `ReplicatedStorage`.

## 6. Rhythm module contract

Each rhythm module has separate gameplay/input but uses a shared session lifecycle and result contract. Conceptual operations:

- `Start(sessionData)`
- `HandleInput(inputData)`
- `Update(deltaTime)` when needed
- `Finish()`
- `Cancel(reason)`

Exact interfaces must be agreed and documented before integration. Rhythm modules must not create their own reward, inventory, pity, or loot pipeline. Client metrics may support responsiveness, but the server must validate or independently derive the authoritative performance result.

### Piano
Current files: `PianoTilesGame.lua`, `PianoTilesUI.lua`, `PianoTilesConfig.lua`. The current config uses **A/W/S/D**, while README says **D/F/J/K**. Resolve the discrepancy explicitly and update both code/docs. Test keyboard, mouse/click, and mobile touch.

### Guitar
Pattern/sequence mechanic, separate module, selected only by `rhythmType = "Guitar"`, shared session/performance/reward pipeline.

### Drum
Reaction/timing-window mechanic, separate module, selected only by `rhythmType = "Drum"`, shared session/performance/reward pipeline.

## 7. Rarity and progression

Canonical rarity tiers: `COMMON → RARE → SUPER RARE → LEGENDARY → MYTHIC → SPECIAL`. Do not restore older tier names without an approved Change Request.

- Level progression is uncapped; do not add `MaxLevel` without approval.
- Level is progression, not direct Luck or an unapproved rarity gate.
- Prefer `TotalXP` as persistence source of truth and derive level/progress from the approved curve.
- Avoid inefficient linear loops for level derivation at high levels.
- Luck is bounded by approved configuration; current prototype uses 0–100.
- Cast quality and validated performance affect Luck only according to the approved formula.
- Pity is server-authoritative and updated consistently with the catch result.
- Treat rarity weights, pity thresholds, XP, economy values, and multipliers as configuration—not arbitrary constants.

**Known gap:** current server adds `floor(level / 5)` to base Luck, contradicting the approved progression rule. Remove/migrate via a tracked task.

## 8. Inventory, economy, persistence

Server owns inventory, fish metadata, coins, XP, level, pity, and statistics. Selling must verify the fish is owned, valid, and not already sold. Prevent duplicate rewards and transactions. Production persistence must handle load/save, disconnect, errors, and schema versioning. Do not mark persistence complete based on in-memory tables or leaderstats alone.

**Known gap:** current player data is in-memory; production persistence is not shown in the inspected prototype.

## 9. Target architecture

```text
src/
├── ReplicatedStorage/
│   └── Shared/
│       ├── Config/
│       ├── Definitions/
│       └── Types/
├── ServerScriptService/
│   ├── Services/
│   │   ├── FishingService
│   │   ├── RhythmService
│   │   ├── LootService
│   │   ├── InventoryService
│   │   ├── EconomyService
│   │   ├── PlayerDataService
│   │   └── AntiExploitService
│   └── ServerBootstrap.server.lua
└── StarterPlayer/
    └── StarterPlayerScripts/
        └── Controllers/
            ├── FishingController.client.lua
            ├── RhythmController.client.lua
            └── Rhythm/
                ├── Piano/
                ├── Guitar/
                └── Drum/
```

- `FishingService`: sessions and fishing state transitions.
- `RhythmService`: rhythm session binding and server performance validation.
- `LootService`: rarity, pity, fish selection, reward result.
- `InventoryService`: ownership and inventory operations.
- `EconomyService`: validated selling/currency transactions.
- `PlayerDataService`: persistence and schema migration.
- `AntiExploitService`: shared validation/rate-limit helpers.

The repository is currently a compact prototype. Migrate incrementally, preserve working gameplay, and keep Rojo mappings aligned. Shared modules contain safe definitions/config only; server-authoritative logic remains server-side. Avoid circular dependencies and duplicate systems.

## 10. Code and documentation rules

- Use consistent names: `instrumentId`, `rhythmType`, `sessionId`.
- Keep each module focused; avoid oversized monolithic scripts.
- Document remote names, argument types, response payloads, and failure behavior.
- Comments explain non-obvious decisions/invariants, not every line.
- Keep README and `default.project.json` aligned with actual source.
- Do not commit credentials, private player data, generated junk, or unrelated files.
- Keep branches focused; do not combine unrelated refactors.
- List all affected Task IDs in PRs.

## 11. Task status

- `Not started`: implementation has not begun.
- `In progress`: implementation is active.
- `Done`: acceptance criteria implemented, integrated, tested, and reviewed.

Do not mark a task Done merely because a prototype approximation exists or a file was created. Record evidence: files/modules, tests, commit/PR, and known limitations. Status reflects repository reality, not the target architecture.

## 12. Definition of Done

- [ ] Acceptance criteria satisfied.
- [ ] Integrated with agreed architecture/contracts.
- [ ] No blocking errors introduced.
- [ ] Server authority and exploit cases reviewed.
- [ ] Normal, failure, invalid-input, and duplicate-submission paths tested.
- [ ] PC controls and mobile behavior tested where relevant.
- [ ] Multiplayer/player isolation tested where relevant.
- [ ] Persistence/migration tested where relevant.
- [ ] Existing gameplay regression-tested.
- [ ] Reviewed by the other developer.
- [ ] README/Notion/contracts updated.
- [ ] Task status and commit/PR evidence updated.

## 13. Required QA

- Functional: cast, bite, rhythm, catch/fail, reveal, inventory, sell, XP, level.
- Security: fake score/session, duplicate submission, remote spam, locked instrument, nonexistent/double-sold fish, client-chosen reward.
- Multiplayer: concurrent fishing, session isolation, disconnect/cancel, no cross-player state.
- Data: load/save, disconnect, schema migration, failed-save handling.
- Platform: PC, mobile touch, UI scaling/readability.
- Performance: FPS, memory, network traffic, server script time.
- Balance: catch duration, rarity distribution, coins/minute, XP/minute, average performance, pity behavior, retry rate.

## 14. Current known gaps

From the inspected repository:
1. Client calls Piano directly; no instrument-based `RhythmController` yet.
2. Guitar and Drum modules are not present.
3. Target `Shared/Services/Controllers` layout is not implemented.
4. `SessionStarted` exposes rolled rarity before challenge completion.
5. Level-derived Luck conflicts with the progression rule.
6. Production persistence is not shown.
7. Rhythm metrics submitted by client need authoritative validation.
8. README key mapping conflicts with Piano config.

These are tracked migration/hardening items. Preserve the working prototype while fixing them through explicit tasks.
