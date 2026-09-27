# Garden Architecture

> Status: **Draft v0.1**
>
> Purpose: This document defines the technical architecture for Garden: engine and platform decisions, module boundaries, state ownership, persistence, time/randomness handling, event-rule architecture, Android lifecycle behavior, testing strategy, and implementation constraints.
>
> This document must be read together with `PROJECT_RULES.md` and `GAME_DESIGN.md`. If documents conflict, follow the precedence defined in `PROJECT_RULES.md`.

---

## 1. Decision Status Legend

This document uses the same decision discipline as `GAME_DESIGN.md`:

- **LOCKED** — approved architecture for the current project unless the owner explicitly changes it.
- **PROVISIONAL** — preferred approach, suitable for implementation/prototyping, but may be revised with evidence.
- **TBD** — intentionally undecided. Do not invent a permanent answer during implementation.

An AI agent must not silently convert a **PROVISIONAL** or **TBD** item into a permanent project-wide convention.

---

## 2. Architecture Goals

**Status: LOCKED**

The architecture exists to make a small game dependable, testable, inspectable in Git, and safe for AI-assisted development.

The primary goals are:

1. **Keep game rules independent from presentation.**
   Plant growth, economy, visitor eligibility, event conditions, offline progression, and save validation must be testable without manually operating a scene.

2. **Keep one authoritative game state.**
   UI nodes, scene objects, animation nodes, and save files must not each become competing sources of truth.

3. **Make time deterministic in tests.**
   Domain logic must not read the system clock directly.

4. **Make randomness deterministic in tests.**
   Domain/application logic must not depend on uncontrolled global random calls.

5. **Prefer data-driven content.**
   Adding a normal plant, visitor, decoration, or event should primarily mean adding/changing content definitions rather than expanding giant conditional chains.

6. **Make persistence explicit and versioned.**
   Save/load is a first-class subsystem, not an afterthought.

7. **Respect Android lifecycle realities.**
   Pause, background, resume, process death, touch input, aspect-ratio differences, and battery use are architectural concerns.

8. **Keep the project small enough to understand.**
   Avoid enterprise patterns, plugin sprawl, unnecessary global services, or abstractions with no demonstrated need.

9. **Make changes easy to review.**
   Prefer text-based resources, clear folder boundaries, focused scripts, stable IDs, and narrow diffs.

10. **Allow the game to grow without forcing a rewrite.**
    The MVP should remain simple while preserving clean boundaries around systems likely to expand.

---

## 3. Locked Technology Stack

**Status: LOCKED**

### Engine

- **Godot 4.7.2 Stable**
- Standard Godot build, not the .NET/C# build
- Do not upgrade Godot versions in an unrelated task.
- Any engine upgrade must be deliberate, tested, and documented.

### Language

- **GDScript**
- Static typing is strongly preferred and is required for core domain/application code unless there is a concrete reason not to use it.
- Avoid relying on dynamic types where the data contract is known.

### Rendering and game type

- **2D**
- **Compatibility renderer**
- No 3D gameplay requirement for the MVP.

### Primary platform

- **Android first**
- Desktop/editor execution is a development convenience, not the product target.

### Orientation

- **Portrait**
- Reference design canvas: **1080 x 1920**
- The game must not assume every phone has that exact resolution or aspect ratio.

### Connectivity

- **Offline-first**
- No backend for the MVP.
- No account system for the MVP.
- No cloud save for the MVP.
- No analytics SDK for the MVP.
- No advertising SDK for the MVP.
- No network permission should be introduced unless a future approved feature requires it.

---

## 4. Architectural Non-Goals

**Status: LOCKED**

The MVP architecture must not introduce these systems without explicit owner approval:

- Entity Component System (ECS);
- service-locator frameworks;
- dependency-injection frameworks;
- a general-purpose global event bus;
- backend APIs;
- multiplayer/network synchronization;
- Firebase or equivalent remote platform services;
- cloud save;
- telemetry/analytics;
- ads/monetization SDKs;
- mod/plugin architecture;
- scripting language embedded inside game content;
- deep inheritance hierarchies;
- per-entity threads, timers, or coroutines for simulation;
- a database when a small versioned local save is sufficient.

These are not permanently forbidden. They are simply unjustified for the current game and MVP.

---

## 5. High-Level Layering

**Status: LOCKED**

The codebase should conceptually contain five layers:

```text
+--------------------------------------------------+
|                  Presentation                    |
| Scenes, UI, animation, input, visual/audio views |
+-------------------------+------------------------+
                          |
                          v
+--------------------------------------------------+
|                 Application                      |
| GameSession, commands, orchestration, use cases  |
+-------------------------+------------------------+
                          |
                          v
+--------------------------------------------------+
|                    Domain                        |
| State, rules, growth, economy, eligibility       |
+--------------------------------------------------+
          ^                               ^
          |                               |
+---------+----------+          +---------+----------+
|      Content       |          |    Infrastructure   |
| Definitions/data   |          | Save, clock, RNG,   |
| plants/events/etc. |          | lifecycle adapters  |
+--------------------+          +---------------------+
```

### Dependency rule

The domain must not depend on presentation scenes or Android lifecycle APIs.

Presentation may call application services and render domain/application state.

Infrastructure implements external concerns such as system time and file access. Infrastructure may know about Godot platform APIs; domain rules should not.

Content definitions describe what exists in the game. They should not become containers for arbitrary presentation logic.

---

## 6. Proposed Repository Structure

**Status: PROVISIONAL**

Use the following structure unless implementation reveals a clear reason to refine it:

```text
/
├── PROJECT_RULES.md
├── GAME_DESIGN.md
├── ARCHITECTURE.md
├── DEFINITION_OF_DONE.md          # expected next
├── project.godot
├── export_presets.cfg             # once Android export is configured
│
├── src/
│   ├── domain/
│   │   ├── state/
│   │   ├── plants/
│   │   ├── visitors/
│   │   ├── events/
│   │   ├── economy/
│   │   ├── progression/
│   │   └── common/
│   │
│   ├── application/
│   │   ├── game_session.gd
│   │   ├── commands/
│   │   ├── queries/
│   │   └── services/
│   │
│   ├── infrastructure/
│   │   ├── persistence/
│   │   ├── time/
│   │   ├── random/
│   │   └── platform/
│   │
│   └── presentation/
│       ├── garden/
│       ├── ui/
│       ├── visitors/
│       ├── effects/
│       └── app/
│
├── scenes/
│   ├── app/
│   ├── garden/
│   ├── ui/
│   └── visitors/
│
├── content/
│   ├── plants/
│   ├── visitors/
│   ├── decorations/
│   ├── events/
│   └── progression/
│
├── assets/
│   ├── art/
│   ├── audio/
│   ├── fonts/
│   └── icons/
│
└── tests/
    ├── domain/
    ├── application/
    ├── persistence/
    └── fixtures/
```

Do not create every empty folder up front merely to match this diagram. Add folders when their first real contents are introduced.

Do not put business rules into `scenes/` merely because a scene needs them.

---

## 7. Composition Root and Autoload Policy

**Status: LOCKED**

The project should have a clear composition root responsible for constructing and connecting long-lived services.

For the MVP, prefer **one application-level autoload/composition root** (working name: `AppRoot` or `App`) rather than many independent singleton managers.

The composition root may own or create long-lived objects such as:

- the current `GameSession`;
- persistence service;
- system clock adapter;
- random source;
- lifecycle coordinator;
- scene/screen coordinator if genuinely required.

### Autoload rule

Do not create one autoload per system (`PlantManager`, `VisitorManager`, `CurrencyManager`, `SaveManager`, `WeatherManager`, etc.).

A new autoload beyond the composition root requires an explicit architectural reason and should be called out in the task report.

Autoloads must not become dumping grounds for unrelated mutable global state.

---

## 8. Authoritative Game State

**Status: LOCKED**

The game must maintain one authoritative runtime model of persistent player state.

Working concept:

```text
GameState
├── schema/runtime metadata
├── economy state
├── plant instances
├── decoration instances
├── discovery/journal state
├── progression state
├── weather state
└── other approved persistent state
```

### Rules

- Scene nodes are **views/controllers**, not the canonical save state.
- A plant Sprite/Node disappearing from a scene must not delete a plant from the game model by accident.
- UI labels must not be the source of currency values.
- Animation state must not be the source of growth state.
- Persistent state classes should be independent from scene-tree ownership whenever practical.

Use typed domain data objects (for example `RefCounted` classes or similarly lightweight typed structures) rather than requiring every state object to be a `Node`.

### State mutation

Persistent state should be changed through explicit domain/application operations rather than arbitrary writes from UI scripts.

Examples:

```text
plant(...)
harvest(...)
purchase(...)
place_decoration(...)
move_decoration(...)
record_discovery(...)
apply_offline_progress(...)
```

The exact API may evolve, but the direction is locked: presentation code requests an action; application/domain code validates and mutates authoritative state.

---

## 9. Definition Data vs Runtime Instance Data

**Status: LOCKED**

The architecture must distinguish between **what a thing is** and **the player's instance of that thing**.

### Definition examples

A `PlantDefinition` may contain:

```text
id
name/localization key
growth stage timings
environmental traits
harvest/repeat timing
economy values
art references
content tags
```

A `VisitorDefinition` may contain:

```text
id
name/localization key
eligibility requirements
weight/chance configuration
cooldown/category data
preferred anchors/interactions
art/scene reference
```

A `DecorationDefinition` may contain:

```text
id
name/localization key
price
environmental traits
placement properties
art/scene reference
```

### Instance examples

A `PlantState` should contain only player-specific/runtime facts such as:

```text
instance_id
definition_id
placement
planted_at
last_harvest_at / next_ready_at as appropriate
instance-specific state
```

A definition is not copied wholesale into every save entry.

This keeps save files small and allows content tuning without duplicating static data.

---

## 10. Stable IDs

**Status: LOCKED**

Every persistent content type must use a stable, explicit ID.

Example style:

```text
plant.holy_basil
plant.chili
plant.jasmine
visitor.butterfly
visitor.frog
decoration.clay_jar
event.cat_sleeping
```

Rules:

- Do not use display names as IDs.
- Do not use translated text as IDs.
- Do not use scene/resource file paths as the persistent identity.
- Do not casually rename an ID after it can appear in save data.
- If an ID must change, provide save migration/alias handling.

Runtime instances that require unique identity should have a separate `instance_id` from their `definition_id`.

---

## 11. Content Representation

**Status: PROVISIONAL**

Prefer Godot text-based `Resource` definitions (`.tres`) for authored content when they remain readable, reviewable, and easy to validate.

Possible typed definition resources:

- `PlantDefinition`
- `VisitorDefinition`
- `DecorationDefinition`
- `EventDefinition`
- `ProgressionDefinition`

Content definitions should be loaded through a small repository/catalog abstraction rather than discovered ad hoc throughout presentation scenes.

Working concept:

```text
ContentCatalog
├── plants_by_id
├── visitors_by_id
├── decorations_by_id
└── events_by_id
```

The catalog must validate duplicate IDs and missing required references during development.

### No arbitrary code in content

Do not create an embedded mini-language or allow arbitrary executable scripts inside content definitions for the MVP.

Event requirements should use a finite, typed set of requirement kinds that can be validated and tested.

---

## 12. Environmental Traits

**Status: PROVISIONAL**

Plants and decorations may contribute environmental traits to the garden.

Examples:

```text
flower
water
shade
food
fruit
light
shelter
perch
dense_vegetation
```

The domain/application layer should be able to build a `GardenSnapshot` or equivalent query model that summarizes the conditions relevant to visitor/event rules.

Example conceptual snapshot:

```text
flower: 3
water: 1
shade: 2
light: 1
current_time_period: NIGHT
weather: RAIN
```

Visitors/events should generally query this derived state rather than searching scene nodes directly.

Do not encode core eligibility as `get_tree().get_nodes_in_group(...)` checks inside visitor presentation scripts.

---

## 13. Plant Growth Architecture

**Status: LOCKED**

Plant growth must be derived from authoritative timestamps and definition data.

A plant must **not** require a continuously running Timer node while the app is closed.

Conceptually:

```text
GrowthState = f(
    planted_at,
    harvest history / ready timestamp,
    current_time,
    PlantDefinition
)
```

### Rules

- No per-plant busy loops.
- No per-plant background threads.
- Do not increment `age += delta` as the only source of persistent age.
- Do not save a countdown every second.
- On resume/load, compute the state from timestamps.
- Long offline periods must not require simulating every elapsed second.
- Negative elapsed time must never reduce/corrupt progress.

Presentation may animate transitions, but animation completion must not be the authoritative growth rule.

---

## 14. Time Architecture

**Status: LOCKED**

Time is an infrastructure concern and must be centralized.

### GameClock abstraction

Use a clock abstraction with production and test implementations.

Conceptual API:

```text
GameClock
- utc_now_seconds() -> int
- monotonic_milliseconds() -> int
```

Possible implementations:

```text
SystemGameClock
FakeGameClock
```

Domain functions should preferably receive `now` as an argument rather than reaching out to the clock themselves.

Example:

```text
application service obtains now from GameClock
             ↓
domain rule receives now explicitly
             ↓
result is deterministic
```

### Persistent timestamps

Persistent timestamps should use a consistent UTC/Unix-time representation in integer seconds unless a future requirement proves another format is necessary.

Do not persist localized date strings as authoritative time values.

### Clock rollback

If the device clock moves backward:

- elapsed time must clamp to zero rather than become negative;
- state must remain valid;
- development diagnostics should record the anomaly where practical;
- the MVP must not punish the player or corrupt the save in an attempt at anti-cheat enforcement.

### Foreground simulation

Do not require reading wall-clock time every frame.

Use low-frequency centralized refresh or derived queries where sufficient. Visual animation may still use frame time; persistent game progression should not depend on frame count.

---

## 15. Randomness Architecture

**Status: LOCKED**

Randomness must be routed through an injectable/replaceable source.

Conceptual API:

```text
RandomSource
- next_float() -> float
- range_int(min, max) -> int
- choose_weighted(...)
```

Possible implementations:

```text
GodotRandomSource
SeededRandomSource / FakeRandomSource for tests
```

### Rules

- Do not call global random helpers throughout domain code.
- Tests must be able to use a fixed seed or scripted sequence.
- Eligibility tests should not rely on random rolls.
- Selection/weight tests must be deterministic.

The MVP does not require randomness to be cryptographically secure.

---

## 16. Visitor and Event Rule Engine

**Status: LOCKED for architecture; rule vocabulary PROVISIONAL**

Visitors and special events must be evaluated through a centralized rule/eligibility system rather than hard-coded independently in presentation scenes.

Conceptual pipeline:

```text
Authoritative GameState
        +
Content Definitions
        +
Current context (time/weather)
        ↓
GardenSnapshot
        ↓
Eligibility evaluation
        ↓
Eligible candidates
        ↓
Cooldown / active-limit filtering
        ↓
Random weighted selection
        ↓
VisitorIntent / EventIntent
        ↓
Presentation spawns visual behavior
```

### Requirement vocabulary

For the MVP, prefer a small typed set of requirements such as:

- minimum environmental trait count;
- required time period;
- allowed weather state;
- required plant/decoration definition ID when genuinely needed;
- minimum garden progression stage;
- discovery prerequisite if later required.

Requirements may support simple **ALL** and **ANY** composition if needed.

Do not build a general expression parser or scripting language.

### Presentation boundary

The rule engine decides **whether/what may happen**.

Presentation decides **how it looks and animates**.

A cat animation script must not become the place where eligibility, economy, journal state, and cooldown logic are all implemented.

---

## 17. Active Visitor/Event State

**Status: PROVISIONAL**

Most ordinary visitors are ephemeral presentation/application state and do not need to be serialized as full persistent entities.

Persistent state should usually record only what matters across sessions, such as:

- first discovery;
- last/next cooldown timestamp if needed;
- event completion/discovery flags if needed.

Do not persist animation frame, Sprite position, or transient path-following state unless a future feature genuinely requires exact continuation after process death.

On app restart, it is acceptable for ephemeral visitor visuals to restart rather than resume mid-animation, provided persistent discoveries/progression remain correct.

---

## 18. Weather Architecture

**Status: PROVISIONAL**

Weather is internal game state for the MVP and does not depend on a real-world weather API.

Persistent weather state may contain:

```text
current_weather
started_at
next_change_at
(optional seed/state if required by final algorithm)
```

Weather transitions should be orchestrated centrally, not by multiple scene nodes competing to change the weather.

Loading after a long absence should calculate a valid current state efficiently. It must not simulate thousands of tiny frame/timer updates.

The exact weather schedule and probabilities are tuning data and remain outside architecture.

---

## 19. Placement Architecture

**Status: PROVISIONAL; exact placement UX TBD**

The game design has not yet locked free placement versus grid/slot placement.

Therefore persistent placement data must remain independent from raw screen coordinates.

### Rules

- Never save viewport pixels such as `x=742, y=1683` as the only authoritative placement if those values depend on device resolution.
- Use garden-local logical coordinates, stable slot IDs, grid coordinates, or another resolution-independent representation.
- Presentation converts logical placement into the current rendered layout.
- Placement validation belongs in application/domain logic where possible, not only in drag visual code.

The exact placement model should be decided by a focused prototype before large amounts of content depend on it.

---

## 20. Economy Architecture

**Status: LOCKED**

Currency is integer state.

The MVP has one ordinary currency.

All currency mutations must pass through explicit operations that enforce invariants.

Examples:

```text
can_afford(price)
spend(price)
earn(amount)
purchase(definition_id)
```

Rules:

- UI never directly subtracts coins.
- Prices/rewards should come from definitions/tuning data, not duplicated literals across scenes.
- Coin balance must never become negative because two UI actions raced or validation was bypassed.
- Floating-point currency is not allowed.

---

## 21. Journal and Discovery Architecture

**Status: LOCKED**

Discovery state must use stable content IDs.

A discovery record may contain:

```text
definition_id
first_seen_at
(optional) times_seen
(optional) metadata approved by design
```

The journal UI queries discovery state plus content definitions.

Do not copy full localized names/descriptions into save data.

First-time discovery should be idempotent: seeing the same visitor twice must not accidentally award first-discovery rewards twice.

---

## 22. Persistence Architecture

**Status: LOCKED**

The MVP uses local on-device persistence.

### Save format

Use a versioned, inspectable data format composed only of explicit serializable primitives. **JSON is the preferred initial format** unless implementation reveals a concrete reason to change it.

Do not serialize live scene trees or arbitrary Node graphs as the save contract.

Conceptual save shape:

```json
{
  "schema_version": 1,
  "saved_at_utc": 1790470000,
  "economy": {
    "coins": 250
  },
  "plants": [],
  "decorations": [],
  "discoveries": [],
  "progression": {},
  "weather": {}
}
```

The exact schema will be specified when persistence is implemented, but `schema_version` is required from version 1.

### Save pipeline

Conceptually:

```text
GameState
  ↓
SaveMapper / DTO conversion
  ↓
Validation / serialization
  ↓
temporary file
  ↓
safe replacement of primary save
  ↓
optional last-known-good backup
```

### Load pipeline

Conceptually:

```text
read bytes/text
  ↓
parse
  ↓
validate structure/types/ranges
  ↓
migrate old schema if needed
  ↓
map into GameState
  ↓
validate invariants
  ↓
start GameSession
```

### Save corruption behavior

- Do not silently treat malformed data as a valid empty save.
- Preserve diagnostics in development.
- If a last-known-good backup exists, recovery may be attempted explicitly.
- Never overwrite a potentially recoverable save with an empty replacement before determining what failed.

---

## 23. Save Schema Migration

**Status: LOCKED**

Schema migration is sequential and explicit.

Conceptual approach:

```text
v1 -> v2
v2 -> v3
v3 -> v4
```

Do not implement a single giant "accept anything" loader that guesses old formats indefinitely.

Migration rules must be deterministic and covered by tests once multiple schema versions exist.

When content IDs are renamed or removed, migration/alias rules must preserve valid player state wherever practical.

Resetting all progress is not an acceptable migration strategy unless the owner explicitly approves it for a pre-release prototype.

---

## 24. Save Timing

**Status: PROVISIONAL**

The app should save at meaningful state boundaries rather than every frame.

Likely save triggers include:

- after an important purchase;
- after planting/removing/moving a persistent object;
- after harvest/economy mutation;
- after first-time discovery/progression changes;
- when the app is paused/backgrounded;
- at controlled checkpoints/debounced intervals if many edits occur quickly.

Do not rely exclusively on a graceful application-exit callback; Android may terminate the process without one.

Save frequency must balance data safety with unnecessary storage writes.

---

## 25. Android Lifecycle Architecture

**Status: LOCKED**

Lifecycle behavior must be coordinated in one place.

Working component: `LifecycleCoordinator`.

### Background/pause

When the app moves out of active play:

1. capture a consistent state checkpoint;
2. record the relevant timestamp;
3. save when appropriate;
4. pause presentation/audio behavior as required.

### Resume

When returning:

1. obtain current time once through `GameClock`;
2. calculate elapsed/offline progression once;
3. clamp invalid negative elapsed values;
4. advance authoritative state;
5. update weather/time context;
6. refresh presentation from the new state.

### Critical rule

Do not apply offline progression independently in multiple places such as:

- load function;
- main garden scene `_ready()`;
- resume notification;
- plant nodes individually.

That pattern causes double counting. One coordinator/application operation owns the transition.

---

## 26. Offline Progression

**Status: LOCKED**

Offline progression is computed, not simulated frame-by-frame.

For each time-dependent subsystem, prefer direct calculations from timestamps.

Examples:

```text
plant stage = stage_for(now - planted_at)
produce ready = now >= next_ready_at
```

If a future system accumulates repeated production, calculate the number of completed cycles mathematically rather than running one loop per elapsed second.

Visitors that were never actually observed during offline time must not automatically count as player discoveries unless game design explicitly changes this rule.

---

## 27. Scene Architecture

**Status: PROVISIONAL**

Suggested top-level scene shape:

```text
App/Main
├── GardenScreen
│   ├── GardenView
│   ├── PlantLayer
│   ├── DecorationLayer
│   ├── VisitorLayer
│   ├── EffectsLayer
│   └── AmbientLayer
├── HUD
└── OverlayLayer
    ├── ShopPanel
    ├── JournalPanel
    ├── PlacementUI
    └── Dialog/Toast layer
```

The exact node names may change.

### Scene responsibilities

A scene should own visual composition and input behavior relevant to itself.

A scene should not become the canonical owner of cross-session domain state.

Visitor scenes may own:

- sprites/animation;
- short movement behavior;
- visual interaction with anchors;
- presentation-only timing.

Visitor scenes should not own:

- persistent discovery rules;
- economy;
- save file updates;
- global eligibility calculation;
- unrelated progression.

---

## 28. Presentation Synchronization

**Status: LOCKED direction**

Presentation should render authoritative state and respond to explicit state-change notifications.

Prefer narrow signals/events such as:

```text
coins_changed
plant_added
plant_state_changed
decoration_changed
discovery_added
weather_changed
visitor_intent_created
```

Do not use a single untyped global event bus where any system can emit arbitrary string messages.

Signals should be owned by the object/service whose state they describe.

For broad UI refresh after load/resume, a controlled `state_reloaded`/snapshot refresh is acceptable.

---

## 29. Input and Mobile UX Architecture

**Status: LOCKED principles; detailed controls PROVISIONAL**

The game is touch-first.

Rules:

- No core interaction may require mouse hover.
- Editor mouse input may mirror touch for development convenience.
- Drag interactions must tolerate finger occlusion and small movement jitter.
- Important controls must respect safe areas/cutouts.
- Modal overlays must clearly capture/release input.
- UI must not depend on right-click, keyboard shortcuts, or precision mouse placement.

The exact touch target sizing and accessibility tuning will be specified during UI implementation/testing.

---

## 30. Resolution and Layout

**Status: LOCKED direction**

The reference design canvas is 1080 x 1920 portrait, but layout must adapt to real devices.

The architecture should preserve two coordinate concepts:

1. **Garden-local logical space** for persistent object placement.
2. **Screen/UI space** for device-specific rendering and controls.

Do not mix them casually.

The garden composition must tolerate common tall-phone aspect ratios without exposing invalid empty world space or clipping essential controls.

UI panels should use anchors/containers or equivalent responsive layout tools rather than hard-coded absolute screen positions wherever practical.

---

## 31. Audio Architecture

**Status: PROVISIONAL**

Audio should initially remain simple.

Separate conceptual categories:

- ambience;
- music;
- sound effects/UI.

Do not introduce an elaborate audio framework before requirements justify it.

A small centralized audio coordinator may be introduced when real content exists, but it must not become a general-purpose global manager for unrelated systems.

Audio settings, if added, belong in persistent settings data separate from garden gameplay state where practical.

---

## 32. Localization Architecture

**Status: PROVISIONAL**

Because the setting may be Thai-inspired while remaining accessible internationally, content definitions should prefer stable localization keys over embedding display strings into persistent state.

Example:

```text
name_key = "plant.holy_basil.name"
description_key = "plant.holy_basil.description"
```

The MVP may begin with one language during development, but architecture should not make localization unnecessarily expensive later.

Save data must never depend on translated display text.

---

## 33. Error Handling and Diagnostics

**Status: LOCKED**

During development, invalid state should fail visibly enough to diagnose.

Examples that must not be silently ignored:

- duplicate content ID;
- missing definition referenced by save data;
- malformed save field;
- negative currency;
- invalid placement record;
- failed save write;
- unsupported future save schema;
- impossible enum/state value.

Use clear assertions/errors during development where appropriate, while preserving player-safe recovery paths for production.

Do not fabricate substitute content to hide missing required data.

---

## 34. Testing Architecture

**Status: LOCKED principles; exact framework PROVISIONAL**

Automated tests must focus heavily on pure domain/application behavior.

### Required testability

At minimum, architecture must make these testable without manual UI input:

- plant growth stage boundaries;
- repeat harvest readiness;
- offline progression;
- clock rollback;
- pause/resume calculation without double counting;
- visitor eligibility;
- event eligibility;
- deterministic weighted selection;
- economy invariants;
- purchase validation;
- first-discovery idempotency;
- save/load round trip;
- malformed save handling;
- migration between schema versions once relevant.

### Test framework

**Approved initial approach (Task 0.4B, Milestone 0): native GDScript headless runner.**

The project uses a small, self-contained headless test runner written in GDScript with no third-party addon or plugin dependency.

Key properties of the approved runner:

- Entry point: `res://tests/run_tests.gd` (extends `SceneTree`).
- Base class: `res://tests/test_suite_base.gd` (extends `RefCounted`).
- Suites are registered explicitly in the runner — no filesystem discovery.
- Canonical command: `godot --headless --path . --script res://tests/run_tests.gd`
- Exit code 0 when all tests pass; exit code 1 when any test fails.
- No autoload, no scene required, no global mutable state.

This runner should remain intentionally minimal. Do not grow it into a general-purpose testing framework merely to avoid adopting a dependency. If the project later needs a more capable test framework (such as GUT or GdUnit4), that adoption must go through the normal dependency and architecture-change process defined in Sections 38 and 46.

There is currently no third-party testing addon in the project.

### Test fixtures

Use small explicit fixtures/builders rather than loading the entire real game content set for every unit test.

Tests must not depend on actual wall-clock time or uncontrolled random outcomes.

---

## 35. Verification and Build Strategy

**Status: PROVISIONAL**

The repository should evolve toward a repeatable command-line verification path that an AI agent and CI runner can execute.

Desired verification categories:

1. parse/load the Godot project without script errors;
2. run automated domain/application tests headlessly;
3. validate content definitions;
4. run targeted integration checks;
5. build/export Android debug when the Android toolchain is configured;
6. inspect the actual Git diff and working-tree state.

A task report must state which checks were actually executed.

Do not claim Android verification merely because the project ran on desktop.

---

## 36. Android Export and Secrets

**Status: LOCKED principles; SDK levels TBD**

Android export configuration may be committed when it contains no secrets and is useful for reproducible development.

Never commit:

- release keystores;
- keystore passwords;
- signing secrets;
- local SDK paths tied to one machine;
- private service credentials.

Release signing should remain outside the repository.

Exact Android minimum/target SDK decisions are **TBD** and should be chosen based on the Godot version, Google Play requirements at release time, and desired device support.

Do not invent or freeze SDK levels prematurely in an unrelated task.

---

## 37. Performance and Battery Rules

**Status: LOCKED**

The game should remain light enough for ordinary Android devices.

Rules:

- Avoid per-frame processing in scripts that do not need it.
- Disable `_process`/physics processing for idle presentation nodes when unnecessary.
- Do not run a Timer per plant for persistent growth.
- Do not poll save files continuously.
- Do not rebuild the whole garden scene every frame.
- Do not use high-frequency domain simulation for systems that can be timestamp-derived.
- Avoid premature object pooling; measure first.
- Optimize based on profiling, not folklore.

A small number of ambient visual animations is acceptable; the restriction is against unnecessary simulation overhead, not against a living-looking garden.

---

## 38. Dependency Policy

**Status: LOCKED**

The MVP begins with **no third-party Godot addons required by architecture**.

A dependency may be added later only when:

- a concrete need exists;
- a local implementation would be meaningfully worse;
- Android compatibility is verified;
- maintenance/license/size implications are acceptable;
- the owner approves when required by `PROJECT_RULES.md`;
- tests/build still pass.

Vendor/plugin code must not be allowed to dictate core domain architecture.

---

## 39. Data Validation

**Status: LOCKED**

Content and save data must be validated at clear boundaries.

### Content validation examples

- unique ID;
- non-empty required localization key;
- non-negative price/reward;
- valid growth stage timing order;
- known environmental trait;
- referenced scene/resource exists;
- event requirement kind is supported;
- referenced content ID exists.

### Save validation examples

- supported schema version;
- correct primitive types;
- valid IDs;
- non-negative currency;
- valid timestamps/ranges;
- unique instance IDs where required;
- valid placement data.

Validation logic should be centralized enough that editor/runtime/test paths do not each invent different rules.

---

## 40. Content Loading Failures

**Status: LOCKED**

Missing required content is a development defect, not a reason to silently create fake fallback items.

If a save references an unavailable definition:

1. preserve enough information for diagnosis;
2. use an explicitly designed recovery/migration path if one exists;
3. do not silently reinterpret it as another item;
4. do not delete unrelated player state.

During pre-release development, failing loudly may be preferable to hiding content-authoring mistakes.

---

## 41. Concurrency

**Status: LOCKED for MVP**

The MVP should remain primarily single-threaded from the game's point of view.

Do not introduce worker threads for plant growth, visitors, weather, or save calculations without profiling evidence and a clear thread-safety design.

The expected MVP workload is small enough that clean deterministic logic is more valuable than speculative concurrency.

---

## 42. Signals and Coupling

**Status: LOCKED direction**

Use direct references and typed/known signals where relationships are stable and local.

Prefer:

```text
HUD -> GameSession command
GameSession -> coins_changed signal
GardenView -> state query / specific change signal
```

Avoid:

```text
GlobalEventBus.emit("something_happened", arbitrary_dictionary)
```

A general event bus may only be introduced if concrete cross-cutting requirements demonstrate that direct relationships have become unmanageable.

---

## 43. No Scene-Tree Queries as Domain Logic

**Status: LOCKED**

Godot groups and scene-tree searches are useful presentation tools, but they must not become the primary model of persistent gameplay rules.

Bad architectural direction:

```text
"Butterfly checks whether any Node in group 'flowers' exists."
```

Preferred direction:

```text
GameState + content definitions -> GardenSnapshot flower count -> visitor eligibility
```

Presentation can still use groups to find visual anchors after an event has already been approved by domain/application logic.

---

## 44. UI Does Not Own Rules

**Status: LOCKED**

Button scripts may collect input and call commands, but must not contain duplicated versions of game rules.

Bad:

```text
Shop button checks its own hard-coded price,
subtracts coins from label text,
and adds a scene.
```

Preferred:

```text
Shop UI calls GameSession.purchase(id)
GameSession validates price/state
GameState changes
UI receives updated state
```

This rule applies especially to:

- purchases;
- planting;
- harvesting;
- unlocks;
- discovery rewards;
- placement validity.

---

## 45. Tuning Data vs Code

**Status: LOCKED direction**

Values expected to change during playtesting should live in content/tuning data where practical.

Examples:

- plant growth durations;
- prices;
- harvest rewards;
- visitor weights;
- cooldown durations;
- environmental requirements;
- progression thresholds.

Do not hide tuning values as unexplained literals across multiple scripts.

Code should define rules and invariants; data should define most content-specific numbers.

---

## 46. Architecture Change Protocol

**Status: LOCKED**

An implementation task must not silently replace this architecture because another design feels easier in the moment.

When a change is justified:

1. identify the limitation in the current architecture;
2. explain the proposed change;
3. identify migration/refactor impact;
4. update `ARCHITECTURE.md` in the same approved change or immediately before implementation;
5. add/adjust tests that protect the new contract.

Examples requiring explicit architecture review:

- adding a backend;
- adding multiple autoload managers;
- replacing JSON save format;
- moving domain state into Nodes;
- adopting a third-party framework;
- switching renderer/engine/language;
- adding threaded simulation;
- changing the persistent ID strategy;
- changing save schema semantics.

---

## 47. Recommended Initial Implementation Sequence

**Status: PROVISIONAL**

This is an architecture-oriented dependency order, not a complete project plan.

### Phase A — Project foundation

- create Godot 4.7.2 project;
- configure portrait/Compatibility renderer;
- establish source/content/test structure as needed;
- create composition root;
- establish basic headless verification;
- establish Android debug export when environment permits.

### Phase B — Core deterministic primitives

- stable ID conventions;
- clock abstraction;
- random abstraction;
- typed definition/state primitives;
- content catalog and validation.

### Phase C — Persistence foundation

- GameState;
- save DTO/mapper;
- schema version 1;
- safe save/load;
- tests for round trip and malformed saves;
- lifecycle checkpoint integration.

### Phase D — First playable plant loop

- plant definitions;
- plant instance state;
- timestamp-derived growth;
- planting/harvest/economy commands;
- basic garden presentation;
- offline progression tests.

### Phase E — Reactive garden

- environmental trait snapshot;
- weather context;
- visitor definitions;
- eligibility/rule engine;
- deterministic selection;
- first visitor presentation.

### Phase F — Collection and decoration

- discovery/journal state;
- decoration definitions/instances;
- placement prototype and final model decision;
- journal UI;
- additional MVP content.

Do not begin by creating all final art/content before the core loop and architecture have been proven with placeholder assets.

---

## 48. Architecture Acceptance Checklist for New Features

Before considering a non-trivial feature implementation acceptable, verify:

- [ ] Does it respect `PROJECT_RULES.md` and `GAME_DESIGN.md`?
- [ ] Is persistent state owned outside presentation scenes?
- [ ] Are time-dependent rules deterministic/testable?
- [ ] Is randomness controllable in tests?
- [ ] Are content-specific values data-driven where appropriate?
- [ ] Does the feature avoid unnecessary new autoloads/dependencies?
- [ ] Are save-data implications explicit?
- [ ] Are Android pause/resume/process-death implications considered?
- [ ] Can core behavior be tested without manual UI operation?
- [ ] Does the UI request state changes rather than implementing rules itself?
- [ ] Are stable IDs used for persistent references?
- [ ] Is the diff limited to the task?
- [ ] Were relevant verification steps actually run?

---

## 49. Open Architecture Decisions

**Status: TBD unless otherwise noted**

The following decisions are intentionally not finalized yet:

1. Exact placement model: free placement, grid, slots, or hybrid.
2. ~~Exact automated test framework/harness implementation.~~ **RESOLVED (Task 0.4B):** Native GDScript headless runner with no third-party addon. See Section 34 for details.
3. Exact Android minimum/target SDK levels.
4. Exact content localization languages for first release.
5. Exact save-backup retention policy.
6. Exact weather transition algorithm and persisted random state, if any.
7. Exact UI navigation pattern between garden/shop/journal.
8. Whether desktop builds will become an officially supported release target.
9. Whether GitHub Actions CI is introduced during MVP development or after the first playable milestone.

Agents must not turn these items into hidden permanent decisions while implementing unrelated work.

---

## 50. Short Architecture Rule for Every Agent

**One authoritative state. Domain rules outside scenes. Time and randomness injected. Content identified by stable IDs and driven by data. Save data versioned and validated. Android lifecycle handled once. UI requests changes; it does not own the rules. Keep the system small, deterministic, inspectable, and testable.**
