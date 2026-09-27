# Garden Game Design

> Status: **Draft v0.1**
>
> Purpose: This document defines the intended player experience, gameplay structure, content direction, and MVP scope for Garden. It is a product/design document, not a technical architecture specification.
>
> This document must be read together with `PROJECT_RULES.md`. If there is a conflict, follow the precedence defined in `PROJECT_RULES.md`.

---

## 1. Decision Status Legend

To prevent humans or AI agents from treating every draft idea as a permanent requirement, this document uses three status levels:

- **LOCKED** — approved direction for the current project unless the owner explicitly changes it.
- **PROVISIONAL** — current preferred direction, suitable for planning and prototyping, but still open to revision.
- **TBD** — intentionally undecided. Do not invent a permanent answer during implementation.

When a task depends materially on a **TBD** item, stop and ask for a decision rather than silently choosing one.

---

## 2. High-Level Concept

**Status: LOCKED**

Garden is a small, cozy Android game about gradually turning a quiet home garden into a living place.

The player plants useful and decorative plants, places small garden objects, observes changes over time, and discovers visitors and special moments that appear because of the environment they created.

The central fantasy is not "become the richest farmer" or "build the biggest farm."

It is:

> **Build a small garden that slowly develops a life of its own.**

The game should make the player curious to return and see what changed, who visited, and what small moment may happen next.

---

## 3. Player Promise

**Status: LOCKED**

A player should be able to open the game for one to five minutes, enjoy the garden, make one or two meaningful choices, and leave without stress.

The game promises:

- no game over for ordinary inactivity;
- no plant death merely because the player did not return on time;
- no mandatory daily streak;
- no energy system that prevents normal play;
- no pressure to optimize every action;
- no punishment for taking a break from the game;
- meaningful progression even in short sessions;
- a garden that visually and behaviorally changes over time;
- discoveries that reward curiosity rather than reflex skill.

The game may contain goals, timers, rarity, and progression, but they must support relaxation and curiosity rather than anxiety.

---

## 4. Design Pillars

**Status: LOCKED**

All features should support at least one of these pillars. Features that work against several pillars should be reconsidered.

### 4.1 Calm, low-pressure play

The player should feel safe leaving the game at any moment.

Timers indicate growth or change; they are not threats.

### 4.2 A living garden

The garden should continue to feel active when the player is not touching the screen.

Small animations, ambient sound, visitors, weather, plant motion, and occasional events should make the space feel inhabited.

### 4.3 Placement has consequences

Plants and decorations should sometimes influence what can happen in the garden.

Examples:

- flowers can attract butterflies;
- water can attract frogs or dragonflies;
- a bench can create a place for a cat to rest;
- a lamp can influence nighttime visitors;
- a large plant can create shade or perching space.

Decoration is therefore partly expressive and partly systemic.

### 4.4 Curiosity over raw reward

A strong return motivation should be:

> "I wonder what will happen in my garden today."

not only:

> "I need to collect more currency."

Some events should exist only because they are pleasant, funny, surprising, or collectible.

### 4.5 Small world, dense detail

The game should deepen a compact home garden rather than continuously expanding into a giant farm, city, or management simulator.

The player should eventually recognize individual corners of the garden.

---

## 5. Intended Audience and Session Shape

### Audience

**Status: PROVISIONAL**

The game is intended for players who enjoy:

- cozy mobile games;
- light collection;
- decoration;
- idle/offline progression;
- nature and small environmental details;
- games that can be played casually without mastery pressure.

The game should be approachable without requiring prior farming-game knowledge.

### Session length

**Status: LOCKED**

Typical sessions should work well at approximately:

- **1-2 minutes:** check the garden, collect something, notice a visitor;
- **3-5 minutes:** plant, rearrange, purchase, browse the journal;
- **longer passive sessions:** leave the garden visible and enjoy ambience.

No important activity should require the player to stay continuously active for a long period.

---

## 6. Setting and Identity

### Core setting

**Status: PROVISIONAL**

The preferred identity is a **small Thai-inspired home garden** rather than a generic industrial farm.

The garden may include familiar elements such as:

- a modest home;
- clay water jars;
- wooden fences;
- tropical plants;
- herbs used around the home;
- a small pond;
- shaded resting areas;
- warm, humid weather;
- birds, frogs, butterflies, cats, geckos, and fireflies.

The Thai influence should give the game personality without making it inaccessible to international players.

Avoid turning the setting into a caricature or a collection of stereotypes. Everyday environmental details should carry the identity.

### Narrative premise

**Status: PROVISIONAL**

The player begins with a quiet, lightly developed garden beside a small home and gradually makes it their own.

A complex story is not required for the MVP.

The environment itself should tell much of the story through growth, objects, visitors, and discoveries.

---

## 7. Core Gameplay Loop

**Status: LOCKED**

The primary loop is:

1. **Return to the garden.**
2. **Observe what changed.**
3. **Collect ready produce or other simple rewards.**
4. **Plant, place, or adjust something.**
5. **Discover or create conditions for visitors/events.**
6. **Record discoveries and progress.**
7. **Leave whenever desired; growth continues appropriately.**

A successful short session may contain only two or three of these steps.

The loop should not require constant harvesting or repetitive tapping to remain viable.

---

## 8. Secondary Motivation Loops

**Status: PROVISIONAL**

### 8.1 Collection loop

Create conditions -> encounter a new plant/visitor/event -> record it in the journal -> notice unknown entries -> experiment to discover more.

### 8.2 Decoration loop

Earn currency -> obtain an object -> place it -> improve the garden visually -> possibly change environmental conditions -> observe new behavior.

### 8.3 Progression loop

Perform ordinary garden activities -> increase garden progress -> unlock additional plants, objects, or small areas -> create new combinations.

These loops should reinforce one another without forcing the player into a single optimal strategy.

---

## 9. The Garden as a Reactive System

**Status: LOCKED**

The garden must react to what the player creates.

Content should conceptually expose environmental traits such as:

- flower;
- food/fruit;
- shade;
- water;
- light;
- shelter;
- perch;
- dense vegetation;
- daytime activity;
- nighttime activity.

Visitors and special events may require combinations of these traits plus context such as time or weather.

Example design rules:

```text
Butterfly
Requires: flower >= 1
Context: daytime
Result: may visit flowers
```

```text
Frog
Requires: water >= 1
Context: rain or recent rain
Result: may appear near water
```

```text
Cat Resting Event
Requires: bench >= 1
Context: any calm period
Result: a visiting cat may sleep on or near the bench
```

The exact technical representation belongs in `ARCHITECTURE.md`; this document defines only the intended behavior.

---

## 10. Plant System

### General behavior

**Status: LOCKED**

Plants are persistent parts of the garden rather than disposable crops whenever practical.

A typical plant progresses through a small number of readable stages:

```text
planted -> sprout -> growing -> mature/harvestable
```

After reaching maturity, a plant should usually remain in the garden and produce again rather than disappearing after one harvest.

Plants must not die simply because the player did not open the game.

### Growth timing

**Status: PROVISIONAL**

Early content should use relatively short growth times so the player can understand the system quickly.

Indicative tuning only:

| Plant type | Example initial timing |
|---|---:|
| Fast herb | ~5-10 min |
| Small crop | ~10-20 min |
| Flower | ~20-60 min |
| Medium plant | ~1-3 hr |
| Tree | several hours |

These numbers are not final economy values and should be tuned through playtesting.

### MVP plant set

**Status: PROVISIONAL**

The MVP target is **5 plant types**:

1. Holy basil (กะเพรา)
2. Chili (พริก)
3. Jasmine (มะลิ)
4. Marigold (ดาวเรือง)
5. Banana (กล้วย)

These are chosen to provide different silhouettes, growth roles, and environmental traits.

Possible later additions include Thai basil, lemongrass, hibiscus, lotus, fern, papaya, and mango.

---

## 11. Visitor System

### General behavior

**Status: LOCKED**

Visitors are living creatures that may enter the garden when appropriate conditions are present.

They are not initially owned pets.

A visitor should:

- appear naturally rather than from a menu;
- remain for a limited period or perform a short behavior;
- interact visually with an appropriate part of the garden when possible;
- be discoverable in the journal;
- have conditions that the player can gradually infer.

The game should avoid making every visitor a currency dispenser.

### MVP visitors

**Status: PROVISIONAL**

The MVP target is **5 visitor types**:

1. Butterfly
2. Small garden bird
3. Frog
4. Cat
5. Firefly

Example relationships:

| Visitor | Example enabling condition |
|---|---|
| Butterfly | flowers + daytime |
| Bird | plant/tree/perch + daytime |
| Frog | water + rain/recent rain |
| Cat | resting place or pond-related interest |
| Firefly | vegetation + nighttime |

Exact probabilities and timing are tuning data, not locked design values.

---

## 12. Event System

**Status: LOCKED**

The garden should support small environmental events beyond ordinary visitor appearances.

Events are important because they create memorable moments without requiring large new mechanics.

Examples:

- a bird bathes in water;
- a cat falls asleep;
- two butterflies circle one another;
- leaves fall in the wind;
- a frog jumps between wet areas;
- fruit drops from a plant;
- a gecko runs across the wall at night;
- fireflies gather after dark;
- a rainbow appears after rain;
- a bird begins nesting.

Some events may provide a journal discovery; others may exist only as ambience.

### Secret combination events

**Status: PROVISIONAL**

The game should eventually include rare events caused by combinations that are not directly listed as recipes.

Example concept:

```text
jasmine x3 + bench + nighttime
-> chance for a rare cat-under-jasmine resting scene
```

Secret events should encourage experimentation without requiring external guides to enjoy the base game.

---

## 13. Time of Day

**Status: PROVISIONAL**

The preferred approach is to use real local time in broad, forgiving periods rather than minute-by-minute simulation.

Indicative periods:

- Morning: 06:00-10:59
- Day: 11:00-16:59
- Evening: 17:00-19:59
- Night: 20:00-05:59

Time of day may affect:

- lighting;
- ambient audio;
- visitor availability;
- special event availability;
- plant presentation.

Important progression content should not be permanently inaccessible to players who normally play at only one time of day. Alternative discovery paths or sufficiently broad windows should be considered.

---

## 14. Weather

**Status: PROVISIONAL**

Weather should initially be an internal game system, not dependent on real-world weather services.

MVP weather target:

1. Clear
2. Cloudy
3. Rain

Possible later states include light rain, wind, heavy cloud, and post-rain conditions.

Weather should:

- change ambience;
- influence visitor/event conditions;
- make the garden visually varied;
- avoid destructive punishment.

Rain should feel like an opportunity for different life to appear, not a disaster state.

---

## 15. Decoration System

### Purpose

**Status: LOCKED**

Decorations serve two purposes:

1. allow visual self-expression;
2. sometimes contribute environmental traits that affect visitors/events.

The player should be able to make the garden feel personally arranged without needing expert layout skills.

### MVP decoration set

**Status: PROVISIONAL**

Target **8 placeable objects**:

1. Clay water jar / water vessel
2. Bench
3. Garden lamp
4. Watering can
5. Wooden fence element
6. Plant pot
7. Small table
8. Small pond

Not every decoration needs gameplay effects.

For example, a watering can may initially be mostly decorative while a pond contributes a water trait.

### Placement

**Status: PROVISIONAL**

Placement should be simple and mobile-friendly.

The precise grid/free-placement model, rotation behavior, collision rules, and editing UX remain technical/product details to confirm during prototyping.

---

## 16. Journal / Collection

**Status: LOCKED**

The journal is a major long-term motivation system.

Working name: **Garden Journal / สมุดบ้านสวน**.

The journal should eventually track categories such as:

- plants;
- animals/visitors;
- insects;
- special events;
- decorations or meaningful objects.

Undiscovered entries should usually appear as silhouettes, question marks, or otherwise incomplete entries so the player knows more exists without being told every solution.

A discovered visitor/event may record information such as:

- name;
- illustration/icon;
- date first seen;
- short flavor text;
- broad clue about preferred conditions.

The journal should encourage discovery, not become a checklist that pressures daily completion.

---

## 17. Economy

### Currency

**Status: LOCKED for MVP**

The MVP should use **one ordinary currency only**.

Working name: Coins.

Coins may be earned from:

- harvesting produce;
- simple goals;
- first-time discoveries;
- other low-pressure garden activity if later approved.

Coins may be spent on:

- plants/seeds;
- pots;
- decorations;
- small garden expansions/unlocks.

### What the MVP should not contain

**Status: LOCKED**

Do not add separate gems, tickets, energy, premium tokens, loot boxes, or similar layered currencies to the MVP.

The economy should be understandable without a tutorial spreadsheet.

### Balance philosophy

**Status: LOCKED**

Progress should feel steady rather than optimized around artificial scarcity.

The player should regularly be able to make a meaningful purchase or plan toward one without repetitive grinding.

Exact prices and reward numbers remain tuning values.

---

## 18. Garden Progression

**Status: PROVISIONAL**

Instead of emphasizing a conventional character level from 1 to 100, the preferred presentation is a **Garden Level / Garden Stage** that represents how established the space has become.

Possible presentation names:

- Starting Garden
- Growing Garden
- Shady Garden
- Living Garden
- Happy Garden Home

Internally, progress may still use points/XP if useful, but the player-facing experience should emphasize the garden developing rather than numerical grinding.

Garden progression may unlock:

- new plant types;
- new decoration types;
- new visitor possibilities;
- one or two additional small garden zones.

Large world expansion is outside the current direction.

---

## 19. Offline Progression

**Status: LOCKED**

Appropriate growth continues while the game is closed.

When the player returns:

- plants may have advanced growth stages;
- repeatable produce may be ready;
- normal time-based state may have progressed;
- the player should not be punished for absence.

Visitors that happened entirely while the player was offline should **not automatically count as discovered**, because that would make the collection game complete itself.

The return experience should avoid a stack of intrusive reward popups.

A lightweight message such as "The garden grew a little while you were away" is acceptable if useful.

Exact offline caps, catch-up rules, and clock-integrity handling belong partly to later tuning and architecture decisions.

---

## 20. Optional Daily Guidance

**Status: PROVISIONAL**

The game may offer three lightweight suggestions under a friendly presentation such as:

> **What could we do today? / วันนี้ทำอะไรดี**

Examples:

- harvest 3 times;
- plant 1 flower;
- observe 1 visitor.

These are guidance, not obligations.

There should be no harmful streak reset or meaningful penalty for ignoring them.

Daily guidance is **not required for the first playable MVP** unless explicitly included in a task.

---

## 21. First-Time User Experience

**Status: PROVISIONAL**

The tutorial should teach by allowing the player to act in the garden rather than presenting long text panels.

The first session should ideally establish this sequence:

1. See the garden.
2. Plant something.
3. Observe visible growth or a short accelerated first growth.
4. Harvest or interact.
5. Obtain enough currency for a simple choice.
6. Place or plant something that changes visitor conditions.
7. Encounter an early visitor.
8. See that discovery recorded in the journal.

By the end of the first session, the player should understand:

> "What I put in the garden affects what can happen here."

---

## 22. Suggested First Seven Days of Discovery

**Status: PROVISIONAL — pacing target, not a login lock**

This is a design pacing reference. Content should not be hard-locked to calendar days unless explicitly approved.

### Early phase / first session

- Receive the small garden.
- Plant a fast herb.
- Learn basic collection/harvesting.
- Gain access to an early flower.
- Encounter an easy first visitor such as a butterfly.

### Early return

- Water-related object becomes available.
- Bird activity becomes possible.
- Journal begins showing unknown entries.

### Developing garden

- Decoration placement opens more fully.
- Bench/resting object becomes available.
- Cat visit becomes possible.

### Weather discovery

- Rain demonstrates that weather changes the garden.
- Frog becomes possible around water.

### Water habitat

- Small pond becomes available.
- Water-related visitors/events become more varied.

### Night discovery

- Night ambience becomes meaningful.
- Fireflies demonstrate time-dependent life.

### First expansion

- A small adjacent garden section or equivalent progression reward becomes available.
- The player now has enough systems to experiment independently.

Again, this is intended as **experience pacing**, not mandatory consecutive-day attendance.

---

## 23. MVP v0.1 Scope

**Status: LOCKED as the current scope target unless the owner revises it**

The first playable MVP should prove one question:

> **Is it enjoyable to build a tiny garden and return to see how it reacts?**

### Required MVP systems

- one playable garden scene;
- basic plant placement/planting;
- plant growth over time;
- repeatable or persistent mature plants;
- simple harvesting/reward flow;
- one-currency economy;
- purchase/unlock flow sufficient for MVP content;
- decoration placement sufficient to arrange the garden;
- visitor eligibility/spawning;
- small event capability;
- day/night presentation;
- three weather states;
- journal/collection for MVP discoveries;
- local save/load;
- offline growth/progression;
- Android touch interaction;
- usable Android build.

### Required MVP content targets

- **5 plants**;
- **5 visitors**;
- **8 decorations**;
- **3 weather states**;
- a small number of ambient/special events;
- enough journal entries to demonstrate discovery and unknown entries.

### Explicitly outside MVP unless separately approved

- online accounts;
- cloud saves;
- multiplayer;
- social systems;
- friend gardens;
- leaderboards;
- backend services;
- real-world weather APIs;
- advertising SDKs;
- in-app purchases;
- premium currencies;
- loot boxes;
- large story campaign;
- NPC town system;
- cooking system;
- crafting tree;
- livestock farming;
- large farm expansion;
- seasonal live-service events;
- user-generated content;
- complex character customization.

The MVP should stay deliberately small enough to finish and evaluate.

---

## 24. MVP Interaction Matrix

**Status: PROVISIONAL**

The first content set should create several visible cause-and-effect relationships with very few assets.

| Garden element | Context | Possible result |
|---|---|---|
| Jasmine / Marigold | Day | Butterfly visit |
| Banana / suitable vegetation | Day | Bird visit |
| Pond / water | Rain | Frog visit |
| Bench | Calm period | Cat resting visit/event |
| Vegetation + lamp or suitable garden state | Night | Firefly appearance |

The purpose of this matrix is to make the MVP feel systemic rather than like five disconnected scripted events.

---

## 25. Failure and Pressure Philosophy

**Status: LOCKED**

Ordinary play should not include harsh failure states.

The player may make choices that are inefficient, but those choices should normally be reversible or recoverable.

Avoid:

- dead plants due to absence;
- expired rewards that create anxiety;
- irreversible decoration mistakes;
- large currency loss from ordinary interactions;
- punishment for missing a day;
- aggressive countdowns;
- mechanics that demand repeated notifications to avoid loss.

Challenge may exist later, but it must be deliberately designed rather than inherited from conventional farming-game habits.

---

## 26. UI / UX Direction

### Orientation

**Status: PROVISIONAL**

Portrait orientation is the preferred starting direction because it supports short one-handed Android sessions.

Final orientation should be confirmed during prototype work before UI implementation becomes expensive.

### Main garden screen

**Status: PROVISIONAL**

The garden itself should dominate the display.

A minimal interface might expose:

- currency near the top;
- a compact bottom navigation/action area;
- contextual controls only when an object is selected.

Potential primary actions:

- Shop
- Plant
- Journal
- Decorate

Avoid permanent HUD clutter that covers the garden.

### Interaction philosophy

**Status: LOCKED**

Touch targets must be comfortable on real phones.

The game must not depend on hover, right-click, tiny precision targets, or mouse-only behavior.

Common actions should require few taps and provide visible feedback.

---

## 27. Art Direction

**Status: PROVISIONAL**

Preferred direction:

- 2D illustrated presentation;
- soft, warm, hand-made feeling;
- readable silhouettes;
- gentle motion;
- natural but slightly simplified colors;
- a compact diorama-like garden composition;
- enough visual personality to feel distinct from generic farm UI art.

A lightly hand-painted or storybook-like style is preferred over highly detailed realism.

Pixel art is **not currently the preferred direction**, but the final art direction is not locked until visual prototypes are reviewed.

The game should remain visually readable on a small phone screen.

---

## 28. Audio Direction

**Status: PROVISIONAL**

Ambient sound is important to the feeling of a living garden.

Potential layers include:

- birds;
- wind;
- leaves;
- rain;
- insects;
- frogs;
- subtle water sounds.

Day and night should feel audibly different.

Music, if used, should be gentle and optional. The garden should still feel pleasant with ambient sound and no continuous music.

Audio must be easy to mute or adjust later; exact settings UX is TBD.

---

## 29. Accessibility and Comfort

**Status: LOCKED as a design goal; detailed requirements TBD**

The game should avoid unnecessary barriers.

Design toward:

- readable text sizes;
- adequate contrast;
- icons supported by text where meaning may be unclear;
- touch targets suitable for fingers;
- important state not communicated by color alone;
- reduced reliance on fast reaction timing;
- ability to mute music and sound separately if practical;
- non-essential animation that does not prevent interaction.

Detailed accessibility targets should be expanded before release-quality UI work.

---

## 30. Monetization

**Status: TBD**

No monetization model is approved yet.

For the MVP:

- do not add ads;
- do not add in-app purchases;
- do not add premium currency;
- do not add monetization SDKs.

If monetization is considered later, it must preserve the low-pressure design pillars.

Optional rewarded advertising may be evaluated in the future, but it is **not an approved feature by virtue of being mentioned here**.

---

## 31. Notifications

**Status: TBD**

Push/local notifications are not required for the MVP.

If considered later, they must not use guilt, false urgency, or threats of loss.

Examples of language to avoid:

- "Your plants are dying!"
- "Come back now or lose your reward!"

The game should remain enjoyable without notifications enabled.

---

## 32. Localization

**Status: PROVISIONAL**

The project should be designed with Thai and English localization in mind, even if the earliest prototype uses only one language.

Avoid embedding important player-facing text directly into visual assets where possible.

Final launch languages are TBD.

---

## 33. Content Expansion Philosophy

**Status: LOCKED**

After MVP, expansion should primarily deepen the existing garden before adding entirely new game genres.

Good expansion examples:

- more plants;
- more visitor variants;
- rare environmental events;
- additional object interactions;
- a few new small garden areas;
- more journal discoveries;
- richer weather ambience;
- more nighttime behavior;
- seasonal visual variation if it can exist without live-service pressure.

Expansion should be questioned if it pushes the project toward becoming:

- a full town builder;
- a large economic simulator;
- a combat game;
- a chore-heavy crafting game;
- a high-pressure live-service product.

New systems must justify how they strengthen the core fantasy of a small living garden.

---

## 34. Design Questions Still Open

**Status: TBD**

The following decisions are intentionally not finalized in this document:

1. Final game title.
2. Game engine and programming stack.
3. Exact camera perspective and placement model.
4. Final portrait vs. landscape confirmation.
5. Final visual style and production art pipeline.
6. Final economy numbers and growth timings.
7. Exact garden progression/unlock curve.
8. Whether optional daily guidance ships in v0.1 or later.
9. Exact number and type of special events in the MVP.
10. Final Thai/English launch language plan.
11. Monetization strategy, if any.
12. Notification strategy, if any.
13. Release/distribution plan.

AI agents must not silently convert these TBD items into permanent project decisions.

---

## 35. MVP Success Criteria

**Status: PROVISIONAL**

The MVP is conceptually successful if playtesting supports most of the following observations:

- players understand the basic garden loop without a long tutorial;
- returning after time away feels pleasant rather than punitive;
- players notice that garden composition affects visitors/events;
- players show curiosity about unknown journal entries;
- players enjoy watching the garden even when not constantly interacting;
- short sessions feel complete rather than abruptly interrupted;
- the small content set already produces multiple combinations and moments;
- players express interest in seeing additional plants, visitors, and events rather than asking for an entirely different game.

These are product-learning goals, not automated test criteria.

Technical completion gates belong in `DEFINITION_OF_DONE.md`.

---

## 36. Feature Evaluation Checklist

Before approving a new gameplay feature, ask:

1. Does it make the garden feel more alive?
2. Does it create meaningful player expression or discovery?
3. Can it work in short mobile sessions?
4. Does it avoid punishing inactivity?
5. Does it fit the small-garden identity?
6. Does it create interesting interactions with existing systems?
7. Is its complexity justified by what the player gains?
8. Can the game remain enjoyable if the player ignores this feature?

A feature does not need to answer "yes" to every question, but repeated "no" answers are a warning that it may not belong in this game.

---

## 37. Relationship to Other Project Documents

This file answers:

> **What game are we trying to make, and what should it feel like to play?**

It intentionally does not decide the implementation architecture.

Expected companion documents:

- `PROJECT_RULES.md` — non-negotiable working and quality rules;
- `ARCHITECTURE.md` — engine choice, code/data boundaries, time/random abstractions, save architecture, event/rule implementation, platform strategy;
- `DEFINITION_OF_DONE.md` — objective verification gates for tasks, milestones, and release candidates.

When implementation uncovers a genuine game-design question, update this document deliberately rather than encoding the answer only in code.

---

## Short Design Rule

> **A small garden should become more interesting because of what the player chose to grow and place. Returning should create curiosity, not obligation.**
