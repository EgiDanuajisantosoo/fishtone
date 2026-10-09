---
description: # FISH!TUNE — Development Workflow
---

# FISH!TUNE — Development Workflow

**Repository:** https://github.com/EgiDanuajisantosoo/fishtone  
**Master Notion:** https://app.notion.com/p/3e94606b1b7e815f8418fd53e70fdff9?pvs=204  
**Development Roadmap:** https://app.notion.com/p/3e94606b1b7e8120a0fcdca28b28a79c?pvs=204  
**Task Cards:** https://app.notion.com/p/f1048dc4c1cc467eabd73912687491b2  
**Technical Design:** https://app.notion.com/p/3e94606b1b7e8143af5bca21b39755d0?pvs=204  
**QA:** https://app.notion.com/p/3e94606b1b7e81f09801d89402aad548?pvs=204  
**Deployment:** https://app.notion.com/p/3e94606b1b7e81e59e56c3fd5bb3a86d?pvs=204

## 1. Workflow overview

```text
Notion backlog
  → clarify requirement/dependencies
  → assign owner, priority, acceptance criteria
  → create task branch
  → implement smallest complete change
  → test normal + failure + exploit paths
  → review by other developer
  → update docs and Task Card
  → merge
  → regression/multiplayer/mobile smoke tests
  → release only when release gates pass
```

Do not start work while expected behavior or a shared contract is ambiguous.

## 2. Team ownership

### Developer 1 — Systems / Backend
- Architecture and module boundaries.
- Server fishing sessions/state machine.
- Rhythm session contract and server-side performance validation.
- Loot, rarity, Luck, pity, fish selection.
- Enforce cast-quality rule: PERFECT/GREAT/GOOD set mini-game starting progress to 35%/20%/10%; they must never change Luck or rarity weights.
- Inventory, economy, player data, persistence.
- Instrument ownership/equip validation and anti-exploit.
- Server-side QA.

### Developer 2 — Client / Experience
- Fishing/rhythm client controllers.
- Piano/Guitar/Drum UI and input.
- Animation, VFX, SFX, reveal presentation.
- Mobile interaction/UI scaling.
- World, fishing zones, environment, NPC/tutorial as assigned.
- Client-side QA and usability.

### Shared
- Game design and balance decisions.
- Remote/session contract agreement.
- Full-loop playtesting, PR review, regression fixes, release notes.
- Notion and README synchronization.

Each task must have one accountable owner. `Shared` requires the team to agree who drives implementation; it must not mean unclear ownership.

## 3. Notion task card before coding

Every task should include:
- Task ID/title, objective, player-facing result.
- Owner, priority, phase, status.
- Dependencies, scope, non-goals.
- Inputs and expected outputs.
- Acceptance criteria and edge cases.
- Affected files/modules and remote/data contracts.
- Testing checklist, branch name, PR/commit links.

If criteria are vague, clarify the card first.

Priority definitions:
- `P0 Critical`: blocks core loop, architecture, security, or release.
- `P1 Important`: required for a planned milestone.
- `P2 Enhancement`: improves quality but does not block the milestone.
- `P3 Future`: backlog/post-launch.

Status definitions:
- `Not started`: no active implementation.
- `In progress`: implementation underway.
- `Done`: acceptance criteria passed and change is integrated/reviewed.

Never mark Done because a similar prototype behavior exists. Record blockers and next action in the card.

## 4. Recommended current implementation sequence

Follow the Notion dependency graph. The sequence below reflects gaps found in the inspected repository and should be reconciled if approved Notion dependencies change.

1. **Audit and stabilize prototype**
   - Confirm existing Piano loop still works.
   - Resolve keyboard mismatch: README says D/F/J/K; `PianoTilesConfig.lua` currently uses A/W/S/D.
   - Stop exposing rarity before challenge completion.
   - Remove Level-derived Luck according to approved progression rules.
   - Remove cast-based Luck bonuses (+35/+15/+0); casting quality only sets mini-game starting progress (PERFECT 35%, GREAT 20%, GOOD 10%).
2. **FISH-002 — Folder Architecture**
   - Migrate toward `Shared`, `Remotes`, `Services`, `Controllers`.
   - Keep the working loop alive during migration.
3. **FISH-029 — Instrument Definition & Equip**
   - Define canonical `instrumentId` and `rhythmType`.
   - Validate equipped/unlocked instrument on server.
4. **Rhythm router and Piano migration**
   - Add `RhythmController`.
   - Move Piano into its own module without rebuilding unnecessarily.
5. **Server rhythm contract**
   - Define session-bound inputs/results and authoritative performance validation.
6. **FISH-027 Guitar and FISH-028 Drum**
   - Separate mechanics; reuse session/performance/reward pipeline.
7. **Persistence, inventory, economy, progression hardening**
   - Follow task dependencies and verify production readiness.
8. **QA, balance simulation, release**
   - Complete the release gates before publishing.

## 5. Git workflow

Use one focused branch per task. Prefer the branch name already recorded in Notion.

Examples:
- `feature/FISH-002-folder-architecture`
- `feature/FISH-029-instrument-definition-equip`
- `feature/FISH-027-guitar-rhythm`
- `feature/FISH-028-drum-rhythm`
- `fix/FISH-XXX-short-description`
- `docs/short-description`

Commit message examples:
- `feat(FISH-029): add instrument definitions`
- `fix(FISH-XXX): prevent duplicate catch rewards`
- `refactor(FISH-002): split client controllers`
- `test(FISH-XXX): validate invalid rhythm submissions`
- `docs: align piano controls with config`

Commits should be focused. Avoid mixing unrelated features, formatting, and refactors.

## 6. Pull request requirements

Each PR should include:
- Task IDs and Notion links.
- Problem and expected behavior.
- Implementation summary and changed modules.
- Remote/data/schema contract changes.
- Test steps and actual results.
- Screenshots/video for UI changes when useful.
- Known limitations and follow-up tasks.

Do not claim a test passed unless it was actually run. If Roblox Studio testing was not performed, state that clearly.

## 7. Contract-first collaboration

Before changing a system another developer depends on, document:
- Remote name, request argument types, response payload.
- Session lifecycle and invalid-state behavior.
- Who validates and owns authoritative state.
- Cancel/timeout/failure behavior.
- Any DataStore schema or economy formula changes.

Canonical instrument routing:

`EquippedInstrument/Rod → validated rhythmType → RhythmController → Piano/Guitar/Drum`

The island/zone affects fish pool and approved difficulty modifiers, not rhythm type. Instrument modules must not implement their own reward pipeline.

## UI/GUI change policy — preserve Roblox Studio work

**Do not replace or recreate existing UI/GUI built in Roblox Studio.** This is a hard constraint for AI agents and developers, including when a script opens, enables, populates, or updates that UI. Existing Studio-authored hierarchy, names, layout, styling, assets, and responsive behavior must be preserved unless the user explicitly requests a specific UI change.

Before editing a UI-related script:
1. Locate the GUI in Roblox Studio Explorer and inspect the relevant object hierarchy and references.
2. Identify whether the GUI already exists in Studio or is created by a script. Reuse the existing GUI; do not create a duplicate.
3. Change only the behavior needed for the task. Prefer updating event connections, state, data binding, or visibility logic over changing the GUI structure.
4. Never replace a Studio-authored GUI with an `Instance.new()`-generated GUI as a shortcut. Do not rename, delete, reparent, or restyle existing objects without explicit scope approval.
5. If required UI details cannot be inspected, stop before making structural/visual assumptions. Request an Explorer hierarchy, screenshot, or relevant script, or proceed only with a minimal non-structural logic change.
6. Test that the existing GUI opens, references resolve, controls work, and no duplicate UI is created. Check PC and mobile layouts where relevant. Record whether Studio testing was actually performed.

A task asking to fix fishing, rhythm, input, rewards, or another gameplay system does **not** grant permission to redesign the UI. UI reconstruction requires explicit approval.

## 8. Local test workflow

Before committing:
1. Pull latest `main`.
2. Confirm Rojo mapping matches file layout.
3. Run in Roblox Studio using the team's agreed Rojo workflow.
4. Test the task's acceptance criteria.
5. Test failure, cancellation, invalid input, and duplicate action as relevant.
6. Test PC controls and mobile touch/UI where relevant.
7. Check Output for errors/warnings.
8. Regression-test existing fishing.
9. Update README/Notion if behavior/contracts changed.

Use a multi-player Studio test for server state and multiplayer changes where practical.

## 9. Required scenarios

### Fishing and routing
- Valid instrument starts session; invalid/locked instrument is rejected.
- Session follows legal state transitions.
- Piano Rod routes to Piano; Guitar Rod to Guitar; Drum Rod to Drum.
- Changing island does not change rhythm type.
- Zone modifiers affect only approved difficulty/fish-pool fields.
- Unsupported rhythm type fails safely.
- Cancel/timeout/rod loss follows the agreed rule.

### Rewards/security
- Client cannot choose rarity, fish identity, or reward.
- Fake score/session and malformed payloads are rejected/bounded.
- Duplicate submission grants at most one reward.
- Selling verifies ownership and prevents double sell.
- Blind reveal does not expose rarity before the approved reveal moment.

### Multiplayer/data/platform
- Concurrent players have isolated sessions.
- Disconnect and save errors are handled.
- Persistence/schema migration tested when relevant.
- PC keyboard/mouse and mobile touch are usable.
- UI scales/readable on mobile.
- Check FPS, memory, network traffic, and server script time when relevant.

## 10. Review checklist

Reviewer verifies:
- Acceptance criteria and `rules.md` are satisfied.
- Logic lives in the correct layer.
- Session ownership and server authority are preserved.
- Invalid input and duplicate operations are handled.
- Remote/schema/economy changes are documented and approved.
- Tests are real and results accurately reported.
- README, Notion, and Rojo mapping match the implementation.
- The other developer can maintain the change without guessing.

Security, persistence, rewards, and shared-contract changes require explicit review by the systems/backend owner.

## 11. Notion synchronization after changes

1. Add branch and PR/commit to Task Card.
2. Record files/modules changed.
3. Update acceptance checklist based on evidence.
4. Record tests and results.
5. Document limitations/follow-ups.
6. Update status only when its definition is met.
7. Update Technical Design/Master Plan when approved architecture/design changes.
8. Keep status synchronized with code, not plans.

Current caution: inspected `main` still uses direct Piano integration and a compact layout. Instrument routing, separate Guitar/Drum modules, and the target `Shared/Services/Controllers` architecture are not complete until verified in code and tests.

## 12. Definition of Done and release gate

A task is Done only after acceptance criteria, integration, review, relevant functional/failure tests, security checks, platform checks, and documentation synchronization are complete.

Do not release while any core gate fails:
- Server-authoritative rewards.
- Unique sessions and player isolation.
- Blind rarity reveal.
- Reliable persistence.
- Validated inventory/economy.
- Multiplayer and mobile smoke tests.
- Approved balance configuration.

## 13. Communication rules

- Raise ambiguity before coding.
- Report blockers with exact file, observed behavior, expected result, and reproduction steps.
- Do not silently change another developer's contract.
- Prefer safe migration over rewriting working mechanics.
- Keep PRs reviewable.
- If Notion and code disagree, record both states and create a reconciliation task.
- “Code exists” ≠ “tested”; “tested locally” ≠ automatically “production-ready”.
