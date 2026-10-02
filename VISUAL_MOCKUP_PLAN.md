# Garden Controlled Concept Mockup Plan

> **Document Type:** Concept-Art Experiment Specification
>
> **Status:** **PROVISIONAL EXPERIMENT SPECIFICATION — TASK 4.2A**
>
> **Milestone:** Milestone 4 (Visual Direction & Asset Pipeline)
>
> **Reference Target:** Android Portrait (1080 × 1920 Reference Canvas)
>
> **Engine Baseline:** Godot 4.7.2 Stable (Compatibility 2D)
>
> **Upstream Authority:** `VISUAL_STYLE_BIBLE.md` (Task 4.1 / 4.1C)

---

## 1. Authority, Precedence, and Purpose

### 1.1 Document Authority and Status
This document defines the controlled, reproducible concept-art experiment plan for **Milestone 4 — Task 4.2**. It establishes the visual evaluation methodology to compare candidate art directions fairly and objectively before any asset generation occurs.

- **Experiment Specification Only:** This document is an experiment plan and evaluation framework. It does **not** lock final art direction, does **not** promote any provisional direction to locked status, and does **not** constitute production asset creation.
- **Strict Precedence:** This document is subordinate to higher-level project documentation in accordance with `PROJECT_RULES.md` §2:
  1. Explicit project owner instructions in current tasks.
  2. `PROJECT_RULES.md` (non-negotiable governance and quality gates).
  3. `ARCHITECTURE.md` (technical foundations, 2D renderer, Android-first portrait target).
  4. `GAME_DESIGN.md` (pillars, setting, plant/visitor/decoration systems, accessibility).
  5. `DEFINITION_OF_DONE.md` (verification and defect gates).
  6. `VISUAL_STYLE_BIBLE.md` (visual authority and decision status framework).
- **No Automatic Authority for Generated Art:** No generated image, AI draft, or single successful mockup can automatically become authoritative or lock a visual style.
- **Explicit Project Owner Approval Required:** Visual evidence gathered from this plan will be presented to the project owner. Only the project owner may approve the Master Style or promote provisional aesthetic hypotheses to locked status.
- **Dependency Gate for Task 4.3:** Task 4.3 (Asset Technical Pipeline) **must not begin** until the Master Style decision has been explicitly reviewed and approved by the project owner in the Master Style Record.

### 1.2 Separation from Gameplay Specifications
Mockups generated under this plan serve strictly to evaluate visual rendering, palette harmony, silhouette readability, and cultural authenticity.
- **Accidental Content Is Non-Authoritative:** Stochastic image generation may produce accidental elements (such as extra flower varieties, unapproved furniture, background windows, tool sheds, pathways, or stray creatures). Such elements **do not** become game features, backlog requirements, or gameplay commitments.
- **Gameplay Authority:** Only `GAME_DESIGN.md` and `ARCHITECTURE.md` establish gameplay entities, progression rules, interaction mechanics, and system behaviors.

---

## 2. Visual Decision Status Framework & Governance

In compliance with `VISUAL_STYLE_BIBLE.md` §2, this plan operates within the explicit three-tier status discipline:

| Topic / Decision Area | Status | Governing Authority | Experiment Constraint |
|---|---|---|---|
| **2D Presentation** | **LOCKED** | `ARCHITECTURE.md` §3 | All prompts must specify 2D illustration. No 3D models or isometric engines. |
| **Android-First Portrait (1080 × 1920)** | **LOCKED** | `ARCHITECTURE.md` §3 | All mockups use 9:16 portrait composition framed for mobile viewing. |
| **Calm, Low-Pressure Product Goal** | **LOCKED PRODUCT GOAL** | `GAME_DESIGN.md` §4.1 | Art must convey gentle warmth, safety, and unhurried living continuity. |
| **Mobile Silhouette Readability Goal** | **LOCKED DESIGN GOAL** | `GAME_DESIGN.md` §29 | Key entities must be identifiable by outline/value at phone display scale. |
| **Everyday Thai-Inspired Garden Identity** | **PROVISIONAL** | `GAME_DESIGN.md` §6 | Tested via authentic domestic elements; no tourism tropes or temples. |
| **Hand-Painted / Storybook Visual Treatment** | **PROVISIONAL** | `GAME_DESIGN.md` §27 | Core hypothesis tested through Candidates A, B, and C. |
| **Watercolor vs. Gouache Balance** | **PROVISIONAL** | `VISUAL_STYLE_BIBLE.md` §5 | **Primary test variable** of Round A. |
| **Edge Softness & Line Policy** | **PROVISIONAL** | `VISUAL_STYLE_BIBLE.md` §9 | Evaluated across phone display sizes for readability vs. softness. |
| **Reference Color Palette Swatches** | **PROVISIONAL** | `VISUAL_STYLE_BIBLE.md` §11 | Indicative natural hues; not locked final digital asset values. |
| **Material Rendering & Weathering** | **PROVISIONAL** | `VISUAL_STYLE_BIBLE.md` §10 | Lived-in textures evaluated against noise on small mobile screens. |
| **Visitor Stylization & Anatomy** | **PROVISIONAL** | `VISUAL_STYLE_BIBLE.md` §15 | Evaluated for natural animal posture vs. avoiding mascot caricature. |

> **Governance Principle:** The experiment tests provisional hypotheses. It must never silently promote them to locked status.

---

## 3. Experiment Structure: Two-Round Visual Evaluation

The visual evaluation is structured into two sequential rounds to ensure fair comparison and focused validation.

```text
+-------------------------------------------------------------------------------+
|                       TWO-ROUND VISUAL EVALUATION PROCESS                     |
+-------------------------------------------------------------------------------+
| ROUND A: STYLE SELECTION (Controlled Comparison)                              |
| - Compare 3 candidate painterly executions (Candidate A, B, C)               |
| - Exact same reference scene, objects, composition, lighting, and format       |
| - Test variable: PAINTERLY TREATMENT ONLY                                     |
| - Output: Visual evidence for Project Owner Review & Master Style Decision     |
+---------------------------------------+---------------------------------------+
                                        |
                                        v
+-------------------------------------------------------------------------------+
| [GATEWAY: EXPLICIT PROJECT OWNER REVIEW & MASTER STYLE APPROVAL]              |
| - Owner selects A, B, C, requests iteration, or approves combined traits     |
| - Master Style Record is formally completed                                  |
+---------------------------------------+---------------------------------------+
                                        |
                                        v
+-------------------------------------------------------------------------------+
| ROUND B: STYLE VALIDATION (Condition & Content Robustness)                    |
| - Validates approved Master Style across diverse environmental conditions:    |
|   1. Rainy Garden (wet materials, teal-grey atmosphere, rain readability)     |
|   2. Night Garden (cool indigo ambient, localized warm lamp pool, fireflies)  |
|   3. Plant Growth Close-Read (Holy Basil & Marigold: 4 stages side-by-side)   |
|   4. Visitor Moment (Cat on bench, butterfly on flower, scale & anatomy)      |
+-------------------------------------------------------------------------------+
```

*Note on Task Scope:* Task 4.2A defines the complete specification and prompt templates for both rounds. **No images are generated in Task 4.2A.**

---

## 4. Fixed Round-A Reference Scene Specification

To compare painterly treatments without confounding variables, Candidates A, B, and C share a single, strictly controlled daytime reference scene.

### 4.1 Canvas and Format
- **Orientation:** Portrait (9:16 aspect ratio).
- **Reference Canvas:** 1080 × 1920 pixels.
- **Compositional Framing:** Compact mobile garden perspective. The garden stage occupies the central vertical field (~1080 × 1400 safe area), leaving balanced breathing room at the top (sky, roof eaves) and bottom (foreground earth) for future UI accommodation without actual UI elements present.

### 4.2 Setting and Environment
- **Location:** A small, modest residential yard beside an everyday Thai home (*สวนกระถางข้างบ้าน*).
- **Atmosphere:** Warm, quiet, living, domestic, and inviting.
- **Boundary Elements:** A soft wooden roof eave or verandah corner visible in the upper background, paired with a simple low weathered wooden boundary fence (*รั้วไม้ระแนง*).
- **Ground Surface:** A natural, lived-in mix of warm dark moist soil, weathered earth, worn gravel, and moss-softened concrete paving stones.
- **Foreground:** Subtle, out-of-focus tropical leaf tips framing the upper corners only; zero occlusion of the central interactive area.

### 4.3 Time and Weather Conditions
- **Time of Day:** Calm late morning / soft daytime (~10:00–11:00 AM).
- **Weather:** Clear sky with soft tropical sunlight.
- **Lighting Quality:** Warm directional sunlight filtered gently through foliage; soft, diffused shadows with warm ambient fill; no harsh black cast shadows or blown-out highlights.

### 4.4 Required Visible Content Roster
The reference scene contains exactly the initial vertical slice entities established in `VISUAL_STYLE_BIBLE.md` §27:
1. **Plants (2 species, mature):**
   - **Mature Holy Basil (*กะเพรา* — `plant.holy_basil`):** Multi-branching compact herb bush with rounded, aromatic olive-green leaves and tiny purple-tinted flower spikes at branch crowns.
   - **Mature Marigold (*ดาวเรือง* — `plant.marigold`):** Bushy green foliage crowned by full, vibrant, rounded golden-orange pom-pom blossoms.
2. **Decorations (2 objects):**
   - **Clay Water Jar (*โอ่งดินเผา* — `decoration.clay_jar`): Stout, rounded terracotta earthenware jar with traditional shoulder rim, subtle kiln markings, and light lime weathering.
   - **Garden Bench (*ม้านั่งไม้* — `decoration.bench`):** Simple, sturdy slatted weathered teak bench with softened rectangular framing and grey-brown wood patina.
3. **Primary Visitor (1 creature):**
   - **Domestic Cat (*แมวบ้าน* — `visitor.cat`):** One relaxed ginger/cream domestic cat resting in a natural, peaceful pose (loaf or light curl) on or immediately beside the garden bench. Believable domestic anatomy; no cartoon/mascot caricature.
4. **Secondary Life (1 creature):**
   - **Garden Butterfly (`visitor.butterfly`):** One small, delicate butterfly with cream and warm yellow wing patterns hovering near or resting gently on the marigold blossoms.
5. **Subtle Supporting Domestic Details (Restrained):**
   - One simple utilitarian watering can resting near the jar.
   - A couple of small, empty terracotta pots stacked or placed neatly near the planting edge.
   - A few fallen leaves on the pavers adhering to the "one-or-two details" lived-in rule.

---

## 5. Fixed Cultural Grounding & Authenticity Rules

All Round-A candidate prompts must preserve authentic domestic reality and prevent exotic or stereotypical drift:

```text
AUTHENTIC EVERYDAY THAI DOMESTIC REALITY:
✓ Modest residential living yard beside an ordinary home.
✓ Humid tropical microclimate with dappled leaf shade.
✓ Earthenware clay jar (โอ่งดินเผา), weathered teak bench, practical planters.
✓ Familiar domestic herbs and garden flowers (holy basil, marigold).
✓ Weathered, cared-for domestic yard materials reflecting daily life.

STRICTLY FORBIDDEN EXOTIC & STEREOTYPICAL TROPES:
✗ No Buddhist temples, chedis, monks, shrines, or spirit houses.
✗ No golden palace filigree, royal ornamentation, or ceremonial spires.
✗ No tourist postcard clichés: no tuk-tuks, boxing gloves, or souvenir trinkets.
✗ No fantasy RPG elements: no glowing blue crystals, fairy dust, or giant mushrooms.
✗ No foreign garden styles: no Japanese zen gardens/lanterns, no English cottage lawns,
  no American/European barns, no luxury resort infinity cabanas.
✗ No glossy mobile-farm caricatures: no neon plastic crops, no oversized chibi animals.
```

---

## 6. Fixed Camera and Compositional Anchors

To guarantee identical framing across all candidate images:
- **Camera Perspective:** Slightly elevated, eye-level-to-midground illustrated garden view (~25–30 degree downward incline). Suitable for a compact mobile garden diorama.
- **Forbidden Camera Types:** No first-person perspective; no dramatic ground-level wide-angle; no extreme isometric strategy grid; no landscape panoramic framing; no character portrait closeup.
- **Compositional Placement Anchors (Reference Layout):**
  - **Upper Background:** Modest home roof eave / timber siding and low weathered wooden fence providing a gentle backstop.
  - **Left Midground:** Terracotta clay water jar (*โอ่งดินเผา*), establishing a solid rounded anchor.
  - **Center-Left Midground:** Potted or bedded mature Holy Basil (*กะเพรา*).
  - **Center-Right Midground:** Potted or bedded mature blooming Marigold (*ดาวเรือง*).
  - **Right Midground:** Simple slatted weathered teak bench (*ม้านั่งไม้*).
  - **Bench Anchor:** Domestic cat resting comfortably upon the bench surface.
  - **Marigold Anchor:** Small butterfly fluttering near the golden blossom crowns.
  - **Foreground Borders:** Ground transition of earth, gravel, and stone pavers in lower third; soft out-of-focus leaf silhouette in top corners only.

*Note:* These placement anchors are composition guidelines for image generation, **not** gameplay coordinate or grid mechanics.

---

## 7. Controlled Experiment Variables

To isolate the visual impact of painterly treatment, all other generation parameters are strictly frozen:

| Experiment Parameter | Status in Round A | Specification Across Candidates A, B, C |
|---|---|---|
| **Aspect Ratio / Resolution** | **FIXED** | Portrait 9:16 (1080 × 1920 reference) |
| **Camera Perspective** | **FIXED** | Slightly elevated illustrated garden diorama view (~25–30°) |
| **Setting & Environment** | **FIXED** | Everyday Thai residential home garden with fence and eave |
| **Time of Day** | **FIXED** | Calm late morning (~10:30 AM) |
| **Weather & Lighting** | **FIXED** | Clear tropical daylight, soft directional sun, warm ambient fill |
| **Entity Roster** | **FIXED** | Holy basil, marigold, clay jar, bench, resting cat, butterfly |
| **Compositional Layout** | **FIXED** | Jar left, basil center-left, marigold center-right, bench & cat right |
| **Scene Density** | **FIXED** | Compact, uncluttered; follows "one-or-two details" lived-in rule |
| **Negative Constraints** | **FIXED** | Identical common negative prompt block across all candidates |
| **PAINTERLY TREATMENT** | **TEST VARIABLE** | **Varies deliberately across Candidates A, B, and C** |

---

## 8. Common Negative Constraints Block

The following negative constraint block is mandatory and identical for all Round-A prompts:

```text
COMMON NEGATIVE CONSTRAINTS:
No text, no letters, no words, no numbers, no labels, no UI buttons, no icons, no HUD,
no health bars, no dialogue boxes, no menu frames, no screenshot borders, no logos,
no watermarks, no artist signature. No 3D CGI rendering, no 3D computer graphics models,
no ray-tracing, no specular shine, no glossy plastic toy textures, no shiny game-engine assets.
No photorealism, no raw photographic textures. No sharp vector flat art, no corporate clip art,
no clinical geometric beziers. No pixel art, no 8-bit/16-bit sprites, no grid dithering.
No anime character tropes, no giant cartoon eyes, no oversized chibi mascot proportions,
no deformed animal caricatures. No continuous heavy black comic-book outlines around objects.
No oversaturated neon colors, no fluorescent glow, no rainbow casino palette.
No magical sparkle spam, no floating glitter particles, no glowing fantasy crystals,
no enchanted runes. No Buddhist temples, no chedis, no monks, no religious shrines,
no spirit houses, no golden royal palace ornaments, no ceremonial spires.
No tourist tuk-tuks, no tourism postcard kitsch. No giant animals, no giant fantasy insects.
No farm machinery, no tractors, no industrial farming tools. No massive open crop fields,
no red American/European barns, no silos. No Japanese stone lanterns, no zen gravel patterns,
no torii gates. No luxury resort infinity pools, no hotel cabanas.
```

---

## 9. Round-A Candidate Specifications & Prompts

### 9.1 Candidate A: Watercolor-Forward / Airy Painterly

- **Stylistic Hypothesis:** A lighter, watercolor-forward interpretation creates maximum cozy, gentle handmade warmth and natural atmosphere, evoking a soft illustrated storybook.
- **Key Visual Characteristics:**
  - Translucent layered watercolor washes with visible pigment sedimentation.
  - Wet-on-wet blooming and soft bleed transitions between tones.
  - Airy, breathable foliage clusters with delicate leaf-edge suggestions.
  - Subtle cold-press paper grain texture visible in broad light areas.
  - Very soft edges with minimal selective warm-umber contour accents on focal objects.
  - Light visual weight, luminous daylight reflections, gentle organic softness.
- **Risks to Evaluate:**
  - Object silhouettes may become too diffuse or soft on small mobile screens.
  - Foreground-to-background separation may weaken without firmer contrast.
  - Paper grain and pigment blooming might read as visual noise on high-DPI displays.

#### Candidate A Image-Generation Prompt
```text
PROMPT — CANDIDATE A (WATERCOLOR-FORWARD / AIRY PAINTERLY):

A beautiful 2D soft hand-painted storybook illustration of a cozy, lived-in everyday Thai domestic home garden in a small residential yard. Modest wooden eave of a home and a low weathered wooden fence form the upper boundary. The central ground features a natural transition of warm moist earth, weathered gravel, and moss-softened concrete pavers. Restrained tropical foliage gently frames the outer upper corners without obstructing the scene.

A stout rounded terracotta clay water jar (ong din pao) sits in the left-midground with subtle lime patina. Near the center-left grows a mature, bushy holy basil plant (kaprao) with aromatic green leaves and tiny flower spikes. Near the center-right blooms a mature, bushy marigold plant (dao ruang) with vibrant golden-orange rounded blossoms. On the right-midground rests a simple weathered teak garden bench. A relaxed domestic cat is curled comfortably on the bench. One small gentle butterfly flutters near the marigold blossoms. A modest practical watering can and a couple of small terracotta pots sit quietly nearby.

Calm late-morning natural tropical daylight with soft, warm golden illumination and gentle diffused shadows. Clear weather, humid atmosphere, peaceful observational perspective. Android portrait mobile composition (9:16 aspect ratio, reference 1080x1920 canvas).

Painterly treatment: Watercolor-forward airy illustration. Translucent layered watercolor washes with visible wet-on-wet blooming and pigment granulation on subtle cold-press paper grain. Very soft, breathing edges with minimal selective warm-sepia contour accents on key forms. Airy foliage clusters with delicate value transitions and a light visual weight. Luminous, breathable, warm natural atmosphere with gentle watercolor gradients.

NEGATIVE PROMPT:
[INSERT COMMON NEGATIVE CONSTRAINTS BLOCK]
```

---

### 9.2 Candidate B: Gouache-Forward / Shape-Led Painterly

- **Stylistic Hypothesis:** An opaque, gouache-forward interpretation maximizes mobile silhouette readability and crisp touch affordance while preserving artisanal, hand-painted charm.
- **Key Visual Characteristics:**
  - Opaque, creamy gouache paint layers with clear shape boundaries.
  - Strong, distinct silhouette grouping for plants, jar, bench, and visitor.
  - Confident local value contrast between interactive entities and the ground plane.
  - Slightly firmer painted edges with subtle hand-trimmed organic imperfection.
  - Visible, restrained matte brushstroke textures without high-frequency grit.
  - Simplified interior surface detail focusing on bold, recognizable volumes.
  - Muted, grounded natural palette with tactile, earthy solidity.
- **Risks to Evaluate:**
  - Artwork may veer toward overly graphic or posterized illustration.
  - May lose the gentle, airy, organic atmosphere of a breathing garden.
  - If over-simplified, risks feeling like conventional flat vector mobile-game art.

#### Candidate B Image-Generation Prompt
```text
PROMPT — CANDIDATE B (GOUACHE-FORWARD / SHAPE-LED PAINTERLY):

A beautiful 2D soft hand-painted storybook illustration of a cozy, lived-in everyday Thai domestic home garden in a small residential yard. Modest wooden eave of a home and a low weathered wooden fence form the upper boundary. The central ground features a natural transition of warm moist earth, weathered gravel, and moss-softened concrete pavers. Restrained tropical foliage gently frames the outer upper corners without obstructing the scene.

A stout rounded terracotta clay water jar (ong din pao) sits in the left-midground with subtle lime patina. Near the center-left grows a mature, bushy holy basil plant (kaprao) with aromatic green leaves and tiny flower spikes. Near the center-right blooms a mature, bushy marigold plant (dao ruang) with vibrant golden-orange rounded blossoms. On the right-midground rests a simple weathered teak garden bench. A relaxed domestic cat is curled comfortably on the bench. One small gentle butterfly flutters near the marigold blossoms. A modest practical watering can and a couple of small terracotta pots sit quietly nearby.

Calm late-morning natural tropical daylight with soft, warm golden illumination and gentle diffused shadows. Clear weather, humid atmosphere, peaceful observational perspective. Android portrait mobile composition (9:16 aspect ratio, reference 1080x1920 canvas).

Painterly treatment: Gouache-forward shape-led illustration. Rich, opaque painted shape masses with clear silhouette grouping and firm local value separation. Slightly crisper painted edges on interactable plants, bench, and jar, with visible but restrained creamy matte brushstroke textures. Simplified interior detail focused on bold graphic volumes, muted organic palette, and tactile handmade imperfection without flat vector stiffness.

NEGATIVE PROMPT:
[INSERT COMMON NEGATIVE CONSTRAINTS BLOCK]
```

---

### 9.3 Candidate C: Balanced Storybook Hybrid

- **Stylistic Hypothesis:** A balanced hybrid combining gouache body color for core silhouettes with watercolor washes for environmental depth achieves the ideal compromise between mobile clarity and cozy warmth.
- **Key Visual Characteristics:**
  - Soft gouache body tones on interactive elements (plants, visitor, jar, bench) for clear silhouette definition.
  - Gentle watercolor-inspired washes and atmospheric gradients in the background and ground transitions.
  - Softly painted storybook edges: distinct exterior contours paired with tender interior tonal shifts.
  - Selective crispness focused strictly on interactive focal zones (flower centers, jar rim, cat face).
  - Restrained fine-tooth paper grain providing tactile continuity across the canvas.
  - Warm, lived-in material rendering with balanced visual density.
- **Risks to Evaluate:**
  - Compromise may lack a distinct, bold visual signature if not carefully calibrated.
  - Balancing two media treatments across a single production pipeline may require tighter art supervision.

#### Candidate C Image-Generation Prompt
```text
PROMPT — CANDIDATE C (BALANCED STORYBOOK HYBRID):

A beautiful 2D soft hand-painted storybook illustration of a cozy, lived-in everyday Thai domestic home garden in a small residential yard. Modest wooden eave of a home and a low weathered wooden fence form the upper boundary. The central ground features a natural transition of warm moist earth, weathered gravel, and moss-softened concrete pavers. Restrained tropical foliage gently frames the outer upper corners without obstructing the scene.

A stout rounded terracotta clay water jar (ong din pao) sits in the left-midground with subtle lime patina. Near the center-left grows a mature, bushy holy basil plant (kaprao) with aromatic green leaves and tiny flower spikes. Near the center-right blooms a mature, bushy marigold plant (dao ruang) with vibrant golden-orange rounded blossoms. On the right-midground rests a simple weathered teak garden bench. A relaxed domestic cat is curled comfortably on the bench. One small gentle butterfly flutters near the marigold blossoms. A modest practical watering can and a couple of small terracotta pots sit quietly nearby.

Calm late-morning natural tropical daylight with soft, warm golden illumination and gentle diffused shadows. Clear weather, humid atmosphere, peaceful observational perspective. Android portrait mobile composition (9:16 aspect ratio, reference 1080x1920 canvas).

Painterly treatment: Balanced storybook painterly hybrid. Soft gouache body tones harmonized with delicate watercolor wash transitions. Warm painted storybook edges with organic softness and selective clarity on focal plants, jar, bench, and cat. Tactile, restrained fine paper texture with gentle layered brushwork. Lived-in material rendering with balanced visual weight, combining clear mobile silhouette readability with airy handmade warmth.

NEGATIVE PROMPT:
[INSERT COMMON NEGATIVE CONSTRAINTS BLOCK]
```

---

### 9.4 Prompt-Difference Audit

To verify that Candidates A, B, and C strictly isolate the test variable, the following table audits text identity across the prompts:

| Prompt Section | Candidate A (Watercolor) | Candidate B (Gouache) | Candidate C (Hybrid) | Audit Status |
|---|---|---|---|---|
| **Paragraph 1: Setting & Bounds** | Exact match | Exact match | Exact match | **IDENTICAL** |
| **Paragraph 2: Entities & Placement** | Exact match | Exact match | Exact match | **IDENTICAL** |
| **Paragraph 3: Lighting & Canvas** | Exact match | Exact match | Exact match | **IDENTICAL** |
| **Paragraph 4: Painterly Treatment** | Translucent watercolor washes, wet blooms, airy masses | Opaque gouache shapes, firm silhouettes, creamy brushwork | Soft gouache body + watercolor washes, balanced storybook | **TEST VARIABLE** |
| **Paragraph 5: Negative Constraints** | Exact match | Exact match | Exact match | **IDENTICAL** |

---

## 10. Stochastic Generation Limitations & Evaluation Guardrails

AI-assisted and procedural image generation involves inherent stochastic variation:
1. **Compositional Drift:** Even with identical framing prompts, generated images may exhibit subtle differences in seed placement, foliage distribution, or precise object angles.
2. **Evaluation Focus:** Reviewers must evaluate **broad painterly qualities** (edge softness, pigment behavior, silhouette grouping, texture density, color harmony) rather than getting distracted by accidental seed differences.
3. **No Accidental Gameplay Commitments:** If a candidate image happens to render an extra watering pot, a small gecko on the fence, or a stone pathway, these elements **do not** become gameplay requirements. Only `GAME_DESIGN.md` defines systemic content commitments.

---

## 11. Round-A Review Criteria & Scorecard

Reviewers (and ultimately the project owner) will evaluate each candidate across 14 standardized criteria on a scale of 1 to 5 (1 = Poor / Problematic, 3 = Acceptable, 5 = Exemplary):

| # | Evaluation Criterion | Description & Mobile Context | Candidate A (Watercolor) | Candidate B (Gouache) | Candidate C (Hybrid) |
|---|---|---|---|---|---|
| 1 | **Calm / Cozy Emotional Fit** | Conveys safety, warmth, and unhurried restfulness (`GAME_DESIGN.md` §4.1) | [ 1–5 ] | [ 1–5 ] | [ 1–5 ] |
| 2 | **Everyday Home-Garden Authenticity** | Feels like a genuine residential yard, not a public park or wilderness | [ 1–5 ] | [ 1–5 ] | [ 1–5 ] |
| 3 | **Thai Identity Without Stereotype** | Evokes authentic materials/climate without resort/temple clichés | [ 1–5 ] | [ 1–5 ] | [ 1–5 ] |
| 4 | **Mobile Silhouette Readability** | Key shapes immediately readable when viewed at phone scale (1080×1920) | [ 1–5 ] | [ 1–5 ] | [ 1–5 ] |
| 5 | **Plant Readability** | Holy basil and marigold clearly distinguished by form and leaf mass | [ 1–5 ] | [ 1–5 ] | [ 1–5 ] |
| 6 | **Visitor Readability (No Mascot)** | Cat is recognizable and dignified; natural animal pose without caricature | [ 1–5 ] | [ 1–5 ] | [ 1–5 ] |
| 7 | **Material Differentiation** | Terracotta clay, weathered wood, earth, and foliage feel distinct | [ 1–5 ] | [ 1–5 ] | [ 1–5 ] |
| 8 | **Lived-In Quality** | Subtle authentic imperfections adhere to "one-or-two details" rule | [ 1–5 ] | [ 1–5 ] | [ 1–5 ] |
| 9 | **Visual Clutter Control** | Ground surfaces and background remain restful, avoiding pixel noise | [ 1–5 ] | [ 1–5 ] | [ 1–5 ] |
| 10 | **Distinctiveness from Generic Farm Games** | Avoids glossy candy assets, flat vector icons, and Western farm tropes | [ 1–5 ] | [ 1–5 ] | [ 1–5 ] |
| 11 | **Condition Adaptability** | Visual style plausibly translates into rainy and nighttime scenes | [ 1–5 ] | [ 1–5 ] | [ 1–5 ] |
| 12 | **UI Overlay Support** | Ample breathing room and calm areas for future HUD and menus | [ 1–5 ] | [ 1–5 ] | [ 1–5 ] |
| 13 | **Low-Pressure Product Consistency** | Visual tone actively discourages stress, urgency, or sensory overload | [ 1–5 ] | [ 1–5 ] | [ 1–5 ] |
| 14 | **Production Pipeline Plausibility** | Feasible for repeatable 2D sprite creation in downstream Task 4.3 | [ 1–5 ] | [ 1–5 ] | [ 1–5 ] |

### Qualitative Review Notes Template
```text
QUALITATIVE AUDIT LOG:

Candidate A (Watercolor-Forward):
- Strongest Qualities: [ Notes on atmosphere, paper warmth, soft washes ]
- Weaknesses / Risks: [ Notes on edge softness on phone, silhouette clarity ]
- Elements Worth Borrowing: [ Specific wash effects, sky gradients, foliage softness ]
- Retain / Reject Recommendation: [ Retain / Reject / Synthesize ]

Candidate B (Gouache-Forward):
- Strongest Qualities: [ Notes on graphic clarity, solid silhouettes, interactables ]
- Weaknesses / Risks: [ Notes on potential flatness or vector-like stiffness ]
- Elements Worth Borrowing: [ Specific entity contour strength, opaque clay tones ]
- Retain / Reject Recommendation: [ Retain / Reject / Synthesize ]

Candidate C (Balanced Storybook Hybrid):
- Strongest Qualities: [ Notes on balance, readability, and gentle warmth ]
- Weaknesses / Risks: [ Notes on distinctiveness, execution complexity ]
- Elements Worth Borrowing: [ Specific layering techniques, edge treatment ]
- Retain / Reject Recommendation: [ Retain / Reject / Synthesize ]
```

> **Strict Evaluation Governance Rule:** An agent must **never** automatically declare a winning Master Style solely from numerical score totals. Scores are structured evidence to assist human judgment. Master Style selection requires explicit project owner review and approval.

---

## 12. Project Owner Review Rule & Governance

Following generation and review in Task 4.2B, visual evidence will be formally presented to the project owner. The project owner has full authority to:
1. **Select Candidate A** as the Master Style Anchor.
2. **Select Candidate B** as the Master Style Anchor.
3. **Select Candidate C** as the Master Style Anchor.
4. **Approve a Synthesized Direction** combining explicitly specified traits from multiple candidates (e.g., Candidate B's silhouette clarity on plants with Candidate A's background wash treatment).
5. **Request an Iteration Round** with adjusted prompt parameters if all candidates reveal unacceptable drift or defects.

No aesthetic direction is promoted to LOCKED until the project owner explicitly approves it.

---

## 13. Master Style Decision Record (Pending Owner Review)

This section serves as the formal project ledger for the visual direction decision. In Task 4.2A, all fields remain deliberately pending:

```text
================================================================================
MASTER STYLE DECISION RECORD — PENDING OWNER REVIEW
================================================================================
Selected Candidate:         TBD (Pending Owner Review in Task 4.2)
Approved Borrowed Traits:   TBD (Pending Owner Review)
Rejected Traits:            TBD (Pending Owner Review)
Palette Direction:          TBD (Pending Owner Review)
Edge Treatment:             TBD (Pending Owner Review)
Texture Treatment:          TBD (Pending Owner Review)
Silhouette Treatment:       TBD (Pending Owner Review)
Cultural Grounding Notes:   TBD (Pending Owner Review)
Owner Approval Status:      PENDING EXPLICIT HUMAN APPROVAL
================================================================================
```

---

## 14. Round-B Validation Mockups Plan

Once the project owner approves the Master Style Anchor, Round B will test that single visual style across four critical condition and content scenarios. Round B ensures the chosen style does not collapse under environmental shifts or specialized content requirements.

### 14.1 Scene A: Rainy Garden
- **Objective:** Validate wet surface responses, rain readability, and mood maintenance.
- **Key Visual Checks:**
  - Diffuse silver-teal atmospheric wash; distant foliage gently fades into mist.
  - Soft, non-intrusive vertical rain streaks and delicate circular puddle ripples.
  - Materials reflect dampness: subtle wet specular sheen on the terracotta rim and leaves; heavier, slightly drooping foliage stems.
  - **Emotional Tone:** Cozy, refreshing, and calming—never dark, stormy, cold, or punitive (`GAME_DESIGN.md` §14).

### 14.2 Scene B: Night Garden
- **Objective:** Validate nocturnal readability, localized warm lighting, and magical atmosphere.
- **Key Visual Checks:**
  - Base ambient wash in deep, peaceful indigo (`#1A233A`); strictly no crushed pitch-black shadows.
  - Localized warm illumination radiating from a simple garden lantern or warm window glow, illuminating the bench and nearby soil.
  - Soft floating firefly motes with gentle yellow-green luminescence.
  - Key plant and object silhouettes remain clearly readable against the nocturnal ambient backdrop.

### 14.3 Scene C: Plant Growth Close-Read
- **Objective:** Validate 4-stage growth silhouette differentiation at mobile phone scale.
- **Key Visual Checks:**
  - Side-by-side progression for **Holy Basil** and **Marigold**:
    1. *Planted:* Small mound of dark moist earth with tiny furrow or marker.
    2. *Sprout:* Tender, upright two-leaf shoot emerging from soil (~5% stage height).
    3. *Growing:* Multi-branched leafy shrub (~10–12% stage height) with immature buds.
    4. *Mature:* Full bushy silhouette (~15–18% stage height) with harvestable flower spikes (basil) or lush golden blossoms (marigold).
  - Growth stages must be distinguishable by silhouette and mass alone, with zero dependence on text labels.

### 14.4 Scene D: Visitor Moment
- **Objective:** Validate animal scale, natural anatomy, and environment interaction without mascot distortion.
- **Key Visual Checks:**
  - Cat resting in a dignified, peaceful pose on the weathered bench.
  - Yellow butterfly delicately perched upon a mature marigold blossom.
  - Correct relative scale: cat is believable domestic size relative to the bench and clay jar; butterfly is delicate and small.
  - Complete absence of chibi heads, oversized cartoon eyes, or comical expressions.

---

## 15. Round-B Prompt Templates (Using Master Style Anchor)

Each Round-B prompt incorporates the placeholder `[APPROVED MASTER STYLE ANCHOR]`. These templates remain unexecuted until Round A selection is finalized:

### 15.1 Template: Rainy Garden
```text
PROMPT TEMPLATE — VALIDATION SCENE A (RAINY GARDEN):

A beautiful 2D soft hand-painted illustration of the cozy everyday Thai domestic home garden during a gentle tropical daytime rain. Modest wooden home eave and boundary fence in upper background, clay water jar on left-midground, mature holy basil and marigold plants in central midground, weathered teak bench on right-midground.

Atmosphere: Soft diffuse silver-teal rain mist washing through the scene, gentle translucent rain streaks falling softly, delicate circular ripples forming in small puddles and the water jar rim. Plant leaves and terracotta surfaces appear freshly damp with a soft, gentle sheen. Cozy, refreshing, serene, and nurturing mood; not dark or stormy. Android portrait mobile composition (9:16 aspect ratio).

[APPROVED MASTER STYLE ANCHOR]

NEGATIVE PROMPT:
[INSERT COMMON NEGATIVE CONSTRAINTS BLOCK]
Additional negatives: No lightning, no thunderclouds, no dark ominous skies, no torrential flooding, no damaged plants, no scary storm weather.
```

### 15.2 Template: Night Garden
```text
PROMPT TEMPLATE — VALIDATION SCENE B (NIGHT GARDEN):

A beautiful 2D soft hand-painted illustration of the cozy everyday Thai domestic home garden at peaceful night. Modest wooden home eave and boundary fence in upper background, clay water jar on left-midground, mature holy basil and marigold plants in central midground, weathered teak bench on right-midground.

Atmosphere: Deep peaceful indigo nocturnal ambient light (#1A233A) with zero crushed black shadows. A small warm garden lamp softly illuminates the weathered bench and adjacent earth in a gentle pool of golden light. A few soft, glowing yellow-green fireflies drift gently across the garden foliage. Intimate, tranquil, safe sanctuary mood. Android portrait mobile composition (9:16 aspect ratio).

[APPROVED MASTER STYLE ANCHOR]

NEGATIVE PROMPT:
[INSERT COMMON NEGATIVE CONSTRAINTS BLOCK]
Additional negatives: No pitch black darkness, no spooky shadows, no horror atmosphere, no harsh blue monochrome filters, no blinding neon glow.
```

### 15.3 Template: Plant Growth Close-Read
```text
PROMPT TEMPLATE — VALIDATION SCENE C (PLANT GROWTH CLOSE-READ):

A 2D soft hand-painted botanical growth study sheet demonstrating the 4-stage growth progression of two Thai garden plants, displayed side by side against a clean, neutral handmade paper background (#F7F4EB).

Top Row: Holy Basil (kaprao) growth stages from left to right:
1. Planted: Small neat mound of moist dark earth with tiny furrow.
2. Sprout: Tender upright two-leaf green seedling emerging from soil.
3. Growing: Branching compact herb bush with young green leaf tiers.
4. Mature: Full dense bushy herb dome crowned with tiny purple/reddish flower spikes.

Bottom Row: Marigold (dao ruang) growth stages from left to right:
1. Planted: Small neat mound of moist dark earth with planting marker.
2. Sprout: Slender upright shoot with feathered first leaves.
3. Growing: Bushy leafy mound with round green flower buds.
4. Mature: Lush foliage topped with full, rounded, vibrant golden-orange blossoms.

Clear silhouette distinctions between all stages, readable at mobile display scale without any text labels.

[APPROVED MASTER STYLE ANCHOR]

NEGATIVE PROMPT:
[INSERT COMMON NEGATIVE CONSTRAINTS BLOCK]
Additional negatives: No text labels, no stage names, no numbers, no arrows, no UI frames.
```

### 15.4 Template: Visitor Moment
```text
PROMPT TEMPLATE — VALIDATION SCENE D (VISITOR MOMENT):

A beautiful 2D soft hand-painted illustration of an intimate, peaceful wildlife visitor moment in the cozy Thai domestic home garden. Clear calm late-morning tropical daylight.

Focal interactions: On the right midground, a relaxed domestic ginger-and-cream cat sleeps peacefully in a soft curl on the weathered slatted teak bench. Near the center-right, a delicate cream-and-yellow butterfly hovers and gently alights atop a vibrant golden marigold blossom. In the supporting midground, the terracotta clay water jar and aromatic holy basil plant anchor the natural scene. Natural animal scale and believable anatomy; creatures feel like dignified living guests rather than cartoon mascots. Android portrait mobile composition (9:16 aspect ratio).

[APPROVED MASTER STYLE ANCHOR]

NEGATIVE PROMPT:
[INSERT COMMON NEGATIVE CONSTRAINTS BLOCK]
Additional negatives: No cartoon mascot faces, no chibi proportions, no humanized animal poses, no giant butterflies, no collar or leash on cat.
```

---

## 16. Image Output Naming Plan

For planning and traceability, future generated review artifacts will use the following standardized filenames:

### Round A: Candidate Comparison
- `mockup_round_a_candidate_a_watercolor.png`
- `mockup_round_a_candidate_b_gouache.png`
- `mockup_round_a_candidate_c_hybrid.png`

### Round B: Master Style Validation
- `mockup_validation_rain.png`
- `mockup_validation_night.png`
- `mockup_validation_plant_stages.png`
- `mockup_validation_visitors.png`

> **Notice:** These filenames are planning conventions only. **No image files are created in Task 4.2A.**

---

## 17. Generated Image Repository & Asset Policy

To keep the Git repository lean and maintainable:
1. **External Generation:** Concept images are generated through approved image-generation workflows outside the tracked repository or in temporary artifact workspaces.
2. **Visual Curation Gate:** Stochastic generation runs often produce artifacts with minor prompt drift or seed defects. All failed drafts must be discarded immediately.
3. **Selective Tracking:** Only the final, intentionally selected candidate review mockups (maximum 3 files for Round A, 4 files for Round B) may ever be committed to documentation or design folders.
4. **Production Asset Separation:** Concept mockups are full-scene illustrations for visual direction review. They are **not** game-ready production sprites. The slicing, atlas packing, and technical import of 2D game assets belongs exclusively to downstream tasks (Task 4.3 and implementation milestones).
5. **No Repository Bloat:** Raw iteration batches, discarded prompt tests, and high-resolution generation dumps must **never** be committed to Git.

---

## 18. Visual Review Protocols

### 18.1 Mobile-Size Display Review
Because *Garden* is an Android-first mobile game (`ARCHITECTURE.md` §3), all candidate images must be reviewed under two conditions:
1. **Full-Resolution Inspection (Desktop Monitor):** To evaluate brushstroke fidelity, pigment bleed, paper grain, and edge quality.
2. **Mobile Screen Simulation (Reduced Scale):** The image must be scaled down to approximately 65–75 mm width (simulating a standard 6-inch phone display held at arm's length).
   - *Check 1:* Can the cat be immediately identified as a resting animal?
   - *Check 2:* Is the butterfly discoverable near the marigold without zooming?
   - *Check 3:* Can holy basil and marigold be distinguished by silhouette alone?
   - *Check 4:* Does the clay jar retain its distinct rounded earthenware volume?
   - *Check 5:* Does the garden background stay restful, or does brush texture degenerate into pixel noise?

### 18.2 Value and Accessibility Review
To serve the locked accessibility goal of adequate visual contrast (`GAME_DESIGN.md` §29):
1. **Grayscale Desaturation Check:** Reviewers must inspect a desaturated (grayscale) version of each mockup.
2. **Value Contrast Threshold:** The midground interactive entities (plants, jar, bench, cat) must remain cleanly distinct from the ground and fence plane based on luminance value alone.
3. **No Color-Only Information:** Identification must not rely solely on hue (e.g., distinguishing basil from marigold must rely on leaf clump geometry and blossom shape, not just green vs. yellow).

---

## 19. Task 4.2A Acceptance Checklist

Before considering this planning phase complete, verify all criteria:

```text
[x] 1. Controlled mockup plan exists as VISUAL_MOCKUP_PLAN.md.
[x] 2. Exactly one tracked file added to git scope (A VISUAL_MOCKUP_PLAN.md).
[x] 3. Round A defines a controlled comparison of three candidates (A, B, C).
[x] 4. All Round-A candidates use the exact same reference scene, composition, entities, and lighting.
[x] 5. Painterly treatment is established as the sole intentional test variable.
[x] 6. Candidate A specifies watercolor-forward airy painterly treatment.
[x] 7. Candidate B specifies gouache-forward shape-led painterly treatment.
[x] 8. Candidate C specifies balanced storybook hybrid painterly treatment.
[x] 9. Reusable Common Negative Constraints block is defined and applied.
[x] 10. Prompts strictly avoid named artist, studio, or copyrighted game imitation.
[x] 11. Prompts strictly forbid embedded text, UI, logos, and watermarks.
[x] 12. Standardized 14-point review scorecard is established.
[x] 13. Automatic winner computation from scores is explicitly forbidden.
[x] 14. Project owner review and approval rule is formally recorded.
[x] 15. Master Style Decision Record template is established with all fields PENDING.
[x] 16. Round-B validation scenes (Rain, Night, Plants, Visitors) are fully documented.
[x] 17. Round-B prompt templates use [APPROVED MASTER STYLE ANCHOR] placeholders.
[x] 18. Standardized image naming plan is established (planning names only).
[x] 19. Generated-image repository handling and anti-bloat policy is documented.
[x] 20. Accidental generated objects are explicitly barred from becoming gameplay specs.
[x] 21. Mobile-size scaling and grayscale accessibility review protocols are defined.
[x] 22. VISUAL_STYLE_BIBLE.md is completely untouched.
[x] 23. No code, scenes, resources, tests, or export configs are modified.
[x] 24. No images or media assets are generated or committed in Task 4.2A.
[x] 25. No provisional visual direction is promoted to LOCKED.
[x] 26. Godot tests pass with 613 passed, 0 failed.
```

---

*End of Visual Mockup Plan — Task 4.2A*
