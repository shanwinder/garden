# Garden — Agent Instructions (`AGENTS.md`)

This file orients AI coding agents working in `/Applications/garden`. It **references** the repository's authoritative documents without duplicating or modifying their rules.

## 1. Document Authority & Precedence

Follow the precedence defined in `PROJECT_RULES.md` §2 (`VISUAL_STYLE_BIBLE.md` §1 and `ASSET_PIPELINE.md` §0 are subordinate to the core project documents):

1. Explicit instruction from the project owner in the current task.
2. [`PROJECT_RULES.md`](./PROJECT_RULES.md) — non-negotiable engineering, Git, scope, and stop rules.
3. [`ARCHITECTURE.md`](./ARCHITECTURE.md) — stack, layering, state ownership, time/RNG, persistence, lifecycle.
4. [`GAME_DESIGN.md`](./GAME_DESIGN.md) — player promise, design pillars, MVP scope, LOCKED/PROVISIONAL/TBD status.
5. [`DEFINITION_OF_DONE.md`](./DEFINITION_OF_DONE.md) — objective quality gates and canonical verification commands.
6. [`VISUAL_STYLE_BIBLE.md`](./VISUAL_STYLE_BIBLE.md) & [`VISUAL_MOCKUP_PLAN.md`](./VISUAL_MOCKUP_PLAN.md) — Owner-approved Master Style.
7. [`ASSET_PIPELINE.md`](./ASSET_PIPELINE.md) & [`ASSET_PIPELINE_SPIKE_REPORT.md`](./ASSET_PIPELINE_SPIKE_REPORT.md) — 2D asset contract and spike evidence.

When a real conflict or a task-blocking **TBD** decision is encountered, **stop and ask the owner** rather than guessing.

## 2. Non-Negotiable Technical & Design Guardrails

- **Engine & Renderer:** **Godot 4.7.2 Stable** (`4.7.2.stable.official.ed1daf0bf`), **GDScript** with static typing in core code (no C#/.NET), **2D GL Compatibility renderer** (`project.godot`).
- **Platform & Orientation:** **Android-first portrait** (`1080 × 1920` reference canvas), touch-first (never rely on hover, right-click, or mouse-only input), offline-first (no backend, accounts, cloud save, analytics, or ads).
- **Single Authoritative State:** `GameSession` owns the sole authoritative `GameState`. `App` (`src/application/app_root.gd`) is the single composition root / autoload. Scene, UI, and animation nodes are views/controllers only and must never hold competing authoritative state.
- **Layer Separation:** Keep strict boundaries across `src/domain/`, `src/application/`, `src/infrastructure/`, `src/presentation/`, and `content/` (`.tres` definitions identified by `StableContentId`, localized via `GardenLocalization`). Never query the SceneTree as domain logic.
- **Deterministic Time & Randomness:** Domain/application logic must receive timestamps/RNG explicitly via `GameClock` and `RandomSource` (and `FakeGameClock` / `FakeRandomSource` in tests). Plant growth (`PlantGrowth`) and weather/progression are timestamp-derived ($O(1)$, negative elapsed time clamped to 0). Never add per-plant `Timer`s or `_process` polling loops.
- **Versioned Persistence:** Preserve the JSON Save Schema V3 contract (`GameStateCodec`, `LocalSaveRepository`), exact decimal-string int64 wire encoding, sequential migrations (`v1 -> v2 -> v3`), and safe write rotation. Never silently break saves or reset progress.
- **Master Visual Style & Asset Contract:** Preserve the Owner-approved **Balanced Storybook Hybrid** (gouache clarity on gameplay entities + watercolor atmospheric softness; everyday Thai home-garden grounding; no pixel art, no heavy black comic outlines, no glossy 3D, no chibi mascots). Follow `ASSET_PIPELINE.md` (1:1 `1080 × 1920` PNG exports, straight alpha sRGB, bottom-center Option A pivot for grounded sprites, `CanvasItem` Linear filtering, committed `.import` sidecars, no unapproved `assets/` clutter).
- **No Unapproved Dependencies or Architecture Drift:** Do not add third-party Godot addons/plugins, extra autoloads, or architectural changes without explicit owner approval (`PROJECT_RULES.md` §3, §9; `ARCHITECTURE.md` §38, §46).

## 3. Project-Scoped Agent Skills (`.agents/skills/`)

Eight project-scoped skills from `awesome-gamedev-agent-skills` are installed under `.agents/skills/` (`router`, `create-game-assets`, `godot-gdscript`, `godot-resources`, `godot-animation`, `godot-gdscript-headless-testing`, `godot-ui-control`, `game-ui-ux`; see `.agents/attribution/`).

**Garden's authoritative documents always override generic skill defaults:**

- **`create-game-assets`:** Ignore generic `64×64` pixel-art / `nearest`-filter examples in its templates (`assets/asset-manifest.json`). Use Garden's `VISUAL_STYLE_BIBLE.md` + `ASSET_PIPELINE.md` (Linear filtering, Lossless provisional baseline, 4 px transparent gutter, 1:1 canvas scale). Never auto-write uncurated generation outputs into `assets/`.
- **`godot-ui-control` & `game-ui-ux`:** Ignore `1920×1080` landscape defaults and `tr()` localization assumptions. Garden targets **1080×1920 portrait**, touch-first interaction, and centralized `GardenLocalization` (`"th"` / `"en"`). Inspect `project.godot` before assuming `window/stretch/*` settings.
- **`godot-gdscript`, `godot-resources`, `godot-animation`, `godot-gdscript-headless-testing`:** Note that `godot-nodes-scenes` is not installed locally (skip references to `../godot-nodes-scenes/scripts/check_godot_project.py`). Use `res://tests/run_tests.gd` instead of creating a parallel test runner.

## 4. Canonical Verification & Git Discipline

- Run canonical checks from `DEFINITION_OF_DONE.md` §44 before reporting completion:
  - `godot --version`
  - `godot --headless --import --log-file ./.godot/headless.log`
  - `godot --headless --path . --script res://tests/run_tests.gd --log-file ./.godot/headless.log`
  - `godot --headless --path . --quit-after 2 --verbose --log-file ./.godot/headless.log`
  - `git diff --check`
- Never delete, skip, or weaken tests to force a green run (`PROJECT_RULES.md` §13).
- Do not modify `main` directly, force-push, or commit/push/merge without explicit owner authorization (`PROJECT_RULES.md` §15; `DEFINITION_OF_DONE.md` §21).
