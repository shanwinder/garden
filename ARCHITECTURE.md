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

#### Implementation Status (Milestones 6, 11, 13, and 14)

- **Plant, Visitor, Decoration & Event definition loading**: `PlantContentLoader` (`src/infrastructure/content/plant_content_loader.gd`) loads the five authored MVP plant `.tres` resources (`plant.banana`, `plant.chili`, `plant.holy_basil`, `plant.jasmine`, `plant.marigold`), `VisitorContentLoader` (`src/infrastructure/content/visitor_content_loader.gd`) loads the five authored MVP visitor `.tres` resources (`visitor.bird`, `visitor.butterfly`, `visitor.cat`, `visitor.firefly`, `visitor.frog`), `DecorationContentLoader` (`src/infrastructure/content/decoration_content_loader.gd`) loads the eight authored MVP decoration `.tres` resources, and `EventContentLoader` (`src/infrastructure/content/event_content_loader.gd`) loads the six authored event `.tres` resources — five MVP ambient/special events plus one secret combination event (`event.bird_shade_song`, `event.cat_jasmine_night_rest`, `event.cat_sleeping_bench`, `event.firefly_night_glow`, `event.frog_rain_chorus`, `event.morning_butterflies`).
- **Validated catalog**: `ContentCatalog.try_create(plant_definitions, visitor_definitions = [], decoration_definitions = [], event_definitions = [])` (`src/application/content/content_catalog.gd`) validates every `PlantDefinition`, `VisitorDefinition`, `DecorationDefinition`, and `EventDefinition` in an all-or-nothing pass, enforces unique canonical IDs, and provides deterministic ascending-order enumeration (`get_all_plants()`, `get_all_plant_ids()`, `get_all_visitors()`, `get_all_visitor_ids()`, `get_all_decorations()`, `get_all_decoration_ids()`, `get_all_events()`, `get_all_event_ids()`).
- **Startup completeness check**: `AppRoot.bootstrap_session()` (`src/application/app_root.gd`) verifies that all `EXPECTED_PRODUCTION_PLANT_IDS` (5), `EXPECTED_PRODUCTION_VISITOR_IDS` (5), `EXPECTED_PRODUCTION_DECORATION_IDS` (8), and `EXPECTED_PRODUCTION_EVENT_IDS` (5) are present in the built `ContentCatalog` before marking content `READY`.

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

#### Implementation Status (Milestones 11, 13, and 14)

- **Canonical trait vocabulary**: `EnvironmentalTrait` (`src/domain/environment/environmental_trait.gd`) defines the nine canonical traits (`dense_vegetation`, `flower`, `food`, `fruit`, `light`, `perch`, `shade`, `shelter`, `water`) and validates trait lists for membership and uniqueness.
- **Authored plant & decoration traits**: `PlantDefinition` (`src/domain/plants/plant_definition.gd`) and `DecorationDefinition` (`src/domain/decorations/decoration_definition.gd`) include `@export var environmental_traits: Array[String] = []` (validated via `EnvironmentalTrait.is_valid_trait_list(...)`).
- **Time-of-day & weather context**: `GardenTimePeriod` (`src/domain/environment/garden_time_period.gd`) defines the four canonical time periods (`morning`, `day`, `evening`, `night`) and derives the active period deterministically from UTC timestamps. `GardenWeather` (`src/domain/environment/garden_weather.gd`) defines the three canonical MVP weather states (`clear`, `cloudy`, `rain`) and derives the active weather state in $O(1)$ time from UTC timestamps.
- **Immutable derived snapshot**: `GardenSnapshot` (`src/domain/environment/garden_snapshot.gd`) and `GardenSnapshotBuilder` (`src/application/environment/garden_snapshot_builder.gd`) derive active environmental trait counts (summed across plants and placed decorations), per-definition plant and decoration counts, total and mature plant counts, total decoration count, `time_period`, and `weather_state` at an explicit `now_utc_seconds` timestamp without querying the scene tree.

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

#### Implementation Status (Milestones 11 and 14)

- **Typed visitor & event definitions**:
  - `VisitorDefinition` (`src/domain/visitors/visitor_definition.gd`) defines `id` (`visitor.` namespace), `weight` (`> 0.0`), `required_trait_counts`, `required_plant_ids`, `required_decoration_ids`, `allowed_time_periods`, `allowed_weather_states`, `min_total_plants`, and `min_mature_plants`, validated via pure `is_valid()`.
  - `EventDefinition` (`src/domain/events/event_definition.gd`) defines `id` (`event.` namespace), `weight` (`> 0.0`), `required_trait_counts`, `required_plant_ids`, `required_decoration_ids`, `allowed_time_periods`, `allowed_weather_states`, `min_total_plants`, `min_mature_plants`, `min_total_decorations`, `required_plant_counts` (`plant.` ID → minimum planted count `> 0`), and `is_secret`, validated via pure `is_valid()`. The five authored MVP `.tres` events in `content/events/` implement all five rows of the MVP Interaction Matrix (`GAME_DESIGN.md` Section 24).
  - Secret combination events (`GAME_DESIGN.md` Section 12): an `EventDefinition` with `is_secret = true` uses the same `EventEligibility` / `EventSelectionService` path as ambient events (no separate system), but authors a low `weight` so it stays rare. `JournalPanel` never lists a secret event's name or recipe while it is inactive; it shows `JournalPanel.SECRET_EVENT_CLUE_TEXT` instead of the condition clue, and names the event only once its combination is present. Events are not persisted, so this adds no save-schema change. The first authored secret is `event.cat_jasmine_night_rest` (jasmine x3 + bench + night, any weather, weight 5.0).
- **Pure deterministic eligibility**: `VisitorEligibility` (`src/domain/visitors/visitor_eligibility.gd`) and `EventEligibility` (`src/domain/events/event_eligibility.gd`) evaluate `is_eligible(...)` and `filter_eligible_visitors(...)` / `filter_eligible_events(...)` purely against `GardenSnapshot` with zero randomness or scene queries.
- **Deterministic weighted selection**: `VisitorSelectionService` (`src/application/visitors/visitor_selection_service.gd`) and `EventSelectionService` (`src/application/events/event_selection_service.gd`) build a `GardenSnapshot`, filter eligible definitions in deterministic ascending ID order, and select one candidate via `RandomSource.choose_weighted_index(weights)`, returning `VisitorSelectionResult` / `EventSelectionResult`. When no candidates are eligible, zero random numbers are consumed.
- **Ephemeral active visitor/event state**: Per Section 17, active visitor observations and ambient events are ephemeral runtime state; persistent discoveries are recorded in `JournalState` (Save Schema V3 preserved).

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

#### Implementation Status (Milestones 14 and 18)

- **Deterministic $O(1)$ weather schedule**: `GardenWeather` (`src/domain/environment/garden_weather.gd`) implements the three canonical MVP weather states (`clear`, `cloudy`, `rain`) using 2-hour windows (`WEATHER_WINDOW_SECONDS = 7200`) and a 5-step deterministic cycle (`["clear", "cloudy", "rain", "clear", "cloudy"]`) coprime with the 12 daily windows so every time-of-day period experiences all three weather states across days.
- **Timestamp-derived without step simulation**: `GardenWeather.weather_for_utc_seconds(now_utc_seconds)` derives the active weather state in $O(1)$ time from the injected `GameClock` timestamp (clamping negative timestamps to `0`) without requiring background timers or simulating intermediate ticks after long offline absences.
- **Schedule transition forecast queries (Milestone 18)**: `GardenWeather.next_weather_for_utc_seconds(now_utc_seconds)` and `GardenWeather.seconds_until_next_weather(now_utc_seconds)` (along with `GardenTimePeriod.next_period_for_period(period_id)`, `GardenTimePeriod.next_period_for_utc_seconds(now_utc_seconds, utc_offset_seconds)`, and `GardenTimePeriod.seconds_until_next_period(now_utc_seconds, utc_offset_seconds)`) compute the next transition state and remaining seconds in $O(1)$ time from the single refresh timestamp.
- **Atmospheric presentation**: `GardenView` (`src/presentation/garden/garden_view.gd` and `scenes/garden/garden_view.tscn`) renders the active time period (`ยามเช้า`, `กลางวัน`, `ยามเย็น`, `ยามค่ำคืน`), weather state (`ท้องฟ้าแจ่มใส`, `มีเมฆมาก`, `ฝนตก`), and active ambient events in `AtmosphereLabel`, exposes next time/weather transition forecasts, and applies a calm time-of-day and weather color tint to `Background` (`ColorRect`) during centralized refreshes.

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

#### Implementation Status (Milestones 10 and 13)

- **Authored plant harvest rewards**: `PlantDefinition` (`src/domain/plants/plant_definition.gd`) defines `@export var harvest_reward: int = 0` (validated non-negative via `is_valid()`), and all five authored production `.tres` definitions specify positive integer rewards (`plant.holy_basil`: 5, `plant.chili`: 10, `plant.marigold`: 20, `plant.jasmine`: 25, `plant.banana`: 60).
- **Validated harvest & cycle reset**: `PlantHarvestService` (`src/application/plants/plant_harvest_service.gd`) validates plant existence, catalog membership, maturity (`PlantGrowth.Stage.MATURE`), positive reward (`harvest_reward > 0`), and `EconomyState.MAX_CURRENCY` overflow before replacing the plant in `PlantCollectionState.try_replace_existing_plant(...)` with a new `PlantState(runtime_instance_id, definition_id, now_utc_seconds)` and granting `harvest_reward` to `EconomyState`.
- **Authored decoration prices & purchase loop (Milestone 13)**: `DecorationDefinition` (`src/domain/decorations/decoration_definition.gd`) defines `@export var price: int = 0` (`>= 0`) and `@export var environmental_traits: Array[String] = []` across the 8 authored MVP decorations (`decoration.bench`, `decoration.clay_jar`, `decoration.garden_lamp`, `decoration.plant_pot`, `decoration.small_pond`, `decoration.small_table`, `decoration.watering_can`, `decoration.wooden_fence`). `DecorationPurchaseService` (`src/application/decorations/decoration_purchase_service.gd`) validates catalog membership and sufficient coins (`EconomyState.can_afford(price)`), generates a unique `"decor-inst-"` runtime instance ID via `DecorationRuntimeIdGenerator`, deducts `price`, and adds `DecorationState` to `DecorationCollectionState`. Placed decorations contribute their environmental traits to `GardenSnapshotBuilder`, unlocking `"water"` habitat (`decoration.clay_jar` and `decoration.small_pond`) for `visitor.frog`.

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

#### Implementation Status (Milestones 12, 15, 17, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, and 40)

- **Immutable discovery value object**: `DiscoveryRecord` (`src/domain/journal/discovery_record.gd`) stores `_definition_id` (validated canonical `StableContentId` in `"plant."` or `"visitor."` namespaces), `_first_seen_at` (`>= 0`), and `_times_seen` (`>= 1`). Its `with_additional_sighting(seen_at_utc)` returns a new `DiscoveryRecord` that preserves `_first_seen_at` (idempotent first discovery) and increments `_times_seen` by 1 while guarding against 64-bit integer overflow.
- **Authoritative journal state slice**: `JournalState` (`src/domain/state/journal_state.gd`) is owned by `GameState` (`state.get_journal()`), providing deterministic ascending ID queries (`get_all_records()`, `get_discovered_ids()`), persistence reconstruction (`try_put_record(record)`), and idempotent sighting recording (`try_record_sighting(definition_id, seen_at_utc)`).
- **Validated discovery recording**:
  - `PlantRegistrationService.try_register_plant(...)` automatically records a plant sighting (`journal.try_record_sighting(definition_id, planted_at)`) when a plant is registered into `GameState`.
  - `JournalDiscoveryService` (`src/application/journal/journal_discovery_service.gd`) validates `definition_id` against `ContentCatalog` (`has_plant` / `has_visitor`) and records the sighting in `JournalState`, returning a typed `JournalDiscoveryResult` (`FIRST_DISCOVERY`, `REPEAT_SIGHTING`, `INVALID_INPUT`, `UNKNOWN_DEFINITION_ID`, or `STATE_UPDATE_REJECTED`).
- **Visitor observation checkpoint**: `VisitorObservationPersistenceCoordinator` (`src/application/visitors/visitor_observation_persistence_coordinator.gd`) samples `GameClock.utc_now_seconds()` once, evaluates visitor selection at that timestamp, records the selected visitor discovery in `JournalState`, and immediately checkpoints `GameState` via `LocalSaveRepository.save(state)`, returning `VisitorObservationCheckpointResult` (`OBSERVED_SAVED`, `OBSERVED_SAVE_FAILED`, `NO_ELIGIBLE_VISITORS`, `OBSERVATION_REJECTED`, or `NOT_READY`).
- **Journal presentation (`สมุดบ้านสวน`, Milestones 12, 17, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, and 40)**: `JournalPanel` (`src/presentation/garden/journal_panel.gd` and `scenes/garden/journal_panel.tscn`) binds read-only to `JournalState`, `ContentCatalog`, and optional `DecorationCollectionState` / `GardenSnapshot`, displaying overall discovery progress and placed/active counts (`ค้นพบแล้ว X / 10 รายการ (พืช A/5, ผู้มาเยือน B/5) | ของตกแต่ง C/8 | เหตุการณ์ D/5`), localized names, `first_seen_at`, `times_seen`, live planted counts (`กำลังปลูกในสวน: X ต้น`), and live visitor habitat eligibility (`มีโอกาสพบในขณะนี้` / `ยังไม่ตรงเงื่อนไขในขณะนี้`) for discovered entries, `[???]` mystery placeholders with environmental trait, habitat, and readiness clues (`สภาพแวดล้อมพร้อมแล้ว ลองสำรวจผู้มาเยือนในสวน`) for undiscovered entries, placed vs unplaced decoration catalog entries (`หมวดของตกแต่งสวน`), active vs mystery ambient event entries (`หมวดเหตุการณ์พิเศษในสวน`) with condition clues, and category/live-status queries (`get_discovered_plant_entry_count()`, `get_discovered_visitor_entry_count()`, `get_placed_count_for_decoration_id(...)`, `is_event_active_in_journal(...)`, `get_discovered_plant_ids_in_journal()`, `get_undiscovered_plant_ids_in_journal()`, `get_discovered_visitor_ids_in_journal()`, `get_undiscovered_visitor_ids_in_journal()`, `get_eligible_visitor_ids_in_journal()`, `get_ineligible_visitor_ids_in_journal()`, `get_placed_decoration_ids_in_journal()`, `get_unplaced_decoration_ids_in_journal()`, `get_active_event_ids_in_journal()`, `get_inactive_event_ids_in_journal()`, `is_entry_discovered_in_journal(...)`, `get_times_seen_for_id(...)`, `get_first_seen_at_for_id(...)`, `get_currently_planted_plant_ids_in_journal()`, `get_currently_planted_plant_entry_count()`, `get_unplanted_plant_ids_in_journal()`, `get_undiscovered_entry_count()`, `get_undiscovered_plant_entry_count()`, `get_undiscovered_visitor_entry_count()`, `get_total_sighting_count_in_journal()`, `get_total_plant_sighting_count_in_journal()`, `get_total_visitor_sighting_count_in_journal()`, `get_ineligible_visitor_entry_count()`, `get_unplaced_decoration_entry_count()`, `get_inactive_event_entry_count()`, `get_unplanted_plant_entry_count()`, `is_all_entries_discovered_in_journal()`, `get_total_plant_entry_count()`, `get_total_visitor_entry_count()`, `is_all_plants_discovered_in_journal()`, `is_all_visitors_discovered_in_journal()`, `is_all_decorations_placed_in_journal()`, `is_all_events_active_in_journal()`, `has_any_discovered_entries_in_journal()`, `has_any_discovered_plants_in_journal()`, `has_any_discovered_visitors_in_journal()`, `has_any_eligible_visitors_in_journal()`, `has_any_placed_decorations_in_journal()`, `has_any_active_events_in_journal()`, `is_all_visitors_eligible_in_journal()`, `has_any_undiscovered_entries_in_journal()`, `has_any_undiscovered_plants_in_journal()`, `has_any_undiscovered_visitors_in_journal()`, `has_any_ineligible_visitors_in_journal()`, `has_any_unplaced_decorations_in_journal()`, `has_any_inactive_events_in_journal()`, `has_any_currently_planted_plants_in_journal()`, `has_any_unplanted_plants_in_journal()`, `is_all_planted_species_present_in_journal()`, `has_bound_journal()`, `has_bound_catalog()`, `has_bound_decorations()`, `has_bound_snapshot()`, `has_plant_in_journal_catalog(...)`, `has_visitor_in_journal_catalog(...)`, `has_decoration_in_journal_catalog(...)`, `has_event_in_journal_catalog(...)`, `get_all_plant_ids_in_journal()`, `get_all_visitor_ids_in_journal()`, `get_all_decoration_ids_in_journal()`, `get_all_event_ids_in_journal()`, `get_total_planted_plant_instance_count_in_journal()`, `get_total_placed_decoration_instance_count_in_journal()`, `is_decoration_placed_in_journal(...)`, `is_plant_currently_planted_in_journal(...)`, `get_plant_display_name_in_journal(...)`, `get_visitor_display_name_in_journal(...)`, `get_decoration_display_name_in_journal(...)`, `get_event_display_name_in_journal(...)`, `get_event_description_in_journal(...)`, `has_summary_text()`, `get_displayed_entry_count()`, `has_any_displayed_entries()`, `get_plant_traits_summary_in_journal(...)`, `get_decoration_traits_summary_in_journal(...)`, `get_visitor_clue_in_journal(...)`, `get_event_clue_in_journal(...)`, `get_decoration_price_in_journal(...)`, `get_plant_harvest_reward_in_journal(...)`, `get_plant_mature_after_seconds_in_journal(...)`, `get_plant_sprout_after_seconds_in_journal(...)`, `get_plant_growing_after_seconds_in_journal(...)`, `get_plant_traits_in_journal(...)`, `get_decoration_traits_in_journal(...)`, `get_plant_trait_display_names_in_journal(...)`, `get_decoration_trait_display_names_in_journal(...)`, `has_plant_trait_in_journal(...)`, `has_decoration_trait_in_journal(...)`, `get_plant_trait_count_in_journal(...)`, `get_decoration_trait_count_in_journal(...)`, `has_plant_any_traits_in_journal(...)`, `has_decoration_any_traits_in_journal(...)`, `get_all_plant_display_names_in_journal()`, `get_all_visitor_display_names_in_journal()`, `get_all_decoration_display_names_in_journal()`, `get_all_event_display_names_in_journal()`, `get_discovered_plant_display_names_in_journal()`, `get_discovered_visitor_display_names_in_journal()`, `get_placed_decoration_display_names_in_journal()`, `get_active_event_display_names_in_journal()`, `get_undiscovered_plant_display_names_in_journal()`, `get_undiscovered_visitor_display_names_in_journal()`, `get_eligible_visitor_display_names_in_journal()`, `get_ineligible_visitor_display_names_in_journal()`, `get_unplaced_decoration_display_names_in_journal()`, `get_inactive_event_display_names_in_journal()`, `get_currently_planted_plant_display_names_in_journal()`, `get_unplanted_plant_display_names_in_journal()`, `get_plant_ids_with_trait_in_journal(...)`, `get_decoration_ids_with_trait_in_journal(...)`, `get_plant_count_with_trait_in_journal(...)`, `get_decoration_count_with_trait_in_journal(...)`, `has_any_plants_with_trait_in_journal(...)`, `has_any_decorations_with_trait_in_journal(...)`, `get_plant_display_names_with_trait_in_journal(...)`, `get_decoration_display_names_with_trait_in_journal(...)`, `has_plant_display_name_in_journal(...)`, `has_visitor_display_name_in_journal(...)`, `has_decoration_display_name_in_journal(...)`, `has_event_display_name_in_journal(...)`, `has_event_description_in_journal(...)`, `has_plant_traits_summary_in_journal(...)`, `has_decoration_traits_summary_in_journal(...)`, `has_visitor_clue_in_journal(...)`, `has_event_clue_in_journal(...)`, `has_decoration_positive_price_in_journal(...)`, `has_plant_positive_harvest_reward_in_journal(...)`, `has_plant_positive_mature_duration_in_journal(...)`).
- **Garden Progression & Optional Gentle Guidance (Milestones 15 and 20)**:
  - `GardenProgressionStage` (`src/domain/progression/garden_progression_stage.gd`) and `GardenProgressionSummary` (`src/domain/progression/garden_progression_summary.gd`) implement pure deterministic progression evaluation across the five canonical stages from `GAME_DESIGN.md` Section 18 (`starting_garden`, `growing_garden`, `shady_garden`, `living_garden`, `happy_garden_home`) and the six low-pressure optional guidance prompts from `GAME_DESIGN.md` Section 20 (`guidance.plant_first`, `guidance.observe_visitor`, `guidance.place_decoration`, `guidance.create_water_habitat`, `guidance.discover_more`, `guidance.enjoy_garden`).
  - Progression is derived purely from `GardenSnapshot` and `JournalState` (with `GameSession.evaluate_progression_at(...)`, `GameSession.evaluate_progression_now(...)`, and `AppRoot.evaluate_progression_now()`), requiring zero save-schema changes (Save Schema V3 preserved).
  - In Milestone 20, `GardenView` (`src/presentation/garden/garden_view.gd`) surfaces the next-stage establishment progress (`อีก X แต้มสู่<ชื่อระดับถัดไป>` or `สูงสุดแล้ว` at `happy_garden_home`) in `ProgressionLabel` and exposes `get_next_progression_stage_id()` and `get_points_to_next_progression_stage()`.
- **Daily Guidance System ("วันนี้ทำอะไรดี", GAME_DESIGN.md Section 20)**:
  - `DailyGuidanceItem` (`src/domain/progression/daily_guidance_item.gd`) captures an immutable, non-punitive daily activity suggestion with stable ID, category, positive target count, and localized Thai text.
  - `DailyGuidanceEvaluator` (`src/domain/progression/daily_guidance_evaluator.gd`) deterministically derives exactly three distinct, non-punitive daily suggestions for a day index / UTC timestamp (`floor(now_utc_seconds / 86400)`), drawing across growth/harvest, visitor/event, and care/decoration/journal pools and adapting gently to current garden state (e.g. suggesting planting for an empty garden).
  - `GardenProgressionSummary` attaches the three daily suggestions (`get_daily_guidance_items()`, `get_daily_guidance_ids()`, `get_daily_guidance_count()`, `has_daily_guidance()`).
  - `GardenView` surfaces the three daily guidance suggestions in `DailyGuidanceLabel` (`กิจกรรมแนะนำวันนี้: 1. ... • 2. ... • 3. ...`) and exposes presentation queries (`get_daily_guidance_label()`, `get_daily_guidance_text()`, `has_daily_guidance()`, `get_daily_guidance_count()`, `get_daily_guidance_ids()`, `get_daily_guidance_display_texts()`, `get_daily_guidance_item(index)`), preserving Save Schema V3 and all existing stage/guidance contracts.
- **First-Time User Experience (FTUE) Sequence (GAME_DESIGN.md Section 21)**:
  - `FtueStep` (`src/domain/progression/ftue_step.gd`) models the immutable, non-punitive introductory guidance steps (`ftue.see_garden`, `ftue.watch_growth`, `ftue.harvest_plant`, `ftue.place_decoration`, `ftue.observe_visitor`, `ftue.check_journal`, `ftue.completed`) with step index (0..6), title, and localized Thai instruction.
  - `FtueEvaluator` (`src/domain/progression/ftue_evaluator.gd`) deterministically derives the active FTUE step from `GardenSnapshot`, `JournalState`, and `EconomyState.get_currency()`, guiding new players through the 8-stage sequence (see garden -> plant -> watch growth -> harvest -> place decoration -> observe visitor -> check journal -> completed) without intrusive modal popups.
  - `GardenProgressionSummary` attaches the active FTUE step (`get_ftue_step()`, `get_ftue_step_id()`, `get_ftue_step_index()`, `get_ftue_title()`, `get_ftue_instruction()`, `is_ftue_active()`, `is_ftue_completed()`, `has_ftue_step()`), preserving Save Schema V3 and all existing stage/guidance contracts.
  - `GardenView` surfaces the introductory hint in `FtueLabel` during active FTUE and gracefully hides it once FTUE completes or when startup is blocked, exposing presentation queries (`get_ftue_label()`, `get_ftue_text()`, `has_ftue_step()`, `is_ftue_active()`, `is_ftue_completed()`, `get_ftue_step_id()`, `get_ftue_step_index()`, `get_ftue_title()`, `get_ftue_instruction()`).

---

## 22. Persistence Architecture

**Status: LOCKED**

The MVP uses local on-device persistence.

### Save format

Use a versioned, inspectable data format composed only of explicit serializable primitives. **JSON is the active format.**

Do not serialize live scene trees or arbitrary Node graphs as the save contract.

#### Original Conceptual Shape (Historical / Non-Normative)

During early architectural planning, a conceptual save structure was outlined as follows:

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

This conceptual shape served to illustrate versioning and modular data groupings before persistence was implemented.

#### Current Implemented V3 Contract and V1/V2 Compatibility (Normative)

Persistence is implemented in the codebase via `GameStateCodec`, `LocalSaveRepository`, and `LocalSaveLoadResult`. As of Milestone 13, `CURRENT_SCHEMA_VERSION = 3`. The canonical V3 wire format is:

```json
{
  "schema_version": 3,
  "economy": {
    "currency": "250"
  },
  "plants": [
    {
      "instance_id": "plant-instance-a",
      "definition_id": "plant.holy_basil",
      "planted_at": "1700000000"
    }
  ],
  "discoveries": [
    {
      "definition_id": "plant.holy_basil",
      "first_seen_at": "1700000000",
      "times_seen": "1"
    },
    {
      "definition_id": "visitor.butterfly",
      "first_seen_at": "1700000300",
      "times_seen": "2"
    }
  ],
  "decorations": [
    {
      "instance_id": "decor-instance-a",
      "definition_id": "decoration.clay_jar",
      "placed_at": "1700000600"
    }
  ]
}
```

Legacy Schema V1 and V2 saves remain supported on decode through explicit sequential deterministic migration (`GameStateCodec.migrate_v1_to_v2(v1_snapshot)` followed by `GameStateCodec.migrate_v2_to_v3(v2_snapshot)`), which upgrades `schema_version` to `3` and initializes `"discoveries": []` (for V1) and `"decorations": []` (for V1/V2).

#### Int64 Wire Encoding Rule

Important: `currency`, `planted_at`, `first_seen_at`, `times_seen`, and `placed_at` are canonical non-negative decimal **strings** at the JSON wire boundary.

- Runtime/domain types remain `int` (signed 64-bit integer).
- Reason: Godot's built-in `JSON` parser represents numeric values as 64-bit floating-point numbers (`float`). A 64-bit IEEE-754 float cannot losslessly represent arbitrary signed 64-bit integers beyond $2^{53}$ (9,007,199,254,740,992). To avoid precision loss on large values up to `9223372036854775807`, persistent int64 domain values are encoded as exact decimal strings on the wire.
- These strings are persistence-wire encoding only; they are not domain-level string types.
- Canonical decimal string rules:
  - Exact ASCII decimal digits without leading zeros (except the single value `"0"`).
  - No explicit sign (`+` or `-`), no decimal point, and no scientific notation.
  - Valid wire examples: `"0"`, `"42"`, `"9007199254740993"`, `"9223372036854775807"`.
  - Invalid wire examples: `"01"` (leading zero), `"+1"` (explicit plus), `"-1"` (negative), `"1.0"` (float), `"1e3"` (exponent).

#### Strict V3 Validation Rules

The V3 codec enforces strict schema integrity:

- `CURRENT_SCHEMA_VERSION = 3` (with explicit `SCHEMA_VERSION_V1 = 1` and `SCHEMA_VERSION_V2 = 2` sequential auto-migration on `decode`).
- Root exact required keys (V3): `schema_version`, `economy`, `plants`, `discoveries`, `decorations`.
- Economy exact required key: `currency`.
- Plant exact required keys: `instance_id`, `definition_id`, `planted_at`.
- Discovery exact required keys: `definition_id`, `first_seen_at`, `times_seen` (`times_seen >= 1`, `definition_id` in `"plant."` or `"visitor."` namespace).
- Decoration exact required keys: `instance_id`, `definition_id`, `placed_at` (`definition_id` in `"decoration."` namespace, `placed_at >= 0`).
- Unexpected keys in root, economy, plant, discovery, or decoration objects: rejected.
- Unsupported schema versions (anything other than `1`, `2`, or `3`): rejected.
- Duplicate plant runtime `instance_id`, duplicate discovery `definition_id`, or duplicate decoration runtime `instance_id`: rejects the whole snapshot (atomic all-or-nothing decoding).
- Malformed required data: rejected.
- `ContentCatalog` existence validation: intentionally NOT placed in `GameStateCodec` (codec validates schema syntax and namespace prefixes only, keeping infrastructure persistence independent of the catalog; `PlantSaveContentValidator` validates saved plant, discovery, and decoration IDs against `ContentCatalog` at the startup boundary).
- Derived plant growth stage: not persisted (computed at runtime from `planted_at`).
- `PlantDefinition`, `VisitorDefinition`, and `DecorationDefinition` static data: not duplicated into save.

#### Local Storage File Layout

The on-device local storage contract uses four defined paths:

- **PRIMARY (`user://garden_save.json`)**: Active canonical save file.
- **TEMP (`user://garden_save.tmp`)**: Transient file used during safe write operations.
- **BACKUP (`user://garden_save.bak`)**: Last-known-good backup rotated from the preceding valid PRIMARY.
- **CORRUPT (`user://garden_save.corrupt`)**: Quarantine file for corrupt PRIMARY when a valid BACKUP exists.

Rules:
- `TEMP` and `CORRUPT` are **not** normal load candidates.
- Load authority hierarchy:
  - Valid `PRIMARY`
  - → otherwise valid `BACKUP`
  - → otherwise typed failure / `NO_SAVE` result.

#### Safe-Write Implementation Status

The save pipeline implements an application-level safe replacement strategy rather than relying on OS-level atomic filesystem transactions:

1. Encode authoritative `GameState` using `GameStateCodec.encode()`.
2. Write serialized JSON to `TEMP`.
3. Flush and close `TEMP`.
4. Read, parse, and decode `TEMP` via `GameStateCodec.decode()` to verify write integrity.
5. Inspect and validate existing `PRIMARY`.
6. Safe promotion/rotation:
   - **First save (no PRIMARY)**: promote `TEMP` → `PRIMARY`.
   - **Normal rotation (valid PRIMARY)**: rotate `PRIMARY` → `BACKUP`, promote `TEMP` → `PRIMARY` (with rollback `BACKUP` → `PRIMARY` if promotion fails).
   - **Corrupt PRIMARY with valid BACKUP**: quarantine `PRIMARY` → `CORRUPT`, promote `TEMP` → `PRIMARY`.
   - **Corrupt PRIMARY with missing/invalid BACKUP**: abort save to preserve potentially recoverable data.
7. PRIMARY is never directly truncated during ordinary save.

#### Load Outcomes and Startup Policy

`LocalSaveRepository.load()` returns a strongly-typed `LocalSaveLoadResult` with five possible statuses:

- `LOADED_PRIMARY`: Valid state loaded from primary save.
- `LOADED_BACKUP`: Valid state recovered from backup.
- `NO_SAVE`: No save files found (clean first run).
- `INVALID_DATA`: Files exist but contain corrupt or malformed data.
- `IO_ERROR`: Unrecoverable filesystem I/O error occurred.

#### Application Startup Content-Reference Validation (Task 6.4)

At the application startup boundary (`AppRoot.bootstrap_session()`), decoded saved `PlantState` references from `LOADED_PRIMARY` or `LOADED_BACKUP` are validated against the successfully loaded production `ContentCatalog` using `PlantSaveContentValidator`:

- **Distinction between structural validity and content compatibility**:
  - `GameStateCodec` V1 validates file and schema syntax independently of the content catalog.
  - `PlantSaveContentValidator` inspects whether each saved `PlantState.definition_id` exists in the current `ContentCatalog`.
  - An unknown saved definition ID is a **content compatibility failure**, not JSON corruption or malformed schema.
- **Preserve load-result truth**:
  - The persistence result remains `LOADED_PRIMARY` (or `LOADED_BACKUP`), reflecting true schema validity.
  - The content validation result (`PlantSaveContentValidationResult`) separately reports `UNKNOWN_PLANT_IDS` or `COMPATIBLE`.
- **Startup session mapping**:
  - `COMPATIBLE` (from `LOADED_PRIMARY` or `LOADED_BACKUP`) ⇒ Active `GameSession` constructed from the exact loaded `GameState`.
  - `UNKNOWN_PLANT_IDS` or `INVALID_INPUT` ⇒ Active session blocked (`game_session == null`).
  - `NO_SAVE` ⇒ Fresh in-memory `GameSession` constructed (validation result is null).
  - `INVALID_DATA` or `IO_ERROR` ⇒ Active session blocked (`game_session == null`, validation result is null).
- **Anti-data-loss and file preservation**:
  - If `PRIMARY` references an unknown plant ID, the app does NOT automatically fall back to `BACKUP` (which could discard newer player progress).
  - All save files on disk (`PRIMARY`, `BACKUP`, etc.) remain completely unchanged; no files are deleted, rewritten, or renamed.
  - No fallback `GameState` is created, and no unknown plants are stripped from memory.
  - Lifecycle pause persistence is safely suppressed via `LifecycleCoordinator`'s existing null-session gate (`SKIPPED_NO_ACTIVE_SESSION`).
- **Scope limitation**:
  - Validation occurs at the application startup boundary for loaded saves. It does not validate every internal write.
  - Future plant-creation gameplay commands must enforce catalog membership before creating new persistent `PlantState` instances.
  - Unknown saved IDs require future explicit migration or recovery workflows.

#### Presentation and Recovery UX Status (Milestones 6 and 8)

`INVALID_DATA`, `IO_ERROR`, and `UNKNOWN_PLANT_IDS` (along with content bootstrap failures `LOAD_FAILED` and `INVALID_DEFINITIONS`) are exposed through `AppRoot` startup queries (`get_content_bootstrap_status()`, `get_startup_load_result()`, and `get_saved_content_validation_result()`).

In Milestone 8:
- `MainScreen` (`res://src/presentation/app/main_screen.gd`) inspects `AppRoot` startup readiness and binds `GardenView` only when content is `READY` and an active `GameSession` exists.
- When startup is blocked, `MainScreen` maps the diagnostic state to a player-readable Thai message via `GardenView.show_blocked_startup(...)`, disables all planting controls (`PlantButton` and `PlantingPicker`), and performs no session creation or disk writes.
- Destructive or mutating recovery UI actions (such as "Reset Save", "Restore Backup", "Delete Save", or "Continue Anyway" buttons) remain intentionally out of scope through Milestone 8 to prevent accidental data loss.

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

#### Implementation Status (Milestones 12 and 13)

- **Deterministic V1 -> V2 migration**: `GameStateCodec.migrate_v1_to_v2(v1_snapshot: Variant) -> Variant` validates that `v1_snapshot` is a `Dictionary` with `schema_version == 1` and exact V1 root keys (`schema_version`, `economy`, `plants`), returning a new V2 `Dictionary` with `"schema_version": 2`, preserved `"economy"` and `"plants"`, and `"discoveries": []` without mutating the caller's input dictionary.
- **Deterministic V2 -> V3 migration**: `GameStateCodec.migrate_v2_to_v3(v2_snapshot: Variant) -> Variant` validates that `v2_snapshot` is a `Dictionary` with `schema_version == 2` and exact V2 root keys (`schema_version`, `economy`, `plants`, `discoveries`), returning a new V3 `Dictionary` with `"schema_version": 3`, preserved `"economy"`, `"plants"`, and `"discoveries"`, and `"decorations": []` without mutating the caller's input dictionary.
- **Automatic sequential decode upgrade**: `GameStateCodec.decode(snapshot)` transparently runs `migrate_v1_to_v2(snapshot)` (when `schema_version == 1`) and `migrate_v2_to_v3(...)` (when `schema_version == 2`) before validating and decoding into `GameState`. All subsequent `GameStateCodec.encode(state)` calls write Schema V3.

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

#### Implementation Status (Milestones 5, 7, 8, 9, and 10)

Milestone 5 implemented the foundational lifecycle pause checkpoint:
- `APPLICATION_PAUSED`: Persists authoritative `GameSession` state via `LifecycleCoordinator` upon mobile pause notifications.

Milestone 7 (Task 7.3) introduced the first approved gameplay mutation persistence boundary, and Milestone 8 connected it to confirmed touch presentation:
- **Successful logical planting checkpoint**: Following successful logical plant registration (`PlantRegistrationService.try_register_plant`), an immediate persistence checkpoint is attempted via `PlantingPersistenceCoordinator.try_plant_and_save()` delegating to `LocalSaveRepository.save(GameState)`.
- **Confirmed touch UI dispatch (Milestone 8)**: `PlantingPicker` requires explicit two-step confirmation before emitting `planting_requested(definition_id)` once; `GardenView` forwards the request to `MainScreen`, which invokes `AppRoot.try_plant_and_checkpoint(definition_id)` exactly once, renders typed feedback (`PlantingCheckpointResult`), and refreshes `GardenView` when `result.is_registered()` is true. Cancelling or closing the picker never triggers a save.
- **Order of operations**: Persistence is attempted strictly AFTER authoritative in-memory `GameState` insertion.
- **Separation of logical and durability statuses**: Logical planting success and persistence checkpoint success are reported as distinct typed outcomes via `PlantingCheckpointResult`:
  - `REGISTERED_SAVED`: In-memory registration succeeded and persistence checkpoint succeeded (durable write confirmed).
  - `REGISTERED_SAVE_FAILED`: In-memory registration succeeded but persistence checkpoint failed (`repository.save()` returned false). The authoritative in-memory plant remains registered (no unsafe rollback, deletion, or GameState replacement); durability is not claimed.
  - `PLANTING_REJECTED`: Logical planting failed; no persistence save is attempted.
  - `NOT_READY`: Preconditions or dependencies unmet; no planting or save attempted.
- **Successful logical harvest checkpoint (Milestone 10)**: Following a validated harvest (`PlantHarvestService.try_harvest_now`), `HarvestPersistenceCoordinator.try_harvest_and_save()` immediately checkpoints `GameState` via `LocalSaveRepository.save(GameState)` and returns a typed `HarvestCheckpointResult` (`HARVESTED_SAVED`, `HARVESTED_SAVE_FAILED`, `HARVEST_REJECTED`, or `NOT_READY`). Rejected harvests never call `repository.save()`.
- **Successful visitor observation & discovery checkpoint (Milestone 12)**: Following a successful visitor observation (`VisitorObservationPersistenceCoordinator.try_observe_visitor_and_save()`), the visitor sighting is recorded in `JournalState` and `GameState` is immediately checkpointed via `LocalSaveRepository.save(GameState)`, returning a typed `VisitorObservationCheckpointResult` (`OBSERVED_SAVED`, `OBSERVED_SAVE_FAILED`, `NO_ELIGIBLE_VISITORS`, `OBSERVATION_REJECTED`, or `NOT_READY`). When no visitors are eligible, zero state mutations and zero disk writes occur.
- **Successful decoration purchase & placement checkpoint (Milestone 13)**: Following a validated decoration purchase (`DecorationPurchasePersistenceCoordinator.try_purchase_and_checkpoint_now()`), `GameState` is immediately checkpointed in Save Schema V3 via `LocalSaveRepository.save(GameState)`, returning a typed `DecorationPurchaseCheckpointResult` (`PURCHASED_SAVED`, `PURCHASED_SAVE_FAILED`, `PURCHASE_REJECTED`, or `NOT_READY`). Rejected purchases never call `repository.save()`.
- **Independent boundaries**: Planting persistence checkpoints, harvest persistence checkpoints, visitor observation checkpoints, decoration purchase checkpoints, and lifecycle pause checkpoints are completely independent. A later approved checkpoint (such as `APPLICATION_PAUSED`) may persist the active in-memory state that remained unpersisted during a prior failed save.
- **Deferred gameplay features**: Seed purchasing and free-form placement coordinates remain out of scope through Milestone 13 and deferred to future tasks.

All other save triggers (after purchase, discovery, or debounced interval checkpoints) remain provisional and will only be introduced through explicit future tasks.

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

#### Implementation Status (Milestones 5, 9, and 16)

This section remains the **LOCKED** target architecture. Milestones 5, 9, and 16 implement the pause persistence checkpoint, centralized resume presentation refresh, and away-time return summary UX:

- **Currently implemented**:
  - Startup load and bootstrap (`AppRoot.bootstrap_session()`);
  - Pause persistence checkpoint (`LifecycleCoordinator.on_application_paused(game_session)`);
  - Duplicate-pause suppression (`IGNORED_DUPLICATE_PAUSE`);
  - Typed resume transition gating (`LifecycleCoordinator.on_application_resumed(game_session)` returning `ResumeOutcome.RESUMED`, `SKIPPED_NO_ACTIVE_SESSION`, or `IGNORED_NOT_PAUSED`, with `get_last_resume_outcome()`);
  - Corruption-safe null-session behavior (`SKIPPED_NO_ACTIVE_SESSION`);
  - Narrow application resume signal (`AppRoot.session_resumed`) emitted only on a genuine `PAUSED` -> `RESUMED` transition when both an active `GameSession` and `ContentCatalog` are ready;
  - Centralized presentation resume refresh (`MainScreen._on_app_session_resumed()` -> `GardenView.refresh_from_session()`), which samples `GameClock.utc_now_seconds()` once, recomputes plant growth stages via `PlantGrowth.stage_for_state_at(...)` (with negative elapsed times clamped to 0), evaluates the away-time `GardenReturnSummary` against the previous refresh timestamp without additional clock reads, preserves ephemeral plant selection, displays calm Thai return feedback (`GardenView.show_return_summary(...)`) when `return_summary.has_meaningful_changes()` is true, and performs zero disk reads or writes on resume.

- **Still NOT implemented**:
  - Persisted lifecycle/session timestamp (`saved_at_utc`);
  - Stateful domain mutations on resume (such as accumulated repeat-harvest cycles);
  - Presentation and audio pause policies.

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

#### Implementation Status (Milestones 7, 9, 16, and 18)

- **Timestamp-derived plant growth & remaining-time queries**: `PlantGrowth.stage_for_state_at(plant_state, definition, now_utc_seconds)` computes plant growth stages (`PLANTED`, `SPROUT`, `GROWING`, `MATURE`) directly from `now_utc_seconds - planted_at`, clamping negative elapsed intervals (`now_utc_seconds < planted_at`) to `0` so clock rollbacks never crash or corrupt state. In Milestone 18, `PlantGrowth.seconds_until_next_stage_for_elapsed(...)`, `PlantGrowth.seconds_until_mature_for_elapsed(...)`, `PlantGrowth.seconds_until_next_stage_at(...)`, and `PlantGrowth.seconds_until_mature_at(...)` compute remaining seconds to the next stage and to maturity in $O(1)$ time (`0` when `MATURE`, `-1` on invalid inputs), displayed in `GardenView`'s plant inspection details panel without per-frame timers.
- **Deterministic away-time return evaluation (Milestone 16)**:
  - `GardenReturnSummary` (`src/domain/progression/garden_return_summary.gd`) is an immutable domain value object capturing `_previous_utc_seconds`, `_current_utc_seconds`, clamped `_elapsed_seconds`, `_clock_rolled_back`, ascending `_advanced_plant_ids`, ascending `_newly_matured_plant_ids`, `_ready_to_harvest_count`, and previous/current `GardenTimePeriod` and `GardenWeather` states.
  - `GardenReturnEvaluator` (`src/application/progression/garden_return_evaluator.gd`), exposed via `GameSession.evaluate_return_between(...)`, `GameSession.evaluate_return_from_now(...)`, and `AppRoot.evaluate_return_from_now(previous_utc_seconds)`, computes `GardenReturnSummary` in a single pass with zero `GameState` mutations, zero disk writes, and zero RNG draws.
  - Clock rollbacks (`current_utc_seconds < previous_utc_seconds`) are explicitly flagged (`was_clock_rolled_back() == true`), clamp `elapsed_seconds` to `0`, and report zero advanced or newly matured plants.
  - In strict compliance with `GAME_DESIGN.md` Section 19, offline return evaluation never automatically records unobserved visitors in `JournalState`.

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

#### Implementation Status (Milestones 8, 9, 10, 11, 12, 13, 14, 15, 17, 19, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, and 40)

Milestone 8 establishes the initial portrait garden presentation hierarchy (extended in Milestone 10 with HUD currency display and selection harvest controls, in Milestone 11 with environmental trait summary and visitor observation controls, in Milestone 12 with the Garden Journal HUD row and modal `JournalPanel`, in Milestone 13 with the Decoration HUD row and modal `DecorationPicker`, in Milestone 14 with `AtmosphereLabel` and time/weather background tinting, in Milestone 15 with `ProgressionLabel` displaying garden stage and optional gentle guidance, in Milestone 17 with `ObserveEventButton` and expanded `JournalPanel` decoration/event sections, in Milestone 19 with rich catalog metadata, planted/placed counts, and read-only currency context in `PlantingPicker`, `DecorationPicker`, and the plant inspection panel, in Milestone 21 with harvest reward / maturity countdown badges in `PlantView` cards and plant trait clues / live planted counts in `JournalPanel`, in Milestone 22 with discovery badges `[พันธุ์ใหม่]` / `[ค้นพบแล้ว]` and confirmation details in `PlantingPicker`, confirmation trait summaries in `DecorationPicker`, and live visitor habitat eligibility status in `JournalPanel`, in Milestone 23 with placement discovery badges `[ของตกแต่งใหม่]` / `[จัดวางแล้ว]` and affordability/placement queries in `DecorationPicker`, environmental trait summaries in `PlantingPicker`'s confirmation prompt, and selected-plant / pending-harvest queries in `GardenView`, in Milestone 24 with environmental trait summaries and stage-aware visual accent colors on `PlantView` cards, planted/placed counts and discovery/affordability badges in `PlantingPicker` and `DecorationPicker` confirmation prompts, category ID queries in `JournalPanel`, and growing-plant / selected-plant detail queries in `GardenView`, in Milestone 25 with placed-decoration / active-event summary counts and complement category ID queries in `JournalPanel`, unplanted/planted status queries in `PlantingPicker`, and next-harvest countdown / live environmental-trait / placed-decoration queries in `GardenView`, in Milestone 26 with `seconds_until_next_stage` / `is_growing_stage()` on `PlantView`, per-entry sighting history and live planted species queries in `JournalPanel`, and next-stage transition countdown, per-stage plant IDs/counts, and planted-species snapshot queries in `GardenView`, in Milestone 27 with sprout/growing timing and species/instance count queries in `PlantingPicker`, placed-species / total-placed / affordable-count / coins-needed queries in `DecorationPicker`, unplanted-plant / undiscovered-count / total-sighting queries in `JournalPanel`, and definition-filtered plant IDs, distinct species counts, discovered entry count, and max-progression-stage queries in `GardenView`, in Milestone 28 with `is_mature_stage()` / trait membership / name label queries on `PlantView`, trait-filtered plant IDs and undiscovered/unplanted species counts in `PlantingPicker`, trait-filtered decoration IDs and unplaced/unaffordable counts in `DecorationPicker`, per-category sighting totals, complement counts, and full-discovery completion check in `JournalPanel`, and trait-filtered rendered plant IDs/counts, undiscovered entry count, and eligible visitor/event count queries in `GardenView`, in Milestone 29 with stage predicate queries (`is_planted_stage()`, `is_sprout_stage()`, `is_growing_phase_stage()`, `is_valid_stage()`) on `PlantView`, trait-filtered counts and catalog completion queries in `PlantingPicker` and `DecorationPicker`, per-category catalog count and completion queries in `JournalPanel`, and selected-plant / active-trait / present-definition / eligible-visitor-and-event membership queries in `GardenView`, in Milestone 30 with countdown/reward/trait presence queries (`has_any_environmental_traits()`, `has_harvest_reward()`, `has_countdown_to_mature()`, `has_countdown_to_next_stage()`) on `PlantView`, display-name / trait-count / planted-and-discovered presence queries in `PlantingPicker`, display-name / trait-count / placed-and-affordable / currency-context presence queries in `DecorationPicker`, per-category presence and full-visitor-eligibility queries in `JournalPanel`, and garden-wide presence / selected-plant-trait queries in `GardenView`, in Milestone 31 with bound-data presence queries (`has_runtime_instance_id()`, `has_definition_id()`, `has_display_name()`, `is_bound()`) on `PlantView`, catalog membership / complement presence / bound-context queries in `PlantingPicker` and `DecorationPicker`, complement presence and full-planted-species queries in `JournalPanel`, and selected-plant growing/trait-count queries, full-harvest-readiness, and active visitor/event/discovery presence queries in `GardenView`, in Milestone 32 with invalid-stage / planted-timestamp / known-definition / selection-highlight queries on `PlantView`, pending-selection detail queries in `PlantingPicker` and `DecorationPicker`, bound-context and per-category catalog membership queries in `JournalPanel`, and bound-dependency / summary-presence / open-modal queries in `GardenView`, in Milestone 33 with trait-count / known-trait / touch-button / subtitle-presence queries on `PlantView`, pending-plant display-name / traits / sprout-and-growing timing queries in `PlantingPicker`, pending-decoration display-name / traits / option-text queries in `DecorationPicker`, per-category catalog IDs / total instance counts / item-placed-and-planted predicates in `JournalPanel`, and open-modal / last-result presence / localized selected-plant-and-active-visitor-or-event display-name queries in `GardenView`, in Milestone 34 with rendered label-presence / localized trait display-name queries on `PlantView`, pending-plant trait-check / option-text / button-count / prompt-presence / traits-summary queries in `PlantingPicker`, button-count / prompt-presence / traits-summary / known-definition queries in `DecorationPicker`, localized per-category display-name / event-description / summary-presence queries in `JournalPanel`, and localized active-event-description / time-weather-progression-guidance display-name / selected-plant stage-predicate queries in `GardenView`, in Milestone 35 with localized plant/stage/bound-trait display-name queries on `PlantView`, known-definition / known-trait / localized trait display-name array / trait-presence queries in `PlantingPicker` and `DecorationPicker`, displayed-entry count / traits-summary / habitat-and-event clue / price-and-reward metadata queries in `JournalPanel`, and ID-based localized display-name / active-and-selected trait display-name array / eligible visitor-and-event display-name array queries in `GardenView`, in Milestone 36 with stage-based display-name / accent-color and bound-trait dictionary validation queries on `PlantView`, localized category display-name array and pending known-definition queries in `PlantingPicker` and `DecorationPicker`, sprout/growing timing and raw/localized trait array and membership queries in `JournalPanel`, and present plant/decoration display-name arrays, selected-plant stage display-name, and provisional dictionary membership queries in `GardenView`, in Milestone 37 with known/unknown bound trait ID arrays, known trait count, and stage-growing predicate on `PlantView`, trait-filtered localized display-name arrays and pending catalog/reward/duration/price/unaffordability predicates in `PlantingPicker` and `DecorationPicker`, trait count/presence and per-category localized display-name array queries in `JournalPanel`, and known plant/decoration definition checks, per-category catalog membership checks, and selected-plant accent-color / countdown / reward presence queries in `GardenView`, in Milestone 38 with unknown bound trait count/presence, known bound trait display-name array, and stage-valid/mature predicates on `PlantView`, pending complement/duration/summary predicates in `PlantingPicker` and `DecorationPicker`, complement category localized display-name array queries in `JournalPanel`, and bound-catalog category counts, ID arrays, and full-species-presence predicates in `GardenView`, in Milestone 39 with unknown bound trait display-name array and stage-planted/sprout/growing-phase/invalid predicates on `PlantView`, ID-based and pending option-text/display-name/traits-summary/price/coins-needed predicates in `PlantingPicker` and `DecorationPicker`, trait-filtered plant and decoration ID/count/presence/display-name queries in `JournalPanel`, and bound-catalog localized display-name arrays and unplanted/unplaced catalog species ID/count/presence queries in `GardenView`, and in Milestone 40 with provisional dictionary key/count/display-name-presence queries on `PlantView`, ID-based reward/duration/undiscovered/unplanted/unplaced/unaffordability and button/currency presence predicates in `PlantingPicker` and `DecorationPicker`, ID-based display-name/description/summary/clue/price/reward/duration presence predicates in `JournalPanel`, and unplanted/unplaced catalog display-name arrays and ineligible catalog visitor/event ID/count/presence/display-name queries in `GardenView`):

```text
Main (res://scenes/app/main.tscn — MainScreen)
└── GardenView (res://scenes/garden/garden_view.tscn — GardenView)
    ├── HeaderArea (TitleLabel, PlantButton, RefreshButton)
    ├── CurrencyLabel (Authoritative Coin HUD display)
    ├── ProgressionLabel (Derived GardenProgressionStage & Optional Gentle Guidance HUD)
    ├── AtmosphereLabel (Derived Time-of-Day, Weather, and Active Ambient Events HUD)
    ├── EnvironmentLabel (Derived GardenSnapshot trait summary)
    ├── VisitorRow (VisitorStatusLabel + ObserveVisitorButton + ObserveEventButton)
    ├── JournalRow (JournalStatusLabel + JournalButton)
    ├── DecorationRow (DecorationStatusLabel + DecorateButton)
    ├── FeedbackArea (FeedbackLabel)
    ├── ContentArea
    │   ├── PlantsScroll -> PlantsContainer (GridContainer of PlantView instances)
    │   ├── EmptyStateContainer
    │   └── BlockedStateContainer
    ├── DetailsArea (Selection inspection panel + DetailRewardLabel + HarvestButton)
    ├── PlantingPicker (res://scenes/garden/planting_picker.tscn — PlantingPicker)
    │   ├── PickerPanel (Catalog plant option buttons)
    │   └── ConfirmationOverlay (Explicit Confirm / Cancel dialog)
    ├── DecorationPicker (res://scenes/garden/decoration_picker.tscn — DecorationPicker)
    │   ├── PickerPanel (Catalog decoration shop buttons with price, traits, and owned count)
    │   └── ConfirmationOverlay (Explicit Confirm / Cancel purchase dialog)
    └── JournalPanel (res://scenes/garden/journal_panel.tscn — JournalPanel)
        └── JournalModalPanel (SummaryLabel, ScrollContainer -> EntriesContainer, CloseButton)
```

- `MainScreen` (`src/presentation/app/main_screen.gd`) acts as a thin composition adapter binding `AppRoot` (`game_session`, `content_catalog`, `game_clock`, and `session_resumed`) into `GardenView`, and supports `bind_app_root(app)` for isolated test injection without global Autoload coupling.
- `GardenView` (`src/presentation/garden/garden_view.gd`), `PlantView` (`src/presentation/garden/plant_view.gd`), and `PlantingPicker` (`src/presentation/garden/planting_picker.gd`) receive dependencies explicitly (`bind_garden`, `bind_plant_data`, `bind_catalog`) and never own, duplicate, or directly mutate `GameState`.
- Responsive portrait sizing accommodates narrow portrait viewports (such as `720x1600`) as well as the `1080x1920` reference canvas without control clipping.

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

#### Implementation Status (Milestones 8, 9, 10, and 11)

- **Controlled snapshot refresh**: `GardenView.refresh_from_session()` reads `GameSession.get_currency()` for `CurrencyLabel`, reads `GameSession.get_state().get_plants().get_all_plants()` in deterministic `runtime_instance_id` order, samples `GameClock.utc_now_seconds()` **once** per refresh, computes each plant's stage via `PlantGrowth.stage_for_state_at(plant_state, definition, now_utc)`, and derives the garden's environmental traits and eligible visitors via `GardenSnapshotBuilder.build_snapshot(...)` and `VisitorEligibility.filter_eligible_visitors(...)` using the same `now_utc` sample without consuming RNG.
- **No per-frame polling**: Neither `GardenView`, `PlantView`, nor `PlantingPicker` runs `_process`, `_physics_process`, or per-plant `Timer` nodes for growth progression.
- **Ephemeral selection**: `GardenView` tracks selected `runtime_instance_id` purely in presentation memory, preserving selection across refreshes if the plant still exists and clearing it safely otherwise.
- **Narrow command & lifecycle signals**:
  - `PlantingPicker` emits `planting_requested(definition_id)` only upon confirmed touch input (guarded against duplicate confirmation dispatch), which `GardenView` forwards to `MainScreen` to execute `AppRoot.try_plant_and_checkpoint(definition_id)` and trigger `refresh_from_session()`.
  - `GardenView` enables `HarvestButton` only when the selected plant's derived stage is `PlantGrowth.Stage.MATURE` and `definition.harvest_reward > 0`, emitting `harvest_requested(runtime_instance_id)` to `MainScreen` to execute `AppRoot.try_harvest_and_checkpoint(runtime_instance_id)`, render `HarvestCheckpointResult` feedback, and trigger `refresh_from_session()` when `result.is_harvested()` is true.
  - `GardenView` enables `ObserveVisitorButton` only when at least one visitor is eligible in the current `GardenSnapshot`, emitting `visitor_observation_requested()` to `MainScreen` to execute `AppRoot.try_observe_visitor_and_checkpoint()`, display visitor observation and journal discovery feedback via `GardenView.show_visitor_observation_result(result)`, and trigger `refresh_from_session()` when `result.is_observed()` is true.
  - `GardenView` enables `ObserveEventButton` only when at least one ambient/special event is eligible in the current `GardenSnapshot`, emitting `event_observation_requested()` to `MainScreen` to execute `AppRoot.evaluate_event_now()` and display calm Thai ambient event feedback via `GardenView.show_event_result(result)` with zero disk writes (Save Schema V3 preserved).
  - `AppRoot` emits `session_resumed()` only when `LifecycleCoordinator.on_application_resumed(game_session)` reports `ResumeOutcome.RESUMED` and both `GameSession` and `ContentCatalog` are ready; `MainScreen` listens to `session_resumed` and calls `GardenView.refresh_from_session()` once per genuine pause-to-resume transition.

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
