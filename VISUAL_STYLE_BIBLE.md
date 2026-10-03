# Garden Visual Style Bible

> Status: **Authoritative Visual Style Bible — Milestone 4 (Task 4.2E Round-B Owner Validated Master Style)**
>
> Reference Target: **Android Portrait (1080 × 1920 Responsive)**
>
> Engine Baseline: **Godot 4.7.2 Stable (Compatibility 2D)**

---

## 1. Document Authority and Precedence

**Status: LOCKED**

This document establishes the authoritative **Visual Style Bible** for the *Garden* project. Its purpose is to guide visual artists, concept creators, UI designers, animators, image-generation workflows, and technical developers so that all artwork, mockups, sprites, environment elements, interface components, and weather treatments remain unified, authentic, and purposeful.

### 1.1 Scope of Authority

- **Visual Execution Only:** This document governs art direction, visual composition, aesthetic language, color hierarchy, lighting, animation feel, and material presentation.
- **Subordinate to Project Foundations:** This document is strictly subordinate to:
  1. Explicit project owner instructions in the current task.
  2. `PROJECT_RULES.md` (non-negotiable quality and process guardrails).
  3. `ARCHITECTURE.md` (technical structure, state ownership, lifecycle, performance).
  4. `GAME_DESIGN.md` (player experience, design pillars, economy, core loop).
  5. `DEFINITION_OF_DONE.md` (verification gates and defect severity).
- **No Gameplay Redefinition:** This document must not redefine or expand locked gameplay mechanics, introduce new MVP commitments, create new currencies, or alter progression rules.
- **Conflict Resolution:** If any visual proposal conflicts with architecture or game design contracts, the higher-level documents prevail.
- **Document Integrity:** Existing authoritative documents (`PROJECT_RULES.md`, `GAME_DESIGN.md`, `ARCHITECTURE.md`, `DEFINITION_OF_DONE.md`) are not modified by this visual guide.

---

## 2. Visual Decision Status Framework

**Status: LOCKED**

Following the discipline established in `GAME_DESIGN.md` and `ARCHITECTURE.md`, every visual direction in this document is classified into one of three explicit status levels:

- **LOCKED VISUAL DIRECTION:** Approved and binding for the project. May only be changed with explicit owner approval.
- **PROVISIONAL VISUAL DIRECTION:** The current preferred visual approach, suitable for concept art, mockups, and prototyping, but subject to refinement during visual milestone reviews.
- **TBD (TO BE DECIDED):** Intentionally open. Must be resolved during downstream pipeline tasks (e.g., Task 4.3 asset technical specifications) without making silent assumptions today.

### 2.1 Status Promotion Rule

A PROVISIONAL visual decision may become LOCKED only when:

1. higher-level authoritative documents (`PROJECT_RULES.md`, `ARCHITECTURE.md`, `GAME_DESIGN.md`) already lock it, OR
2. the project owner explicitly approves/promotes it after visual review (e.g., following Task 4.2 candidate evaluation).

*Governance Event (Task 4.2C):* Condition 2 has occurred. Following visual review of Round-A candidates (A, B, C), the Project Owner has explicitly approved the synthesized Master Style direction (Candidate C foundation + Candidate A atmosphere + Candidate B readability). Approved aesthetic directions and qualitative hierarchies are now **LOCKED VISUAL DIRECTION**. Unrelated technical asset specifications remain **TBD**.

*Governance Event (Task 4.2E):* Condition 2 re-confirmed. Following visual review of Round-B condition validation mockups and controlled refinement, the Project Owner has formally reviewed and approved all four representative scenarios (Rainy Garden: PASS, Night Garden: PASS, Plant Growth Close-Read: PASS, Visitor Moment: PASS).
- Master Style remains **LOCKED + ROUND-B VALIDATED** (UNCHANGED).
- Qualitative treatments for Rain, Night, Plant-Stage Readability, and Visitor Natural Scale are promoted to **VALIDATED / LOCKED QUALITATIVE DIRECTION**.
- Landscape botanical validation plate is recognized as a review/reference format only; Android-first portrait 1080 × 1920 reference game canvas remains locked.
- Technical implementation details (sprite sizes, PPU, atlasing, compression, animation FPS, shaders, exact numerical HEX) remain explicitly **TBD** for Task 4.3.
- Asset Technical Pipeline Gate is **OPEN**.

### 2.2 Visual Decision Audit Table

| Topic / Decision Area | Status | Authority & Notes |
|---|---|---|
| 2D Game Presentation | **LOCKED** | `ARCHITECTURE.md` §3 (Compatibility 2D renderer) |
| Android-First / Portrait / 1080 × 1920 Reference Canvas | **LOCKED** | `ARCHITECTURE.md` §3 (Mobile portrait target; reference canvas unchanged by review plates) |
| Calm, Low-Pressure Visual Experience Goal | **LOCKED PRODUCT GOAL** | `GAME_DESIGN.md` §4 (Pillars 4.1 & 4.2; low-pressure living garden) |
| Soft Hand-Painted / Storybook Visual Treatment | **LOCKED + ROUND-B VALIDATED** | Synthesized Master Style foundation (Candidate C core + Candidate A atmosphere + Candidate B readability); Owner Approved (Task 4.2C) and Validated across all Round-B conditions (Task 4.2E) |
| Everyday Thai-Inspired Domestic Garden Identity | **LOCKED VISUAL DIRECTION — OWNER APPROVED** | Authentic residential home-garden setting; modest, lived-in, humid tropical climate without tourist or temple tropes; Owner Approved (Task 4.2C) |
| Watercolor vs. Gouache Execution Hierarchy | **LOCKED VISUAL DIRECTION** | Balanced Storybook Hybrid: watercolor softness for atmospheric depth; gouache clarity for important gameplay entities; Owner Approved (Task 4.2C) |
| Edge Treatment Hierarchy | **LOCKED QUALITATIVE HIERARCHY** | Firmer painted outer edges on important gameplay entities; softer edges on background/atmosphere; no universal heavy black outline; exact pixel thickness TBD |
| Texture Treatment Strategy | **LOCKED QUALITATIVE HIERARCHY** | Restrained handmade paper/brush character; clear readable entity shapes; zero high-frequency noise that harms phone readability; exact texture assets TBD |
| Silhouette Treatment & Mobile Readability | **VALIDATED / LOCKED QUALITATIVE DIRECTION** | Gameplay plants (4 stages) and visitors (natural domestic scale) readability VALIDATED / LOCKED (Task 4.2E); exact asset dimensions and PPU remain TBD for Task 4.3 |
| Rain Visual Treatment | **VALIDATED / LOCKED QUALITATIVE DIRECTION** | Gentle tropical rain, cozy/refreshing/non-punitive atmosphere, diffuse soft lighting, restrained streaks, wet sheen; shaders & particle density TBD (Task 4.2E) |
| Night Visual Treatment | **VALIDATED / LOCKED QUALITATIVE DIRECTION** | Deep peaceful indigo ambient, localized warm lamp pools, restrained fireflies; no crushed black shadows or neon; exact HEX & lighting nodes TBD (Task 4.2E) |
| Plant Stage Visual Readability | **VALIDATED / LOCKED QUALITATIVE DIRECTION** | 4-stage silhouette differentiation (Planted, Sprout, Growing, Mature) without text dependency; basil vs marigold distinction locked; sprite sizes TBD (Task 4.2E) |
| Visitor Natural-Scale Treatment | **VALIDATED / LOCKED QUALITATIVE DIRECTION** | Believable domestic anatomy, dignified poses; butterfly delicate and small relative to flowers; no chibi/mascots; animation frames TBD (Task 4.2E) |
| Color Palette Character vs. Numerical Values | **LOCKED BROAD CHARACTER / PROVISIONAL VALUES** | Warm, natural, restrained, slightly earthy palette character is LOCKED; exact digital HEX values remain PROVISIONAL / TBD for Task 4.3 |
| Avoidance of Pixel Art | **LOCKED VISUAL DIRECTION** | Consequence of approved painterly Master Style; retro grid pixel art strictly rejected |
| Avoidance of Glossy 3D / Heavy Chibi Mascots | **LOCKED VISUAL DIRECTION** | Consequence of approved storybook Master Style; natural animal proportions and matte painted rendering locked |
| Three-Tier Value & Contrast Hierarchy Implementation | **LOCKED QUALITATIVE HIERARCHY** | Visual method serving locked accessibility goal (`GAME_DESIGN.md` §29); Tier 1 (focal) > Tier 2 (supporting) > Tier 3 (background) |
| MVP Vertical Slice Entity Validation Roster | **VALIDATED IN ROUND B** | Mockup validation roster (2 plants, 2 visitors, 2 decors, 3 env states) completed and approved in Task 4.2E |
| Lighting & Weather Conditions Execution Profiles | **VALIDATED / LOCKED QUALITATIVE DIRECTION (Rain & Night); PROVISIONAL (Cloudy)** | Rain and Night qualitative profiles VALIDATED / LOCKED (Task 4.2E); exact shaders, particle density, and final production HEX values remain TBD for Task 4.3 |
| UI Surface Card Texture & Panel Rounding Radii | **PROVISIONAL** | Subject to UI layout prototyping; UI implementation out of scope |
| Specific Font Families (Thai & Latin) | **TBD** | Evaluation criteria set; font selection belongs to future UI asset task |
| Exact Sprite Pixel Dimensions & PPU | **TBD** | Belongs to Task 4.3 Asset Technical Pipeline |
| Animation Frame Rates & Sprite Sheet Layouts | **TBD** | Belongs to Task 4.3 Asset Technical Pipeline |
| Texture Compression & Atlas Allocation | **TBD** | Belongs to Task 4.3 Asset Technical Pipeline |
| Final Production HEX Values | **TBD** | Belongs to Task 4.3 Asset Technical Pipeline |
| Exact Brush & Paper Texture Assets | **TBD** | Belongs to Task 4.3 Asset Technical Pipeline |
| Shader Architecture & Technical Export Presets | **TBD** | Belongs to Task 4.3 Asset Technical Pipeline |

---

## 3. Visual North Star

**Status: LOCKED VISUAL DIRECTION — OWNER APPROVED**

> ### "A quiet, living Thai home garden that breathes softly and gently welcomes you home."

The Visual North Star encapsulates the core identity of *Garden*, formally approved by the Project Owner in Task 4.2C as the synthesized Balanced Storybook Hybrid:

- **Warm & Intimate:** The garden is a small personal sanctuary, not a public park or commercial plantation. It feels embraced by natural shade, domestic warmth, and calm breeze.
- **Lived-In & Everyday:** It reflects gentle daily care—clay pots arranged over time, wooden furniture softened by weather, a water jar standing ready by the path, lush herbs grown for household cooking.
- **Gentle & Handmade:** Visual assets exhibit organic contours, tactile brush textures, and subtle human touch rather than sterile geometric precision or algorithmic stiffness.
- **Quietly Magical & Observational:** The magic is grounded in nature: golden morning sun filtering through banana leaves, a cat napping on a sun-warmed bench, a yellow butterfly fluttering past holy basil, fireflies drifting over damp evening soil.
- **Living Continuity:** The garden must feel like a space that continues to exist peacefully while the player is away, rather than a paused board waiting for user clicks.
- **Globally Readable, Unmistakably Thai:** The cultural grounding comes from genuine everyday domestic details, climate, and materials that international players find charming and authentic, without resorting to clichéd exotic tropes.

---

## 4. Cultural Direction and Authenticity Guardrails

**Status: LOCKED VISUAL DIRECTION — OWNER APPROVED**

*Garden* derives its soul from the authentic atmosphere of an ordinary Thai residential garden (*สวนกระถางหน้าบ้าน / สวนข้างบ้าน*). Following explicit Project Owner review, this everyday domestic direction is locked as the authoritative cultural grounding for Milestone 4 onward.

### 4.1 Authentic Everyday Cultural Cues

Visual design should consistently incorporate ordinary, recognizable elements:

- **Domestic Planting Language:** Potted herbs, practical shrubs, and flowering plants kept for cooking, tea, aroma, or simple daily pleasure (e.g., holy basil, chili, marigold, jasmine).
- **Clay Water Jar (*โอ่งดินเผา*):** Practical, unadorned or subtly weathered earthenware water jars used for cooling water, dipping ladles, or gathering rainwater.
- **Modest Garden Furniture:** Simple teak or local hardwood benches, slightly weathered by tropical rain and humidity, or cast concrete garden seating with softened edges.
- **Pots and Planters:** Terracotta pots of various sizes, glazed ceramic planters with gentle patina, reused household tins, and hanging baskets.
- **Ground and Paving Transitions:** Organic mixtures of moist packed earth, worn gravel paths, moss-softened concrete pavers, and patches of resilient clover or tropical groundcover.
- **Shaded Tropical Microclimate:** Dappled shadows cast by broad leaves, roof eaves offering shelter from monsoon rain, bamboo or wooden trellises giving light shade.
- **Everyday Yard Objects:** A metal or practical watering can placed beside a jar, simple wooden garden fences (*รั้วไม้ระแนง*), small clay saucers holding water for birds.

### 4.2 Cultural Authenticity Guardrails

To preserve genuine domestic intimacy and avoid stereotypical exoticism, adhere strictly to these negative guardrails:

```text
DO:
✓ Depict modest, everyday domestic Thai garden life.
✓ Emphasize natural tropical flora, humid warmth, and weathered earthenware.
✓ Show practical household objects that feel lived-with and treasured.
✓ Ground identity in climate, materials, flora, and quiet lifestyle.

DO NOT:
✗ Rely on Buddhist temples, chedis, monks, or religious sanctums.
✗ Include ornate golden filigree, royal palace decorations, or gilded roofs.
✗ Feature mythical creatures (nagas, garudas, yaksha giants) as garden visitors.
✗ Resort to tourist-kitsch shorthand (tuk-tuks, boxing gloves, tourist souvenirs).
✗ Present an exaggerated, neon "exotic tropical jungle" fantasy.
✗ Add ceremonial or ritual imagery that has no place in an ordinary residential garden.
✗ Interpret the garden as a luxury themed resort or hotel landscape.
```

> **Important Boundary:** This locks the approved visual-cultural execution, **not** every specific object appearing in generated concept art. It does **not** create new gameplay commitments.

---

## 5. Core Art Style and Visual Vocabulary

**Status: LOCKED 2D Technical Direction (ARCHITECTURE.md §3); LOCKED + ROUND-B VALIDATED (Task 4.2C Owner Approved, Task 4.2E Owner Validated)**

The technical foundation of *Garden* is **2D** (LOCKED by `ARCHITECTURE.md` §3). Following visual evaluation of Round-A candidates in Task 4.2B, the Project Owner explicitly approved the synthesized **Balanced Storybook Hybrid** as the project's Master Style (LOCKED VISUAL DIRECTION — Task 4.2C). In Task 4.2E, the Master Style survived comprehensive Round-B condition validation (Rain, Night, Plant Growth Close-Read, Visitor Moment) with PASS, confirming the style as **VALIDATED — UNCHANGED**.

The approved Master Style synthesizes traits across the experimental candidates into one coherent illustrated world:
- **Core Foundation (Candidate C):** Balanced storybook painterly hybrid providing unified harmony between subjects and environment.
- **Atmospheric Borrowing (Candidate A):** Soft, airy watercolor wash transitions across background foliage, ground planes, and sky gradients.
- **Readability Borrowing (Candidate B):** Gouache-like body color opacity, firm local value separation, and clear silhouette grouping on gameplay-relevant entities.

```text
+-------------------------------------------------------------------------------+
|                       APPROVED MASTER STYLE SYNTHESIS                         |
+-----------------------+-------------------------------+-----------------------+
| 2D Storybook Hybrid   | Atmospheric Softness          | Gameplay Readability  |
| Candidate C Core:     | Borrowed from Candidate A:    | Borrowed from Cand. B:|
| Tactile, organic,     | Watercolor transitions,       | Firm silhouettes,     |
| living storybook      | gentle environmental depth,   | gouache body colors,  |
| illustration          | airy breathable background    | selective edge clarity|
+-----------------------+-------------------------------+-----------------------+
```

### 5.1 Shape Language

- **LOCKED PRINCIPLE — Softened Organic Volumes:** Shapes favor rounded contours, gentle ellipses, and softened corners to convey safety, calm, and handmade warmth.
- **LOCKED PRINCIPLE — Mobile Silhouette Readability:** Every gameplay-relevant plant, visitor, and decoration must possess an instantly readable exterior contour at reduced phone display scale.
- **LOCKED PRINCIPLE — Natural Domestic Proportions:** Visiting creatures retain natural animal anatomy and dignity; oversized chibi heads, giant anime eyes, and cartoon mascot distortions are strictly prohibited.
- **PROVISIONAL IMPLEMENTATION DETAIL — Architectural Contours:** Built structures (house walls, fence slats, concrete benches) have softly rounded and weathered corners, with exact curvature tuned per asset during production.

### 5.2 Line and Edge Policy

- **LOCKED PRINCIPLE — No Universal Heavy Black Outlines:** Do not use continuous thick black ink outlines around assets. Forms must breathe.
- **LOCKED QUALITATIVE HIERARCHY — Edge Hierarchy:**
  1. *Focal Interactive Edge:* Important gameplay entities receive moderately clear painted outer edges with selective clarity on focal zones.
  2. *Midground Support Edge:* Passive beds, resting pots, and fence slats have painterly edges with slight texture bleed.
  3. *Background & Atmosphere Edge:* Distant foliage clusters, distant eaves, sky clouds, and nighttime ambient shadows use softer watercolor-like edges.
- **LOCKED PRINCIPLE — Internal Detail Softness:** Interior details within an entity must remain softer than the outer silhouette to preserve mobile readability.
- **TBD — Exact Line Thickness:** Exact pixel outline thickness belongs to Task 4.3.

```text
ILLUSTRATIVE EDGE PRINCIPLES:

[GOOD]: Foliage painted as soft, layered value clusters with readable exterior
        leaf silhouettes and gentle interior tone variations.
[BAD]:  Every individual leaf enclosed in a rigid 2-pixel black outline,
        creating noisy wireframe clutter on small screens.
```

### 5.3 Brush and Texture Character

- **LOCKED QUALITATIVE HIERARCHY — Restrained Handmade Texture:** Surfaces display restrained handmade paper and brush character with organic warmth. High-frequency texture noise, harsh grain, or sparkling that harms phone readability is strictly prohibited.
- **LOCKED PRINCIPLE — Selective Detail Density:** Detail is concentrated at primary focal points (flower centers, visitor eyes, jar rims). Large surfaces (walls, soil patches, broad leaves) remain restful, uncluttered fields.
- **TBD — Texture Assets & Engine:** Exact paper texture file, grain percentage, brush engine presets, and texture resolutions belong to Task 4.3.

### 5.4 What to Avoid (Negative Visual Style Bounds)

Following the Master Style decision, the project strictly rejects:
- **No Flat Corporate Vector Art:** No clinical, razor-sharp geometric bezier curves devoid of warmth.
- **No Pixel Art:** The project aesthetic is painterly illustration, not retro grid pixels.
- **No Photorealism:** Avoid phototextures, raw scans, or ray-traced lighting models.
- **No Glossy 3D Mobile-Game Look:** Avoid plastic specular highlights, candy-gloss shaders, and spherical bulbous mobile-ad models.
- **No Chibi/Anime Mascot Distortion:** Characters and animals must have believable, gentle anatomy rather than oversized heads and giant cartoon eyes.
- **No White Concept Presentation Border in Game:** The in-game presentation must **NOT** use the decorative white paper border seen around Candidate C's generated concept image. That border is a stochastic concept-art presentation artifact, not part of the approved gameplay presentation.

---

## 6. Camera and Composition Direction

**Status: LOCKED Technical Canvas (Android-First Portrait 1080×1920); PROVISIONAL Framing & Composition**

*Garden* is designed as an **Android-First Portrait** experience (LOCKED by `ARCHITECTURE.md` §3).

### 6.1 Reference Canvas and Aspect Flexibility

- **Base Reference Canvas:** `1080 × 1920` (9:16 portrait aspect ratio).
- **Responsive Staging:** Real Android devices span from 9:16 (1.77) to 9:20 (2.22) and beyond (punch-holes, rounded corners, dynamic navigation bars).
- **Safe Zone Composition:**
  - The core garden interaction stage occupies the central vertical field (`1080 × 1400` equivalent safe box).
  - Upper boundary allows breathing room for sky, distant roof eaves, and lightweight HUD currency status.
  - Lower boundary provides a clean, unobtrusive anchor zone for primary navigation tabs (Shop, Plant, Journal, Decorate).

```text
+-----------------------------+ 0px (Top)
| Sky / Roof Eaves / Ambience |
| [ Lightweight Status HUD ]  | Safe margin for cutouts & status bar
+-----------------------------+ ~260px
|                             |
|                             |
|      PRIMARY PLAYABLE       |
|        GARDEN VIEW          |
|    (Focal Interaction Zone) | 1080 × 1920 reference stage
|                             |
|                             |
+-----------------------------+ ~1640px
| Ground Foreground / Framing |
| [ Bottom Navigation Bar ]   | Safe margin for navigation gestures
+-----------------------------+ 1920px (Bottom)
```

### 6.2 Composition and Layering

1. **Background Layer (Depth & Context):**
   - Hint of house wall, wooden siding, or shaded verandah corner.
   - Soft garden fence boundary (*รั้วไม้*), lush distant bamboo or tropical foliage foliage silhouettes.
   - Sky opening to register morning, daylight, sunset, and starry night gradients.
   - Low contrast, muted saturation, soft edge definitions.
2. **Midground Layer (Active Garden Life):**
   - The primary gameplay stage containing garden soil, pots, active planting beds, decorative furniture, and water vessels.
   - Visitors alight and interact here.
   - High visual clarity, balanced contrast, warm ambient lighting.
3. **Foreground Layer (Intimacy & Framing):**
   - Subtle framing elements along screen borders (e.g., a soft branch of banana or mango leaf dipping into the upper corner, gentle blade of grass in lower edge).
   - Framing elements must never obstruct touch zones or active plant interaction slots.

### 6.3 Mobile Scale and Interaction Readability

- Interaction targets must be recognizable and tappable without requiring camera zoom gestures.
- Key silhouettes (a sprout emerging from soil, a caterpillar on a stem, a butterfly resting on a flower) must stand out against their immediate background support.

---

## 7. Scale Language

**Status: PROVISIONAL**

Scale in *Garden* follows an **illustrated relative scale** rather than rigorous architectural surveying. Proportions are tuned for readability on phone displays while maintaining a grounded, believable domestic feel.

### 7.1 Relative Object Scale Matrix

| Object Category | Entity Example | Relative Visual Height / Volume | Staging Role & Anchor Notes |
|---|---|---|---|
| **Large Boundary** | Garden Fence / House Wall | ~35–45% of stage height | Provides backstop and vertical framing; non-interactable. |
| **Large Decor** | Clay Water Jar (*โอ่ง*) | ~18–22% of stage height | Anchoring volume; broad rounded silhouette; solid domestic weight. |
| **Large Decor** | Garden Bench (*ม้านั่ง*) | ~15–18% height, ~25% width | Wide horizontal resting plane; provides perching/sleeping space for cat. |
| **Water Feature** | Small Pond (*บ่อน้ำ*) | ~25–30% width, ~10% height | Ground-level horizontal focal plane; reflects sky/ripples. |
| **Tree Plant** | Banana Plant (*ต้นกล้วย*) | ~40–50% of stage height | Tallest plant; arching broad leaves framing upper midground. |
| **Bush Plant** | Mature Marigold / Jasmine | ~15–20% of stage height | Full bushy silhouette; clear floral accents. |
| **Herb Plant** | Mature Holy Basil (*กะเพรา*) | ~12–16% of stage height | Branching compact herb silhouette; domestic culinary scale. |
| **Sprout Plant** | Any Sprout / Seedling | ~4–7% of stage height | Small, fragile, upright silhouette; stands out on dark soil. |
| **Medium Decor** | Plant Pot (*กระถางต้นไม้*) | ~8–12% of stage height | Stable flared base; supports individual plants. |
| **Small Decor** | Garden Lamp / Watering Can | ~8–12% of stage height | Distinct utilitarian silhouette; lamp provides night light pool. |
| **Medium Visitor**| Domestic Cat (*แมวบ้าน*) | ~10–13% stage height (sitting) | Believable domestic size relative to bench and jar; distinct postures. |
| **Small Visitor** | Garden Bird (*นกกระจอก*) | ~4–6% of stage height | Small, perching silhouette; sits atop fence or bench backrest. |
| **Small Visitor** | Garden Frog (*กบ/คางคก*) | ~4–5% of stage height | Low-profile ground dweller; nests near water jar or pond edge. |
| **Tiny Visitor**  | Butterfly (*ผีเสื้อ*) | ~3–5% of stage height | High contrast silhouette; hovers near blossoms; vibrant wing accent. |
| **Micro Element** | Firefly (*หิ่งห้อย*) | ~1–2% stage height (point glow)| Night-time atmospheric point; soft radial halo. |

### 7.2 Visitor Discoverability Rule

Visitors must be visually discoverable through silhouette and gentle idle motion rather than artificial neon arrows, high-contrast halos, or oversized "chibi" caricature heads. When a cat visits, it looks like a real cat settling into a garden corner.

---

## 8. Shape Language

**Status: LOCKED QUALITATIVE PRINCIPLES (grounded in locked calm/low-pressure product pillar & owner approval); PROVISIONAL IMPLEMENTATION DETAILS**

Shape language establishes the emotional tone of safety, warmth, and relaxation, supporting the locked low-pressure pillar (`GAME_DESIGN.md` §4.1) and the Owner-approved Master Style synthesis.

```text
ROUNDED & ORGANIC                SOFT GEOMETRY                 SHARP & AGGRESSIVE
(Primary Language)              (Secondary Language)           (Forbidden Language)
       ●                               ■                              ▲
Curved leaves, pots, jars,       Benches, fence slats,          No barbed edges,
cats, petals, soil mounds        paving tiles, window frames    no harsh spikes,
→ Conveys calm and comfort.     → Softened handmade edges.     → Causes visual stress.
```

- **LOCKED PRINCIPLE — Dominant Organic Forms:** Leaves, flower petals, earthen mounds, clouds, water droplets, and visiting animals are defined by continuous smooth curves and organic convex forms.
- **LOCKED PRINCIPLE — Softened Geometry for Built Items:** Man-made objects (wooden benches, fences, square planters, ceramic tiles) avoid clinical 90-degree corners. Edges exhibit subtle bevels, hand-carved waviness, and worn corners.
- **LOCKED PRINCIPLE — Silhouette Mobile Rule:** Every entity must possess a unique exterior contour. Silhouette and local value separation strictly outrank tiny decorative interior detail at mobile screen scale. If filled completely with solid black, a player should still instantly distinguish holy basil from marigold, a cat from a frog, and a water jar from a plant pot.
- **LOCKED PRINCIPLE — Natural Domestic Proportions:** Visiting creatures retain natural animal proportions and domestic dignity; oversized chibi heads, giant cartoon eyes, and mascot caricatures are strictly barred.
- **PROVISIONAL IMPLEMENTATION DETAIL — Asset-Specific Contours:** Exact curve radii, bevel angles, and polygon silhouette counts per individual sprite remain provisional for Task 4.3 pipeline testing.

---

## 9. Line and Edge Policy

**Status: LOCKED QUALITATIVE HIERARCHY (Exact pixel thickness TBD)**

*Garden* does not use heavy black ink outlines, nor does it use borderless flat vector blobs. It employs a **painterly edge hierarchy**:

### 9.1 The Edge Hierarchy

1. **LOCKED — Focal Interactive Edge (Moderately Clear / Firmer):** Active harvestable plants, newly arrived visitors, and selected garden decorations have clearly defined, firmly painted outer contours with selective edge clarity on focal zones and subtle warm-tone edge accents.
2. **LOCKED — Midground Support Edge (Medium Soft):** Passive soil beds, background foliage, resting garden pots, and fence slats have painterly edges with slight texture bleed into neighbors.
3. **LOCKED — Background & Atmosphere Edge (Softest):** Distant foliage clusters, distant roof eaves, sky clouds, and nighttime ambient shadows use soft watercolor-like edge gradients with minimal internal detail.
4. **LOCKED PRINCIPLE — Internal Detail Softness:** Interior details within an entity must remain softer than the outer silhouette to preserve mobile readability.
5. **LOCKED VISUAL DIRECTION — No Heavy Comic Outlines:** No continuous heavy black outlines around entire assets; sharpness follows hierarchy rather than being uniform.
6. **TBD — Pixel Outline Thickness:** Exact pixel outline thickness per sprite remains TBD for Task 4.3.

### 9.2 Word Examples of Edge Application

```text
EXAMPLE A (Foliage):
  GOOD: Holy basil foliage reads as clumps of warm-green leaf masses separated by
        subtle value shifts and light occlusion shadows, with a few individual leaf
        tips catching highlight.
  BAD:  Every holy basil leaf is drawn with a rigid 2px black stroke, turning the plant
        into a tangled wire fence.

EXAMPLE B (Clay Jar):
  GOOD: The clay jar is defined by its strong rounded silhouette, a soft gradient across
        its curved belly, a subtle dark rim crevice, and a soft cast shadow beneath.
  BAD:  The jar has a dark cartoon outline around its entire perimeter with flat,
        unrendered orange fill inside.

EXAMPLE C (Cat Visitor):
  GOOD: The cat's body is a smooth, sculpted shape of warm cream and ginger patches,
        separated from the wooden bench by value contrast and a gentle contact shadow.
  BAD:  The cat looks like a sticker with a white cutout stroke or heavy cartoon outline.
```

---

## 10. Texture and Material Language

**Status: LOCKED QUALITATIVE HIERARCHY (Exact texture assets TBD)**

Materials in *Garden* look tactile, natural, and weathered by tropical air, following the approved qualitative texture strategy:

- **LOCKED PRINCIPLE — Restrained Handmade Texture:** Restrained handmade paper and brush character is locked; environmental watercolor wash variation may be visible in broad fields, while important objects retain clean readable shapes.
- **LOCKED PRINCIPLE — Zero Mobile Noise:** Textures must strictly avoid high-frequency grit, pixel noise, or sparkling that harms phone readability.
- **TBD — Asset Specifications:** Exact paper texture asset file, grain percentage, brush engine presets, and texture resolutions belong to Task 4.3.

### 10.1 Material Rendering Profiles

- **Foliage:** Semi-matte, waxy tropical leaf finish. Light penetrates thin leaves (subtle translucency). Clusters show broad value planes rather than individual leaf veins.
- **Soil & Earth:** Rich, moist tropical garden soil. Slightly clumpy and textured with warm brown and umber tones; damp patches after rainfall.
- **Clay & Terracotta (*ดินเผา*):** Porous, matte, earthy terracotta with subtle kiln marks, chalky mineral blooms, and light weathering.
- **Wood (*ไม้ระแนง / ไม้เรือน*):** Warm teak or aged tropical timber with visible, muted grain. Softened corners, sun-bleached grey-brown tones, and gentle rainwater streaks.
- **Concrete & Stone:** Porous, slightly weathered grey and sand-toned surfaces with subtle moss or patina at base joints where moisture accumulates.
- **Metal (Watering Can, Lamp Trim):** Painted enamel or galvanized metal with gentle matte finish. Mild signs of use; zero chrome or hyper-specular glare.
- **Water:** Soft translucent surface with gentle light refraction, floating lily leaves, and delicate circular ripples upon disturbance. Reflects ambient sky color.
- **Fabric (Cushion, Cloth):** Natural woven cotton or linen with soft matte folds and muted natural dyes.

```text
TEXTURE DENSITY RULE:
Textures must provide tactile warmth at 100% mobile zoom without creating
high-frequency pixel noise or sparkling when scaled down on smaller screens.
```

---

## 11. Color System (By Role)

**Status: LOCKED BROAD PALETTE CHARACTER; PROVISIONAL REFERENCE HEX VALUES (NOT LOCKED FINAL ASSET COLORS)**

The color palette of *Garden* is warm, organic, and grounded in tropical Southeast Asian nature. Saturation is disciplined to maintain a restful, low-pressure ambiance. Neon, fluorescent, and casino-like color ramps are strictly prohibited.

- **LOCKED BROAD CHARACTER:** The broad palette character is warm, natural, restrained, and slightly earthy, featuring varied tropical greens, terracotta, weathered wood, warm earth, moss, muted concrete, and controlled warm flower/visitor accents.
- **PROVISIONAL / TBD VALUES:** The exact numerical HEX values below represent provisional reference anchors for concept exploration. Final production color values belong to Task 4.3 (Asset Technical Pipeline). Do not lock final numerical colors today.

```text
================================================================================
PROVISIONAL VISUAL REFERENCES — NOT LOCKED FINAL ASSET COLORS
The HEX values below represent mood and value anchors for concept exploration.
================================================================================
```

### 11.1 Color Roles and Reference Swatches

| Role Name | Description & Intent | Provisional Reference HEX | Visual Context & Usage |
|---|---|---|---|
| **Foliage Dark** | Deep canopy, under-leaf shadows, ambient occlusion | `#243B28` | Shaded plant interiors, deep shrub bases |
| **Foliage Mid** | Core healthy tropical leaf tone | `#426B42` | Primary leaf surfaces, general garden greenery |
| **Fresh Growth**| Young sprouts, emerging shoots, bright leaf tips | `#82A756` | Sprout stages, sunny foliage highlights |
| **Warm Soil** | Moist, rich garden earth and potting mix | `#4A3525` | Garden planting beds, pot interiors |
| **Terracotta / Clay** | Traditional unglazed earthenware and pots | `#B86842` | Clay water jar (*โอ่ง*), terracotta pots |
| **Weathered Wood** | Worn teak, wooden fencing, garden bench | `#806C5A` | Bench slats, trellis frames, fence posts |
| **Concrete Neutral**| Garden pavers, stone borders, foundation | `#A2A197` | Step stones, pot saucers, bench frames |
| **Warm Highlight** | Golden morning sunlight, lantern glow rim | `#F2D388` | Sun-kissed foliage tips, lamp rim lighting |
| **Day Atmosphere** | Soft tropical morning sky, ambient aerial wash | `#D8E8E6` | Distant background, sky gradient |
| **Night Ambient** | Deep, peaceful indigo; clear midnight sky | `#1A233A` | Night sky gradient, cool ambient shadows |
| **Rain Atmosphere** | Humid, diffuse silver-teal cloud cover | `#6E8387` | Overcast sky wash, rainy atmospheric tint |
| **UI Neutral Surface**| Warm handmade paper / card base | `#F7F4EB` | Journal pages, dialog panels, card bases |
| **UI Neutral Dark**| Deep warm charcoal for text and icons | `#383431` | Body typography, readable UI headers |
| **Discovery Accent**| Natural warm floral gold for highlights | `#E29E38` | Marigold blossoms, journal discovery stamp |

---

## 12. Value and Contrast Hierarchy

**Status: LOCKED QUALITATIVE HIERARCHY (serving locked readability and accessibility goals)**

To serve the locked accessibility goal of adequate visual readability on phone displays (`GAME_DESIGN.md` §29), contrast is managed through a locked three-tier hierarchy where silhouette and value separation strictly outrank tiny decorative detail:

```text
+-------------------------------------------------------------------------------+
|                        VALUE AND CONTRAST HIERARCHY                           |
+---------------------+-------------------------+-------------------------------+
| TIER 1: HIGHEST     | TIER 2: MEDIUM          | TIER 3: RESTFUL BACKGROUND    |
| Readability         | Readability             | Readability                   |
| Active interactable | Mature plants, active   | Soil beds, fences, walls,     |
| plants, new visitor | decorations, UI cards   | distant trees, sky gradient   |
| (Contour contrast)  | (Balanced local values) | (Muted value, low saturation) |
+---------------------+-------------------------+-------------------------------+
```

### 12.1 Readability Across Environmental States

- **Daylight:** Crisp light-to-shadow contrast with warm ambient bounce. Interactive items pop through crisp silhouettes against soft earth/foliage.
- **Night:** Low ambient contrast overall; readability is maintained by **localized light pools** (garden lamp, house light) and silhouette cutouts against the moonlit background.
- **Rain / Overcast:** Muted contrast with soft atmospheric fogging in background; wet specular reflections on leaves and jar rims provide fresh local contrast.

---

## 13. Lighting and Atmospheric Conditions

**Status: VALIDATED / LOCKED QUALITATIVE DIRECTION (Rain & Night — Task 4.2E); PROVISIONAL (Cloudy); Technical Shaders & Numerical Values TBD**

*Round-B Validation Outcome (Task 4.2E):* The Master Style underwent comprehensive condition validation in Round B. Both **Rainy Garden** and **Night Garden** visual treatments received formal Project Owner PASS approval. Their qualitative visual principles are promoted to **VALIDATED / LOCKED VISUAL DIRECTION**, while exact technical implementations remain TBD for Task 4.3.

Lighting in *Garden* conveys the gentle passage of time and the lived rhythm of the tropics, aligning with the provisional time-of-day and weather frameworks in `GAME_DESIGN.md` §13 and §14.

### 13.1 Validated Qualitative Weather & Lighting Principles

#### 13.1.1 Rain Visual Treatment
- **Status: VALIDATED / LOCKED QUALITATIVE DIRECTION (Task 4.2E)**
- **Locked Principles:**
  - Gentle tropical daytime rain with a cozy, refreshing, and non-punitive atmosphere (`GAME_DESIGN.md` §14).
  - Diffuse softened lighting with gentle silver-teal atmospheric mist washing through the scene.
  - Visible but restrained translucent vertical rain streaks.
  - Small puddles and ripples where appropriate.
  - Damp foliage and surfaces exhibiting a soft, gentle wet sheen (subtle specular highlight on clay and leaves).
  - Readable wet ground and material response; silhouettes remain clearly readable against the damp backdrop.
  - Visual treatment must never become storm, disaster, cold horror, or threatening imagery.
- **Explicitly TBD for Task 4.3 (Technical):** Exact rain streak count, rain particle speed, shader implementation, wet reflection strength curve, exact numerical production HEX colors, and technical engine implementation technique.

#### 13.1.2 Night Visual Treatment
- **Status: VALIDATED / LOCKED QUALITATIVE DIRECTION (Task 4.2E)**
- **Locked Principles:**
  - Cool, peaceful ambient night base; important silhouettes remain clearly readable.
  - Strictly no crushed black shadows; the garden maintains an intimate, safe, calm sanctuary mood.
  - Localized warm illumination radiating from a simple garden lantern or soft house window glow, pooling on the bench and adjacent soil.
  - Restrained, gentle firefly accents where appropriate, drifting with soft yellow-green luminescence.
  - Intimate, safe, tranquil, and contemplative atmosphere.
  - Strictly no horror mood, no neon/cyberpunk saturation drift, and no excessive magical-particle treatment.
- **Explicitly TBD for Task 4.3 (Technical):** Exact numerical HEX night base (provisional `#1A233A` to be calibrated), lamp light radius and attenuation curve, shader / CanvasModulate architecture, final number of fireflies, animation rate, and exact light intensity values.

#### 13.1.3 Cloudy Atmosphere (Provisional)
- **Status: PROVISIONAL Visual Direction**
- Diffuse, omni-directional soft skylight without harsh directional shadows.
- Slightly desaturated warm tones, allowing rich foliage greens to appear deeper and lusher.
- Atmosphere feels calm, cool, and quiet before or after rainfall.

```text
+---------------------------------------------------------------------------------------------------+
| VALIDATED LIGHTING CONDITION PROFILES (QUALITATIVE DIRECTION)                                     |
| - DAY: Directional warm sun (~35-45°), soft diffused shadows with warm bounce, humid life.       |
| - NIGHT: Deep indigo ambient base, no crushed blacks, warm lamp pool on bench, gentle fireflies.  |
| - RAIN: Diffuse silver-teal mist, soft rain streaks, wet leaf/clay sheen, cozy & non-punitive.     |
| - CLOUDY (Provisional): Diffuse skylight, deeper saturated greens, quiet contemplative calm.       |
+---------------------------------------------------------------------------------------------------+
```

### 13.2 Environmental Conditions Comparison Table

| Condition | Primary Light Source | Ambient Hue & Tone | Shadow Quality | Foliage & Material Response | Mood & Experience |
|---|---|---|---|---|---|
| **CLEAR (Day)** | Warm directional sun | Warm golden cream | Soft, warm-tinted cast | Vibrant greens, crisp highlights on clay/leaves | Cheerful, peaceful, awakening |
| **CLOUDY** | Diffuse overcast sky | Cool silver-grey | Very soft, ambient occlusion only | Deep, saturated greens, matte clay surfaces | Restful, quiet, humid calm |
| **RAIN** | Soft rainy sky mist | Desaturated teal-grey | Diffuse ground wetness | Wet sheen on leaves/pots, heavier drooping stems | Coziness, soothing nature, renewal |
| **NIGHT** | Soft moonlight & lamps | Deep indigo & amber pools | Soft nocturnal silhouette falloff | Deep silhouettes, warm local illumination | Intimate, magical, safe sanctuary |

---

## 14. Plant Visual Language

**Status: LOCKED Gameplay Growth Stages (GAME_DESIGN.md §10); VALIDATED / LOCKED QUALITATIVE DIRECTION (Task 4.2E); Technical Asset Specs TBD**

> **Round-B Validation Outcome (Task 4.2E):** The 4-stage visual growth presentation of Holy Basil and Marigold received formal Project Owner PASS approval. Qualitative differentiation principles are promoted to **VALIDATED / LOCKED VISUAL DIRECTION**.
>
> **Landscape Botanical Reference Plate Governance:** The accepted 16:9 landscape validation plate is strictly a **REVIEW / REFERENCE FORMAT** for evaluating side-by-side growth progressions ($2\text{ rows} \times 4\text{ columns}$). It does **NOT** alter the Android-first product target, portrait gameplay orientation, 1080 × 1920 reference canvas, camera system, UI layout, or sprite production aspect ratios. Architecture remains strictly Android-first portrait 1080 × 1920 (`ARCHITECTURE.md` §3).
>
> **Stochastic Detail Notice & Technical Non-Lock:** Visual principles of clear 4-stage silhouette differentiation, mass progression, and botanical trait distinction are **LOCKED**. Exact leaf counts, branch counts, flower counts, sprite pixel dimensions, PPU, and sprite frame counts remain explicitly **TBD** for Task 4.3.

Plants are living, persistent members of the garden. They grow through four clearly readable stages:

```text
PLANTED            SPROUT             GROWING            MATURE
[ Small Mound ] -> [ Pale Green Tip ] -> [ Bushy Stem ] -> [ Full Silhouette & Produce ]
```

### 14.1 General Growth Stage Rules

1. **Stage Distinguishability (LOCKED):** The player must distinguish plant stages primarily by **silhouette, plant mass, height, branching, foliage density, and mature species-specific traits**, with **zero dependency on text labels or numerical markers**. Growth stages (`planted -> sprout -> growing -> mature/harvestable`) and persistence after harvest are LOCKED gameplay contracts (`GAME_DESIGN.md` §10); the visual differentiation principles are LOCKED visual directions, while exact sprite dimensions and PPU belong to Task 4.3.
2. **Persistence After Maturity (LOCKED):** Reaching maturity produces flowers or harvestable goods. In accordance with `GAME_DESIGN.md` §10, mature plants remain in the garden after harvest rather than vanishing.
3. **Organic Identity:** Plants retain clear botanical character (leaf shapes, branch structure) without requiring dry botanical textbook realism.
   - **Holy Basil (*กะเพรา*):** Distinguished by broad leafy branching dome structure and mature purple/reddish flower spikes at crown tips.
   - **Marigold (*ดาวเรือง*):** Distinguished by finely segmented foliage and mature full rounded golden-orange pom-pom blossom heads.

### 14.2 Initial Vertical Slice Plants

#### Holy Basil (*กะเพรา* — `plant.holy_basil`)

- **Identity:** Ubiquitous Thai culinary herb. Compact, lively, aromatic bush.
- **Silhouette:** Upright, multi-branching stem structure with rounded, softly serrated oval leaves in opposite pairs.
- **Stage Progression:**
  - *Planted:* Small mound of dark moist earth with tiny planted furrow.
  - *Sprout:* Tender two-leaf shoot emerging upright from soil (~5% stage height).
  - *Growing:* Branched stem with 2–3 tiers of small green leaf clusters (~10% stage height).
  - *Mature:* Full, bushy dome of dense green foliage with tiny purple/reddish flower spikes at crown tips (~15% stage height). Visibly abundant and harvestable.
- **Coloration:** Medium olive green foliage with subtle purple-tinged stems and leaf margins. Avoid turning it into ornamental fantasy foliage.

#### Marigold (*ดาวเรือง* — `plant.marigold`)

- **Identity:** Beloved Thai home and auspicious garden flower. Bushy, vibrant, comforting.
- **Silhouette:** Compact shrub with pinnate, deeply lobed slender leaves crowned by round, pom-pom flower heads.
- **Stage Progression:**
  - *Planted:* Small soil mound with planting marker.
  - *Sprout:* Slender upright seedling with first feathered leaf pair.
  - *Growing:* Multi-branched leafy green mound with tight round green flower buds.
  - *Mature:* Lush foliage crowned with vibrant, fully opened rounded blossoms (~18% stage height).
- **Coloration:** Deep forest green foliage contrasting with rich, warm yellow and golden-orange flower heads. Marigold serves as a natural warm focal accent in the garden.

### 14.3 Future Plant Visual Guidance

- **Chili (*พริก*):** Slender, glossy pointed leaves, branching upright form, small white blossoms, mature stage bearing slender upright green and red peppers.
- **Jasmine (*มะลิ*):** Dark glossy rounded leaves, compact woody shrub, crowned by star-like pure white fragrant blossom clusters.
- **Banana (*กล้วย*):** Thick fleshy trunk, giant sweeping paddle-shaped leaves with gentle splits and arching forms; provides majestic vertical green layering.

---

## 15. Visitor Visual Language

**Status: LOCKED Behavioral Rules (GAME_DESIGN.md §11); VALIDATED / LOCKED QUALITATIVE DIRECTION (Task 4.2E); Technical Asset Specs TBD**

> **Round-B Validation Outcome (Task 4.2E):** The natural domestic scaling and anatomy of visitors (Cat and Butterfly) received formal Project Owner PASS approval after controlled refinement reducing the butterfly to natural scale. Qualitative visitor scale and anatomy principles are promoted to **VALIDATED / LOCKED VISUAL DIRECTION**.
>
> **Stochastic Detail Notice & Technical Non-Lock:** Visual principles of believable domestic anatomy, natural restful postures, and dignity without caricature or chibi mascots are **LOCKED**. Exact fur/wing color variations, exact poses, animation frame rates, and sprite sheet layouts remain explicitly **TBD** for Task 4.3.

Visitors are wild or domestic creatures that choose to visit the garden because of the conditions created by the player.

### 15.1 Core Visitor Principles

- **Autonomous Living Guests, Not Collectible Tokens (LOCKED):** Visitors must feel like living creatures that chose to enter the garden sanctuary, not board-game mascots placed for collection or progression gating. Core visitor behavior is LOCKED by `GAME_DESIGN.md` §11; visual execution principles (natural domestic proportions, dignified resting postures, soft gouache body clarity) are LOCKED visual directions, while exact animation sprite sheets belong to Task 4.3.
- **Readable Natural Anatomy & Scale (LOCKED):** Silhouettes reflect believable domestic animal proportions softened by storybook illustration. Strictly no oversized chibi heads, giant cartoon anime eyes, comical mascot proportions, or humanoid postures.
- **Environmental Grounding (LOCKED):** Visitors physically interact with the garden environment in naturalistic ways (e.g., cat sleeps peacefully curled on the bench, butterfly flutters and alights naturally atop flowering plants).
- **Subtle Idle Life:** Breathing motion, occasional ear twitch, wing flutter, or head turn. Visitors do not constantly bounce or loop hyperactive animations.

### 15.2 Initial Vertical Slice Visitors

#### Butterfly (`visitor.butterfly`)

- **Identity:** Gentle daytime visitor attracted to flowering plants (marigold, jasmine).
- **Visual Form (LOCKED QUALITATIVE SCALE):** Small and delicate; naturally scaled relative to flowers (significantly smaller than cat head). Simple graceful wings with soft warm cream and subtle yellow/orange patterning.
- **Discoverability (LOCKED):** Must remain discoverable through placement, value contrast, and gentle color rather than artificial physical enlargement.
- **Behavior & Staging:** Delicate flutter path through midground; pauses and rests gently atop blossom crowns. Associated naturally with flowering plants.
- **Negative Bounds:** Must not be giant, fantastical, or leave magical glitter trails.
- **Technical Non-Lock:** Exact wing patterns, colors, animation frame count, and sprite dimensions remain TBD for Task 4.3.

#### Cat (`visitor.cat`)

- **Identity:** Local domestic neighborhood cat visiting for peace, warmth, and shade.
- **Visual Form (LOCKED QUALITATIVE SCALE):** Believable domestic anatomy and natural scale relative to furniture (bench, clay jar). Soft rounded contours, short coat, warm cream or ginger tabby markings.
- **Key Poses:**
  - *Curled Sleeping:* Curled into a soft crescent or loaf on the wooden bench or sunny paver.
  - *Sitting Alert:* Upright seated posture, tail wrapped around paws, watching butterflies.
  - *Slow Walking:* Leisurely stroll through the garden path.
- **Personality (LOCKED):** Calm, independent, affectionate presence. Conveys personality primarily through body posture, pose, and ear angle rather than exaggerated human facial expressions. Strictly no mascot/chibi anatomy.
- **Technical Non-Lock:** Exact coat pattern variations, exact pose frames, and sprite pixel dimensions remain TBD for Task 4.3.

### 15.3 Future Visitor Consistency Guidance

- **Small Garden Bird (*นกกระจอก*):** Plump, perching songbird silhouette; perches on fence or water jar rim with quick, curious head hops.
- **Garden Frog (*กบ/อึ่งอ่าง*):** Rounded, low-profile body; moist smooth skin; sits quietly beside damp water jar bases or pond stones.
- **Firefly (*หิ่งห้อย*):** Softly pulsing golden-green point light drifting in gentle arcs over nighttime garden vegetation.

---

## 16. Decoration Visual Language

**Status: LOCKED Purpose Principles (GAME_DESIGN.md §15); LOCKED Qualitative Styling Principles; PROVISIONAL Profiles**

> **Stochastic Detail Notice:** The visual principles of authentic domestic utility, lived-in weathering, and rounded earthenware/timber silhouettes are **LOCKED**. Stochastic details appearing in concept mockups (such as exact pot rim curvature, bench slat counts, or specific kiln markings) are non-authoritative and not locked.

Garden decorations are practical, cherished household items that have accumulated over time. They reflect domestic hospitality and natural utility.

### 16.1 Decoration Principles

- **Believable Utility:** Objects look functional and meaningful (a jar holds cooling water, a bench provides rest, a pot holds an herb). The dual purpose of decorations (visual self-expression and systemic traits) is LOCKED by `GAME_DESIGN.md` §15; visual styling and weathering principles are LOCKED qualitative directions, while exact 2D asset dimensions belong to Task 4.3.
- **Subtle Weathering:** Surfaces show sun-faded paint, softened timber edges, moss traces at soil level, or gentle water marks.
- **No Luxury Showroom Polish:** Objects are not pristine chrome, plastic, or high-end theme-park collectibles.
- **Personal Arrangement:** Objects feel naturally set down by a caring homeowner.

### 16.2 Initial Vertical Slice Decorations

#### Clay Water Jar (*โอ่งดินเผา* — `decoration.clay_jar`)

- **Identity:** The definitive symbol of traditional Thai domestic garden hospitality.
- **Visual Form:** Stout, rounded terracotta body with a flared rim and sturdy flat base. Simple traditional engraved banding around the shoulder; subtle kiln color variations.
- **Material & Weathering:** Earthy terracotta red-brown with chalky lime streaks and soft dark moisture marks near the base.
- **Mobile Readability:** Distinct, heavy rounded silhouette that anchors any garden corner.

#### Garden Bench (*ม้านั่งไม้* — `decoration.bench`)

- **Identity:** Simple wooden or concrete garden seating nestled in a shady corner.
- **Visual Form:** Modest slatted hardwood bench with softened rectangular framing and sturdy legs.
- **Material & Weathering:** Weathered teak/timber with warm grey-brown patina and gentle grain lines.
- **Interaction Role:** Designed with a clear, readable horizontal seating plane sized specifically to support resting visitor poses (e.g., the sleeping cat).

### 16.3 Future Decoration Guidance

- **Garden Lamp:** Warm metal lantern on short wooden post; provides cozy focal illumination at night.
- **Watering Can:** Modest metal or green plastic household watering can set near a pot.
- **Wooden Fence Element:** Low wooden picket or slatted fence (*รั้วไม้ระแนง*) defining the rear garden boundary.
- **Plant Pot:** Classic flared terracotta or ceramic pot for holding individual decorative plants.
- **Small Table:** Low wooden or stone drink table placed beside the garden bench.
- **Small Pond:** Natural stone-bordered shallow pool with water lilies and clear ripples.

---

## 17. Environment Layering and Composition

**Status: PROVISIONAL Composition (serving locked touch clearance and readability goals)**

The garden scene is composed in three distinct visual depth planes to create richness without visual clutter:

```text
[ BACKGROUND ]  Distant sky, house verandah eave, boundary wooden fence, soft bamboo
       ↓        Low contrast, cooler/softer values, minimal internal detail.
[ MIDGROUND ]   Active garden earth, planting pots, water jar, bench, plants, visitors
       ↓        PRIMARY INTERACTION ZONE. Full contrast, sharpest readability, rich colors.
[ FOREGROUND ]  Soft out-of-focus leaf silhouette in top corner, lower border lawn blade
                Framing elements only; zero obstruction of tappable slots or entities.
```

### 17.1 Layering Rules

1. **Unobstructed Play Area:** Interactive plants, pots, and visitors must never be obscured by foreground framing elements or heavy UI overlays (serving locked touch and readability goals in `GAME_DESIGN.md` §26.3 and §29). Specific framing margins and composition percentages remain PROVISIONAL.
2. **Clear Depth Cues:** Depth is created through value atmosphere, slight overlap of objects, and soft contact shadows on the ground plane.
3. **No Parallax Disorientation:** Background elements remain stable to prevent disorientation on mobile portrait screens.

---

## 18. "Lived-In" Detail Rule (Controlled Storytelling)

**Status: PROVISIONAL Visual Guideline (grounded in locked small-world detail pillar)**

A home garden feels alive because of small, authentic imperfections. Grounded in the locked design pillar of "small world, dense detail" (`GAME_DESIGN.md` §4.5) and calm play (`GAME_DESIGN.md` §4.1), this visual guideline controls detail density to avoid mobile noise:

```text
THE "ONE-OR-TWO DETAILS" RULE:
Every local visual cluster (e.g., around the water jar, under the bench,
along the soil edge) may contain at most ONE or TWO subtle storytelling details.
```

### 18.1 Approved Storytelling Details

- A couple of dry fallen leaves curled on the garden paver.
- A faint damp water splash mark beneath the clay water jar rim.
- A tiny cluster of wild clover or moss growing in a paver seam.
- A gentle weather-bleached grain on the wooden bench armrest.
- A light terracotta saucer catching runoff beneath a potted herb.

### 18.2 Forbidden Clutter

- Covering every surface in pebbles, weeds, twigs, cracks, and litter.
- Cluttering the play area with broken tools, discarded packaging, or random debris.
- Over-detailing soil texture until it resembles gravel noise.

---

## 19. UI Visual Direction

**Status: PROVISIONAL Visual Direction (UI Implementation is Out of Scope)**

The user interface must remain a gentle, supportive companion to the garden, never overwhelming or competing with the living environment.

### 19.1 UI Visual Aesthetic

- **Paper & Card Language:** UI dialogs, panels, and cards evoke smooth, warm handmade paper or light cardstock with soft rounded corners.
- **Quiet Palette:** Soft neutral ivory and cream backdrops (`#F7F4EB`) with deep warm charcoal typography (`#383431`) and muted natural accent borders.
- **Soft Touch Affordances:** Buttons feel like pressed paper or smooth wooden tokens with gentle drop shadows rather than glossy plastic bubbles.
- **Subtle Ink Influence:** Icons and divider rules exhibit a delicate, hand-drawn ink character with consistent stroke weight.

### 19.2 What UI Must Avoid

- **No Glossy Mobile Game HUD:** No shiny plastic bevels, bright candy buttons, or gold-encrusted frames.
- **No Notification Dot Spam:** No aggressive red badges, flashing alert icons, or artificial urgency markers.
- **No Casino-Style HUD:** Currency counters must remain discrete and modest in the upper corner, not giant flashing coin tickers.
- **No Heavy Fantasy / Sci-Fi Framing:** Avoid ornate stone carvings, glowing magic runes, metallic chrome brackets, or neon cyber borders.

---

## 20. Typography Criteria

**Status: TBD Font Selection; LOCKED Accessibility & Readability Goals (GAME_DESIGN.md §29)**

*No font binary files are bundled or committed in this milestone.* Font families will be evaluated and integrated in a future UI asset task according to the following strict criteria:

1. **Dual Script Harmony:** Exceptional readability and aesthetic harmony between **Thai** (*ภาษาไทย*) and **Latin** character sets.
2. **Humanist Warmth:** Typeforms must have a friendly, humanist, slightly warm grotesque or softened serif/sans-serif feeling that complements the storybook illustration style.
3. **Small-Screen Clarity:** Clear letterforms with generous counter spaces, legible diacritics (Thai tone marks and vowels must not collide or clip), and distinct numeral forms at 12–14pt equivalent mobile scale.
4. **No Decorative Body Text:** Stylized, script, or calligraphic fonts may only be used sparingly for special header titles; all body text, stats, and dialogs must use clean, highly legible type.
5. **Open Source / Commercial Freedom:** Candidate fonts must use permissive licensing (e.g., SIL Open Font License).

---

## 21. Journal and Discovery Visual Direction

**Status: PROVISIONAL**

The Journal (*สมุดบ้านสวน / สมุดบันทึกธรรมชาติ*) is the emotional archive of the player's discoveries.

- **Nature Field Notebook Feel:** Pages resemble an illustrated botanical and naturalist notebook. Discovered entries feel like hand-painted watercolor vignettes accompanied by personal field notes.
- **Warm Discovery Vignettes:** Discovered plants, visitors, and events are presented as beautiful, soft illustrations with short, affectionate observations.
- **Curiosity-Driven Silhouettes:** Undiscovered entries appear as soft, warm grey silhouettes or delicate outlines accompanied by gentle question marks (`?`). They spark curiosity rather than anxiety.
- **No Completionist Pressure:** The journal does not use aggressive progress bars (e.g., "12/50 collected — 24% complete!"), countdown clocks, or empty locked padlocks. Discovery is a pleasant surprise, not a chore checklist.

---

## 22. Animation and Motion Principles

**Status: PROVISIONAL Motion Guidance (grounded in locked living-garden design pillar)**

Animation brings the garden to life through gentle, asynchronous breathing rather than cinematic spectacle, supporting the locked living-garden design pillar (`GAME_DESIGN.md` §4.2) and the provisional gentle-motion art direction (`GAME_DESIGN.md` §27).

```text
+-------------------------------------------------------------------------------+
|                             ANIMATION PRINCIPLES                              |
+----------------------+--------------------------+-----------------------------+
| Low Amplitude        | Gentle Timing            | Asynchronous Rhythm         |
| Subtle leaf sways    | Soft ease-in/ease-out    | Wind moves plants at        |
| and gentle breathing | without frantic snappiness| different times, creating  |
| displacements        | or jarring stops         | natural, living flow        |
+----------------------+--------------------------+-----------------------------+
```

### 22.1 Motion Examples

- **Foliage:** Plants sway gently in a soft, passing breeze with low amplitude (1–3 degrees) and staggered, offset wave timing.
- **Visitor Idles:** A cat breathes peacefully with slow torso expansion; an occasional ear or tail tip flick; a butterfly hovers with rhythmic, soft wing beats.
- **Weather Elements:** Rain falls as gentle, continuous semi-transparent streaks; puddles show delicate concentric expanding rings.
- **Lighting Ambience:** Night fireflies drift in gentle, lazy three-dimensional curves; lamp glow exhibits a very subtle, warm breathing pulse.

### 22.2 What Animation Must Avoid

- **No Universal Constant Bouncing:** Objects must not bounce, pulse, or hop in place merely to demand player attention.
- **No Exaggerated Squash-and-Stretch:** Avoid rubbery cartoon distortion; maintain physical substance and dignity.
- **No Screen-Shaking or Confetti:** Routine actions (harvesting, planting) produce pleasant soft particle feedback, never screen shake or casino confetti bursts.

---

## 23. Motion Density Budget

**Status: PROVISIONAL Production Guidance**

To preserve the calm aesthetic and protect mobile battery life, the screen operates under a provisional **Motion Density Budget** to be evaluated in prototypes:

```text
MOTION DENSITY BUDGET RULE:
At any given moment during ordinary garden play, no more than 3 to 5 subtle
ambient motions should be active simultaneously on the screen.
```

- When the wind sways the banana leaves, other background elements remain resting.
- When a butterfly is fluttering across the midground, plants beneath it remain largely still.
- The garden feels restful to gaze at for minutes at a time without causing visual fatigue.

---

## 24. Effects and Particles Policy

**Status: PROVISIONAL Production Guidance**

Visual effects (*VFX*) must remain delicate, naturalistic, and understated, supporting the calm, low-pressure tone of the game.

### 24.1 Permitted Effects

- **Pollen & Dust Motes:** A few soft, semi-transparent warm motes drifting lazily through sunbeams.
- **Raindrops & Splashes:** Slender, translucent rain streaks; tiny circular droplet rings on water surfaces.
- **Firefly Luminescence:** Small soft glowing dots with subtle radial light halos at night.
- **Harvest Feedback:** A tiny puff of rich soil dust or a gentle drift of sweet aroma motes when produce is gathered.

### 24.2 Prohibited Effects

- **No Golden Loot Beams:** No vertical pillars of light shooting into the sky.
- **No Fireworks or Starbursts:** Routine achievements must not trigger loud visual explosions.
- **No Dense Screen-Filling Fog:** Avoid heavy particle fogs that obscure garden readability.
- **No Sparkle Spam:** Do not shower the screen with glittering stars or spinning sparkles for mundane taps.

---

## 25. Mobile Readability Rules

**Status: LOCKED Accessibility Goals (GAME_DESIGN.md §26, §29); PROVISIONAL Implementation Rules**

To satisfy locked touch and accessibility goals (`GAME_DESIGN.md` §26.3, §29), artwork must maintain flawless legibility on real Android hardware across various screen sizes:

1. **Silhouette Readability:** Core entities (mature basil, sprout, cat, jar) must be immediately identifiable at gameplay resolution without zooming.
2. **No Single-Pixel Dependency:** No vital visual clue (such as whether a plant is harvestable or a flower has bloomed) may rely on a 1-pixel detail.
3. **Line Weight Safety:** Any accent line work must have sufficient weight (minimum 2–3px equivalent at 1080p canvas) to prevent disappearing or aliasing on high-DPI phone screens.
4. **Color-Blind Accessible Contrast:** State differences (e.g., unwatered vs. watered soil, growing vs. harvestable plant) must be reinforced by shape, value, and fullness, not color hue alone.
5. **Comfortable Touch Clearance:** Visual objects that are interactive must offer clear visual footprints compatible with minimum touch target standards.

---

## 26. Performance-Aware Art Rules

**Status: LOCKED Platform Constraints (ARCHITECTURE.md §3); PROVISIONAL Art Guidelines**

While detailed technical asset specifications belong to Task 4.3, art direction must respect mobile hardware constraints from day one:

- **Material & Color Reuse:** Foliage, woods, clays, and metals should draw from the unified color role system, allowing future sprite atlas packing and texture reuse.
- **Restrained Texture Dimensions:** Asset concepts should avoid gratuitously massive resolutions. Master art should be created at resolutions appropriate for a 1080 × 1920 viewport without requiring 4K textures for small garden props.
- **Avoid Overlapping Full-Screen Alpha Layers:** Atmospheric washes (fog, rain mist) should use efficient vertex-tinted planes or lightweight shader overlays rather than stacking dozens of overlapping full-screen transparent bitmaps.
- **Batch-Friendly Construction:** Assets should be designed so that multiple garden elements can later be packed into unified sprite sheets without awkward bleeding.

---

## 27. Vertical Slice Visual Target

**Status: PROVISIONAL VALIDATION SCOPE**

To prove the visual direction before launching full-scale content production, the project defines an initial **Vertical Slice Visual Target**. This represents a provisional mockup validation set to test hypotheses in Task 4.2, not a new permanent gameplay commitment.

### 27.1 Vertical Slice Visual Roster

```text
+-------------------------------------------------------------------------------+
|                         VERTICAL SLICE VISUAL ROSTER                          |
+-------------------+--------------------+------------------+-------------------+
| ENVIRONMENT       | PLANTS             | VISITORS         | DECORATIONS       |
| - Main Thai Home  | - Holy Basil       | - Butterfly      | - Clay Water Jar  |
|   Garden (Corner) |   (4 stages)       |   (Flutter/Rest) |   (Terracotta)    |
| - Ground & Soil   | - Marigold         | - Cat            | - Garden Bench    |
| - Fence Boundary  |   (4 stages)       |   (Sleep/Sit)    |   (Weathered Wood)|
+-------------------+--------------------+------------------+-------------------+
| LIGHTING & WEATHER CONDITIONS:                                                |
| - Day (Clear Sunlight)  - Night (Lamp Pool & Fireflies)  - Rain (Wet Surfaces)|
+-------------------------------------------------------------------------------+
```

### 27.2 Vertical Slice Validation Matrix

| Target Asset / Scene | Key Validation Question | Success Criteria |
|---|---|---|
| **Garden Environment** | Does the space feel like an authentic, lived-in Thai home garden? | Warm domestic atmosphere; natural ground transition; balanced composition. |
| **Holy Basil (4 stages)** | Are growth stages instantly readable without text labels? | Sprout, growing, and mature stages differ clearly in mass and silhouette. |
| **Marigold (4 stages)** | Does the mature blossom serve as a warm focal accent? | Cheerful golden-orange flower heads pop naturally without looking fluorescent. |
| **Butterfly Visitor** | Does the creature feel like a natural garden guest? | Delicate flight path; rests naturally on marigold; zero cartoon caricature. |
| **Cat Visitor** | Does the cat convey personality through relaxed posture? | Believable domestic proportions; looks peaceful curled upon the bench. |
| **Clay Water Jar** | Is it culturally authentic and recognizable at mobile scale? | Sturdy rounded earthenware form with subtle patina; unmistakable identity. |
| **Garden Bench** | Does it provide a functional, inviting resting plane? | Weathered timber slats; structurally grounds the cat; readable seating surface. |
| **Day / Night / Rain** | Do environmental states dramatically alter mood without losing readability? | Day is warm and clear; Night is readable with warm pools; Rain feels cozy and fresh. |

---

## 28. Concept Mockup Experiment Plan (Task 4.2 Sequence)

**Status: TASK 4.2E COMPLETED (Round-B Owner Validated — PASS); TASK 4.3 NEXT (Asset Pipeline Gate OPEN)**

Task 4.2 evaluates visual hypotheses through a controlled two-round experiment sequence:
- **Task 4.2A:** Controlled concept mockup experiment specification (`VISUAL_MOCKUP_PLAN.md`). [COMPLETED]
- **Task 4.2B:** Round-A style comparison generating Candidates A, B, and C. [COMPLETED]
- **Task 4.2C:** Record Project Owner approved Master Style synthesis decision. [COMPLETED]
- **Task 4.2D/E:** Round-B Master Style validation across 4 targeted scenarios and Owner Review. [COMPLETED — ALL PASS]

```text
+-------------------------------------------------------------------------------+
|                      ROUND-B VALIDATION OUTCOMES (TASK 4.2E) [ALL PASS]       |
+-------------------------------------------------------------------------------+
| 1. RAINY GARDEN: PASS                                                         |
|    - Validated: Soft diffuse teal mist, non-punitive coziness, wet sheen.     |
| 2. NIGHTTIME GARDEN WITH LAMP & FIREFLIES: PASS                               |
|    - Validated: Nocturnal readability, warm lamp pool, restrained fireflies.  |
| 3. PLANT CLOSE-READ (HOLY BASIL & MARIGOLD): PASS                             |
|    - Validated: 4-stage silhouette differentiation; landscape reference plate.|
| 4. VISITOR MOMENT (CAT ON BENCH & BUTTERFLY ON MARIGOLD): PASS                |
|    - Validated: Natural animal scale, relaxed cat pose, delicate butterfly.   |
| - MASTER STYLE STATUS: VALIDATED — UNCHANGED (Balanced Storybook Hybrid)      |
| - ASSET TECHNICAL PIPELINE GATE: OPEN (Proceed to Task 4.3)                   |
+-------------------------------------------------------------------------------+
```

---

## 29. Master Style Selection Process

**Status: LOCKED Process — STEP 5 COMPLETED (Owner Approved in Task 4.2C & Validated in Task 4.2E)**

To ensure cohesive art direction and prevent style fragmentation, the project follows an explicit **Master Style Selection Process**:

```text
+-----------------------------+
| Step 1: Bible Hypotheses    |  VISUAL_STYLE_BIBLE.md defines preferred visual
+--------------+--------------+  hypotheses with correct decision statuses. [DONE]
               |
               v
+-----------------------------+
| Step 2: Generate Mockups    |  Generate concept mockups guided strictly
+--------------+--------------+  by Bible hypotheses (Task 4.2B). [DONE]
               |
               v
+-----------------------------+
| Step 3: Comparative Audit   |  Evaluate mockups against Cultural Guardrails,
+--------------+--------------+  Mobile Readability, and Core Art Style. [DONE]
               |
               v
+-----------------------------+
| Step 4: Reject Drift        |  Eliminate any style drift toward generic anime,
+--------------+--------------+  western farm, pixel art, or glossy 3D. [DONE]
               |
               v
+-----------------------------+
| Step 5: Owner Review & Lock |  Project owner approved Master Style Anchor
+--------------+--------------+  (Task 4.2C) & validated Round B (Task 4.2E). [PASS]
               |
               v
+-----------------------------+
| Step 6: Asset Tech Pipeline |  Establish technical asset pipeline, sprite grids,
+-----------------------------+  and Godot import presets (Task 4.3). [GATE OPEN]
```

*Governance Reaffirmation:* The Project Owner has explicitly reviewed Round-A candidates and approved the synthesized Master Style (Candidate C foundation + Candidate A atmosphere + Candidate B readability) in Task 4.2C, and confirmed its robustness across all representative conditions (Rain, Night, Plant growth, Visitor scale) with PASS in Task 4.2E. Core visual style directions are **LOCKED + ROUND-B VALIDATED**. Technical asset specifications remain **TBD** until Task 4.3.

---

## 30. Approved Master Style Prompt Anchor

**Status: LOCKED MASTER STYLE ANCHOR (Owner Approved in Task 4.2C)**

The following standardized prompt block serves as the **Approved Master Style Anchor** for all future concept and asset reference generation (including Task 4.2D Round-B validation). It encapsulates all approved aesthetic requirements and negative constraints into a repeatable format:

```text
PROMPT ANCHOR TEMPLATE:

A beautiful 2D soft hand-painted storybook illustration combining soft gouache-like body colors for important gameplay entities with delicate watercolor-like atmospheric wash transitions in the background and ground planes. Clear, instantly readable silhouettes for plants, visitors, and garden objects with moderate local value separation from the surrounding environment. Organic, softened painted contours with selective edge clarity on focal elements; strictly no universal heavy black comic outlines. Restrained, tactile handmade paper and brush texture conveying organic warmth without high-frequency noise or small-screen grain. Warm, natural, slightly earthy color palette featuring tropical greens, rich terracotta, weathered teak wood, moist garden soil, soft moss, and muted concrete. Culturally grounded in an authentic everyday Thai domestic residential yard, evoking a calm, peaceful, low-pressure, lived-in domestic sanctuary. No glossy 3D CGI rendering, no photorealism, no pixel art, no chibi mascot proportions, framed specifically for Android portrait mobile readability (9:16 aspect ratio).

NEGATIVE / EXCLUSION ANCHOR:
No glossy 3D rendering, no CGI specular highlights, no pixel art, no sharp vector flat art,
no photorealism, no anime character tropes, no cute oversized chibi mascots,
no Buddhist temples, no golden religious ornaments, no mythical naga creatures,
no tourist tuk-tuks, no neon casino colors, no UI buttons, no text, no letters,
no watermarks, no framing borders, no white concept presentation borders.
```

---

## 31. Negative Visual Rules & Explicitly Rejected Traits

**Status: LOCKED VISUAL DIRECTION (Owner Approved in Task 4.2C)**

### 31.1 Explicitly Rejected Traits from Round-A Review

The Project Owner's visual review explicitly rejected the following stylistic extremes:

- **From Candidate A (Watercolor-Forward) — REJECTED:**
  - Excessive watercolor softness that merges interactables into the background environment.
  - Excessive pigment granulation and paper noise that reads as grit at mobile scale.
  - Weak foreground/background value separation.
- **From Candidate B (Gouache-Forward) — REJECTED:**
  - Excessively hard or poster-like graphic rendering.
  - Generic flat mobile-game appearance lacking illustrated soul.
  - Loss of atmospheric softness and airy environmental depth.
  - Loss of handmade watercolor warmth.
- **From Candidate C (Hybrid) — REJECTED:**
  - Overly neutral compromise without recognizable handmade character.
  - Decorative white paper framing border as part of in-game presentation (presentation artifact only).
- **General Rejected Outcomes:**
  - Glossy 3D CGI rendering and specular plastic highlights.
  - Photorealism and raw photographic textures.
  - Pixel-art direction, grid dithering, and retro sprites.
  - Universal heavy comic book outlines.
  - Hyper-saturated mobile farming-game color ramps.
  - Chibi mascot-world treatment and oversized cartoon eyes.
  - Excessive magical sparkle effects, loot rays, or fireworks.
  - Visually cluttered environments violating the "one-or-two details" rule.

### 31.2 Visual Production Priority

All visual asset creation and evaluation must strictly adhere to this approved priority order:
1. **Mobile Readability** (Silhouette clarity, touch targets, value separation on phone screens).
2. **Calm and Inviting Atmosphere** (Soft light, low-pressure ambiance, peaceful setting).
3. **Coherent Handmade Illustrated Character** (Storybook warmth, visible artisan craft, unified world).
4. **Everyday Lived-In Garden Authenticity** (Modest Thai domestic reality, natural weathering, practical care).
5. **Repeatability Across a Practical 2D Production Pipeline** (Feasible, scalable 2D sprite creation in Godot).

### 31.3 Standard Visual Drift Avoidance Rules

To preserve the unique soul of *Garden*, visual artists and generation workflows must vigilantly avoid drifting toward the following visual tropes:

1. **Do NOT drift toward Generic Western Farm:** No red wooden barns, silos, white picket fences, hay bales, or tractor ruts.
2. **Do NOT drift toward Japanese Zen Garden:** No manicured bonsai, raked gravel zen waves, torii gates, or bamboo water tippers (*shishi-odoshi*).
3. **Do NOT drift toward Fantasy RPG Forest:** No glowing magical blue crystals, giant bioluminescent mushrooms, fairy dust rings, or enchanted runes.
4. **Do NOT drift toward Temple Courtyard:** No chedis, gilded Buddhist spires, ceremonial altars, or monastic shrines.
5. **Do NOT drift toward Luxury Resort Garden:** No infinity pools, manicured palm-tree avenues, pristine white sun loungers, or five-star cabanas.
6. **Do NOT drift toward Hyper-Saturated Mobile Farming Game:** No fluorescent candy greens, neon yellow buttons, pulsing arrows, or shiny plastic surfaces.
7. **Do NOT drift toward Glossy 3D Asset Packs:** No rounded plastic toy assets, specular orb highlights, or Unity/Unreal asset-store look.
8. **Do NOT drift toward Pixel Art:** No grid pixels, dithering, or low-resolution 8-bit/16-bit retro styling.
9. **Do NOT drift toward Photorealism:** No raw photographic textures, unpainted photo-collages, or ray-traced shadows.
10. **Do NOT drift toward Flat Corporate Vector:** No sterile bezier geometry, corporate tech-blog vector illustrations, or faceless purple people.
11. **Do NOT drift toward Chibi Mascot World:** Animals must not have giant bobble-heads, massive cartoon eyes, or comical humanoid poses.
12. **Do NOT drift toward Visual Clutter:** Do not cover every square inch in pebbles, weeds, scratches, and noise.
13. **Do NOT drift toward Magical Sparkles:** No floating diamond sparkles, golden loot rays, or fireworks.
14. **Do NOT drift toward UI Dominance:** The UI must never smother, overwhelm, or dwarf the quiet garden world.

---

## 32. Asset Consistency Checklist

**Status: PROVISIONAL Review Checklist (Evaluation criteria for Task 4.2 mockups)**

Every new concept art piece, mockup, environment sprite, plant stage, visitor pose, decoration, or UI component must pass this 11-point review checklist before acceptance:

```text
[ ] 1. Culturally Plausible?
       Does it feel like an authentic, everyday Thai home garden element?
[ ] 2. Everyday Domestic Tone?
       Does it avoid temple tropes, royal ornament, and tourist kitsch?
[ ] 3. Correct Scale?
       Does its visual volume match the relative scale matrix (e.g., cat vs bench vs jar)?
[ ] 4. Readable Silhouette?
       Can the object be instantly identified from its outer contour alone on a phone?
[ ] 5. Hand-Painted Softness?
       Does it exhibit organic painterly softness without heavy black comic outlines?
[ ] 6. Restrained Detail?
       Is the detail density calm, avoiding high-frequency noise and pixel clutter?
[ ] 7. Mobile Readable?
       Does it remain crystal clear at 1080×1920 portrait scale without zooming?
[ ] 8. Palette Consistent?
       Does it harmonize with the established color roles, avoiding neon/fluorescent saturation?
[ ] 9. Environmental Compatibility?
       Can this asset transition gracefully into Day, Night, and Rainy conditions?
[ ] 10. Dignified & Living?
        Do creatures feel like real animal guests rather than cartoon mascot tokens?
[ ] 11. Supports Calm & Curiosity?
        Does the visual foster relaxation, quiet affection, and low-pressure contemplation?
```

---

## 33. Summary of Visual Decisions & Next Tasks

**Status: TASK 4.2E COMPLETE; ASSET TECHNICAL PIPELINE GATE OPEN (Task 4.3 NEXT)**

To preserve strict separation of concerns, the project status is summarized below:

1. **Master Style Foundation & Synthesis:** **LOCKED + ROUND-B VALIDATED** — Balanced Storybook Hybrid (Candidate C core, Candidate A atmospheric softness, Candidate B gameplay readability; validated unchanged across all conditions in Task 4.2E).
2. **Cultural Grounding:** **LOCKED VISUAL DIRECTION** — Everyday Thai-inspired domestic garden setting.
3. **Qualitative Visual Hierarchies:** **LOCKED VISUAL DIRECTION** — Edge hierarchy, texture strategy, silhouette readability priority, and broad warm earthy palette character.
4. **Lighting & Weather Qualitative Treatments:** **VALIDATED / LOCKED QUALITATIVE DIRECTION** — Rainy Garden (soft diffuse mist, wet sheen, non-punitive) and Night Garden (deep indigo, warm lamp pool, restrained fireflies) validated with PASS in Task 4.2E.
5. **Plant & Visitor Qualitative Readability:** **VALIDATED / LOCKED QUALITATIVE DIRECTION** — 4-stage plant growth differentiation (no text dependency) and natural visitor scaling/anatomy validated with PASS in Task 4.2E.
6. **Master Style Validation (Round B):** **COMPLETED / OWNER VALIDATED — PASS** (Rain, Night, Plant Growth Close-Read, Visitor Moment; Task 4.2E).
7. **Asset Technical Pipeline Gate:** **OPEN** — Task 4.3 permitted to establish technical specifications.
8. **Typography Asset Selection & Licensing:** Font families will be evaluated and verified in a future UI asset task (TBD).
9. **Asset Technical Pipeline Specifications:** Exact sprite sheet layouts, pixel dimensions, PPU, Godot 2D import compression, and atlas boundaries belong to **Task 4.3** (TBD).
10. **Final Numerical Colors:** Final production HEX calibration belongs to **Task 4.3** (TBD).
11. **Exact Texture & Brush Assets:** Paper textures, grain files, and brush engine presets belong to **Task 4.3** (TBD).
12. **Shader and Lighting Technical Implementation:** Shaders, light nodes, and canvas modulators belong to milestone implementation tasks (TBD).
13. **Audio and Ambient Soundscape:** Audio assets and sound direction belong to Milestone 5 (TBD).
