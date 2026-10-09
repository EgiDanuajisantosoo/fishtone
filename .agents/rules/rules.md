---
trigger: always_on
---

# FISH!TUNE — Project Rules
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
- Cast quality does **not** affect Luck or rarity weights.
- Cast quality only sets the rhythm mini-game starting progress: PERFECT = 35%, GREAT = 20%, GOOD = 10%.
- Validated rhythm performance may affect Luck according to the approved formula; cast quality and rhythm performance are separate inputs.
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

## UI/GUI preservation — mandatory rule

**AI agents must preserve UI/GUI authored or arranged in Roblox Studio. Do not replace, recreate, redesign, delete, rename, reparent, or restyle existing UI just because a script change would be easier.** This applies to `ScreenGui`, `SurfaceGui`, `BillboardGui`, `Frame`, buttons, labels, layout objects, constraints, UI assets, and any GUI hierarchy created manually in Studio or opened/managed by scripts.

Before changing UI-related code:
1. Inspect the existing GUI hierarchy in Studio/Explorer and the scripts that reference it, where access is available.
2. Reuse existing instances and their names, hierarchy, properties, assets, layout, and visual design. Make the smallest code change needed.
3. If a script opens, enables, populates, or updates a Studio-authored GUI, modify only the necessary behavior; do not generate a replacement GUI in code.
4. Do not use `Instance.new()` to create a duplicate/replacement of an existing GUI or its controls. Creating a new UI instance is allowed only when the task explicitly requires a new element and confirms no existing instance should be reused.
5. Do not delete, rename, reparent, or alter visual properties of existing UI objects unless the task explicitly asks for that exact change. Preserve responsive behavior, anchors, constraints, scaling, and PC/mobile interactions.
6. If the hierarchy or intended UI behavior cannot be inspected, do not guess and rebuild it. Ask for the relevant Explorer hierarchy, screenshots, or script, or make a narrowly scoped change that does not alter the UI structure.
7. After changes, verify that the existing GUI still opens and behaves correctly, with no duplicate GUI instances, missing references, or visual regressions. Test in Roblox Studio when possible and state clearly if that test was not performed.

**Default policy: logic-only changes must remain logic-only.** UI redesign/reconstruction requires explicit user approval; it is not implied by a request to fix a script or gameplay mechanic.
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
## 13. Current known gaps
From the inspected repository:
1. Client calls Piano directly; no instrument-based `RhythmController` yet.
2. Guitar and Drum modules are not present.
3. Target `Shared/Services/Controllers` layout is not implemented.
4. `SessionStarted` exposes rolled rarity before challenge completion.
5. Level-derived Luck conflicts with the progression rule.
6. The old cast-based Luck bonus (+35/+15/+0) is obsolete. Casting must only set starting mini-game progress (35%/20%/10% for PERFECT/GREAT/GOOD).
6. Production persistence is not shown.
7. Rhythm metrics submitted by client need authoritative validation.