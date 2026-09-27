# Garden Definition of Done

> Status: **Draft v0.1**
>
> Purpose: This document defines the objective quality gates that must be satisfied before work in Garden may be called complete. It applies to human contributors and AI coding agents.
>
> This document must be read together with `PROJECT_RULES.md`, `GAME_DESIGN.md`, and `ARCHITECTURE.md`. If instructions conflict, follow the precedence defined in `PROJECT_RULES.md`.

---

## 1. Why This Document Exists

Garden is being developed with heavy AI assistance. That makes it especially important that "done" is based on evidence rather than confidence, generated code volume, or an agent saying that a task is finished.

A task is complete only when:

1. the requested behavior exists;
2. the implementation respects the approved architecture and design rules;
3. relevant automated and manual verification has actually been performed;
4. no known blocking defect is being hidden;
5. the resulting repository state is understandable and reviewable.

A green editor, a successful happy-path run, or a plausible implementation is not sufficient by itself.

---

## 2. Decision Status Legend

This document uses the same decision discipline as the other project documents:

- **LOCKED** — required unless the project owner explicitly changes it.
- **PROVISIONAL** — current preferred gate, subject to refinement when the tooling or project matures.
- **TBD** — intentionally undecided; do not silently invent a permanent rule.

---

## 3. Levels of Done

**Status: LOCKED**

"Done" is evaluated at four levels:

1. **Task Done** — one scoped implementation task is complete.
2. **Milestone Done** — a coherent set of tasks forms a usable, integrated capability.
3. **MVP Done** — the first complete playable product loop exists and is stable enough for meaningful playtesting.
4. **Release Candidate Done** — a build is suitable for release evaluation on real Android devices.

Passing a lower level does not automatically satisfy the higher levels.

---

# Part I — Task Definition of Done

## 4. Task Scope Is Satisfied

**Status: LOCKED**

A task is not done until every explicit acceptance criterion in the task has been satisfied.

The implementation must:

- solve the requested problem, not a nearby approximation;
- remain within the stated scope;
- avoid unrelated refactors unless they are strictly necessary;
- avoid adding speculative features;
- preserve existing behavior outside the intended change unless the task explicitly changes it;
- report any intentionally deferred item clearly.

If an acceptance criterion cannot be satisfied, the task must be reported as incomplete or blocked rather than declared complete.

---

## 5. Repository State Was Inspected Before Work

**Status: LOCKED**

Before implementation, the contributor/agent must identify at least:

- current branch;
- baseline commit when available;
- working-tree cleanliness or existing unrelated changes;
- relevant project documents;
- existing code/tests in the affected area.

Unrelated uncommitted work must not be overwritten, deleted, reformatted, or silently incorporated.

---

## 6. Project Rules Were Followed

**Status: LOCKED**

The task must not violate `PROJECT_RULES.md`, `GAME_DESIGN.md`, or `ARCHITECTURE.md`.

For code changes, review at minimum whether the task introduced any of the following without approval:

- new game engine or engine upgrade;
- C#/.NET usage;
- backend/network service;
- analytics or advertising;
- cloud save or account system;
- new third-party dependency;
- new mutable global singleton;
- architecture bypass;
- direct system-clock access inside domain/application logic;
- uncontrolled randomness inside deterministic game logic;
- incompatible save-format change;
- out-of-scope gameplay redesign.

Any intentional architectural exception must be explicitly approved and documented.

---

## 7. Code Quality Gate

**Status: LOCKED**

Changed production code must be understandable and maintainable.

Before a task is done, confirm that the change does not introduce avoidable:

- giant scripts or manager classes;
- duplicated game rules;
- deeply nested control flow where simpler logic is reasonable;
- unexplained magic values;
- dead code;
- commented-out production code;
- placeholder implementations presented as finished behavior;
- silent exception/error swallowing;
- broad catch-all recovery that hides defects;
- unnecessary inheritance or abstraction layers;
- unnecessary per-frame work;
- per-entity timers/loops where timestamp calculation is the intended architecture;
- scene/UI code becoming the authoritative source for core game state.

Core domain/application GDScript should use static typing where the data contract is known, as required by `ARCHITECTURE.md`.

---

## 8. Data and Stable-ID Gate

**Status: LOCKED**

For content-driven systems such as plants, visitors, decorations, and events:

- stable IDs must be used consistently;
- IDs must not depend on translated display names;
- ordinary content variation should be data-driven where practical;
- adding content must not require expanding giant `if/elif` chains unless the behavior is genuinely unique;
- invalid references between definitions should fail visibly in development.

Renaming a player-visible label must not silently break saved state.

---

## 9. Time-System Gate

**Status: LOCKED when the task touches time**

A task involving growth, cooldowns, offline progression, day/night, weather timing, visitor timing, or lifecycle timing is not done until relevant edge cases are verified.

At minimum, verify as applicable:

- normal elapsed time;
- exact stage/timing boundaries;
- zero elapsed time;
- app background then resume;
- save then process restart;
- long absence;
- negative/rolled-back wall-clock time does not corrupt state;
- elapsed progress is not applied twice after resume/reload;
- logic uses the approved clock abstraction rather than scattered direct wall-clock calls.

Tests should use a controllable/fake clock where practical.

---

## 10. Randomness Gate

**Status: LOCKED when the task touches randomness**

Random systems must be testable deterministically.

Before completion, confirm:

- eligibility logic is tested independently from chance where practical;
- tests do not pass or fail based on luck;
- random selection uses the approved abstraction/seedable source;
- impossible/ineligible visitors or events cannot be selected;
- empty candidate sets are handled safely;
- weights/probabilities do not crash or produce undefined behavior when malformed.

---

## 11. Save/Load Gate

**Status: LOCKED when persistent state is affected**

Any task that changes persistent player state, save structure, migration logic, or offline progression must verify persistence explicitly.

Relevant checks include:

- save -> load round trip preserves authoritative state;
- save schema version is present once persistence exists;
- missing optional data is handled intentionally;
- malformed required data is rejected or recovered safely;
- unknown content IDs do not crash loading;
- interrupted/failed save does not casually destroy the last known-good save where the architecture supports safe replacement;
- older save schema migrates correctly once multiple versions exist;
- current-schema saves remain readable after unrelated changes;
- save semantics were not changed silently.

A task must never "solve" migration by deleting player progress unless explicitly approved by the owner.

---

## 12. Economy and State-Transition Gate

**Status: LOCKED when applicable**

For coins, purchases, harvests, unlocks, journal discoveries, or similar state changes, verify as applicable:

- insufficient funds cannot produce a successful purchase;
- currency cannot become negative through normal operations unless explicitly designed;
- one user action cannot accidentally grant or deduct rewards twice;
- repeated signals/callbacks do not duplicate state transitions;
- save/reload preserves the result;
- UI display reflects authoritative state rather than maintaining a competing counter.

---

## 13. Android Lifecycle Gate

**Status: LOCKED when applicable**

Features involving persistence, time, audio, touch, rendering, or scene state must account for Android lifecycle behavior.

Relevant task-level verification should consider:

- foreground -> background -> foreground;
- pause/resume without duplicate processing;
- process termination followed by restart;
- touch interaction rather than mouse-only behavior;
- multiple phone aspect ratios;
- safe-area handling where UI approaches screen edges;
- no runaway work while backgrounded;
- no obvious battery-hostile polling design.

"Works in the Godot editor" is not sufficient evidence for Android-specific behavior.

---

## 14. UI/UX Gate

**Status: LOCKED when the task changes UI**

UI work must be checked against the game’s calm, touch-first design.

Verify as applicable:

- controls are usable by touch;
- important controls are not unreasonably small;
- labels are readable at target phone sizes;
- layout does not overlap or clip on representative tall and less-tall portrait ratios;
- UI does not obscure the garden unnecessarily;
- normal back/cancel behavior is understandable;
- the player can recover from an accidental open/edit state;
- loading/disabled states do not invite duplicate actions;
- the interaction does not introduce pressure/FOMO contrary to the design documents.

Placeholder visuals are acceptable only when the task explicitly allows them and they are clearly identified as placeholders.

---

## 15. Automated Test Gate

**Status: LOCKED**

New or changed non-trivial game logic should have appropriate automated tests when the project test harness supports it.

At minimum:

- changed logic has targeted coverage for its important behavior;
- discovered bugs receive a regression test when reasonably possible;
- valid existing tests are not deleted, skipped, disabled, or weakened merely to make the implementation pass;
- expected values are not changed to match an implementation bug;
- deterministic systems are tested deterministically.

If a relevant behavior cannot reasonably be automated, the completion report must state what was manually verified instead.

---

## 16. Static/Parse/Headless Verification Gate

**Status: PROVISIONAL until the exact scripts are established**

For every code task, run the strongest available low-cost verification supported by the repository/toolchain.

This may include:

- Godot project parse/load check;
- headless project startup;
- script syntax validation;
- static checks/linting if configured;
- automated test suite;
- import/resource validation;
- `git diff --check` or equivalent whitespace/error check.

The exact canonical commands should be added to this document once the initial project/tooling task establishes them.

No agent may claim a check passed if it was not actually run.

---

## 17. Build Gate

**Status: LOCKED when build tooling exists**

A task that changes build configuration, Android integration, resources required by the runtime, export configuration, or platform behavior must produce a successful relevant build before completion when the environment permits it.

For ordinary domain-only tasks, a full Android build may be deferred to milestone verification if the task specification allows it and faster checks provide sufficient confidence.

If a required build cannot run because of environment/tooling limitations, report:

1. the exact build/check that was not run;
2. the reason;
3. the remaining risk.

Do not substitute "should compile" for a real build result.

---

## 18. Manual Verification Gate

**Status: LOCKED when behavior is visual, tactile, lifecycle-sensitive, or otherwise poorly represented by automated tests**

Manual verification should be narrow and repeatable.

The completion report should describe what was actually exercised, for example:

- plant was placed and advanced through stages;
- journal entry appeared after first discovery;
- touch drag/reposition behaved correctly;
- app was backgrounded and resumed;
- portrait layout was checked at specified viewport sizes;
- Android debug build was launched on device/emulator.

"Tested manually" without saying what was tested is insufficient evidence.

---

## 19. Diff Review Gate

**Status: LOCKED**

Before completion, inspect the actual final diff.

Confirm:

- every changed file is related to the task;
- no secret, generated build artifact, cache, editor-local file, or signing material was added;
- no accidental mass reformat occurred;
- no unrelated file was modified;
- no debug code/log spam remains unless intentionally retained;
- no test was weakened without justified explanation;
- no project document was silently contradicted.

An AI agent must review its own diff before declaring the task complete.

---

## 20. Documentation Gate

**Status: LOCKED when applicable**

Update documentation when a task intentionally changes a documented contract or project-wide decision.

Examples include:

- architectural boundary changes;
- save schema changes;
- new stable-ID conventions;
- new required development commands;
- new dependency;
- engine/export requirements;
- newly locked game-design behavior.

Do not update architecture/design documents merely to make an accidental implementation conform on paper.

Implementation should follow approved architecture; architecture changes require deliberate approval.

---

## 21. Git Gate

**Status: LOCKED**

Before a task is reported complete:

- final branch must be identified;
- final working-tree state must be reported;
- unrelated local work must remain intact;
- destructive history rewriting must not have occurred unless explicitly authorized;
- commit/push/PR actions must only occur if explicitly requested.

If a commit is requested, it should be focused and use a clear message.

If no commit was requested, the agent must not create one automatically.

---

## 22. Required Task Completion Report

**Status: LOCKED**

Every non-trivial coding task completion report must contain evidence, not just a conclusion.

At minimum report:

1. **Outcome** — what was implemented.
2. **Baseline** — starting branch/commit when available.
3. **Files changed** — with brief reasons.
4. **Behavioral verification** — what scenario(s) were checked.
5. **Automated checks** — exact checks/tests/builds actually run and whether they passed.
6. **Unverified items** — anything relevant that could not be checked.
7. **Known limitations/risks** — if any.
8. **Final Git state** — branch and working-tree status.
9. **Commit/push information** — only if those actions were authorized and performed.

Do not report "all tests passed" without identifying which test command/suite was run.

---

# Part II — Milestone Definition of Done

## 23. Milestone Integration Gate

**Status: LOCKED**

A milestone is done only when its tasks work together as one coherent capability.

In addition to all included tasks being individually done:

- milestone acceptance criteria are satisfied end to end;
- integration between newly introduced systems is verified;
- no known Severity 1 or Severity 2 defects remain open within milestone scope;
- representative happy paths and important failure/edge paths work;
- save/load remains compatible with the milestone’s intended state model;
- broader regression checks have been run;
- Android build is verified when tooling permits;
- project documents reflect any approved decisions made during the milestone.

A set of individually completed tasks is not sufficient if the integrated feature is broken.

---

## 24. Architecture Audit at Milestone Boundaries

**Status: LOCKED**

At meaningful milestone boundaries, review the codebase for drift introduced across multiple tasks.

Check for:

- duplicated domain rules;
- overgrown scripts/classes;
- accidental global state;
- too many autoloads/singletons;
- presentation code owning game rules;
- direct clock/random calls bypassing abstractions;
- save schema leakage into presentation;
- hard-coded content that should be data-driven;
- repeated resource loads or expensive per-frame work;
- stale/dead code;
- dependency creep;
- inconsistencies in stable IDs/naming.

The purpose is not to refactor for aesthetics. Fix only meaningful drift that increases future risk or violates the architecture.

---

## 25. Milestone Regression Gate

**Status: LOCKED**

Run the full available automated suite appropriate for the milestone, not only the most recently changed tests.

Where relevant, include regression coverage for:

- project startup;
- save/load round trip;
- plant growth/offline progression;
- visitor eligibility;
- event selection;
- economy transitions;
- journal discoveries;
- placement state;
- pause/resume lifecycle;
- Android export/build.

As the project matures, this section should reference canonical scripts/commands rather than ad-hoc command lists.

---

## 26. Milestone Device Verification

**Status: PROVISIONAL initially; expected to become LOCKED once the Android pipeline is established**

At major gameplay milestones, verify a debug build on at least one real Android device when practical.

Check:

- install/startup;
- touch controls;
- portrait layout;
- background/resume;
- persistence across restart;
- representative gameplay loop;
- obvious performance/stutter issues;
- obvious battery/thermal problems during a short session;
- audio interruption/resume if audio exists.

Emulator-only verification may supplement but should not permanently replace real-device checks for release-oriented milestones.

---

# Part III — MVP Definition of Done

## 27. MVP Scope Gate

**Status: LOCKED**

The MVP is done only when the approved MVP in `GAME_DESIGN.md` exists as a complete playable loop rather than disconnected prototypes.

The expected MVP scope includes the currently approved target of approximately:

- one primary garden scene;
- five plant types;
- five visitor types;
- eight placeable/decorative objects;
- three weather states;
- day/night presentation/logic appropriate to the design;
- coins/economy;
- planting and growth;
- offline progression;
- reactive visitor/event rules;
- journal/collection;
- save/load;
- Android playability.

Exact content may change through an explicit design decision, but an AI agent may not silently redefine the MVP.

---

## 28. MVP Player-Loop Gate

**Status: LOCKED**

A new player must be able to experience the primary loop from a clean save:

```text
start -> understand garden -> plant/place -> wait/progress -> observe change
-> collect/earn -> create new condition -> encounter/discover -> journal records it
-> save/leave -> return -> state/progression is preserved
```

The loop should work without developer intervention, console commands, manual save editing, or debug-only shortcuts.

---

## 29. MVP Reliability Gate

**Status: LOCKED**

Before the MVP is called done:

- no known data-loss bug remains in ordinary use;
- no reproducible crash remains in the primary loop;
- no blocker prevents starting from a clean install;
- save survives normal close/restart;
- offline progression behaves consistently;
- background/resume does not duplicate progression/rewards;
- ordinary malformed/legacy state paths implemented so far fail safely;
- normal play cannot easily create negative/invalid economy state;
- common touch flows do not trap the player in an unrecoverable UI state.

---

## 30. MVP Experience Gate

**Status: PROVISIONAL; evaluated through playtesting**

The MVP must demonstrate the intended experience, not only technical completeness.

Playtesting should be able to answer positively, at least at a basic level:

- Is the garden pleasant to look at for a short session?
- Is it clear what the player can do without excessive explanation?
- Does returning after time away produce something meaningful to observe?
- Does placement/content create visible consequences?
- Is discovery interesting enough to create curiosity?
- Does the game avoid feeling like repetitive reward collection only?
- Is the game calm rather than pressuring?

If the systems technically work but the central "living garden" fantasy is absent, the MVP is not product-complete.

---

# Part IV — Release Candidate Definition of Done

## 31. Release Candidate Build Gate

**Status: PROVISIONAL until distribution configuration is finalized**

A release candidate must be produced from a clean, identified commit and must pass the canonical release/export process once established.

Expected checks include:

- Godot project opens/loads cleanly with the locked supported engine version;
- release export succeeds;
- Android package installs successfully on supported device(s);
- clean-install first launch succeeds;
- upgrade-install path is tested once public/pre-release saves exist;
- app identity/version metadata is correct;
- no debug-only screens/commands are unintentionally exposed;
- no secrets/signing material are committed to the repository;
- required Godot attribution/license obligations are satisfied for distribution.

---

## 32. Release Candidate Save Compatibility Gate

**Status: LOCKED once any external tester/player save exists**

Once builds have been shared outside development, save compatibility becomes a release-critical contract.

A release candidate must test:

- current clean save;
- previous supported schema/version;
- migration path(s);
- corrupted or incomplete save behavior as supported by the architecture;
- restart after migration;
- repeat load after migration does not reapply migration incorrectly;
- content ID changes do not silently erase unrelated progress.

---

## 33. Release Candidate Device Matrix

**Status: TBD**

The final supported Android version/device matrix has not yet been locked.

Before public release, this document must be updated with a concrete minimum verification matrix covering representative:

- Android OS versions;
- low/mid-range hardware targets;
- portrait aspect ratios;
- memory constraints;
- GPU/Compatibility-renderer support.

Agents must not invent the final support matrix before the project owner approves it.

---

## 34. Performance Gate

**Status: PROVISIONAL initially**

Garden is a small 2D game and should behave accordingly.

A release candidate must have no known avoidable architecture causing:

- one timer/thread/coroutine per plant/visitor without need;
- expensive full-state scanning every frame;
- repeated disk writes every frame;
- repeated resource loading in hot paths;
- uncontrolled object/node accumulation;
- obvious memory growth during normal repeated sessions;
- persistent background processing that wastes battery.

Concrete frame-time, memory, and battery targets remain **TBD** until representative art/content and target devices exist.

---

## 35. Accessibility and Usability Gate

**Status: PROVISIONAL**

Before public release, verify at minimum:

- readable text at supported phone sizes;
- touch targets appropriate for phone use;
- important state is not communicated by color alone where avoidable;
- audio can be reduced/disabled;
- interaction does not require rapid reflexes inconsistent with the design;
- important text is not clipped on supported aspect ratios;
- the player can understand save/progress behavior without technical knowledge.

More specific accessibility requirements may be locked later.

---

# Part V — Defect Severity and Stop Rules

## 36. Defect Severity

**Status: LOCKED**

Use the following severity language in reviews and completion reports.

### Severity 1 — Critical

Examples:

- data loss in ordinary use;
- consistent crash/blocker preventing play;
- secret/credential exposure;
- destructive save migration;
- release build cannot start/install;
- major architecture violation that makes state unreliable.

**A task/milestone/release candidate cannot be done with an unresolved Severity 1 defect in scope.**

### Severity 2 — High

Examples:

- major feature does not work as specified;
- duplicate rewards/progression;
- save/load produces incorrect state;
- offline progression materially wrong;
- common Android lifecycle path breaks gameplay;
- common UI flow becomes unusable;
- deterministic rule allows impossible events/content.

**A milestone/release candidate cannot be done with an unresolved Severity 2 defect in scope unless the owner explicitly re-scopes the affected feature.**

### Severity 3 — Medium

Examples:

- non-critical edge case;
- noticeable but recoverable UX problem;
- maintainability issue with concrete future risk;
- minor content/rule inconsistency.

May be deferred if documented and explicitly accepted.

### Severity 4 — Low

Examples:

- cosmetic polish;
- wording inconsistency;
- minor visual alignment issue;
- optional cleanup with no meaningful correctness risk.

May be deferred normally.

---

## 37. Mandatory Stop Conditions

**Status: LOCKED**

Do not claim completion when any of the following is true:

- acceptance criteria are materially unmet;
- a relevant test/build failed and was not resolved;
- an expected check was skipped without disclosure;
- the implementation depends on an unapproved major architectural decision;
- unrelated user work was overwritten;
- a secret was exposed/committed;
- save compatibility was knowingly broken without approval;
- valid tests were weakened to obtain a green result;
- a high-risk feature cannot be meaningfully verified and the task requires that verification;
- the implementation contains a known Severity 1 defect;
- the implementation/report materially misrepresents what was actually tested.

---

# Part VI — AI-Specific Completion Rules

## 38. AI Agents Must Not Self-Certify by Assertion

**Status: LOCKED**

Statements such as the following are not evidence:

- "This should work."
- "The implementation is production-ready."
- "Everything looks correct."
- "There should be no regressions."
- "All edge cases are handled."

Each claim must be supported by inspected code, tests, builds, reproducible manual checks, or clearly identified reasoning where direct verification is impossible.

---

## 39. AI Agents Must Distinguish Facts from Assumptions

**Status: LOCKED**

Completion reports must clearly separate:

- **Verified** — directly checked in the environment;
- **Implemented but not verified** — code exists but the relevant runtime check could not be performed;
- **Not implemented / deferred** — intentionally outside scope or blocked;
- **Assumption** — inferred behavior that still needs confirmation.

Do not present assumptions as test results.

---

## 40. Reviewer Independence

**Status: LOCKED**

When a second agent/model reviews implementation from another agent:

1. review first;
2. identify concrete defects/risks before editing;
3. classify severity;
4. cite relevant file/logic;
5. verify claims where possible;
6. only then implement fixes if the task authorizes it.

A reviewer should not erase evidence of the original defect by immediately rewriting everything.

---

# Part VII — Canonical Checklists

## 41. Minimum Checklist for a Normal Code Task

**Status: LOCKED**

A normal code task should not be called done until the applicable items below are true:

- [ ] Read relevant project documents.
- [ ] Inspected current branch/worktree/baseline.
- [ ] Acceptance criteria satisfied.
- [ ] Scope stayed narrow.
- [ ] Architecture respected.
- [ ] Core logic is deterministic/testable where relevant.
- [ ] Save/time/random/lifecycle edge cases handled where relevant.
- [ ] Relevant automated tests added/updated.
- [ ] Targeted tests/checks pass.
- [ ] Broader regression checks run when appropriate.
- [ ] Build/export check run when required and available.
- [ ] Visual/touch/manual verification performed when relevant.
- [ ] Final diff inspected.
- [ ] No secrets/generated junk/unrelated changes added.
- [ ] Documentation updated if a documented contract changed.
- [ ] Unverified items and risks disclosed.
- [ ] Final Git status reported.

---

## 42. Minimum Checklist for a Milestone

**Status: LOCKED**

- [ ] All milestone acceptance criteria satisfied.
- [ ] Included tasks individually meet Task DoD.
- [ ] Integrated behavior verified end to end.
- [ ] Full available regression suite passes.
- [ ] Save/load remains valid.
- [ ] Architecture drift review completed.
- [ ] No unresolved Severity 1/2 defect remains in scope.
- [ ] Android build verified when tooling permits.
- [ ] Real-device check performed when required by the milestone stage.
- [ ] Project documents reflect approved milestone decisions.

---

## 43. Minimum Checklist for MVP

**Status: LOCKED**

- [ ] Approved MVP content/systems are present.
- [ ] Primary gameplay loop works from clean save.
- [ ] Offline progression works.
- [ ] Save/restart works.
- [ ] Reactive garden rules produce observable consequences.
- [ ] Journal/discovery loop works.
- [ ] Economy supports the intended loop without invalid states.
- [ ] Android build is playable.
- [ ] No ordinary-use data-loss/crash blocker remains.
- [ ] Playtesting demonstrates the intended calm, living-garden experience at a basic level.

---

## 44. Canonical Commands

**Status: PARTIALLY ESTABLISHED — updated by Task 0.4B (Milestone 0)**

The commands below have been verified on Godot 4.7.2.stable.official.ed1daf0bf.
All commands are run from the repository root (`/Applications/garden` or equivalent).

### Godot version check

```sh
godot --version
# Expected output: 4.7.2.stable.official.ed1daf0bf
```

### Project / import validation

```sh
godot --headless --import
# Exit code 0 = project imported cleanly.
# Benign errors about editor_settings-4.7.tres in sandbox/CI are expected and ignorable.
```

### Automated test suite

```sh
godot --headless --path . --script res://tests/run_tests.gd
# Exit code 0 = all tests passed.
# Exit code 1 = one or more tests failed.
# Human-readable PASS/FAIL summary is printed to stdout.
```

### Headless application boot smoke check

The main scene is a persistent application scene and does not self-terminate.
For headless smoke checks, use the import validation above, which verifies that
all scripts parse and the project loads cleanly.

### Git diff validation

```sh
# Check for whitespace errors in unstaged changes:
git diff --check

# Check for whitespace errors in staged changes before commit:
git diff --cached --check

# Inspect full staged diff before commit:
git diff --cached
```

### Android debug export

**TBD** — Android export presets do not yet exist in this repository.
This section will be updated when the Android toolchain task is completed.

### Android release export

**TBD** — Requires signed release keystore and export preset. Not yet established.

### Lint / static checks

**TBD** — No separate static-analysis tool is currently configured.
The Godot headless import (`godot --headless --import`) acts as the primary
parse/type-check step available at this stage.

---

> **Note:** Only document commands that have been actually verified in this repository.
> Do not add commands that were not run successfully.


---

## 45. Definition of Done Changes

**Status: LOCKED**

This document is a quality contract.

Do not weaken it merely because a task is difficult to complete.

A change to this document should happen because:

- the project’s tooling matured;
- a gate proved objectively inappropriate;
- a missing quality requirement was discovered;
- the owner deliberately changed project risk tolerance or release strategy.

When this document changes, the commit/report should explain the reason.

---

## Short Rule for Every Agent

**Do not declare work done because code exists. Declare it done only when the requested behavior is implemented, the architecture is respected, relevant risks are tested, the final diff is clean, and the evidence is reported truthfully.**
