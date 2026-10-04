# Garden Asset Technical Pipeline

> Status: **Authoritative Asset Technical Pipeline — Milestone 4 (Task 4.4B Spike Decisions Recorded)**
>
> Engine: Godot 4.7.2.stable.official.ed1daf0bf
>
> Target: Android Portrait (1080 × 1920 Reference Canvas)
>
> Renderer: GL Compatibility 2D

---

## 0. Document Authority

This document governs **TECHNICAL ART-ASSET PRODUCTION** and integration.

Precedence remains:

```
PROJECT_RULES.md
    >
ARCHITECTURE.md
    >
GAME_DESIGN.md
    >
approved visual direction / VISUAL_STYLE_BIBLE.md
    >
ASSET_PIPELINE.md
```

`ASSET_PIPELINE.md` must not redefine gameplay or approved visual intent.

This document is subordinate to all of the above. Where a technical decision
made here conflicts with a higher-authority document, the higher-authority
document prevails and this document must be updated.

---

## 1. Decision Status Legend

The baseline pipeline status model distinguishes three core categories:

**LOCKED TECHNICAL PIPELINE** — technically mandated by architecture,
approved visual direction, or strong project-specific reasoning. May only be
changed with explicit owner review and update to this document.

**PROVISIONAL TECHNICAL PIPELINE** — current preferred technical approach,
suitable for initial production and vertical-slice work, subject to refinement
with real asset and device evidence.

**TBD / REQUIRES EMPIRICAL VALIDATION** — intentionally undecided; requires
real production assets, profiling, or device testing before a responsible
decision can be made. Do not invent a permanent answer.

### 1.1 Evidence Qualification Suffixes

Where empirical evidence from technical spikes has been gathered, the status is
qualified by one of the following evidence qualifiers:

- **MECHANICALLY VALIDATED — Task 4.4A**: Verified through configuration,
  resource structure, scene serialization, geometry, or build execution in the
  local Godot engine environment.
- **DEVICE VALIDATION REQUIRED**: Requires observation, profiling, or visual
  inspection on authorized representative physical Android hardware.
- **UNVERIFIED — RENDERED VISUAL EVIDENCE REQUIRED**: Direct rendered visual
  comparison was not captured in the headless terminal environment (due to the
  Dummy Rendering Server); requires rendered visual capture or on-device review.

### 1.2 Empirical Validation Record (Task 4.4A Spike)

- **Authoritative Evidence Document:** `ASSET_PIPELINE_SPIKE_REPORT.md`
- **Overall Spike Result:**
  `PARTIAL — local/import/build validation completed; device-dependent evidence remains unavailable`
- **Validated Environment:**
  - Godot Engine: `4.7.2.stable.official.ed1daf0bf`
  - Renderer: GL Compatibility 2D
  - Reference Canvas: 1080 × 1920 Portrait
  - Export Target: Android Debug APK (apksigner verified v2/v3)
- **Scope Distinction:**
  - *Mechanically Validated:* Import mode mapping, Lossless and VRAM import
    configuration, mipmap math and cache growth, bottom-center pivot Option A,
    animation frame bounds and anchor registration, CanvasItem filter
    configuration locus, and Android debug export/signing.
  - *Visually / Device Unverified:* Rendered visual quality comparison of
    Linear vs Nearest, on-device ETC2 visual artifact acceptability, actual
    Android GPU residency, real frame timing, animation pacing/feel, battery
    behavior, and total scene texture-memory budget.

---

## 2. Pipeline Overview

The complete conceptual production flow:

```
Visual Reference / Approved Style (VISUAL_STYLE_BIBLE.md)
        ↓
Production Source Master
  (editable, high-resolution layered file authored by artist)
        ↓
Runtime Export
  (flattened PNG ready for Godot import; per naming contract)
        ↓
Godot Import
  (automatic import at file placement; .import metadata generated)
        ↓
Scene / Resource Integration
  (Sprite2D, AnimatedSprite2D, SpriteFrames, AtlasTexture references)
        ↓
Android Device Validation
  (visual scale, alpha edge quality, filtering, memory, performance)
        ↓
Production Approval
  (asset acceptance checklist passed; committed to repository)
```

### 2.1 Responsibility at Each Boundary

| Boundary | Responsible Party | Key Contract |
|---|---|---|
| Visual Reference → Source Master | Artist | Must satisfy VISUAL_STYLE_BIBLE.md qualitative direction |
| Source Master → Runtime Export | Artist | Correct dimensions, transparent bounds, clean alpha, sRGB PNG |
| Runtime Export → Godot Import | Developer + pipeline rules | Correct import settings per category (compression, mipmaps, process options) |
| Scene Integration | Developer | Correct pivot, Linear texture filter, no arbitrary corrective scale, stable anchor |
| Android Validation | Developer + Artist | Confirmed visual quality on device at reference canvas scale |
| Production Approval | Both | Acceptance checklist complete; committed file only |

---

## 3. Source Master vs Runtime Export

**Status: LOCKED TECHNICAL PIPELINE (boundary principle) / PROVISIONAL TECHNICAL PIPELINE (storage location)**

### 3.1 Definitions

**SOURCE MASTER**

The editable working file created by the artist. May contain:

- Higher base resolution (e.g., 2× or 4× final export dimension for retouching headroom)
- Layers, groups, and masks
- Working color data (e.g., Krita `.kra`, Photoshop `.psd`, Aseprite `.ase` layered)
- Editable brush structure and paint history
- Reference or annotation layers that are not exported

Source masters are **authoring tools**, not runtime game files.

**RUNTIME EXPORT**

The flattened, merged, correctly sized file delivered to Godot. Must contain:

- Only pixels the game needs
- Correct final dimensions per naming and sizing contract
- Clean RGBA, straight alpha, sRGB color
- No layer structure, no unused regions, no embedded ICC profile beyond sRGB

The runtime export is the file that lives inside the Godot project tree and
is tracked in Git.

### 3.2 Source Master Storage Policy

**PROVISIONAL TECHNICAL PIPELINE**

Files placed under the Godot project root participate in the project's
filesystem and resource workflow; recognized importable asset types are scanned
and imported. Editable source-master directories that should not participate in
that workflow should preferably remain outside the project root.

**Preferred Policy (Subject to Owner Decision):**

Editable source masters (`.kra`, `.psd`, `.ase`, `.xcf`) should normally live
**outside** the Godot project root.

Examples:
- External art repository
- External cloud storage or NAS
- Sibling non-Godot art workspace (e.g., `garden-art-sources/` adjacent to the project directory)

The game repository contains runtime exports (clean PNGs), not large working masters.
This keeps clone sizes small and prevents authoring clutter from entering the
project resource tree.

**Alternative: Same-Repository Tracked Source Masters (Owner Option):**

If the project owner later intentionally chooses to keep editable source masters
inside the **same** Git repository and within the Godot project tree:

```
art_sources/
    .gdignore
    ...
```

To make this technically coherent:
- An empty `.gdignore` file placed inside `art_sources/` tells Godot to completely
  ignore that directory and its contents during project resource scanning,
  import flows, and FileSystem dock indexing (per official Godot 4.7 documentation).
- **Distinguish `.gitignore` vs `.gdignore`:**
  - `.gitignore` controls **Git tracking** only. It does not affect Godot's
    internal import or resource scanning behavior. If source masters are intended
    to be tracked in Git, adding them to `.gitignore` would contradict that goal.
    `.gitignore` is only appropriate if source masters should NOT be tracked in Git.
  - `.gdignore` controls **Godot scanning and import visibility** for a directory.
    It has no effect on Git version control.

> **OWNER DECISION REQUIRED:** The final source-master storage and backup
> strategy requires explicit owner decision before production begins.
> Options: (A) entirely separate repository/cloud storage for source masters (preferred);
> (B) tracked `art_sources/` directory in this repository with `.gdignore` to prevent Godot scanning;
> (C) external NAS/cloud with runtime exports only in this repository.
> Git LFS is not introduced in Task 4.3.

### 3.3 Git LFS Policy

**LOCKED TECHNICAL PIPELINE (for Task 4.3 scope)**

Git LFS is **not** part of the repository baseline for Task 4.3. Do not
introduce it in this task. Large binary source masters must not be casually
committed to the repository in their current form until a storage strategy is
approved. See Section 28 (Version-Control Policy) for commit rules.

---

## 4. Runtime Directory Taxonomy

**Status: LOCKED TECHNICAL PIPELINE (structure); PROVISIONAL (per-entity subdirectory depth)**

Runtime assets live under `assets/` in the Godot project root.

```
assets/
├── environment/
│   ├── background/          # Sky, house-wall panels, fence, ground layers
│   ├── ground/              # Soil/paver/earth tileable patches
│   └── foreground/          # Framing leaf silhouettes, border elements
│
├── plants/
│   ├── holy_basil/          # holy_basil_planted.png, holy_basil_sprout.png, etc.
│   ├── marigold/
│   ├── chili/
│   ├── jasmine/
│   └── banana/
│
├── visitors/
│   ├── cat/                 # cat_idle_00.png, cat_sleep_00.png, etc.
│   ├── butterfly/
│   ├── bird/
│   ├── frog/
│   └── firefly/
│
├── decorations/
│   ├── clay_jar/
│   ├── bench/
│   ├── garden_lamp/
│   ├── watering_can/
│   ├── fence/
│   ├── plant_pot/
│   ├── small_table/
│   └── small_pond/
│
├── ui/
│   ├── icons/               # Raster icons for tabs, actions
│   ├── panels/              # Panel texture patches, 9-slice sources
│   └── effects/             # Harvest feedback sprites, UI particles
│
└── effects/
    ├── rain/                # Rain streak texture, splash sprites
    ├── firefly/             # Firefly point sprite
    └── particles/           # Shared particle textures
```

**Rules:**

- Each entity directory contains only files for that entity. No cross-entity
  sharing of source files; shared components (e.g., a generic soil patch) live
  in the category most relevant.
- Do not create these directories now. Add directories when their first real
  runtime export is introduced.
- The directory names above align with stable content IDs in `ARCHITECTURE.md`
  §10 (e.g., `plant.holy_basil` → `assets/plants/holy_basil/`).

---

## 5. Naming Contract

**Status: LOCKED TECHNICAL PIPELINE**

### 5.1 General Rules

- All filenames: **lowercase, snake_case, ASCII only**
- No spaces, no dots other than the extension separator
- No version suffixes in committed production files (e.g., `_v2`, `_final`)
- Align with stable content IDs without blindly embedding every dot

### 5.2 Single-Frame Static Sprites

```
{entity}_{state}.png

Examples:
  holy_basil_planted.png
  holy_basil_sprout.png
  holy_basil_growing.png
  holy_basil_mature.png
  clay_jar_idle.png
  bench_idle.png
  garden_lamp_off.png
  garden_lamp_on.png
```

### 5.3 Animation Frame Sequences

```
{entity}_{animation}_{nn}.png     (zero-padded, starting at 00)

Examples:
  cat_idle_00.png
  cat_idle_01.png
  cat_idle_02.png
  cat_sleep_00.png
  butterfly_flutter_00.png
  butterfly_flutter_01.png
  butterfly_rest_00.png
```

Frame count padding uses two digits for sequences up to 99 frames; extend to
three digits (`_000`) only if a sequence genuinely exceeds 99 frames.

### 5.4 Variant Suffixes

When a meaningful visual variant is required:

```
{entity}_{state}_{variant}.png

Examples (hypothetical day/night only if separate art is justified):
  garden_lamp_on_night.png      # only if a genuine art variant is needed

Examples (weather wet state):
  bench_idle_wet.png            # only if a genuine wet art variant is justified
```

Variants should be avoided by default. Prefer runtime modulation (shader,
CanvasModulate, color adjustment) over duplicate sprite sets. See Section 14
(Lighting-Neutral Base Art).

### 5.5 Directional Suffixes

Directional variants are not currently expected for this project. If future
gameplay requires them:

```
{entity}_{animation}_{direction}_{nn}.png

Direction tokens: _r (right), _l (left), _u (up), _d (down)

Example:
  cat_walk_r_00.png
```

Define directional suffix policy in a future task when directional movement
is confirmed in the design.

### 5.6 UI Asset Naming

```
{context}_{purpose}.png

Examples:
  icon_plant.png
  icon_journal.png
  icon_shop.png
  panel_card_base.png
  panel_dialog_top.png
```

### 5.7 Environment / Background Naming

```
{layer}_{description}.png

Examples:
  bg_house_wall.png
  bg_fence_wide.png
  ground_soil_patch.png
  ground_gravel_tile.png
  fg_leaf_top_left.png
```

### 5.8 Effect Naming

```
effect_{type}_{description}.png

Examples:
  effect_rain_streak.png
  effect_ripple_00.png
  effect_firefly_glow.png
  effect_harvest_dust_00.png
```

---

## 6. Reference-Canvas Scale Contract

**Status: LOCKED TECHNICAL PIPELINE — MECHANICALLY VALIDATED (Task 4.4A)**

### 6.1 Architecture Constraints (Already Locked)

From `ARCHITECTURE.md` §3 and §30:

- Reference design canvas: **1080 × 1920** portrait
- Renderer: **GL Compatibility 2D**
- `project.godot` viewport: `1080 × 1920`
- Godot stretch mode will scale to real device resolution

From `project.godot` (verified):
```
window/size/viewport_width=1080
window/size/viewport_height=1920
window/handheld/orientation=1
```

### 6.2 Coordinate System

In Godot's Compatibility 2D renderer, one Godot canvas pixel corresponds
directly to one logical viewport pixel. The viewport is `1080 × 1920`.

The canonical scale approach for this project:

**Author runtime exports at 1:1 with intended on-canvas pixel size.**

A sprite that should appear 200 × 400 px on the 1080 × 1920 reference canvas
is exported at 200 × 400 px. Its `Sprite2D` node uses `scale = Vector2(1, 1)`.

**Task 4.4A Empirical Validation:**
The 1:1 authored/export/display principle was mechanically validated on
representative reference-size subjects:
- 1080 × 1920 background (`full_canvas_background.png`) placed at `(540, 960)`
  displayed at `scale = Vector2(1, 1)`, covering the canvas exactly.
- Grounded pivot diagnostic sprites (512 × 512) displayed at `scale = Vector2(1, 1)`.
- Fine foliage diagnostic sprites (512 × 512) displayed at `scale = Vector2(1, 1)`.
- Animation diagnostic sequence (256 × 256) displayed at `scale = Vector2(1, 1)`.

### 6.3 Why No Separate PPU Concept Is Needed

The Unity "Pixels Per Unit" (PPU) concept is a 2D-in-3D coordinate bridge
that maps sprite pixels to Unity's 3D world-unit space. Godot's 2D rendering
does not use 3D world units for 2D sprites; canvas coordinates map directly.
Introducing a PPU abstraction here would add conceptual overhead without
benefit for a pure 2D game at a fixed logical canvas size.

### 6.4 Godot Import Scale

The Godot texture import setting `svg/scale` applies to SVG files only.
For PNG/WebP raster imports, the physical pixel size of the file IS the
canvas-pixel size when displayed at `scale = Vector2(1, 1)`.

**Do not** use the Godot import `scale` setting to compensate for incorrectly
sized source exports.

### 6.5 Stretch / Responsive Handling

Real devices will vary from the 9:16 reference ratio. Godot's stretch
settings (set in `project.godot` by a future scene/layout task) will handle
this. Asset authors do not need to target multiple resolutions; they target
the 1080 × 1920 logical canvas.

### 6.6 What Is Forbidden

The pipeline must not allow:

- Sprite2D nodes with compensatory `scale` values such as `(0.35, 0.35)` or
  `(2.5, 2.5)` becoming the normal production workflow
- Different artists exporting sprites at wildly different reference sizes that
  only look correct when hand-scaled per node
- Artists adding scale values to `.tscn` files as a substitute for correct
  export dimensions

The canonical on-canvas pixel size must be expressed at the export step,
not by per-node scale corrections.

**Diagnostic Fixture Layout Exception (Task 4.4A):**
In the Task 4.4A technical spike scene, two 1024 × 1024 gradient comparison
sprites (`GradientLossless` and `GradientVRAM`) intentionally used
`scale = Vector2(0.45, 0.45)` solely to fit side-by-side within the 1080 px
diagnostic comparison fixture. This layout scaling was specific to the technical
test fixture; it does NOT constitute an asset-corrective production scale and
does not invalidate the 1:1 production principle. Arbitrary corrective scale
for production game assets remains strictly forbidden.

---

## 7. Asset Scale Normalization

**Status: PROVISIONAL TECHNICAL PIPELINE (methodology); TBD (exact per-asset dimensions)**

### 7.1 Definitions

**SOURCE SCALE:** The resolution at which the artist paints the source master.
Artists are encouraged to work at 2× or higher relative to the final export
if it helps painting quality, then downsample cleanly during export.

**RUNTIME EXPORT SCALE:** The final pixel dimensions of the PNG committed to
the repository. This is the 1:1 canvas-pixel representation.

**REFERENCE-CANVAS DISPLAY SCALE:** The visual footprint on the 1080 × 1920
logical canvas. For a sprite at `scale = Vector2(1, 1)`, this equals the
runtime export dimensions.

### 7.2 Sizing Methodology

Production artists determine intended on-screen size using the visual scale
matrix in `VISUAL_STYLE_BIBLE.md` §7.1 as the starting reference:

| Entity Category | Approximate Stage Height (% of 1920px) | Approximate px on canvas |
|---|---|---|
| Mature herb (holy basil) | ~12–16% | ~230–307 px height |
| Mature flower (marigold) | ~15–20% | ~288–384 px height |
| Sprout / seedling | ~4–7% | ~77–134 px height |
| Planted mound | ~2–4% | ~38–77 px height |
| Cat sitting | ~10–13% | ~192–250 px height |
| Butterfly | ~3–5% (reference) | TBD (calibrated in spike; naturally small) |
| Clay water jar | ~18–22% | ~346–422 px height |
| Garden bench | ~15–18% height, ~25% width | ~288–346 px H / ~270 px W |

These are **reference calibration ranges only**, derived from the validated
relative scale matrix. They are not locked pixel specifications.

### 7.3 Calibration Process

Before production assets are final:

1. Artist exports a **calibration sprite** at the proposed dimensions.
2. Developer places the sprite in the Godot scene at `scale = Vector2(1, 1)`.
3. Scene is tested at 1080 × 1920 in the Godot editor.
4. Adjust export dimensions if visual weight is wrong; do NOT adjust via node
   `scale`.
5. Record the approved export dimensions in the per-entity art spec (a future
   document, created when vertical-slice production begins).

### 7.4 Avoiding Scale Drift

To prevent drift between species:

- All plant species share the same stage-suffix conventions.
- Sprout height ranges are validated against each other in the same scene
  before production continues.
- A simple Godot validation scene showing all MVP entities at correct relative
  scale must be created during the technical spike (Section 35).

---

## 8. Per-Asset Pixel Dimensions

**Status: TBD / REQUIRES EMPIRICAL VALIDATION**

Exact sprite dimensions for individual entities (holy basil mature exact size,
cat idle exact bounding box, bench exact width) are **not locked in Task 4.3**.

Locking exact dimensions before a single production sprite has been placed in
Godot on the reference canvas would produce numbers without evidence. Sizes
will be calibrated during the technical spike and vertical-slice production.

The sizing methodology in Section 7 defines how to arrive at dimensions, and
the texture dimension policy in Section 9 sets the upper bound.

A future **Per-Entity Art Spec** document will record final approved dimensions
once calibration is complete.

---

## 9. Texture Dimension Policy

**Status: LOCKED TECHNICAL PIPELINE (maximum and approach); PROVISIONAL (per-category defaults)**

### 9.1 Maximum Dimension

**No individual production runtime texture should exceed 2048 px on either axis
without explicit exception approval (see Section 33).**

For ordinary gameplay sprites (plants, visitors, decorations) in this project,
the 1080 × 1920 canvas context means typical sprites will be well under 512 px
on either axis. Textures approaching 1024 px on an axis are large for this
game's scale.

### 9.2 Power-of-Two Requirement

**LOCKED: Power-of-two (POT) dimensions are NOT required for runtime PNGs in
Godot 4.7.2 with the Compatibility renderer.**

Godot 4 supports NPOT (non-power-of-two) textures natively. Requiring POT
would waste transparent canvas space for most hand-painted sprites.
(Verified: Godot 4 documentation confirms NPOT support; GL Compatibility
renderer handles NPOT textures for 2D.)

When ETC2 VRAM compression is applied by the Godot importer on Android (or S3TC
on desktop; see §17.1 for the Compatibility renderer compression path), the engine
handles any required padding internally; the artist does not need to pad to POT.

### 9.3 Per-Category Dimension Guidelines

**PROVISIONAL TECHNICAL PIPELINE**

| Category | Typical Axis Budget | Notes |
|---|---|---|
| Plant sprite (single stage) | ≤ 512 × 512 | Most plants well under this |
| Visitor sprite (animation frame) | ≤ 512 × 512 | Largest visitor (cat) still modest |
| Decoration sprite | ≤ 512 × 512 | Bench may approach 512 wide |
| UI icon (raster) | 64–256 px | Depends on final UI scale |
| UI panel patch (9-slice source) | ≤ 256 × 256 | Panel texture portion only |
| Background layer | ≤ 1080 × 1920 | Full canvas; max exception case |
| Effect/particle texture | ≤ 128 × 128 | Small point sprites; keep tiny |
| Rain streak texture | ≤ 64 × 512 | Tiled vertically; keep narrow |

### 9.4 Exception Process

Any texture requiring dimensions beyond these guidelines must follow the
exception process in Section 33 before production.

---

## 10. Texture Memory Model

**Status: LOCKED TECHNICAL PIPELINE — MATHEMATICALLY & MECHANICALLY VALIDATED (Task 4.4A)**

Understanding GPU memory is essential for Android decision-making.
A PNG file size on disk is irrelevant to runtime GPU memory cost.

### 10.1 Uncompressed RGBA8 GPU Memory Formula

```
GPU memory (bytes) = width × height × 4
```

| Dimension | RGBA8 GPU memory |
|---|---|
| 128 × 128 | 65,536 bytes (~64 KB) |
| 256 × 256 | 262,144 bytes (~256 KB) |
| 512 × 512 | 1,048,576 bytes (~1 MB) |
| 1024 × 1024 | 4,194,304 bytes (~4 MB) |
| 2048 × 2048 | 16,777,216 bytes (~16 MB) |
| 1080 × 1920 | 8,294,400 bytes (~8 MB) |

### 10.2 Mipmap Overhead

When mipmaps are enabled, memory cost increases by approximately 1/3
(geometric series: 1 + 1/4 + 1/16 + ... ≈ 1.333×):

```
RGBA8 with mipmaps ≈ width × height × 4 × 1.333
```

A 512 × 512 RGBA8 texture with mipmaps: ~1.33 MB.

**Task 4.4A Empirical Mipmap Observation:**
Task 4.4A mathematically validated the ~33.3% GPU VRAM overhead.
Empirically, the spike also observed that the import cache file on disk
(`painted_gradient_mipmap_on.png`) grew from 172,218 bytes to 281,980 bytes
(+63.7% on disk) because Godot stores all mip levels inside the `.ctex` container.
This confirmed the critical distinction: **disk cache growth != GPU mipmap overhead**.
The observed disk cache percentage is an artifact of file packaging and must
NOT be generalized as a GPU residency figure.

### 10.3 VRAM Compression Factor

ETC2 reduces GPU memory substantially compared to RGBA8:

- **RGBA8:** 32 bits/pixel (baseline: `width × height × 4 bytes`)
- **ETC2 RGBA (8 bits/pixel):** 8 ÷ 32 = **~25% of RGBA8** (≈ 4:1 compression ratio)

**Exact Block Formula:**
Because ETC2 operates on 4×4 pixel blocks, the exact memory formula is:
```
ETC2 bytes = ceil(width / 4) × ceil(height / 4) × 16
```
For dimensions divisible by 4, this equals exactly 25% of RGBA8.

**Representative Values Validated in Task 4.4A:**
- 512 × 512:
  - RGBA8: 1,048,576 bytes (1.00 MiB)
  - ETC2 RGBA: 262,144 bytes (0.25 MiB / 256 KiB)
- 1024 × 1024:
  - RGBA8: 4,194,304 bytes (4.00 MiB)
  - ETC2 RGBA: 1,048,576 bytes (1.00 MiB)
- 1080 × 1920:
  - RGBA8: 8,294,400 bytes ≈ 7.91 MiB
  - ETC2 RGBA: `(1080 / 4) × (1920 / 4) × 16 = 270 × 480 × 16 = 2,073,600 bytes` ≈ 1.98 MiB

*Note:* Do not infer production acceptability from these mathematical numbers alone.
Visual acceptability on mobile requires on-device evidence.

**ASTC 6×6 (mathematical context only — see §10.4 and §17.1 for renderer path):**
- 128 bits per 6×6 block = 128 ÷ 36 ≈ 3.56 bits/pixel
- 3.56 ÷ 32 ≈ **~11.1% of RGBA8**
- However, ASTC is NOT the normal runtime VRAM-compression path for this
  project's Compatibility renderer on Android. See Section 17.1 for the
  correct compression path.

(Verified: Godot 4.7 importing images documentation confirms VRAM Compressed
reduces memory roughly 4:1 for RGBA textures. Source:
docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_images.html)

VRAM compression is the most effective tool for reducing GPU memory on Android
mobile. See Section 17 (Compression Policy).

### 10.4 Scene Texture Memory Budget

**TBD / REQUIRES EMPIRICAL VALIDATION (DEVICE VALIDATION REQUIRED)**

A total scene GPU texture memory budget cannot be responsibly invented without:

- Real production sprite dimensions
- Confirmed compression settings
- Representative target Android hardware
- Profiling evidence

Task 4.4A did NOT define or accept any total scene-memory budget threshold.
The total scene texture-memory budget remains **TBD / DEVICE VALIDATION REQUIRED**.

Memory measurements in Task 4.4A serve as descriptive technical evidence,
not a pass/fail threshold. A future scene memory budget may be established only
after representative Android device profiling evidence exists.

### 10.5 Distinctions

**Core Distinction Confirmed by Task 4.4A:**
```
Source PNG disk bytes != Godot imported .ctex cache bytes != GPU residency != APK size
```

| Metric | Meaning | Task 4.4A Empirical Behavior |
|---|---|---|
| **Source PNG disk size** | Deflate-compressed PNG on filesystem | Reflects image entropy; 25.8 KB for 512×512 soft alpha |
| **Imported cache (.ctex) size** | Intermediate cache in `.godot/imported/` packaged into APK | Lossless `.ctex` uses Lossless WebP (17.5 KB for 512×512); ETC2 `.ctex` contains raw ETC2 block payload + 52-byte header (262,196 bytes) |
| **GPU VRAM residency** | Memory consumed when texture is uploaded to GPU VRAM | Lossless expands to full uncompressed RGBA8 (1,048,576 bytes / 1.00 MiB); ETC2 occupies block-compressed footprint (262,144 bytes / 256 KiB) |
| **Packaged APK size** | Final Android application package distribution | 30,681,193 bytes (~29.26 MiB) in Task 4.4A debug export |

These are four distinct numbers. Asset decisions must be evaluated on GPU memory
and runtime residency, not disk size or cache file size. Lossless `.ctex` files
are small on disk while expanding to full uncompressed RGBA8 on the GPU.
Conversely, ETC2 `.ctex` files are larger on disk than lossless WebP cache files,
yet result in 4× smaller VRAM residency on mobile GPUs.
Do NOT use `.ctex` file size as a universal GPU measurement.

---

## 11. Transparency, Trimming, and Padding

**Status: PROVISIONAL TECHNICAL PIPELINE**

### 11.1 Transparent Canvas Bounds

Do not export sprites with large amounts of fully transparent border pixels.
Unused transparent space wastes GPU memory proportionally.

Export the sprite to a tight bounding box around the visible painted content.

### 11.2 Required Breathing Room

**Do not trim to the absolute pixel edge of painted content.** Hand-painted
edges with soft watercolor/gouache strokes need a transparent gutter to:

- Prevent linear filtering bleed at the texture boundary
- Allow the soft edges to breathe without visual clipping
- Support future animation if the sprite's silhouette shifts slightly between frames

**Recommended minimum padding: 4 px transparent gutter on all sides**
of the painted content's bounding box (i.e., the exported canvas is the
painted content's tight bound plus 4 px each side).

This is PROVISIONAL; it may be adjusted to 8 px based on visual testing of
filtered edges on device.

### 11.3 Animation Frame Consistency

**Status: LOCKED TECHNICAL PIPELINE — MECHANICALLY VALIDATED (Task 4.4A)**

For frame-based grounded animations (e.g., `cat_idle_00.png` through `cat_idle_04.png`):

- **Consistent Runtime Canvas Dimensions:** All frames in one animation sequence
  MUST share identical pixel dimensions. The bounding box is determined by the
  envelope required for the full motion cycle.
- **Stable Anchor / Contact Preservation:** The intended contact/pivot point
  (e.g., base of paws or ground contact) must remain at the exact same coordinate
  relative to the frame canvas across all frames.
- **No Independent Auto-Trimming:** Do not auto-trim or crop individual frames
  independently in a way that alters the anchor coordinate or canvas footprint.
- **Transparent Padding for Registration:** Individual frames where the painted
  silhouette is smaller must include transparent padding as necessary to maintain
  spatial registration and keep the anchor fixed.
- **Failure to maintain consistent animation bounds is a production defect.**

**Task 4.4A Empirical Validation:**
Task 4.4A mechanically validated this contract using an `AnimatedSprite2D` node
with `SpriteFrames` containing 4 diagnostic frames (`anim_frame_00.png` to `03.png`).
All frames were authored at 256 × 256 with the ground-contact anchor pinned to
`(128, 248)`. By construction, common canvas dimensions and common anchor
configuration remove frame-bound-induced positional displacement.

**Visual Qualification:**
Rendered smoothness, absence of GPU jitter, and frame pacing were NOT visually
confirmed in Task 4.4A because the headless terminal environment prevented direct
frame capture (see §15.4 and §34). Mechanical stability is locked; rendered
animation feel remains subject to device verification.

### 11.4 Pivot Stability

A sprite's logical pivot point must remain spatially consistent when transparent
bounds are trimmed or adjusted. See Section 12 for pivot rules.

### 11.5 Filter Bleed Prevention

With linear filtering, pixels at the extreme edge of a texture can bleed with
adjacent transparent pixels (showing as a colored fringe). The 4 px gutter
rule mitigates this. Additionally, ensure transparent pixels near the edge have
their color channels set to a neutral value matching adjacent opaque pixels
(premultiplied alpha-compatible export, or ensure color values of fully
transparent pixels do not introduce fringe colors).

---

## 12. Pivot and Anchor Contract

**Status: LOCKED TECHNICAL PIPELINE**

All pivot/anchor conventions are expressed as the `offset` property of a
`Sprite2D` node or as the origin in the source canvas, such that when the
node's position is set to a logical garden coordinate, the visual result is
correct without additional manual offsets.

### 12.1 Default Pivots by Category

| Category | Canonical Pivot | Rationale |
|---|---|---|
| **Plants (all stages)** | **Bottom-center** | Ground-contact anchor; plant grows upward from placement point |
| **Standing decorations** (lamp, watering can, small table) | **Bottom-center** | Ground-contact anchor |
| **Clay water jar** | **Bottom-center** | Ground contact; wide base |
| **Garden bench** | **Bottom-center** | Ground contact; horizontal seating plane above |
| **Plant pot** | **Bottom-center** | Pot sits on ground |
| **Cat (ground visitor)** | **Bottom-center (body base)** | Rests on surface; ground contact |
| **Butterfly (flying visitor)** | **Center of body mass** | Hovers; no ground contact |
| **Garden bird** | **Center of body (perching)** | Perches on surfaces from center |
| **Frog** | **Bottom-center** | Low-profile; ground-level |
| **Firefly** | **Center** | Floating point light; no ground dependency |
| **UI icons** | **Center** | Standard UI origin |
| **Background/environment panels** | **Top-left or explicit scene-layout anchor** | Positioned by scene composition, not gameplay logic |
| **Ground patches** | **Top-left** | Tile from top-left corner |
| **Rain effect texture** | **Top-center** | Falls downward |

### 12.2 Expressing Pivot in the Export

**Principle (LOCKED):** All ground-contact sprites must have a ground-contact
bottom-center anchor so that positioning the node's `position` at a logical
garden coordinate places the sprite's base at that point.

**How `Sprite2D.centered` works (Godot 4.7 docs):**

- `centered = true` (default): the texture is drawn centered around the node origin.
- `centered = false`: the texture is drawn from the node origin at the top-left
  corner. The origin is **not** automatically at the bottom-center.

**Setting `centered = false` alone does NOT establish a bottom-center anchor.**
An additional drawing offset is still required to place the texture's bottom-center
at the node origin.

**Default Grounded-Sprite Mechanism (Option A):**

**Status: LOCKED TECHNICAL PIPELINE — MECHANICALLY VALIDATED (Task 4.4A)**

```gdscript
Sprite2D.centered = true
offset.x = 0
offset.y = -(texture_height / 2)
```

Task 4.4A mechanically compared Option A (`centered = true, offset.y = -h/2`)
against Option B (`centered = false, offset = (-w/2, -h)`) using 512 × 512
sprites anchored to `y = 1000`. Both produce mathematically identical bottom-center
geometry. Task 4.4A confirmed Option A is simpler and significantly less
error-prone in production because `offset.x = 0` remains constant by virtue of
centering, requiring only `offset.y = -(texture_height / 2)`.

Option A is therefore locked as the **project-wide default mechanism for all
grounded gameplay sprites**.

**Important Qualification:**
If transparent bounds or the intended contact point do not coincide with the
bottom edge of the runtime export canvas, asset authoring/padding must be
corrected or an explicitly documented asset-specific anchor exception used.
Do NOT blindly assume every future sprite's visible foot or ground contact
coincides with the bottommost pixel row of its canvas.
*(Scene files are not modified in Task 4.4B).*

**Category-Specific Non-Grounded Anchors Preserved:**
This bottom-center Option A promotion applies specifically to **grounded gameplay
sprites** (plants, ground visitors, standing decorations). Other categories retain
their category-specific anchors as defined in §12.1:
- **Flying visitors (butterfly, bird):** Center of body mass
- **Floating effects (firefly):** Center
- **UI icons:** Center
- **Background / environment panels:** Top-left or explicit scene-layout anchor

### 12.3 What Is Forbidden

- Compensating for wrong pivots with arbitrary `position` offsets in scene
  nodes is forbidden as a standard workflow.
- Different plants using different pivot strategies (one bottom-center, one
  center, one top-left) creates maintenance chaos.

---

## 13. Lighting-Neutral Base Art

**Status: PROVISIONAL TECHNICAL PIPELINE**

### 13.1 Approved Lighting Conditions (Visual Direction Already Locked)

From `VISUAL_STYLE_BIBLE.md` §13 (LOCKED qualitative direction):
- Day: warm directional sun
- Night: deep indigo ambient, warm lamp pools
- Rain: diffuse silver-teal mist

### 13.2 Base Sprite Lighting Strategy

**Base sprites should be painted with natural self-shadowing and local ambient
occlusion appropriate to soft diffused daylight, but must NOT bake in a hard
directional spotlight from a specific global angle.**

What MAY be baked in:
- Natural form shadows and object self-shadowing (underside of a bench seat,
  shadow beneath a jar rim, leaf underside shadows)
- Ambient occlusion at the base of objects where they meet the ground
- Subtle warm highlights consistent with soft top-down tropical daylight

What MUST NOT be baked in:
- Strong directional highlight from a fixed 3 o'clock or 9 o'clock angle
  that would be inconsistent with a night or overcast treatment
- Hard cast shadows falling in a specific direction that would contradict
  different weather/time states

### 13.3 Multi-Condition Support

The approved conditions (day, night, rain) will be handled by:

- **CanvasModulate:** Tinting the entire scene for night/overcast ambient
- **Runtime shader or LightOccluder2D:** Lamp pool effects
- **Particle/shader overlay:** Rain streaks and wet-surface effects

A base sprite painted with neutral self-lighting should transition gracefully
under `CanvasModulate` without producing jarring contradictions.

### 13.4 When a True Art Variant Is Justified

A completely separate recolored sprite set is justified ONLY when:

1. The visual difference cannot be achieved through CanvasModulate or a
   simple shader parameter (e.g., a firefly point glow that only appears at
   night is a separate sprite/effect).
2. The condition completely changes the sprite's visual appearance in a way
   that cannot be approximated at runtime (e.g., a plant with distinct
   rain-swollen leaves that cannot be conveyed by tinting alone).

Default: avoid separate day/night sprite sets. The bar for creating a true
art variant is high and requires explicit approval.

---

## 14. Color Space and Alpha

**Status: LOCKED TECHNICAL PIPELINE (verified against Godot 4 behavior)**

### 14.1 Color Space

All runtime export PNGs must use the **sRGB color space**.

Godot 4 assumes sRGB for textures by default in the 2D/Compatibility pipeline.
Exporting with an embedded linear or CMYK profile will cause incorrect color
rendering in-engine.

Do not embed ICC profiles in runtime exports. Export as standard sRGB PNG
without explicit ICC profile embedding, or embed the sRGB profile only.

### 14.2 Alpha Mode: Straight Alpha

Export runtime PNGs with **straight alpha** (non-premultiplied).

Godot 4's 2D texture import handles straight-alpha PNG correctly by default.
Do NOT export premultiplied-alpha PNGs unless a specific future shader or
compositing requirement explicitly requires it and has been tested.

Premultiplied alpha from some export tools produces dark fringe artifacts at
transparent edges in Godot's standard renderer.

### 14.3 Fringe / Halo Prevention

To prevent colored fringe at transparent edges when using linear filtering:

- Ensure that fully transparent pixels adjacent to opaque content do not have
  garbage color channel values. Most painting tools handle this correctly with
  "bleed" or "fill transparent areas" options.
- Use the 4 px minimum transparent gutter (Section 11).

### 14.4 Source Master Color Consistency

- Paint source masters in sRGB color mode (not wide-gamut P3 or ACES).
- Use the provisional reference palette from `VISUAL_STYLE_BIBLE.md` §11 as
  a starting point; final HEX calibration belongs to a future color spec task.
- Monitor calibration affects perceived colors; production artists should use
  a calibrated display or cross-check on a reference device.

---

## 15. Texture Filtering Policy

**Status: LOCKED TECHNICAL PIPELINE (policy & configuration mechanics) / UNVERIFIED — RENDERED VISUAL EVIDENCE REQUIRED (empirical render comparison)**

### 15.1 Default Filter: Linear

The approved art style is **painterly, not pixel art**.

**Default filter for all gameplay sprites, environment art, and effects:
Linear filtering.**

This is consistent with Godot 4's Compatibility renderer default behavior
for 2D CanvasItems. In Godot 4, filtering is set per CanvasItem node
(`texture_filter` property) or via the project default.

**Do NOT use Nearest (nearest-neighbor) filtering** for hand-painted sprites.
Nearest filtering produces a blocky, pixelated look incompatible with the
approved Balanced Storybook Hybrid visual direction.

(Verified: Godot 4 CanvasItem `texture_filter` property supports `Linear`,
`Nearest`, `Linear Mipmap`, `Nearest Mipmap`, `Linear Mipmap Anisotropic`,
and `Inherit` modes. Default project canvas texture filter is controllable
via Project Settings > Rendering > Textures > Canvas Textures.)

**Task 4.4A Empirical Verification & Visual Qualification:**
- **Mechanically Validated (Task 4.4A):** `CanvasItem.texture_filter` can be
  explicitly configured per node; baseline subjects were assigned
  `TEXTURE_FILTER_LINEAR` (Enum 2) and the comparison subject was assigned
  `TEXTURE_FILTER_NEAREST` (Enum 1); scene serialization and resource loading
  are mechanically valid.
- **Visual Evidence Limitation:** Task 4.4A did NOT visually validate Linear
  vs Nearest in rendered output because:
  `LOCAL RENDER SCREENSHOT BLOCKED BY ENVIRONMENT`
  (The macOS headless terminal environment invoked Godot's Dummy Rendering
  Server `PN13RendererDummy`, returning null viewport textures and rendering no
  genuine hardware frames; see §15.4 and §34).
- **Pipeline Baseline Status:** Linear remains the approved pipeline default
  based on visual direction and engine policy. However, direct rendered visual
  comparison remains **UNVERIFIED — RENDERED VISUAL EVIDENCE REQUIRED**.
  Task 4.4A does NOT claim empirical visual proof of Linear superiority.

### 15.2 Allowed Exceptions

Nearest filtering may be used ONLY for:

- UI elements that are intentionally pixel-grid-aligned (e.g., a hand-drawn
  pixel-exact frame border if ever introduced — this contradicts the current
  visual direction, so exceptions are unlikely).
- Technical utility textures that are not rendered directly (masks, lookup
  tables) — these may not apply in this project.

Any Nearest filter assignment to a visible gameplay sprite requires exception
approval.

### 15.3 Mipmapped Filtering

See Section 16 for mipmap defaults. `Linear Mipmap` is the preferred mode
for sprites that will be viewed at significantly reduced scale.

### 15.4 Filtering Is a Rendering Setting, Not an Import Setting

**Important Godot 4 distinction (since Godot 4.0):**

Texture filtering is configured through:

1. **Project-wide default:** Project Settings > Rendering > Textures > Canvas
   Textures > Default Texture Filter (sets the default for all CanvasItems)
2. **Per-node override:** `CanvasItem.texture_filter` property on individual
   Sprite2D / AnimatedSprite2D nodes

**The `.import` sidecar file does NOT store the CanvasItem filter mode.**

`.import` files encode import-time parameters such as:
- `compress/mode` (Lossless, Lossy, VRAM Compressed, etc.)
- `mipmaps/generate` (on/off)
- Process options (Fix Alpha Border, Premult Alpha, etc.)

They do NOT encode the runtime CanvasItem `texture_filter` choice.

Task 4.4A mechanically verified this distinction: the `.import` files generated
for the spike contained purely import parameters, confirming that filtering
configuration resides exclusively in scene node definitions or project settings.

Therefore, **committing `.import` files does NOT reproduce the Linear filtering
policy** for individual nodes. Linear filtering reproducibility requires:

- Setting the project-wide Canvas Textures default to `Linear` in
  `project.godot` (a future project-setting implementation task), **and/or**
- Setting `texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR` on individual
  nodes in scene files.

*(No modification is made to `project.godot` or scene files in Task 4.4B).*

### 15.5 Project Default Versus Per-Node

Setting the project default filter to `Linear` in Project Settings ensures
that sprites without explicit `texture_filter` override are correctly filtered.
Per-node overrides using `CanvasItem.texture_filter` should be used only for
justified exceptions (e.g., a specific node that requires Nearest filtering).

---

## 16. Mipmap Policy

**Status: PROVISIONAL TECHNICAL PIPELINE**

### 16.1 What Mipmaps Do

Mipmaps are pre-generated downsampled versions of a texture at successive
half-size levels. They improve visual quality (reducing aliasing and shimmer)
when a texture is rendered at sizes smaller than its original resolution, and
can improve GPU sampling performance. They cost approximately 33% additional
memory.

(Verified against Godot 4 documentation: mipmaps are optional per-texture in
the import settings. Godot 4 generates mipmaps at import time when enabled.)

### 16.2 Decision Matrix

| Category | Mipmap Default | Rationale |
|---|---|---|
| **UI icons (raster, static)** | OFF | Rendered at or near their native size; no benefit |
| **UI panel patches (9-slice)** | OFF | Fixed layout; not scaled down significantly |
| **Plant sprites** | OFF (provisional) | Displayed near-native size on reference canvas; validate in spike |
| **Visitor sprites** | OFF (provisional) | Same rationale as plants |
| **Decoration sprites** | OFF (provisional) | Near-native display size |
| **Large environment/background** | ON | Background elements may be rendered at various scales with camera zoom (if introduced); backgrounds can sample at lower resolutions benefiting from mipmaps |
| **Effect textures (rain, particles)** | ON | Particle systems may scale these textures; mipmaps prevent shimmer |
| **Tileable ground patches** | ON | May be repeated/scaled; mipmaps prevent aliasing |

**Reasoning for plant/visitor/decoration OFF:** In a portrait 2D game where
sprites are authored at 1:1 canvas scale and displayed near that size,
mipmaps add memory cost without visual benefit. If future gameplay introduces
camera zoom-out or zoomed-out overview, enable mipmaps for those sprites.

**PROVISIONAL:** These defaults must be validated during the technical spike
by checking for shimmer or aliasing artifacts on actual device hardware.

---

## 17. Compression Policy

**Status: PROVISIONAL TECHNICAL PIPELINE (verified Godot behavior; pending visual quality comparison)**

### 17.1 Disk Format vs GPU Format Distinction

The PNG source file is a **disk format** — it is a losslessly compressed
container for pixel data.

Godot imports the PNG and, depending on import settings, may store it in the
`.godot/imported/` cache as:

- Raw RGBA8 (no GPU compression)
- ETC2 (GPU-native compressed format for mobile/Android/web)
- ASTC (GPU-native compressed format for mobile, when High Quality is enabled)
- S3TC/BC (desktop GPU compression)
- BPTC (desktop High Quality compression)

The GPU compression format is what actually occupies VRAM.

#### 17.1.1 Compatibility Renderer Compression Path

The Godot 4.7 documentation states:

> **High-quality VRAM texture compression is only supported in the Forward+
> and Mobile renderers.** When using the Compatibility renderer, High Quality
> is always considered disabled.

With **High Quality disabled** (which applies unconditionally to Compatibility):

- **Desktop platforms:** VRAM compression uses **S3TC**
- **Mobile / Android / web:** VRAM compression uses **ETC2**

**For this project's baseline:**

```
Renderer:   GL Compatibility
Platform:   Android
Mode:       VRAM Compressed
Compression path: ETC2
```

When reasoning about runtime VRAM savings for Garden's Android build, use
**ETC2** (not ASTC) as the applicable compression format.

#### 17.1.2 Project Setting Clarification

`project.godot` contains:
```
textures/vram_compression/import_etc2_astc=true
```

This setting **permits** Godot to import textures into the ETC2/ASTC family
(enabling the relevant import pipeline). It does **not** override the
renderer-specific High Quality behavior described above. Under Compatibility,
High Quality remains disabled regardless of this setting, so the active
runtime path on Android remains ETC2, not ASTC.

Do not infer active ASTC runtime use merely from this project setting name.

**Task 4.4A Import Path Validation:**
Task 4.4A mechanically verified this dual-target behavior. Under `compress/mode=2`
with `import_etc2_astc=true`, Godot generated two distinct cache files in
`.godot/imported/`:
- `.s3tc.ctex`: Desktop S3TC/BC format for desktop preview/testing
- `.etc2.ctex`: Android ETC2 RGBA format for Android export

This mechanically validates the **IMPORT AND BUILD PATH**. It does NOT validate
the visual acceptability of ETC2 compression on Android hardware.

### 17.2 Available Import Modes in Godot 4

(Verified against Godot 4.7 importing images documentation and binary property hints in Task 4.4A.)

The underlying integer enum mapping for `compress/mode` verified in Godot 4.7.2:
- `0`: **Lossless** (default 2D mode)
- `1`: **Lossy** (disk-only WebP compression; no VRAM reduction)
- `2`: **VRAM Compressed** (block compression: S3TC desktop / ETC2 Android Compatibility)
- `3`: **VRAM Uncompressed** (raw uncompressed RGBA8)
- `4`: **Basis Universal** (transcoded VRAM container)

*(Note: This integer mapping is documented as empirical evidence. Production
tooling and editor workflows must use named configuration properties rather
than magic numbers).*

| Godot Import Compress Mode | Mode Enum | GPU Memory Behavior | Disk Behavior |
|---|---|---|---|
| **Lossless** | `0` | Full GPU memory (RGBA8 at runtime); NO VRAM compression | Stored as lossless WebP container (.ctex); no quality loss |
| **Lossy** | `1` | Full GPU memory — same as Lossless/Uncompressed; NOT reduced | Smaller disk size (WebP lossy); some quality loss |
| **VRAM Compressed** | `2` | GPU-native compression; reduced VRAM (~4:1 for ETC2 RGBA on Android/Compatibility) | GPU-native format in cache (.etc2.ctex / .s3tc.ctex) |
| **VRAM Uncompressed** | `3` | Full RGBA8 GPU memory | Uncompressed; useful for formats that can't be compressed |
| **Basis Universal** | `4` | Transcodes to VRAM-compressed format; similar VRAM to VRAM Compressed | Very small files; slower compression; some quality loss |

**Important clarifications verified against Godot 4.7 docs and Task 4.4A spike:**

- **Lossless** does NOT silently become VRAM Compressed when ETC2/ASTC import
  support is enabled. The `textures/vram_compression/import_etc2_astc=true`
  project setting permits ETC2/ASTC import family support but does NOT
  change the Compress > Mode for assets set to Lossless.
- **Lossy** reduces disk size but does NOT reduce GPU memory usage. GPU memory
  is the same as Lossless or VRAM Uncompressed.
- **VRAM Compressed** is the mode that actually reduces GPU memory.

### 17.3 Decision Matrix

**Status: PROVISIONAL TECHNICAL PIPELINE — pending on-device visual quality comparison**

Per Godot 4.7 official documentation:

> **Lossless is the default and most common compression mode for 2D assets.**
> It shows assets without any kind of artifacting.

> VRAM Compressed **can produce noticeable artifacts** in 2D, especially on
> lower-resolution textures. It should generally be avoided for 2D assets
> unless memory savings are critical and artifacts are verified to be acceptable.

Garden baseline policy for painterly 2D sprites (soft alpha edges, watercolor/
gouache texture):

**Baseline (initial quality default before empirical comparison):**

| Asset Category | Baseline Import Mode | Notes |
|---|---|---|
| **Plants (all stages)** | **Lossless** | Painterly with soft alpha; quality baseline (PROVISIONAL) |
| **Visitors (cat, butterfly, etc.)** | **Lossless** | Soft painted edges; quality baseline (PROVISIONAL) |
| **Decorations** | **Lossless** | Quality baseline (PROVISIONAL) |
| **Animated sprite frames** | **Lossless** | Quality baseline; do not assume VRAM Compressed is essential (PROVISIONAL) |
| **UI icons/panels** | **Lossless** | Small; quality critical; minimal VRAM impact (PROVISIONAL) |
| **Small effect sprites** | **Lossless** | Default quality baseline (PROVISIONAL) |
| **Large environment/background** | **PROVISIONAL / EMPIRICAL COMPARISON REQUIRED** | See below |

**Status of Lossless Baseline Remains PROVISIONAL:**
Task 4.4A mechanically confirmed the import configuration and cache generation
for both Lossless (`compress/mode=0`) and VRAM Compressed (`compress/mode=2`).
However, because direct on-device visual comparison and profiling remain deferred,
**no production asset category is promoted permanently to Lossless or to ETC2 by Task 4.4B**.
Lossless remains the provisional baseline; VRAM Compressed remains an optimization
candidate.

**Large environment/background textures — comparison required on device:**

Compare Lossless vs Lossy vs VRAM Compressed (ETC2) for:
- bg_house_wall.png, ground layers, sky panel, fence
- Measure visual artifacts, GPU memory, and APK size
- ETC2 may be approved for background layers if artifacts are acceptable and
  memory savings are material

**When VRAM Compressed may be approved (per-asset basis after device gate):**
- Visual artifacts are acceptable on target devices
- Memory savings are material (large textures benefit most)
- Soft alpha edges, dark semi-transparent shadows, fine gradients have been
  visually reviewed under ETC2 on Android hardware

**Do NOT claim VRAM compression is "essential" for animated sprite frames**
prior to empirical comparison showing unacceptable memory usage under Lossless.

**PROVISIONAL NOTE:** ETC2 compression of sprites with fine painted texture and
soft gradient alpha edges may introduce visible block artifacts, particularly
on dark semi-transparent shadows and soft watercolor edges. Visual quality
comparison must be performed on physical Android hardware before any category
is changed from Lossless baseline to VRAM Compressed.

### 17.4 Source PNG Encoding

Runtime export PNGs should be saved with standard PNG lossless compression
(e.g., PNG-8 where the image has limited colors and no true transparency
gradient; PNG-32 RGBA for all hand-painted sprites with alpha). Use PNG-32
(8 bits per channel) for all production hand-painted art.

JPEG is **strictly forbidden** for any sprite with transparency or soft
painted edges.

---

## 18. Atlas Strategy

**Status: PROVISIONAL TECHNICAL PIPELINE**

### 18.1 Godot 2D Batching Context

Godot 4's Compatibility renderer batches draw calls for 2D sprites that share
the same texture, material, and draw order. Using separate textures per sprite
entity results in one draw call switch per entity change, which for a small
scene with a modest number of sprites is typically acceptable.

An atlas reduces draw-call count by grouping multiple sprites onto one texture,
enabling the renderer to draw many sprites in a single draw call when they are
adjacent in the render order.

### 18.2 Default Strategy: No Pre-Emptive Atlas

**Default: Do not create atlases during initial production.**

Reasons:
- The project scene has a small number of visible entities simultaneously.
- Pre-emptive atlasing before profiling evidence introduces maintenance cost
  (adding a new sprite requires rebuilding the atlas).
- Godot's built-in automatic atlasing via `AtlasTexture` resource provides
  a mid-point option when needed.

### 18.3 When Atlasing Becomes Justified

Atlasing is justified when profiling on target Android hardware demonstrates:

- Draw call count is measurably impacting frame time.
- GPU performance is constrained and batching would provide measurable benefit.
- A natural grouping exists (e.g., all 4 stages of one plant on one sheet).

### 18.4 Preferred Atlas Approach When Needed

When atlas optimization is introduced:

- **Per-entity animation sheet:** An animated entity's frames are laid out on
  a single sprite sheet (e.g., all `cat_idle_*.png` frames → `cat_idle_sheet.png`).
  This is the most maintainable form.
- **Per-category atlas:** Group plants or small UI icons together on one texture
  sheet when category-level draw-call reduction is demonstrated to help.
- **Mega-atlas:** A project-wide single giant atlas is discouraged. It creates
  extreme build-time rigidity and a large memory footprint even for screens
  that don't use most of it.

Godot's `AtlasTexture` resource allows referencing a region of a larger texture,
which supports this workflow.

### 18.5 No Premature Sprite Sheets Required

Production artists should export individual per-frame PNGs following the naming
contract (Section 5). Atlas packing is an optimization step applied later with
tooling. The pipeline supports both workflows (individual files for early
production; atlas sheets for optimization when evidence demands it).

---

## 19. Plant Asset Contract

**Status: LOCKED TECHNICAL PIPELINE (contract); TBD (exact dimensions)**

Plants are central gameplay entities. Their technical contract must support the
locked four-stage growth system (`GAME_DESIGN.md` §10, `ARCHITECTURE.md` §13).

### 19.1 Required Stage Sprites

Each plant species must provide exactly four stage sprites:

```
{species}_planted.png     # Small mound; minimal silhouette
{species}_sprout.png      # First emergence; small upright form
{species}_growing.png     # Intermediate; clear branching
{species}_mature.png      # Full silhouette; species-identifying traits
```

Examples (holy basil, marigold as vertical-slice reference only):
```
holy_basil_planted.png
holy_basil_sprout.png
holy_basil_growing.png
holy_basil_mature.png
marigold_planted.png
marigold_sprout.png
marigold_growing.png
marigold_mature.png
```

### 19.2 Technical Requirements per Plant Sprite

- **Pivot:** Bottom-center (ground-contact anchor)
- **Stable visual footprint:** All four stages of one species must share the
  same canvas width so the plant does not jump laterally between growth stages
  (height may increase but canvas width should be the species' maximum)
- **No embedded labels, stage indicators, or text**
- **Silhouette differentiability:** Each stage must be readable by silhouette
  alone (validated in VISUAL_STYLE_BIBLE.md §14 — LOCKED QUALITATIVE DIRECTION)
- **Lighting neutral:** Self-shadowing permitted; baked hard directional light
  forbidden (see Section 13)
- **Alpha:** Straight alpha, sRGB PNG
- **Filter:** Linear (section 15)
- **Consistent transparent padding:** 4 px minimum gutter (section 11)
- **No gameplay timing encoded in art files:** The `PlantGrowth` domain logic
  determines which stage sprite is displayed; the sprite file itself has no
  timing metadata

### 19.3 Stage Sizing Guidance

All four stages of a species share the same canvas dimensions (set to the
largest stage's bounding box). Smaller stages are centered/anchored within
that shared canvas. The planted mound may be small within a larger canvas.

This ensures the ground anchor point is consistent across stage transitions.

---

## 20. Visitor Asset Contract

**Status: PROVISIONAL TECHNICAL PIPELINE (contract); TBD (exact dimensions and frame counts)**

### 20.1 Cat (visitor.cat)

| Property | Requirement |
|---|---|
| Pivot | Bottom-center of body (sitting/resting) or bottom-center of paw-contact area |
| Natural scale | Must feel proportionally correct against bench and clay jar (LOCKED QUALITATIVE DIRECTION) |
| Idle animation | Loopable; gentle breathing motion; very low amplitude |
| Sleep pose | Static or near-static (minimal chest-rise) |
| Walking animation | Separate from idle; clean loop |
| Frame bounds | All frames of each animation share identical dimensions |
| Body in frame | All key poses fit within the shared frame without clipping |
| Directional | Single direction (right-facing default); horizontal flip in code if needed |
| Shadow/contact | Subtle contact shadow may be baked at base; not a hard cast shadow |
| Lighting neutral | Self-form shading permitted; no baked global directional shadow |

### 20.2 Butterfly (visitor.butterfly)

| Property | Requirement |
|---|---|
| Pivot | Center of body mass (flying entity; hovers) |
| Natural scale | Small and delicate; significantly smaller than cat head (LOCKED QUALITATIVE DIRECTION) |
| Flutter animation | Wing-beat cycle; loopable; fast enough to read as natural flight |
| Rest animation | Wings slowly open/close or near-static resting on flower |
| Frame bounds | All flutter frames identical; all rest frames identical |
| Runtime display size | TBD through reference-canvas calibration in the production validation spike |
| Silhouette | Wing shape readable against foliage at small scale; readable through silhouette/value/placement rather than physical enlargement |

**Locked qualitative requirements for butterfly scale:**
- Naturally small; significantly smaller than cat head
- Must read by silhouette, value, and placement — not by physical enlargement
- Exact pixel height: **TBD** — to be determined through reference-canvas
  calibration during the production validation spike

### 20.3 Future Visitor Consistency

All future visitors follow the same pattern:

- Ground-contact visitors: bottom-center pivot
- Flying/perching visitors: center or body-mass pivot
- Consistent frame bounds within each animation
- Natural domestic scale per `VISUAL_STYLE_BIBLE.md` §7.1
- Loopable idle

---

## 21. Decoration Asset Contract

**Status: PROVISIONAL TECHNICAL PIPELINE**

Decorations are placed objects. Their visual contract supports the locked
dual-purpose design (self-expression + systemic traits, `GAME_DESIGN.md` §15).

### 21.1 Clay Water Jar (decoration.clay_jar)

| Property | Requirement |
|---|---|
| Pivot | Bottom-center |
| Footprint | Stable rounded base; does not appear to float |
| Silhouette | Heavy rounded form; unmistakable at small scale |
| Interaction readability | Rim and body defined clearly for visitor interaction context |
| Lighting neutral | Surface form-shadows OK; no baked hard directional shadow |
| Static | No inherent animation (ripple effects are a separate effect layer) |

### 21.2 Garden Bench (decoration.bench)

| Property | Requirement |
|---|---|
| Pivot | Bottom-center |
| Footprint | Wide horizontal; stable rectangular base |
| Seating surface | Clearly readable horizontal plane for cat visitor placement |
| Occlusion readability | Bench legs do not visually merge into ground in a confusing way |
| Scale | Must visually relate correctly to cat sitting on it |
| Lighting neutral | Slat form-shadows OK; no baked hard directional shadow |
| Static | No inherent animation |

### 21.3 General Decoration Rules

- Bottom-center pivot for all ground-placed decorations
- Static sprites (no animation) unless a specific ambient effect is designed
- Transparent bounds follow 4 px gutter rule
- Lighting neutral base art

---

## 22. UI Asset Contract

**Status: PROVISIONAL TECHNICAL PIPELINE**

UI implementation is out of scope for current milestones. This contract
defines technical principles for when UI asset production begins.

### 22.1 Raster Icon Sizing

- Design to a target touch-target minimum compatible with Android guidelines
  (~48 dp equivalent at runtime)
- Export at 2× the minimum logical size to ensure crisp rendering on high-DPI
  phones (verify against reference canvas and stretch mode)
- Keep icons modest: 64–128 px export for standard toolbar icons is a
  reasonable provisional target

### 22.2 Panels and 9-Slice

- Use 9-slice (`StyleBoxTexture` in Godot) for panels and dialogs that resize
- 9-slice source texture should be small (128 × 128 or 256 × 256 for the source
  patch); only the corner/edge regions contain painted texture
- Do not create giant raster backgrounds for simple UI panels; use 9-slice
  with a small texture and let Godot stretch the center

### 22.3 Painterly Texture Restraint

- UI surfaces may use a subtle paper/card texture consistent with the visual
  direction, but the texture must remain legible and not introduce visual noise
  that conflicts with text readability
- Do not tile a heavily grained texture at full opacity behind text

### 22.4 Touch Readability

- All interactive UI elements must have adequate tap target size
- Icon tap targets should be generous (at least 44–48 dp equivalent)
- Verify layout on representative narrow and wide portrait aspect ratios

### 22.5 SVG Policy

SVG is supported by Godot 4's importer. However:

- SVG rasterizes at import; carefully control the `svg/scale` import parameter
- SVG is appropriate for simple geometric icon shapes that benefit from
  resolution-independent scaling
- SVG is inappropriate for complex painterly artwork; use PNG for those
- Do not use SVG for backgrounds or atmospheric art

### 22.6 Font

Font selection and bundling remain **TBD** per `VISUAL_STYLE_BIBLE.md` §20.
No font files are bundled in Task 4.3.

---

## 23. Weather and Effect Asset Contract

**Status: PROVISIONAL TECHNICAL PIPELINE**

### 23.1 Classification

| Effect | Classification | Rationale |
|---|---|---|
| Rain streak texture | **ART ASSET** (small tileable texture) | A thin semi-transparent texture drawn by rain particle system; needs artist input |
| Raindrop ripple sprite | **ART ASSET** (small animated sprite) | Circular expanding ring; 4–6 frames |
| Wet surface overlay | **PROVISIONAL / RUNTIME EFFECT** | May be CanvasModulate + shader parameter; evaluate in spike |
| Firefly point sprite | **ART ASSET** (small glow sprite) | Simple radial glow; used as particle texture |
| Night color treatment | **RUNTIME EFFECT** (CanvasModulate) | Tint entire scene; no separate art assets needed by default |
| Rain atmosphere / mist | **RUNTIME EFFECT** (CanvasModulate + particle overlay) | Atmospheric tinting; not a giant opaque sprite |
| Harvest dust puff | **ART ASSET** (small animated sprite, 4–6 frames) | Brief feedback animation |
| Lamp glow pool | **RUNTIME EFFECT** (Light2D node or shader) | Dynamic light pooling; not a baked sprite overlay |

### 23.2 Art Asset Specifications

**Rain streak texture:**
- Narrow, tall PNG (≤ 64 × 512 px)
- Semi-transparent white/grey angled streak
- Designed to be tiled/repeated by particle system
- Lighting neutral (no embedded directional lighting)

**Ripple sprite (animation):**
- Small (≤ 128 × 128 px canvas per frame)
- 4–6 frames of expanding concentric ring
- Consistent frame dimensions
- Center pivot

**Firefly glow sprite:**
- Very small (≤ 64 × 64 px)
- Soft radial yellow-green gradient
- Center pivot
- Single frame (animation achieved by AnimationPlayer/shader pulse, not
  by many hand-painted frames)

**Harvest dust / feedback puff:**
- Small (≤ 128 × 128 px per frame)
- 4–6 frames
- Bottom-center pivot
- Brief; designed for single-play (not looped)

### 23.3 Provisionally Deferred

The following require an implementation spike before technical specifications
can be finalized:

- **Wet surface sheen on clay/leaves:** Whether this is a shader modulation
  or a separate sprite overlay requires testing.
- **Exact rain particle density and speed:** Shader/particle parameters;
  not an art asset decision.
- **Firefly drift path:** Handled by AnimationPlayer or particle trajectory;
  not an art file.

---

## 24. Animation Representation Strategy

**Status: PROVISIONAL TECHNICAL PIPELINE**

### 24.1 Preferred Representation by Motion Type

| Motion Type | Preferred Godot Representation | Rationale |
|---|---|---|
| Cat breathing / idle | **AnimatedSprite2D + SpriteFrames** | Subtle frame-by-frame body motion; clear artist control |
| Cat walking | **AnimatedSprite2D + SpriteFrames** | Distinct frame poses required |
| Butterfly flutter | **AnimatedSprite2D + SpriteFrames** | Wing-beat cycle; loopable |
| Butterfly resting | **AnimatedSprite2D + SpriteFrames** | Low-frame alternative animation |
| Leaf sway (ambient) | **AnimationPlayer + transform** | Procedural oscillation on a Sprite2D is efficient; no new frames needed |
| Lamp glow pulse | **AnimationPlayer + modulate/energy** | Color/light property animation; no new sprite frames needed |
| Firefly drift | **AnimationPlayer + transform path** | Position curve animation |
| Rain streaks | **GPUParticles2D or CPUParticles2D** | Particle system with streak texture |
| Water ripple | **AnimatedSprite2D + SpriteFrames** | Small loop of expanding ring frames |
| UI transitions (fade/slide) | **AnimationPlayer + transform/modulate** | Property animation; no new sprites |
| Plant stage transition | **Presentation-only AnimationPlayer** | Crossfade or dissolve between stage sprites; game state is separate |

### 24.2 Why AnimatedSprite2D for Character/Visitor Animation

- Provides a clean separation between animation frames and runtime behavior
- `SpriteFrames` resource is a Godot text resource (`.tres`) — version-control
  friendly
- Frame timing is set in the resource; the script just calls `play("idle")`
- Multiple named animations (idle, sleep, walk) coexist cleanly in one
  `SpriteFrames`

### 24.3 AnimationPlayer for Property Animation

For effects that can be achieved by animating existing properties (position,
scale, modulate, rotation) without new art frames, `AnimationPlayer` is
preferred. This avoids unnecessary additional sprite frames for small ambient
motions.

### 24.4 No Force-Fitting

Do not force every ambient effect into frame animation when a transform
oscillation or shader would produce an equivalent or better result with lower
memory cost.

---

## 25. Animation Budget Ranges

**Status: PROVISIONAL TECHNICAL TARGET (ranges); TBD / DEVICE VALIDATION REQUIRED (final calibration)**

### 25.1 Default Budget Ranges

These are production defaults — reasonable starting points that are not final
gameplay timing requirements.

| Animation | FPS Range | Estimated Frame Count | Notes |
|---|---|---|---|
| Plant ambient sway | N/A (transform) | 0 new frames | AnimationPlayer oscillation |
| Cat idle / breathing | 8–12 fps | 4–8 frames | Subtle; quality over quantity (PROVISIONAL) |
| Cat sleep (near-static) | 4–8 fps | 2–4 frames | Minimal chest-rise (PROVISIONAL) |
| Cat walk cycle | 10–14 fps | 6–10 frames | Must read as natural (PROVISIONAL) |
| Butterfly flutter | 12–16 fps | 4–8 frames | Wing-beat reads at small scale (PROVISIONAL) |
| Butterfly rest | 6–10 fps | 2–4 frames | Near-static (PROVISIONAL) |
| Ripple animation | 8–12 fps | 4–6 frames | Short play-once loop (PROVISIONAL) |
| Harvest feedback puff | 10–14 fps | 4–6 frames | Play-once (PROVISIONAL) |
| Lamp glow pulse | N/A (property) | 0 new frames | AnimationPlayer modulate |
| Firefly drift | N/A (path) | 0 new frames | AnimationPlayer position |
| UI fade/transition | N/A (property) | 0 new frames | AnimationPlayer |

### 25.2 Validation Gate

All frame counts and FPS values above remain **PROVISIONAL**.

**Task 4.4A Empirical Verification:**
Task 4.4A mechanically configured an 8 FPS playback speed on `SpriteFrames`
for the diagnostic 4-frame animation loop. The scene serialization and playback
initialization functioned without error.

**Visual & Device Limitation:**
Perceived smoothness, absence of rendered GPU jitter, frame pacing, and motion
feel were NOT observed because headless execution prevented direct visual capture.
Therefore, the **8–12 FPS range remains a PROVISIONAL TECHNICAL TARGET**. Neither
8 FPS nor 8–12 FPS is permanently locked. Final calibration requires rendered
visual observation and device profiling using real representative production art
on physical Android hardware.
5. Adjust ranges based on evidence; record final approved values in the
   per-entity art spec.

---

## 26. Motion Density Policy

**Status: PROVISIONAL TECHNICAL TARGET (3–5 motions) / INHERITED VISUAL DIRECTION (calm motion principle)**

From `VISUAL_STYLE_BIBLE.md` §23:

> At any given moment during ordinary garden play, no more than 3 to 5 subtle
> ambient motions should be active simultaneously on the screen.

### 26.1 Principle and Status Authority

- **Qualitative principle:** Calm motion density, few concurrent subtle motions,
  restful garden sanctuary. This is the **inherited visual direction** from
  `VISUAL_STYLE_BIBLE.md` and remains a guiding qualitative standard.
- **Exact numeric budget (3–5 simultaneous motions):** This is a **PROVISIONAL
  TECHNICAL TARGET**, not a hard permanently locked technical maximum. It provides
  an initial budget for composition and staging, to be empirically validated and
  tuned during the vertical-slice and device testing spike.

### 26.2 Technical Implementation Principles

- Not every plant animates simultaneously. Only the plant in the active
  interaction focus, or triggered by a wind event, animates.
- Visitors animate when they are present; idle after they depart.
- Background ambient motions (lamp pulse, firefly drift) are independent,
  low-frequency, asynchronous.
- Do NOT run `AnimationPlayer` nodes for off-screen entities (implement
  visibility-based pausing in a future task when prototyping).

### 26.3 Battery Awareness

Consistent with `ARCHITECTURE.md` §37 (Performance and Battery Rules):

- Avoid per-frame `_process` in scripts that manage animations unnecessarily.
- `AnimatedSprite2D` handles its own frame advancement at the engine level;
  do not replicate this in GDScript.
- Particles for rain and ambient effects should have conservative emission
  rates; do not default to maximum particle density.

### 26.4 Not Implemented in Task 4.3

Runtime visibility culling, LOD-based animation pausing, and battery profiling
are deferred to a later implementation task.

---

## 27. File Format Policy

**Status: LOCKED TECHNICAL PIPELINE (PNG as primary); PROVISIONAL (WebP exceptions)**

### 27.1 Primary Runtime Format: PNG

All hand-painted sprite runtime exports use **PNG** (Portable Network Graphics).

- Lossless encoding preserves painting quality and soft alpha edges.
- Universal tool support for artists and developers.
- Godot 4 natively imports PNG.
- VRAM compression is applied by Godot's importer independently of the
  disk format.

### 27.2 JPEG: Strictly Forbidden for Sprites

JPEG does not support transparency. Any sprite with an alpha channel
**must not** use JPEG. JPEG introduces block artifacts at soft painted edges.

JPEG may only be considered for opaque, photographic background elements
with no transparency requirement — there are no such assets in this project's
planned content.

### 27.3 WebP as Alternative

Godot 4 supports WebP import. WebP offers better disk compression than PNG
at the cost of lossy (or somewhat larger lossless) encoding.

- **Lossless WebP** for sprites: slightly smaller disk size than PNG; acceptable
  in theory, but tool support in painting software varies. Use only if the
  export pipeline reliably produces lossless WebP with correct alpha.
- **Lossy WebP** for any sprite with soft alpha edges: generally NOT recommended;
  introduces compression artifacts at alpha boundaries that the GPU's linear
  filter then blurs, creating visible fringing.

Default: use PNG for all hand-painted sprites. Evaluate WebP only with
evidence in the technical spike.

### 27.4 SVG

Permitted for simple UI geometric shapes. Not appropriate for painted art.
See Section 22.5.

### 27.5 Source Master Formats

Source masters may use any format appropriate to the artist's toolchain:
`.kra` (Krita), `.psd` (Photoshop), `.xcf` (GIMP), `.ase` or `.aseprite`
(Aseprite), `.afphoto` (Affinity Photo). These formats are not committed to
the game repository.

---

## 28. Version-Control Policy

**Status: LOCKED TECHNICAL PIPELINE**

### 28.1 What IS Committed to Git

| File Type | Commit? | Notes |
|---|---|---|
| Runtime export PNGs (`assets/**/*.png`) | **YES** | Primary game art; in `assets/` |
| `.import` sidecar files (`assets/**/*.png.import`) | **YES** | Import configuration; must be committed — see §28.4 |
| `SpriteFrames` resource (`.tres`) | **YES** | Animation data; text-based; reviewable |
| Other `.tres` content/definition files | **YES** | Text-based resources |
| Scene files (`.tscn`) referencing assets | **YES** | Text-based; reviewable |
| `export_presets.cfg` | **YES** | Already tracked |
| `project.godot` | **YES** | Already tracked |

### 28.2 What Is NOT Committed

| File Type | Commit? | Notes |
|---|---|---|
| `.godot/` directory (all contents) | **NO** | Already in `.gitignore`; import cache, generated files |
| `.godot/imported/` (import cache) | **NO** | Auto-generated; regenerated on next editor launch |
| Source masters (`.kra`, `.psd`, `.ase`, `.xcf`) | **NO** | Too large; editable source masters normally belong outside repo (see §3.2 and §28.3) |
| Failed concept iteration exports | **NO** | Stochastic output; do not accumulate |
| Temporary test exports | **NO** | Delete after validation |
| `.DS_Store`, `Thumbs.db`, editor state | **NO** | Already in `.gitignore` |
| APK/build outputs | **NO** | Already in `.gitignore` |
| Signing keys / credentials | **NO** | Security requirement |

**Note:** `.import` sidecar files (e.g., `assets/plants/holy_basil/holy_basil_mature.png.import`)
are NOT in `.godot/`; they live next to the source asset and MUST be committed.
Only `.godot/` directory contents are excluded.

### 28.3 Large Binary Source Master Handling

Without Git LFS (not introduced in Task 4.3):

- Do not commit large binary source masters to this repository.
- If source masters must be tracked, use a separate storage mechanism
  (cloud drive, separate repository, or future Git LFS adoption with owner
  approval).
- If the owner later intentionally approves tracking source masters inside the same
  repository under the project root (e.g., `art_sources/`), an empty `.gdignore` file
  must be placed in that folder so Godot ignores it from project scanning and import
  (see §3.2). Do not confuse `.gitignore` (which stops Git tracking) with
  `.gdignore` (which stops Godot scanning/importing).
- Only the runtime export PNG is what the game needs; only that is committed.

### 28.4 Godot Import Sidecar Files

In Godot 4, texture import settings are stored in the `.godot/imported/`
directory (auto-generated) and in `.import` sidecar files co-located with the
source file. The `.import` files need to be examined:

**Verified behavior (Godot 4.7.2 project inspection):**

- `.godot/` is gitignored (confirmed in `.gitignore`)
- Godot 4 stores import cache in `.godot/imported/` — these are generated and
  not committed
- In Godot 4, per-file import settings are stored as `.import` sidecar files
  next to the source asset in the project tree (e.g., `texture.png.import`)

**Policy for `.import` files:**

`.import` sidecar files in Godot 4 store the import parameters chosen in the
Import panel for each asset. These **should be committed** to Git because they
encode the project's intentional import settings (compression mode, mipmap on/off,
process options, etc. — excluding CanvasItem filtering, which is configured
via CanvasItem nodes or project setting; see §15.4) and enable reproducible builds.

**Add to `.gitignore` only:** the `.godot/` directory (already done).
Do NOT add `*.import` to `.gitignore`.

---

## 29. AI-Assisted and Generated Art Policy

**Status: LOCKED TECHNICAL PIPELINE**

The project has used AI-generated images as visual evidence for Round-A and
Round-B mockup evaluation.

### 29.1 Concept Generation Is Not Production Art

- Generated concept images used in Tasks 4.2A–4.2E are **reference material
  only**. They demonstrate visual direction; they are not production-ready
  game sprites.
- A generated image does not automatically become a production asset merely
  because it was used in a review.

### 29.2 Production Asset Requirements

Every production runtime export, regardless of its creation method
(hand-painted, AI-assisted, or AI-generated), must satisfy:

- The same technical checklist in Section 31
- The same visual direction standards from `VISUAL_STYLE_BIBLE.md`
- No residual watermarks, model-provider logos, or generation artifacts
- No embedded AI-generated text or labels
- Clean, intentional alpha edges (AI generation often produces noisy or
  incorrect alpha — must be cleaned)
- Correct pivot placement
- Correct dimensions and format

### 29.3 Stochastic Artifacts Do Not Become Requirements

Accidental details in concept images (extra objects, wrong species traits,
style drift) do not create new content commitments. Only `GAME_DESIGN.md`
and explicit owner decisions define gameplay content.

### 29.4 Intentional Selection Required

When AI assistance is used in production, the artist/developer must:

1. Review the generated output critically
2. Select or clean a specific result
3. Export it correctly per this pipeline
4. Run it through the acceptance checklist

Automated batch export of generation outputs into the `assets/` directory
without review is not permitted.

---

## 30. Godot Import and Cache Behavior

**Status: LOCKED TECHNICAL PIPELINE (verified against Godot 4.7.2)**

### 30.1 What Godot Does on Import

When an image file is placed in the Godot project tree and the editor is open:

1. Godot detects the new file.
2. Godot generates a `.import` sidecar file next to the asset (e.g.,
   `assets/plants/holy_basil/holy_basil_mature.png.import`).
3. Godot processes the image and stores the import result (in the GPU-ready
   compressed format) under `.godot/imported/`.
4. The `.godot/` directory is entirely generated and ephemeral.

### 30.2 Which Files to Source-Control

| File / Directory | Origin | Track in Git? |
|---|---|---|
| `assets/**/*.png` | Artist export | **YES** |
| `assets/**/*.png.import` | Godot auto-generated (but represents settings) | **YES** |
| `.godot/imported/**` | Godot cache | **NO** (gitignored) |
| `.godot/editor/**` | Editor state | **NO** (gitignored) |
| `*.uid` files next to `.gd` | Godot 4 generated UID | **YES** (already tracked) |

**Important Godot 4 distinction from Godot 3:** In Godot 4, the `.import`
sidecar files encode the import settings. Unlike Godot 3 where import files
were sometimes also cached data, in Godot 4 these sidecar files are the
authoritative record of the import configuration. Commit them.

**Note on `.gdignore`:** If non-game files or source masters are intentionally placed
within the project tree and tracked in Git under an approved policy (e.g., `art_sources/`),
an empty `.gdignore` file prevents Godot from scanning and importing them. `.gdignore`
affects Godot resource indexing, while `.gitignore` affects Git tracking.

### 30.3 Regenerating the Import Cache

The `.godot/imported/` directory can always be regenerated by Godot from the
source assets and their `.import` sidecar files. If an engineer deletes
`.godot/`, the next editor launch will reimport all assets. This is the
intended behavior.

### 30.4 Headless Import Behavior

In headless mode (`godot --headless`), imports are processed using the cached
`.godot/imported/` data. For the canonical test command:

```
godot --headless --path . --script res://tests/run_tests.gd
```

This runs domain tests that do not depend on texture import state; headless
import is therefore not required for test correctness.

---

## 31. Asset Acceptance Checklist

**Status: LOCKED TECHNICAL PIPELINE**

Every production runtime export must pass this checklist before being staged
for commit.

```
ASSET ACCEPTANCE CHECKLIST
===========================

IDENTITY
[ ] Correct category (plants / visitors / decorations / environment / ui / effects)
[ ] Stable content ID maps to correct directory and filename per naming contract
[ ] No version suffix in filename (_v2, _final, _fixed)

VISUAL
[ ] Satisfies approved Master Style (Balanced Storybook Hybrid — VISUAL_STYLE_BIBLE.md §5)
[ ] Silhouette readable at intended display scale
[ ] Cultural guardrails respected (no temple tropes, no tourist kitsch, etc.)
[ ] No embedded text, label, watermark, or generation artifact
[ ] Edge quality: soft painted edges without harsh clipping or halo
[ ] No high-frequency noise or grit that harms phone readability

SCALE
[ ] Exported at correct runtime dimensions per calibration (not yet exact — validate in spike)
[ ] Sprite2D.scale = Vector2(1, 1) in scene; no arbitrary corrective scale applied

BOUNDS
[ ] Minimum 4 px transparent gutter on all sides of painted content
[ ] For animation sequences: all frames have identical pixel dimensions
[ ] Pivot placement correct per category (Section 12)
[ ] Pivot stable across animation frames

COLOR
[ ] sRGB color space (no linear, no CMYK, no wide-gamut profile)
[ ] Straight alpha (not premultiplied)
[ ] No colored halo / fringe at transparent edges
[ ] Color profile consistent with source master intent

IMPORT SETTINGS (in .import sidecar)
[ ] Compression mode per category decision matrix (Lossless baseline; Section 17)
[ ] Mipmap setting per category decision matrix (Section 16)
[ ] Image process/import options configured properly (Fix Alpha Border, Premult Alpha off)
[ ] .import sidecar file generated and staged for commit

RENDERING FILTER (CanvasItem / Project Setting)
[ ] Linear filter policy respected for painterly sprites (Section 15)
[ ] Configured via project Canvas default or explicit CanvasItem.texture_filter override (not in .import)

PERFORMANCE
[ ] Pixel dimensions within category guideline (Section 9)
[ ] GPU memory estimate checked against budget awareness (Section 10)
[ ] For animation: frame count within provisional budget range (Section 25)
[ ] Atlas / sheet decision appropriate (Section 18)

MOBILE
[ ] Readable at reference canvas scale on a phone-sized display
[ ] Key silhouette identifiable without zooming
[ ] No single-pixel detail that carries essential information (VISUAL_STYLE_BIBLE.md §25)

GIT
[ ] Only this production file committed (no source masters, no test exports)
[ ] .import sidecar committed alongside the PNG
[ ] git diff --check passes (no whitespace errors)
[ ] Working tree clean before commit
```

---

## 32. Exception Process

**Status: LOCKED TECHNICAL PIPELINE**

When a specific asset must violate a default pipeline rule, the exception must
be documented before the asset is committed.

An exception document (comment in the commit message, entry in a `EXCEPTIONS.md`
file, or a code review note) must state:

1. **Which default is exceeded:**
   (e.g., "texture exceeds 2048 px on one axis" or "Nearest filter used
   instead of Linear")

2. **Why the exception is necessary:**
   (e.g., "Background panel is a full-screen composition; its natural authored
   size is 1080 × 1920 = ~8 MB RGBA8")

3. **Memory / performance implication:**
   (e.g., "Adds ~8 MB uncompressed; mitigated by ETC2 compression to ~2 MB")

4. **Visual benefit:**
   (e.g., "Painting full-resolution avoids any resampling artifact on the
   background panel")

5. **Device / profiling evidence (if available):**
   (e.g., "Profiled on mid-range Android; frame time acceptable with single
   background texture")

6. **Reviewer approval:**
   (explicit acknowledgment from project owner or lead)

Committing an out-of-spec asset without a documented exception is a
production pipeline violation.

---

## 33. First Production Validation Set

**Status: PROVISIONAL TECHNICAL PIPELINE (defined in Task 4.3; not produced in Task 4.3)**

The first future asset set that validates this pipeline:

**Plants:**
- Holy basil: all 4 stages (`holy_basil_planted.png` through `holy_basil_mature.png`)
- Marigold: all 4 stages (`marigold_planted.png` through `marigold_mature.png`)

**Visitors:**
- Butterfly: flutter animation (4–8 frames), rest pose (1–2 frames)
- Cat: idle animation (4–8 frames), sleep pose (2–4 frames)

**Decorations:**
- Bench: single idle sprite
- Clay water jar: single idle sprite

**Environment:**
- Representative background panel (house eave, fence, sky strip)
- Ground layer (soil/paver patch)

**Conditions:**
- Base/day presentation (all the above)
- Rain: rain streak texture, ripple animation
- Night: firefly glow sprite (as particle texture); verify CanvasModulate
  approach on base sprites

**Validation Goals:**
- Confirm pivot placement on device
- Confirm visual scale at reference canvas
- Confirm filter quality on device
- Confirm alpha edge quality
- Confirm visual quality under Lossless baseline vs ETC2 compression on hand-painted sprites
- Confirm animation readability on device
- Confirm memory estimates

Do NOT produce these assets in Task 4.3.

---

## 34. Empirical Validation: Completed Spike & Remaining Device Gate

**Status: LOCKED TECHNICAL PIPELINE (framework & completed evidence) / TBD (device execution)**

The empirical validation strategy is split into two phases: local/build validation
(completed in Task 4.4A) and physical on-device validation (deferred to a future
owner-approved task).

### 34.1 Completed Local and Build Validation (Task 4.4A Spike)

- **Authoritative Evidence Document:** `ASSET_PIPELINE_SPIKE_REPORT.md`
- **Spike Outcome:** `PARTIAL — local/import/build validation completed; device-dependent evidence remains unavailable`
- **Completed Baseline:**
  - Godot Engine: `4.7.2.stable.official.ed1daf0bf`
  - Render Pipeline: GL Compatibility 2D
  - Reference Canvas: 1080 × 1920
  - APK Build & Signing: Android Debug APK produced (exit 0), signed with v2/v3 schemes

**Mechanically Validated Outcomes:**
1. **Import Mode Mapping:** Verified `compress/mode` enum (0=Lossless, 1=Lossy, 2=VRAM Compressed, 3=VRAM Uncompressed, 4=Basis Universal).
2. **Import Configuration & Sidecars:** Verified Lossless generates `.ctex` and VRAM Compressed generates both `.s3tc.ctex` (desktop) and `.etc2.ctex` (Android Compatibility) in `.godot/imported/`.
3. **Mipmap Math & Storage:** Mathematically validated ~33.3% GPU residency overhead; empirically demonstrated disk cache growth (+63.7%) does not equal GPU VRAM overhead.
4. **Metric Distinctions:** Formally demonstrated that Source PNG disk bytes != imported `.ctex` cache bytes != GPU residency != APK size.
5. **Reference-Canvas Scale:** Validated 1:1 authoring/display on representative reference-size subjects (background, pivot, foliage, animation).
6. **Bottom-Center Pivot Default:** Confirmed Option A (`centered = true`, `offset.y = -h/2`) is mechanically simpler and less error-prone than Option B.
7. **Animation Registration:** Confirmed uniform 256 × 256 canvas dimensions and identical (128, 248) contact coordinates eliminate frame-bound-induced jump by construction.
8. **Filtering Locus:** Confirmed filtering configuration belongs to CanvasItem nodes and ProjectSettings, not `.import` sidecars.
9. **Android Export Viability:** Confirmed headless Android debug export (exit 0) and APK signing (v2/v3 valid).

**Visually / Device Unverified in Task 4.4A:**
- Direct visual comparison of Linear vs Nearest in rendered Compatibility output (blocked by headless Dummy Rendering Server).
- On-device ETC2 visual artifact acceptability on fine watercolor washes and soft alpha edges.
- Perceived animation smoothness, absence of GPU jitter, and frame pacing at 8–12 FPS.
- Actual on-device GPU residency, real frame timing, battery behavior, and total scene memory budget.

### 34.2 Remaining Device Validation Gate

The remaining empirical validation gate requires physical Android hardware.

**Prerequisite:** Connected-device testing and APK installation must require
**explicit owner approval**. No automatic APK installation is defined or permitted.

When authorized, a future dedicated device validation task must evaluate:

1. **Lossless vs. ETC2 Visual Comparison:**
   - Inspect soft watercolor/gouache translucent stroke boundaries on physical phone displays.
   - Inspect dark semi-transparent contact shadows under bench, jar, and plants for ETC2 block artifacts or color fringing.
   - Evaluate fine foliage detail (holy basil) and petal clusters (marigold) under ETC2.
   - Inspect large background gradients (sky, wall) for compression banding.
2. **Real Rendering & Performance Metrics:**
   - Measure actual frame timing, pacing, and potential frame drops on representative hardware.
   - Record actual GPU residency and memory metrics where measurable.
   - Assess perceived animation feel and smoothness at 8–12 FPS.
   - Assess battery/power consumption only if a responsible, non-distorted measurement method is available.

The device gate will formally decide whether any asset category is justified
to promote from the Lossless baseline to VRAM Compressed (ETC2).

---

## 35. Performance Formulas Reference

**Status: LOCKED TECHNICAL PIPELINE — MATHEMATICALLY & MECHANICALLY VALIDATED (Task 4.4A)**

### 35.1 RGBA8 Memory

```
Uncompressed RGBA8 memory (bytes) = width × height × 4
Uncompressed RGBA8 with mipmaps  = width × height × 4 × 1.333
```

### 35.2 Representative Sprite Set Example

Hypothetical vertical-slice scene at full load:

```
Asset                         Dimensions    RGBA8 (Uncompressed)  ETC2 RGBA (~25% / 4:1)
----------------------------------------------------------------------------------------
holy_basil_mature             300×350       420 KB                ~105 KB
holy_basil_planted            300×100       120 KB                ~30 KB
marigold_mature               280×380       ~426 KB               ~106 KB
marigold_planted              280×80        ~90 KB                ~22 KB
cat_idle x6 frames            300×300 each  ~2.16 MB              ~540 KB
butterfly_flutter x6 frames   100×100 each  240 KB                60 KB
clay_jar                      250×350       350 KB                ~88 KB
bench                         480×280       ~538 KB               ~134 KB
background                    1080×1920     ~8.29 MB              ~2.07 MB
----------------------------------------------------------------------------------------
APPROXIMATE TOTAL (if all ETC2)                                   ~3.65 MB
APPROXIMATE TOTAL (Lossless sprites + ETC2 background)            ~6.4 MB
```

**Notes on the estimate:**
- **ETC2 is the applicable mobile format:** Under Garden's GL Compatibility
  renderer on Android, VRAM compression uses ETC2 RGBA (8 bpp = ~25% of RGBA8 / 4:1
  ratio), NOT ASTC. ASTC requires High Quality VRAM compression, which is
  unconditionally disabled in Compatibility (see §17.1).
- **Illustrative Arithmetic Only:** The estimated ~6.4 MB total residency is
  purely illustrative arithmetic demonstrating the formula. No total scene-memory
  acceptability threshold has been established, and this calculation does not
  constitute an approved budget. Total scene texture-memory budget remains
  **TBD / REQUIRES REPRESENTATIVE DEVICE EVIDENCE**.
- **Fixed-rate GPU residency vs. variable disk size:** Disk compression ratios
  (PNG, WebP, Lossy) vary with image content and encoder settings. ETC2
  GPU-memory residency is fixed-rate for a given format and dimension (8 bits/pixel
  for ETC2 RGBA, ~25% of RGBA8 / ~4:1 ratio), aside from block alignment (padding
  to 4×4 block multiples), mipmaps, format/channel selection, and resource overhead;
  it does not vary based on whether visual content is simple or complex.

### 35.3 Sprite Sheet Growth

If N animation frames are combined into a sprite sheet:

```
Sheet area = ceil(sqrt(N)) × max_frame_width × ceil(sqrt(N)) × max_frame_height
             (if packed in a square grid; actual packing may be more efficient)
```

Memory is proportional to total pixel area regardless of packing.

### 35.4 Full-Screen Texture Cost

A full-canvas background at 1080 × 1920 RGBA8: **~7.91 MiB uncompressed** (8,294,400 bytes).
With ETC2 RGBA (8 bpp, 25% / 4:1): approximately **~1.98 MiB** (2,073,600 bytes).

*(For mathematical context, ASTC 6×6 would theoretically yield ~11.1% or ~920 KB,
but ASTC is not the runtime format under Compatibility renderer on Android).*

This is the single most expensive texture in the vertical slice; it justifies
empirical comparison of Lossless vs Lossy vs ETC2 during the remaining device gate.

---

## 36. Locked vs Provisional vs TBD Summary Table

**Status: Authoritative decision status ledger updated with Task 4.4A empirical spike decisions (Task 4.4B).**

| Decision Area | Status | Notes |
|---|---|---|
| **Runtime directory structure** | LOCKED TECHNICAL PIPELINE | `assets/{category}/{entity}/` |
| **Naming conventions** | LOCKED TECHNICAL PIPELINE | Lowercase snake_case ASCII |
| **Reference-canvas scale strategy** | LOCKED TECHNICAL PIPELINE — MECHANICALLY VALIDATED (Task 4.4A) | 1:1 canvas pixel; no PPU concept; arbitrary corrective scale forbidden. Validated on 1080×1920 background, grounded pivot, foliage, and animation reference subjects in Task 4.4A. (Note: two gradient comparison sprites used `scale = Vector2(0.45, 0.45)` solely for side-by-side diagnostic fixture layout, not production corrective scaling). |
| **Pivot rules by category / Grounded default (Option A)** | LOCKED TECHNICAL PIPELINE — MECHANICALLY VALIDATED (Task 4.4A) | Option A (`centered = true, offset.x = 0, offset.y = -(height / 2)`) confirmed mechanically as canonical default for grounded gameplay sprites; center pivot for flying/UI/environment items (see Section 12). |
| **Texture filtering configuration locus** | LOCKED TECHNICAL PIPELINE — MECHANICALLY VALIDATED (Task 4.4A) | Texture filtering is controlled via `CanvasItem.texture_filter` and project defaults, not `.import` sidecars. Linear default retained. |
| **Texture filtering rendered visual comparison (Linear vs Nearest)** | UNVERIFIED — RENDERED VISUAL EVIDENCE REQUIRED | Direct rendered visual difference was not captured in Task 4.4A due to macOS headless dummy rendering server (`PN13RendererDummy`). |
| **Power-of-two not required** | LOCKED TECHNICAL PIPELINE | Verified Godot 4 NPOT support |
| **Source vs. runtime boundary** | LOCKED TECHNICAL PIPELINE (principle) | Source masters outside game tree |
| **JPEG forbidden for sprites** | LOCKED TECHNICAL PIPELINE | No transparency support |
| **PNG as primary format** | LOCKED TECHNICAL PIPELINE | Canonical lossless master format |
| **4 px transparent gutter minimum** | PROVISIONAL TECHNICAL PIPELINE | Retained provisional; not directly isolated or challenged in Task 4.4A; to be validated with production art assets. |
| **Mipmap defaults (plants/visitors/deco)** | PROVISIONAL TECHNICAL PIPELINE (OFF) | Theoretical +33.33% overhead validated; actual GPU residency and filtering benefit require device validation. |
| **Mipmap defaults (backgrounds/effects)** | PROVISIONAL TECHNICAL PIPELINE (ON) | Theoretical +33.33% overhead validated; device validation required. |
| **Compression: Lossless baseline for 2D sprites** | PROVISIONAL TECHNICAL PIPELINE | Mechanically validated import/build path via `compress/mode=0`; retains provisional baseline status pending device visual/memory confirmation. |
| **Compression: Large environment/background** | PROVISIONAL / EMPIRICAL COMPARISON REQUIRED | Dual `.ctex` generated in build; choice between Lossless vs Lossy vs ETC2 requires device visual comparison. |
| **Atlas strategy: no premature atlas** | PROVISIONAL TECHNICAL PIPELINE | Profiling-driven optimization only |
| **AnimatedSprite2D for character animation** | PROVISIONAL TECHNICAL PIPELINE | Mechanically validated via SpriteFrames in Task 4.4A; visual pacing/smoothness requires device evaluation. |
| **Animation frame consistency contract** | LOCKED TECHNICAL PIPELINE — MECHANICALLY VALIDATED (Task 4.4A) | Uniform frame canvas (e.g. 256×256) + identical contact coordinate eliminate frame-bound jump by construction. |
| **AnimationPlayer for property animation** | PROVISIONAL TECHNICAL PIPELINE | Leaf sway, lamp, firefly |
| **Animation budget ranges (8–12 FPS)** | PROVISIONAL TECHNICAL TARGET | 8 FPS mechanically loaded in Task 4.4A; visual smoothness and pacing remain unverified on device. |
| **Motion density target (3–5 concurrent)** | PROVISIONAL TECHNICAL TARGET | Validate in future gameplay integration; calm motion principle is inherited visual direction |
| **sRGB color space for runtime exports** | LOCKED TECHNICAL PIPELINE | Godot 4 default assumption |
| **Straight alpha (not premultiplied)** | LOCKED TECHNICAL PIPELINE | Godot 4 default import behavior |
| **Lighting-neutral base art** | PROVISIONAL TECHNICAL PIPELINE | Form-shadow OK; baked directional forbidden |
| **No separate day/night sprite sets by default** | PROVISIONAL TECHNICAL PIPELINE | CanvasModulate preferred |
| **Git: .import files committed** | LOCKED TECHNICAL PIPELINE — MECHANICALLY VALIDATED (Task 4.4A) | Import settings are intentional configuration; validated in build pipeline. |
| **Git: .godot/ not committed** | LOCKED TECHNICAL PIPELINE — MECHANICALLY VALIDATED (Task 4.4A) | Excluded via .gitignore; clean headless build validated. |
| **Git LFS not introduced** | LOCKED TECHNICAL PIPELINE (Milestone 4 scope) | Future decision required if source assets exceed git comfort |
| **Source master storage location** | PROVISIONAL / OWNER DECISION REQUIRED | Preferred outside project root; .gdignore alternative if same-repo tracked masters chosen (see §3.2) |
| **Memory sizing formulas (RGBA8, ETC2, Mipmaps)** | LOCKED TECHNICAL PIPELINE — MATHEMATICALLY & MECHANICALLY VALIDATED (Task 4.4A) | 4 bytes/px (RGBA8 uncompressed), 8 bpp / 25% (ETC2 4×4 block), +33.33% mipmaps; 4 distinct metrics confirmed. |
| **Android debug export & v2/v3 signing viability** | LOCKED TECHNICAL PIPELINE — MECHANICALLY VALIDATED (Task 4.4A) | Clean APK build and valid signature verified via apksigner. |
| **ETC2 visual artifact acceptance** | TBD / DEVICE VALIDATION REQUIRED | Block compression artifacts on painterly gradients unverified due to headless dummy rendering server. |
| **Total scene texture memory budget** | TBD / DEVICE VALIDATION REQUIRED | Mathematical formulas validated; actual GPU residency and budget ceiling require connected device profiling (see §10.4). |
| **Real Android frame timing & battery behavior** | TBD / DEVICE VALIDATION REQUIRED | Requires connected Android device profiling. |
| **Exact per-asset pixel dimensions** | TBD / REQUIRES EMPIRICAL VALIDATION | Calibration during technical spike / production asset authoring |
| **Final font family** | TBD | Future UI asset task |
| **Final shader architecture** | TBD | Future implementation milestone |
| **Wet surface overlay approach** | TBD / PROVISIONAL | Shader vs sprite; validate in future spike |
| **WebP for sprite runtime format** | TBD | Evaluate vs PNG in spike if package size requires |
| **Lossless vs ETC2 quality trade-off** | TBD / REQUIRES EMPIRICAL COMPARISON | Compare on device during future device validation gate (Section 17.3, Section 34) |

---

## 37. Visual Authority Confirmation

This document defines technical pipeline rules only.

The following visual decisions remain **unchanged and unmodified** by Task 4.3:

| Visual Direction | Status | Authority |
|---|---|---|
| Balanced Storybook Hybrid Master Style | LOCKED + ROUND-B VALIDATED | VISUAL_STYLE_BIBLE.md |
| Rain visual treatment (qualitative) | VALIDATED / LOCKED QUALITATIVE DIRECTION | VISUAL_STYLE_BIBLE.md §13.1.1 |
| Night visual treatment (qualitative) | VALIDATED / LOCKED QUALITATIVE DIRECTION | VISUAL_STYLE_BIBLE.md §13.1.2 |
| 4-stage plant growth visual readability | VALIDATED / LOCKED QUALITATIVE DIRECTION | VISUAL_STYLE_BIBLE.md §14 |
| Natural visitor scale and anatomy | VALIDATED / LOCKED QUALITATIVE DIRECTION | VISUAL_STYLE_BIBLE.md §15 |
| Everyday Thai-inspired domestic identity | LOCKED VISUAL DIRECTION | VISUAL_STYLE_BIBLE.md §4 |
| No heavy black outlines | LOCKED VISUAL DIRECTION | VISUAL_STYLE_BIBLE.md §5.2 |
| No pixel art | LOCKED VISUAL DIRECTION | VISUAL_STYLE_BIBLE.md §5.4 |
| No chibi/mascot proportions | LOCKED VISUAL DIRECTION | VISUAL_STYLE_BIBLE.md §15.1 |

---

## 38. Engine-Specific Claims: Verification Record

The following Godot 4.7.2 technical claims were verified:

| Claim / Engine Fact | Verification Method & Authority |
|---|---|
| **A.** Lossless is default/common for 2D assets | Official Godot 4.7 documentation (*Importing images*): "Lossless: This is the default and most common compression mode for 2D assets." |
| **B.** VRAM Compressed can produce noticeable 2D artifacts | Official Godot 4.7 documentation (*Importing images*): warns VRAM compression produces noticeable block artifacts, especially on lower-resolution 2D textures. |
| **C.** Lossy mode does not reduce GPU memory relative to Lossless | Official Godot 4.7 documentation (*Importing images*): "Video memory usage isn't decreased by this mode; it's the same as with Lossless or VRAM Uncompressed." |
| **D.** ETC2 RGBA memory ratio is ~4:1 versus RGBA8 (8 bpp vs 32 bpp = 25%) | Official Godot 4.7 documentation (*Importing images*): confirms ~4:1 compression ratio for RGBA textures; standard GPU format specification (8 bits/pixel vs 32 bits/pixel). |
| **E.** Compatibility renderer disables High Quality VRAM compression | Official Godot 4.7 documentation (*Importing images*): "High-quality VRAM texture compression is only supported in the Forward+ and Mobile renderers. When using the Compatibility renderer, High Quality is always considered disabled." |
| **F.** With High Quality disabled, desktop uses S3TC and Android/mobile uses ETC2 | Official Godot 4.7 documentation (*Importing images*): "uses S3TC on desktop platforms and ETC2 on mobile/web platforms." ASTC is therefore not the runtime format under Compatibility on Android. |
| **G.** Full mipmaps add ~33% additional memory | Standard graphics engineering formula (geometric series: 1 + 1/4 + 1/16 + ... ≈ 1.333×); confirmed in engine asset pipeline context. |
| **H.** 2D texture filtering is CanvasItem / project-default based, not in `.import` | Official Godot 4.7 documentation (*Importing images*): "Since Godot 4.0, texture filter and repeat modes are set in the CanvasItem properties in 2D (with a project setting acting as a default)..." Verified in Task 4.4A. |
| **I.** `<asset>.import` sidecar files should be committed to VCS | Official Godot 4.7 documentation (*Import process*): "Make sure to commit these files to your version control system, as these files contain important metadata." |
| **J.** `.godot/` directory should NOT be committed to VCS | Official Godot 4.7 documentation (*Import process*); confirmed in project `.gitignore` (`.godot/`). |
| **K.** `Sprite2D.centered = false` only shifts texture from center to top-left; not a bottom-center anchor | Official Godot 4.7 `Sprite2D` class reference: `centered` determines whether texture is centered around origin; an additional drawing offset is required to achieve a bottom-center anchor. Verified in Task 4.4A Option A vs Option B comparison. |
| **L.** `.gdignore` ignores a directory from Godot project scanning and import | Official Godot 4.7 documentation (*Project organization*): An empty `.gdignore` file completely excludes a folder and its contents from Godot resource scanning and import. Does not affect Git tracking (which is managed by `.gitignore`). |
| **M.** Android debug export viability with v2/v3 signing | Mechanically verified in Task 4.4A: Godot 4.7.2 CLI export produced 30,681,193-byte APK (~29.26 MiB) verified with `apksigner verify --verbose` (v2/v3 true). |
| **N.** Dual texture compilation under GL Compatibility | Mechanically verified in Task 4.4A: `.s3tc.ctex` (desktop) and `.etc2.ctex` (mobile) both compiled into `.godot/imported/`. |
| **O.** Headless environment on macOS uses Dummy Rendering Server | Mechanically verified in Task 4.4A: `PN13RendererDummy` used in headless terminal execution, blocking direct visual screenshot capture and rendered visual verification. |
| **P.** Sprite2D Option A grounded pivot mechanism | Mechanically verified in Task 4.4A: `centered = true, offset.x = 0, offset.y = -(height / 2)` grounds bottom-center directly at node origin. |
| **Q.** AnimatedSprite2D uniform frame bounds contract | Mechanically verified in Task 4.4A: 256×256 canvas with fixed contact point (128, 248) eliminates frame-bound jumps by construction. |
| Engine version `4.7.2.stable.official.ed1daf0bf` | `godot --version` command run in project directory |
| Viewport 1080×1920 portrait, Compatibility renderer | Direct inspection of `project.godot` |
| NPOT textures supported natively | Official Godot 4 documentation; GL Compatibility 2D renderer handles NPOT |
| AnimatedSprite2D + SpriteFrames valid for 2D animation | Official Godot 4 class reference; verified in Task 4.4A |
| WebP import support | Official Godot 4 supported image formats documentation |
Claims based solely on web search results (not directly verifiable in the local
project) are marked PROVISIONAL and flagged for validation in the technical spike.

---

*End of ASSET_PIPELINE.md*
*Task 4.3 / Task 4.4B — Asset Technical Pipeline (Spike Decisions Recorded)*
*Milestone 4 — Visual Direction and Asset Pipeline*
