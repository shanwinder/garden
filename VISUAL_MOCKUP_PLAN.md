# Garden Controlled Concept Mockup Plan

> **Document Type:** Concept-Art Experiment Specification & Master Style Decision Ledger
>
> **Status:** **MASTER STYLE APPROVED — ROUND B AUTHORIZED (Task 4.2C)**
>
> **Milestone:** Milestone 4 (Visual Direction & Asset Pipeline)
>
> **Reference Target:** Android Portrait (1080 × 1920 Reference Canvas)
>
> **Engine Baseline:** Godot 4.7.2 Stable (Compatibility 2D)
>
> **Upstream Authority:** `VISUAL_STYLE_BIBLE.md` (Task 4.1 / 4.1C / 4.2C)

---

## 1. Authority, Precedence, and Purpose

### 1.1 Document Authority and Status
This document defines the controlled, reproducible concept-art experiment plan for **Milestone 4 — Task 4.2**. It establishes the visual evaluation methodology to compare candidate art directions fairly and objectively before any asset generation occurs, and serves as the ledger for the approved Master Style decision.

- **Experiment Specification & Decision Ledger:** This document specifies the experiment plan, evaluation framework, and records the approved Master Style decision.
- **Strict Precedence:** This document is subordinate to higher-level project documentation in accordance with `PROJECT_RULES.md` §2:
  1. Explicit project owner instructions in current tasks.
  2. `PROJECT_RULES.md` (non-negotiable governance and quality gates).
  3. `ARCHITECTURE.md` (technical foundations, 2D renderer, Android-first portrait target).
  4. `GAME_DESIGN.md` (pillars, setting, plant/visitor/decoration systems, accessibility).
  5. `DEFINITION_OF_DONE.md` (verification and defect gates).
  6. `VISUAL_STYLE_BIBLE.md` (visual authority and decision status framework).
- **Explicit Project Owner Approval Governance:** Visual evidence gathered from Round A was presented to the project owner. In Task 4.2C, the project owner explicitly approved the synthesized Master Style direction (Candidate C foundation + Candidate A atmosphere + Candidate B readability), promoting these aesthetic decisions to LOCKED VISUAL DIRECTION.
- **Dependency Gate for Task 4.3:** Task 4.3 (Asset Technical Pipeline) **must not begin** until the Master Style decision has been recorded and validated through Round B.

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
| **Everyday Thai-Inspired Garden Identity** | **LOCKED VISUAL DIRECTION** | Owner Approval (Task 4.2C) / `GAME_DESIGN.md` §6 | Ordinary domestic residential setting; no tourism tropes, temples, or resort styling. |
| **Hand-Painted / Storybook Visual Treatment** | **LOCKED VISUAL DIRECTION** | Owner Approval (Task 4.2C) / `GAME_DESIGN.md` §27 | Balanced Storybook Hybrid (Candidate C foundation); cozy warmth with artisan touch. |
| **Watercolor vs. Gouache Balance** | **LOCKED VISUAL DIRECTION** | Owner Approval (Task 4.2C) / `VISUAL_STYLE_BIBLE.md` §5 | Gouache clarity for gameplay entities + watercolor softness for atmosphere. |
| **Edge Softness & Line Policy** | **LOCKED QUALITATIVE HIERARCHY** | Owner Approval (Task 4.2C) / `VISUAL_STYLE_BIBLE.md` §9 | Firmer painted edges on interactables; softer background edges; no heavy outlines. |
| **Reference Color Palette Character** | **LOCKED BROAD CHARACTER** | Owner Approval (Task 4.2C) / `VISUAL_STYLE_BIBLE.md` §11 | Warm, natural, restrained, earthy palette; exact HEX values remain TBD. |
| **Material Rendering & Texture Grain** | **LOCKED QUALITATIVE HIERARCHY** | Owner Approval (Task 4.2C) / `VISUAL_STYLE_BIBLE.md` §10 | Restrained handmade paper/brush texture; zero small-screen high-frequency noise. |
| **Visitor Stylization & Anatomy** | **LOCKED QUALITATIVE HIERARCHY** | Owner Approval (Task 4.2C) / `VISUAL_STYLE_BIBLE.md` §15 | Natural domestic proportions; dignified living guests without caricature or chibi mascots. |

> **Governance Principle:** The project owner has explicitly approved the Master Style synthesis. Approved aesthetic directions are now locked; unrelated technical asset specifications remain TBD.

---

## 3. Experiment Structure: Two-Round Visual Evaluation

The visual evaluation is structured into two sequential rounds to ensure fair comparison and focused validation.

```text
+-------------------------------------------------------------------------------+
|                       TWO-ROUND VISUAL EVALUATION PROCESS                     |
+-------------------------------------------------------------------------------+
| ROUND A: STYLE SELECTION (Controlled Comparison) [COMPLETED]                  |
| - Compare 3 candidate painterly executions (Candidate A, B, C)               |
| - Exact same reference scene, objects, composition, lighting, and format       |
| - Test variable: PAINTERLY TREATMENT ONLY                                     |
| - Output: Visual evidence for Project Owner Review & Master Style Decision     |
+---------------------------------------+---------------------------------------+
                                        |
                                        v
+-------------------------------------------------------------------------------+
| [GATEWAY: EXPLICIT PROJECT OWNER REVIEW & MASTER STYLE APPROVAL] [APPROVED]   |
| - Owner explicitly approved Synthesized Master Style Direction (Task 4.2C)    |
| - Candidate C foundation + Candidate A atmosphere + Candidate B readability   |
| - Master Style Decision Record formally approved and locked                   |
+---------------------------------------+---------------------------------------+
                                        |
                                        v
+-------------------------------------------------------------------------------+
| ROUND B: STYLE VALIDATION (Condition & Content Robustness) [AUTHORIZED]       |
| - Status: AUTHORIZED FOR VALIDATION (To be executed in Task 4.2D)             |
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

## 13. Master Style Decision Record (Owner Approved)

This section serves as the formal project ledger for the visual direction decision. In **Milestone 4 — Task 4.2C**, the Project Owner completed visual review of Round-A Candidates (A, B, C) and formally approved the synthesized Master Style direction.

```text
================================================================================
MASTER STYLE DECISION RECORD — OWNER APPROVED
================================================================================
Decision Type:
SYNTHESIZED MASTER STYLE

Selected Candidate:
Candidate C — Balanced Storybook Hybrid

Role:
Candidate C is the primary Master Style foundation.

Approved Borrowed Traits — Candidate A:
- airy, calm environmental atmosphere
- watercolor-like transitions in background foliage, ground and atmosphere
- soft handmade warmth
- restrained paper/pigment character
- light visual weight in supporting environmental areas

Approved Borrowed Traits — Candidate B:
- stronger silhouette clarity for gameplay-relevant entities
- clear local value separation
- firmer painted outer edges on important entities
- simplified interior detail where needed for mobile readability
- production-friendly shape grouping

Owner Approval Status:
APPROVED

Decision Date:
2026-10-03
================================================================================
```

### 13.1 Master Style Synthesis Contract

The approved *Garden* visual direction uses **Candidate C (Balanced Storybook Hybrid)** as its core foundation.

Foreground and gameplay-relevant entities must use:
- Soft gouache-like body colors.
- Clearly readable silhouettes at mobile phone display scale.
- Sufficient local value separation from background and ground planes.
- Selective painted edge clarity on focal elements.

Backgrounds, atmosphere, ground transitions, distant foliage, and secondary environmental detail must use:
- Softer watercolor-like transitions.
- Lower edge sharpness and gentle gradients.
- Restrained handmade paper and pigment texture.
- Lighter visual weight to keep midground interactables prominent.

> **Visual Synthesis Hierarchy:**
> This is **NOT** a literal 50/50 watercolor/gouache mixture. The hierarchy is:
> - **Watercolor Softness** $\rightarrow$ atmosphere, environmental depth, and breathing space.
> - **Gouache Clarity** $\rightarrow$ important gameplay silhouettes, touch targets, and local read.
>
> Both treatments must harmonize seamlessly into **ONE** coherent illustrated storybook world.

### 13.2 Locked Approved Visual Principles

Following explicit Project Owner approval in Task 4.2C, the following aesthetic principles are promoted to **LOCKED VISUAL DIRECTION**:

1. **Master Style Foundation:** Balanced Storybook Hybrid (Candidate C foundation).
2. **Visual Hierarchy:** Softer atmospheric/environmental treatment paired with clearer gameplay-relevant foreground entity treatment.
3. **Important Entity Silhouette Principle:** Plants, visitors, and important decorations require clear, readable silhouettes identifiable at reduced mobile-view scale.
4. **Edge Hierarchy:** Important gameplay entities receive firmer painted outer edges, while atmospheric/background objects use softer edges. Sharpness follows depth and interactive importance rather than being uniform.
5. **Texture Hierarchy:** Restrained handmade paper/brush texture is locked; texture must never degenerate into small-screen pixel noise or destroy mobile readability.
6. **Overall Visual Character:** Warm, quiet, organic, handmade, lived-in, storybook-like, and calm.
7. **No Universal Heavy Black Outlines:** Assets must breathe; heavy comic book strokes are strictly barred.
8. **Rejection of Concept-Art White Border Artifact:** The in-game presentation must **NOT** use the decorative white paper border seen around Candidate C's generated concept image. That border is a stochastic concept-art presentation artifact, not part of the approved gameplay presentation.

### 13.3 Cultural Direction After Owner Review

The approved Master Style locks the everyday Thai-inspired domestic garden identity as its cultural grounding for Milestone 4 onward:
- **Status: LOCKED VISUAL DIRECTION**
- **Approved Grounding:**
  - Ordinary Thai-inspired residential home garden (*สวนกระถางข้างบ้าน / หน้าบ้าน*).
  - Humid tropical domestic setting with dappled leaf shade and natural weather rhythms.
  - Culturally grounded through genuine everyday materials (earthenware clay jar / *โอ่งดินเผา*, weathered teak bench / *ม้านั่งไม้*, terracotta planters), domestic herbs (*กะเพรา*), garden flowers (*ดาวเรือง*), and practical household objects.
  - Modest, lived-in home environment reflecting personal care over time.
- **Strict Avoidance Continued:**
  - No tourism shorthand or postcard clichés (no tuk-tuks, boxing gloves, souvenir trinkets).
  - No temple, monastic, or royal visual shorthand (no chedis, shrines, spirit houses, palace filigree).
  - No exoticized or neon "jungle fantasy" presentation.
  - No themed luxury resort interpretation (no infinity pools, hotel cabanas).

> **Important Boundary:** This locks the approved visual-cultural execution, **not** every specific object appearing in generated concept art. It does **not** create new gameplay commitments.

### 13.4 Color Direction

- **Broad Palette Character:** **LOCKED VISUAL DIRECTION**
  - Warm, natural, restrained, and slightly earthy.
  - Varied tropical greens, rich terracotta, weathered wood, warm moist earth, soft moss, muted concrete, and controlled warm flower/visitor accents.
  - Prohibits neon, fluorescent, or casino-like saturation ramps.
- **Exact Numerical Values:** **TBD / PROVISIONAL PRODUCTION VALUES**
  - Exact digital HEX codes remain provisional reference anchors. Final production palette calibration belongs to Task 4.3 (Asset Technical Pipeline). Do not lock final numerical colors today.

### 13.5 Edge Treatment Hierarchy

- **Status: LOCKED QUALITATIVE HIERARCHY (Exact pixel thickness TBD)**
  - No universal heavy outlines.
  - Important gameplay entities receive moderately clear painted outer edges.
  - Internal details remain softer than the outer silhouette.
  - Background and atmospheric forms use softer, bleeding edges.
  - Sharpness strictly follows visual hierarchy rather than uniform line weights.
  - Exact pixel outline thickness per sprite remains **TBD** for Task 4.3.

### 13.6 Texture Treatment Strategy

- **Status: LOCKED QUALITATIVE HIERARCHY (Exact texture assets TBD)**
  - Restrained handmade paper and brush character.
  - Environmental watercolor wash variation may be visible in broad fields.
  - Important objects retain clean, readable shapes.
  - Zero high-frequency texture noise or grain that harms phone readability.
  - Exact paper texture asset, grain percentage, brush engine, and texture resolution remain **TBD** for Task 4.3.

### 13.7 Silhouette Treatment and Readability

- **Status: LOCKED VISUAL DIRECTION (Exact asset-size rules TBD)**
  - Gameplay-relevant plants, visitors, and decorations must be instantly recognizable at reduced mobile-view size (simulating a 6-inch phone display).
  - Silhouette and local value separation outranks tiny decorative interior detail.
  - Plant species must remain distinguishable by overall mass and form (e.g., holy basil bushy dome vs. marigold pom-pom crowns).
  - Visitors retain natural, believable domestic proportions rather than oversized mascot/chibi forms.
  - Exact asset sizing, grid footprints, and PPU belong to Task 4.3.

### 13.8 Explicit Rejected Traits

The visual review of Round-A Candidates explicitly rejected the following traits:

- **From Candidate A (Watercolor-Forward) — REJECT:**
  - Excessive watercolor softness that merges interactables into the background environment.
  - Excessive pigment granulation and paper noise that reads as grit at mobile scale.
  - Weak foreground/background value separation.
- **From Candidate B (Gouache-Forward) — REJECT:**
  - Excessively hard or poster-like graphic rendering.
  - Generic flat mobile-game appearance lacking illustrated soul.
  - Loss of atmospheric softness and airy environmental depth.
  - Loss of handmade watercolor warmth.
- **From Candidate C (Hybrid) — REJECT:**
  - Overly neutral compromise without recognizable handmade character.
  - Decorative white paper framing border as part of in-game presentation.
- **General Rejected Visual Outcomes (Binding Across Project):**
  - Glossy 3D CGI rendering and specular plastic highlights.
  - Photorealism and raw photographic textures.
  - Pixel-art direction, grid dithering, and retro sprites.
  - Universal heavy comic book outlines.
  - Hyper-saturated mobile farming-game color ramps.
  - Chibi mascot-world treatment and oversized cartoon eyes.
  - Excessive magical sparkle effects, loot rays, or fireworks.
  - Visually cluttered environments violating the "one-or-two details" rule.

### 13.9 Visual Production Priority

All visual asset creation and evaluation must strictly adhere to this approved priority order:
1. **Mobile Readability** (Silhouette clarity, touch targets, value separation on phone screens).
2. **Calm and Inviting Atmosphere** (Soft light, low-pressure ambiance, peaceful setting).
3. **Coherent Handmade Illustrated Character** (Storybook warmth, visible artisan craft, unified world).
4. **Everyday Lived-In Garden Authenticity** (Modest Thai domestic reality, natural weathering, practical care).
5. **Repeatability Across a Practical 2D Production Pipeline** (Feasible, scalable 2D sprite creation in Godot).

*Note:* This governs visual-production hierarchy; it does not alter gameplay rules or design pillars.

### 13.10 Items Remaining Explicitly TBD

Project Owner approval of the Master Style does **NOT** resolve technical pipeline specifications. The following items remain explicitly **TBD** for downstream tasks (primarily Task 4.3):
- Final font family and typography licensing.
- Sprite pixel dimensions and source resolutions.
- Pixels-per-unit (PPU) in Godot 2D.
- Exact animation FPS and frame counts.
- Sprite-sheet layout specifications and margins.
- Texture compression formats (Lossless, VRAM, WebP) and Godot import settings.
- Atlas dimensions, packing strategies, and boundary paddings.
- Final production HEX palette values.
- Exact brush assets and digital paint engine presets.
- Exact paper texture asset file.
- Shader architecture and canvas modulator setups.
- Final technical asset-export specifications and export presets.

---

## 14. Approved Master Style Anchor

**Status: LOCKED MASTER STYLE ANCHOR (Owner Approved in Task 4.2C)**

The following standardized descriptive block represents the **Approved Master Style Anchor**. It directly captures the synthesized visual language established in Task 4.2C without referencing candidate letters, making it directly reusable for replacing `[APPROVED MASTER STYLE ANCHOR]` across all Round-B validation prompts:

```text
APPROVED MASTER STYLE ANCHOR:

A beautiful 2D soft hand-painted storybook illustration combining soft gouache-like body colors for important gameplay entities with delicate watercolor-like atmospheric wash transitions in the background and ground planes. Clear, instantly readable silhouettes for plants, visitors, and garden objects with moderate local value separation from the surrounding environment. Organic, softened painted contours with selective edge clarity on focal elements; strictly no universal heavy black comic outlines. Restrained, tactile handmade paper and brush texture conveying organic warmth without high-frequency noise or small-screen grain. Warm, natural, slightly earthy color palette featuring tropical greens, rich terracotta, weathered teak wood, moist garden soil, soft moss, and muted concrete. Culturally grounded in an authentic everyday Thai domestic residential yard, evoking a calm, peaceful, low-pressure, lived-in domestic sanctuary. No glossy 3D CGI rendering, no photorealism, no pixel art, no chibi mascot proportions, framed specifically for Android portrait mobile readability (9:16 aspect ratio).
```

---

## 15. Round-B Validation Mockups Plan

> **Status: AUTHORIZED FOR VALIDATION (Task 4.2D)**
>
> Following Project Owner approval of the synthesized Master Style in Task 4.2C, Round B is now **AUTHORIZED FOR VALIDATION**.
>
> **Task Scope Guardrail:** Task 4.2C is documentation-only and does **not** generate Round-B images. Image generation will occur in the dedicated next task:
> **Task 4.2D — Round-B Master Style Validation**
>
> Round B will validate the approved Master Style across four critical condition and content scenarios:
> 1. **Rainy Garden** (`mockup_validation_rain.png`)
> 2. **Night Garden** (`mockup_validation_night.png`)
> 3. **Plant Growth Close-Read** (`mockup_validation_plant_stages.png`)
> 4. **Visitor Moment** (`mockup_validation_visitors.png`)

### 15.1 Scene A: Rainy Garden
- **Objective:** Validate wet surface responses, rain readability, and mood maintenance.
- **Key Visual Checks:**
  - Diffuse silver-teal atmospheric wash; distant foliage gently fades into mist.
  - Soft, non-intrusive vertical rain streaks and delicate circular puddle ripples.
  - Materials reflect dampness: subtle wet specular sheen on the terracotta rim and leaves; heavier, slightly drooping foliage stems.
  - **Emotional Tone:** Cozy, refreshing, and calming—never dark, stormy, cold, or punitive (`GAME_DESIGN.md` §14).

### 15.2 Scene B: Night Garden
- **Objective:** Validate nocturnal readability, localized warm lighting, and magical atmosphere.
- **Key Visual Checks:**
  - Base ambient wash in deep, peaceful indigo (`#1A233A`); strictly no crushed pitch-black shadows.
  - Localized warm illumination radiating from a simple garden lantern or warm window glow, illuminating the bench and nearby soil.
  - Soft floating firefly motes with gentle yellow-green luminescence.
  - Key plant and object silhouettes remain clearly readable against the nocturnal ambient backdrop.

### 15.3 Scene C: Plant Growth Close-Read
- **Objective:** Validate 4-stage growth silhouette differentiation at mobile phone scale.
- **Key Visual Checks:**
  - Side-by-side progression for **Holy Basil** and **Marigold**:
    1. *Planted:* Small mound of dark moist earth with tiny furrow or marker.
    2. *Sprout:* Tender, upright two-leaf shoot emerging from soil (~5% stage height).
    3. *Growing:* Multi-branched leafy shrub (~10–12% stage height) with immature buds.
    4. *Mature:* Full bushy silhouette (~15–18% stage height) with harvestable flower spikes (basil) or lush golden blossoms (marigold).
  - Growth stages must be distinguishable by silhouette and mass alone, with zero dependence on text labels.

### 15.4 Scene D: Visitor Moment
- **Objective:** Validate animal scale, natural anatomy, and environment interaction without mascot distortion.
- **Key Visual Checks:**
  - Cat resting in a dignified, peaceful pose on the weathered bench.
  - Yellow butterfly delicately perched upon a mature marigold blossom.
  - Correct relative scale: cat is believable domestic size relative to the bench and clay jar; butterfly is delicate and small.
  - Complete absence of chibi heads, oversized cartoon eyes, or comical expressions.

---

## 16. Round-B Prompt Templates (Using Master Style Anchor)

Each Round-B prompt incorporates the `APPROVED MASTER STYLE ANCHOR` established in §14. In Task 4.2D, prompts will execute with this anchor text inserted directly into the `[APPROVED MASTER STYLE ANCHOR]` slot. The prompt templates are defined below:

### 16.1 Template: Rainy Garden
```text
PROMPT TEMPLATE — VALIDATION SCENE A (RAINY GARDEN):

A beautiful 2D soft hand-painted illustration of the cozy everyday Thai domestic home garden during a gentle tropical daytime rain. Modest wooden home eave and boundary fence in upper background, clay water jar on left-midground, mature holy basil and marigold plants in central midground, weathered teak bench on right-midground.

Atmosphere: Soft diffuse silver-teal rain mist washing through the scene, gentle translucent rain streaks falling softly, delicate circular ripples forming in small puddles and the water jar rim. Plant leaves and terracotta surfaces appear freshly damp with a soft, gentle sheen. Cozy, refreshing, serene, and nurturing mood; not dark or stormy. Android portrait mobile composition (9:16 aspect ratio).

[APPROVED MASTER STYLE ANCHOR]

NEGATIVE PROMPT:
[INSERT COMMON NEGATIVE CONSTRAINTS BLOCK]
Additional negatives: No lightning, no thunderclouds, no dark ominous skies, no torrential flooding, no damaged plants, no scary storm weather.
```

### 16.2 Template: Night Garden
```text
PROMPT TEMPLATE — VALIDATION SCENE B (NIGHT GARDEN):

A beautiful 2D soft hand-painted illustration of the cozy everyday Thai domestic home garden at peaceful night. Modest wooden home eave and boundary fence in upper background, clay water jar on left-midground, mature holy basil and marigold plants in central midground, weathered teak bench on right-midground.

Atmosphere: Deep peaceful indigo nocturnal ambient light (#1A233A) with zero crushed black shadows. A small warm garden lamp softly illuminates the weathered bench and adjacent earth in a gentle pool of golden light. A few soft, glowing yellow-green fireflies drift gently across the garden foliage. Intimate, tranquil, safe sanctuary mood. Android portrait mobile composition (9:16 aspect ratio).

[APPROVED MASTER STYLE ANCHOR]

NEGATIVE PROMPT:
[INSERT COMMON NEGATIVE CONSTRAINTS BLOCK]
Additional negatives: No pitch black darkness, no spooky shadows, no horror atmosphere, no harsh blue monochrome filters, no blinding neon glow.
```

### 16.3 Template: Plant Growth Close-Read
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

### 16.4 Template: Visitor Moment
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

## 17. Image Output Naming Plan

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

> **Notice:** These filenames are planning conventions only. **No image files are created in Task 4.2A or Task 4.2C.**

---

## 18. Generated Image Repository & Asset Policy

To keep the Git repository lean and maintainable:
1. **External Generation:** Concept images are generated through approved image-generation workflows outside the tracked repository or in temporary artifact workspaces.
2. **Visual Curation Gate:** Stochastic generation runs often produce artifacts with minor prompt drift or seed defects. All failed drafts must be discarded immediately.
3. **Selective Tracking:** Only the final, intentionally selected candidate review mockups (maximum 3 files for Round A, 4 files for Round B) may ever be committed to documentation or design folders.
4. **Production Asset Separation:** Concept mockups are full-scene illustrations for visual direction review. They are **not** game-ready production sprites. The slicing, atlas packing, and technical import of 2D game assets belongs exclusively to downstream tasks (Task 4.3 and implementation milestones).
5. **No Repository Bloat:** Raw iteration batches, discarded prompt tests, and high-resolution generation dumps must **never** be committed to Git.

---

## 19. Visual Review Protocols

### 19.1 Mobile-Size Display Review
Because *Garden* is an Android-first mobile game (`ARCHITECTURE.md` §3), all candidate images must be reviewed under two conditions:
1. **Full-Resolution Inspection (Desktop Monitor):** To evaluate brushstroke fidelity, pigment bleed, paper grain, and edge quality.
2. **Mobile Screen Simulation (Reduced Scale):** The image must be scaled down to approximately 65–75 mm width (simulating a standard 6-inch phone display held at arm's length).
   - *Check 1:* Can the cat be immediately identified as a resting animal?
   - *Check 2:* Is the butterfly discoverable near the marigold without zooming?
   - *Check 3:* Can holy basil and marigold be distinguished by silhouette alone?
   - *Check 4:* Does the clay jar retain its distinct rounded earthenware volume?
   - *Check 5:* Does the garden background stay restful, or does brush texture degenerate into pixel noise?

### 19.2 Value and Accessibility Review
To serve the locked accessibility goal of adequate visual contrast (`GAME_DESIGN.md` §29):
1. **Grayscale Desaturation Check:** Reviewers must inspect a desaturated (grayscale) version of each mockup.
2. **Value Contrast Threshold:** The midground interactive entities (plants, jar, bench, cat) must remain cleanly distinct from the ground and fence plane based on luminance value alone.
3. **No Color-Only Information:** Identification must not rely solely on hue (e.g., distinguishing basil from marigold must rely on leaf clump geometry and blossom shape, not just green vs. yellow).

---

## 20. Task 4.2A Acceptance Checklist

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
