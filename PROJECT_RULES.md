# Garden Project Rules

> Status: **Draft v0.1**
>
> Purpose: This file defines the non-negotiable working rules for humans and AI coding agents contributing to this repository. It is intentionally stricter than a normal README so that implementation quality does not depend on which model or agent happens to perform a task.

## 1. Project Intent

Garden is a small, cozy Android game built around a living garden that gradually responds to what the player plants, places, and discovers.

The project should remain:

- calm rather than stressful;
- easy to understand and pleasant to revisit for short sessions;
- small in scope but rich in interaction;
- maintainable enough to grow over time without repeated rewrites;
- offline-capable by default;
- suitable for real Android devices, not only desktop/editor previews.

The working title, engine, final art direction, monetization model, and release plan are **not locked by this document**. They must be decided explicitly elsewhere before an agent treats them as requirements.

## 2. Authority and Document Precedence

When instructions conflict, use this order:

1. Explicit instruction from the project owner in the current task.
2. `PROJECT_RULES.md`.
3. `ARCHITECTURE.md` once it exists.
4. `GAME_DESIGN.md` once it exists.
5. `DEFINITION_OF_DONE.md` once it exists.
6. The current task specification / issue.
7. Existing implementation conventions that do not conflict with the documents above.

A task specification may be more specific than these documents, but it must not silently override them.

If a real conflict remains, **stop and report it instead of guessing**.

## 3. Human Control

The project owner makes product and architectural decisions.

An AI agent may propose alternatives, but it must not independently make major decisions such as:

- choosing or replacing the game engine;
- introducing a backend, account system, cloud save, analytics, ads, or monetization SDK;
- changing the save-data contract;
- replacing the architecture;
- introducing a major dependency;
- changing supported platforms;
- redesigning the core gameplay loop;
- changing Git strategy or repository structure in a disruptive way.

When a task requires one of these decisions and no approved decision exists, the agent must report the decision point before implementation.

## 4. Core Game Design Guardrails

Unless the owner explicitly changes them, preserve these design principles:

1. **No pressure-first design.** The game should not depend on punishment, stress, or aggressive timers.
2. **No inactivity punishment.** Plants or progress must not be destroyed merely because the player did not open the game.
3. **No mandatory streaks or FOMO mechanics.** Missing a day should not meaningfully harm the player.
4. **The garden should feel alive.** Plants, visitors, weather, ambience, and small events should make the world feel active even when the player is not constantly tapping.
5. **Placement should matter where appropriate.** Plants and decorations may influence visitors and events instead of being purely cosmetic.
6. **Curiosity is more important than raw reward.** Discovery should be a major reason to reopen the game.
7. **Prefer depth in a small space over uncontrolled feature growth.** Do not turn the project into a large farming simulator without an explicit design decision.

## 5. Scope Discipline

Implement only what the current task requires.

Do not add "helpful extras" unless they are necessary for correctness or explicitly approved.

Examples of out-of-scope changes include:

- unrelated refactors;
- speculative abstractions for features that do not exist yet;
- additional screens or gameplay systems;
- new services or SDKs;
- broad visual redesigns;
- renaming unrelated files or symbols;
- formatting the whole repository when only one area is being changed.

If an adjacent problem is discovered, report it separately instead of silently expanding the task.

## 6. Architecture Rules

Until `ARCHITECTURE.md` defines more detail, follow these baseline rules.

### 6.1 Separate game rules from presentation

Core game rules should not depend directly on UI widgets, scenes, Android lifecycle callbacks, or rendering code when they can reasonably be expressed as domain logic.

Important logic such as plant growth, visitor eligibility, offline progression, currency changes, save validation, and event conditions should be testable without manually operating the UI.

### 6.2 Time must be controllable

Do not scatter direct wall-clock calls throughout game logic.

Use a central time abstraction or equivalent design so that:

- growth can be tested deterministically;
- offline progression can be tested;
- background/resume behavior can be verified;
- clock rollback or invalid elapsed time can be handled safely.

Never allow negative elapsed time to corrupt progress.

### 6.3 Randomness must be testable

Random visitor/event selection must be controllable or seedable in tests.

Do not make correctness tests depend on luck.

### 6.4 Prefer data-driven content

Plants, visitors, decorations, event requirements, timings, and similar content should be represented as data where practical rather than large chains of hard-coded conditionals.

Adding a new plant or visitor should normally require content/data changes plus targeted behavior code only when the new content truly behaves differently.

### 6.5 Avoid hidden global state

Do not introduce mutable global state or singleton-heavy designs merely for convenience.

State ownership and lifecycle should be clear.

### 6.6 No per-entity busy loops

Do not create continuously running timers, threads, coroutines, or per-frame polling for every plant, visitor, or decoration when elapsed-time calculation or centralized scheduling can solve the problem more safely.

The game must remain suitable for battery-constrained mobile devices.

## 7. Save Data Rules

Save/load is a critical system and must be treated as production code.

- Save data must have an explicit schema/version once persistent saves are introduced.
- Save operations should avoid leaving a partially written/corrupted primary save when practical.
- Load code must validate data instead of assuming every field is valid.
- Missing, malformed, or older data must fail safely.
- Offline progression must be computed from authoritative saved state, not duplicated counters that can drift.
- A future schema change must not silently invalidate existing saves.
- Never reset player progress as a convenient way to fix a migration problem unless the owner explicitly approves it.

Do not change save semantics in an unrelated task.

## 8. Android and Lifecycle Rules

The game is intended for Android, so "works in the editor" is not sufficient evidence of correctness.

Features involving time, persistence, audio, touch, pause/resume, or rendering must consider:

- app foreground -> background -> foreground;
- process termination and restart;
- different phone aspect ratios;
- touch input rather than mouse-only assumptions;
- interrupted saves or lifecycle transitions;
- mobile performance and battery use.

When the toolchain permits it, Android builds should be part of milestone verification.

## 9. Dependency Rules

Do not add a dependency solely because it makes a small task easier.

Before adding a third-party dependency, confirm that it is:

- actually necessary;
- actively maintained enough for the project;
- compatible with the project license and target platform;
- materially better than a small local implementation;
- acceptable in size and runtime cost for Android.

Every new dependency must be reported in the task summary with the reason it was added.

Do not replace an existing dependency or upgrade major versions unless the task requires it.

## 10. Security and Privacy

Never commit:

- passwords;
- API keys;
- signing keys;
- service-account files;
- private tokens;
- production secrets;
- personal user data.

Do not introduce network permissions, telemetry, analytics, advertising, external tracking, or remote services without explicit approval.

If a secret is discovered in the repository, stop and report it rather than copying or propagating it.

## 11. Code Quality Rules

Code should be understandable by the next human or agent without reconstructing the author's reasoning.

Prefer:

- clear names over clever abbreviations;
- small focused functions/classes/modules;
- explicit state transitions;
- straightforward control flow;
- reusable domain rules instead of duplicated logic;
- comments that explain **why**, not comments that restate obvious code;
- constants/configuration instead of unexplained magic numbers.

Avoid:

- giant manager classes;
- duplicated business logic;
- unnecessary inheritance hierarchies;
- dead code;
- commented-out code;
- placeholder production implementations;
- silent exception swallowing;
- catch-all fallbacks that hide defects;
- speculative abstractions with no current use.

A solution is not considered high quality merely because it is shorter.

## 12. Error Handling

Failures should be visible and diagnosable during development.

Do not:

- suppress an error to make a build appear green;
- convert a real failure into an empty success state;
- catch broad exceptions without a clear recovery strategy;
- ignore failed save/load operations;
- silently substitute fabricated data for missing required data.

When safe recovery is appropriate for the player, preserve enough diagnostics for developers to understand what happened.

## 13. Testing Rules

New behavior should be accompanied by the most appropriate automated test when the project has a test framework capable of testing it.

Core systems should eventually have deterministic tests for at least:

- plant growth across time boundaries;
- offline progression;
- foreground/background/resume calculations;
- clock rollback / invalid elapsed time;
- visitor/event eligibility rules;
- deterministic random selection where applicable;
- currency/state transitions;
- save -> load round trips;
- invalid or incomplete save data;
- save schema migration once multiple schema versions exist.

A bug fix should include a regression test when reasonably possible.

### Tests must not be weakened to make implementation pass

An agent must not:

- delete a failing valid test;
- skip/disable a failing valid test;
- loosen assertions merely to accept incorrect behavior;
- alter expected values to match a bug;
- reduce test coverage as a substitute for fixing code.

If a test itself is wrong, explain why before changing it.

## 14. Build and Verification Rules

Before declaring a task complete, run all checks that are relevant and available in the environment.

Typical checks may include:

- formatter / format verification;
- static analysis or linting;
- unit tests;
- integration tests;
- project build;
- Android build when applicable;
- targeted manual verification for visual/touch behavior.

Do not claim that a command, test suite, build, or device check passed unless it was actually run successfully.

If a check cannot be run, clearly state:

1. what was not run;
2. why it could not be run;
3. what remains unverified.

## 15. Git Rules

Keep changes easy to inspect and easy to revert.

- Start every task by identifying the current branch and working-tree state.
- Do not overwrite unrelated uncommitted work.
- Keep the diff limited to the task.
- Do not rewrite history unless explicitly instructed.
- Do not force-push unless explicitly instructed.
- Do not commit generated secrets, build outputs, caches, IDE-local state, or machine-specific files.
- Do not commit, push, create a PR, merge, tag, or release unless the current task explicitly authorizes the relevant action.
- If commits are requested, prefer focused commits with clear messages.

Never use destructive Git commands as a shortcut for restoring a clean state when unrelated work may exist.

## 16. AI Agent Working Protocol

Every coding agent should follow this sequence.

### Step 1 — Inspect

Before editing:

- read this file;
- read the architecture/design/definition-of-done documents relevant to the task;
- inspect the existing implementation instead of assuming structure;
- identify the current branch and baseline commit;
- identify existing tests and conventions in the affected area.

### Step 2 — Plan

State the implementation plan internally or in the task report before making broad changes.

For a non-trivial task, identify:

- files/systems likely to change;
- important edge cases;
- tests needed;
- anything that might conflict with architecture or project rules.

### Step 3 — Implement narrowly

Make the smallest coherent change that fully satisfies the accepted task.

Do not redesign unrelated systems while implementing a feature.

### Step 4 — Verify

Run targeted tests first, then broader checks appropriate to the change.

Inspect the actual diff before declaring completion.

### Step 5 — Report evidence

The completion report must distinguish verified facts from assumptions.

At minimum report:

- task outcome;
- starting branch / baseline commit when available;
- files changed and why;
- tests/checks/builds actually run and their results;
- notable design decisions made within approved scope;
- known limitations or remaining risks;
- final Git status;
- commit SHA / pushed branch only if those actions were explicitly requested and actually performed.

Do not use vague statements such as "everything should work" when evidence can be provided.

## 17. Reviewer Protocol

When one AI agent reviews another agent's work, the reviewer should initially act as a reviewer, not as an implementer.

Review for:

- correctness;
- rule violations;
- regressions;
- architecture drift;
- save compatibility;
- lifecycle problems;
- mobile performance problems;
- missing edge cases;
- unnecessary dependencies;
- weak or misleading tests;
- out-of-scope changes.

The reviewer should cite concrete files/logic and severity instead of giving a generic approval.

Do not immediately rewrite the implementation before first identifying the defects.

## 18. No Fake Completion

A task is **not complete** merely because:

- code was generated;
- the editor shows no red errors;
- a happy path worked once;
- the agent says it is done;
- one narrow test passed;
- desktop behavior appears correct for an Android-specific feature.

Completion requires meeting the task acceptance criteria and the applicable verification rules.

## 19. Stop Conditions

Stop implementation and report the issue when:

- required product behavior is ambiguous in a way that materially changes implementation;
- the task contradicts a higher-priority project rule;
- a required architectural decision has not been approved;
- unrelated uncommitted work would be overwritten;
- a secret or sensitive credential is discovered;
- the requested change would require destructive data loss not explicitly approved;
- the environment prevents meaningful verification of a high-risk change;
- continuing would require inventing missing requirements.

Stopping for clarification is preferable to confidently implementing the wrong system.

## 20. Documents Expected Next

This file defines working rules, not the complete specification.

The repository should eventually add at least:

- `GAME_DESIGN.md` — player experience, gameplay loop, content, progression, economy, MVP scope;
- `ARCHITECTURE.md` — engine choice, modules, state ownership, time/random abstractions, save architecture, event/rule system, platform strategy;
- `DEFINITION_OF_DONE.md` — objective quality gates for tasks, milestones, and release candidates.

Until those documents exist, agents must not fill major gaps by silently inventing long-term architecture or product requirements.

---

## Short Rule for Every Agent

**Inspect first. Change only what the task requires. Preserve the game principles. Keep core logic deterministic and testable. Prove the work with real checks. Never hide failures. Never invent missing decisions.**
