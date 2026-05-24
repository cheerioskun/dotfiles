---
name: explainer
description: Hemant's house style for technical HTML explainers. Opinionated, personal, no slop. Use whenever generating a long-form explanatory page.
---

# explainer

This is the house style. Don't generate before reading it.

## Telos

This is the destination. Every step below exists to hit it.

Technical explanation as premium digital journalism — not SaaS docs, not tutorials. *Serif for thinking, mono for building.* Warm paper-and-ink palettes against screen fatigue. Diagrams as cognitive load managers, not decoration — a static SVG is a map, a stepper is a guided tour. Abstractions grounded in the metal: bytecode, syscalls, structs, real numbers. Distinct visual containers for narrative, code, mental models, and danger — the reader should know at a glance which one they're in. Pull quotes isolate the one thing. Every post is a link in a chain.

Respect the craft. Respect the reader. The rest of this doc is how to operationalise those two principles without drifting into slop.

## Step 0 — Roll the dice

Before designing anything, **inject variety**. Default behaviour produces same-looking pages. Same-looking pages signal AI.

Do exactly one of the following, your pick, and announce the result:

1. Roll a d6. Map the result against a rotating table you keep in your head — palette this turn, font pairing this turn, layout rhythm this turn. *Different table each session.*
2. Ask me a **revealing question**. The kind where my answer telegraphs taste but I can't reverse-engineer the mapping. Examples I like:
   - *"Pick a city: Lisbon, Kyoto, Reykjavík, Marrakech."* (→ palette)
   - *"Pick a desk object: brass compass, mechanical pencil, ceramic mug, polaroid camera."* (→ texture/weight)
   - *"Hemingway, Borges, Calvino, or Didion?"* (→ prose density and sentence rhythm)
   - *"What time of day is this post?"* (→ light/dark default, accent temperature)
   - Invent new ones. Don't reuse last session's.
3. Flip three coins. HHH = severe. TTT = playful. Mixed = pick from context.

Whatever you roll/get, **commit to it.** Don't average. Don't hedge.

This step is not optional. If you skip it, you will default to the last successful aesthetic and the corpus rots.

## Step 1 — The thesis of this skill

Explainers I write are for one reader: someone with adjacent expertise who wants the *internals*, not the surface. They are not tutorials. They are not "intro to X." Treat the reader as a peer who's just walked in late and needs the load-bearing parts.

Density beats coverage. One real mechanism explained correctly beats five mentioned in passing. If something is interesting, it goes in. If something is obvious to a systems engineer, it gets cut.

## Step 2 — Themes (non-negotiable)

- **The mechanism is the point.** If the post can be summarised as "here's the API," the post shouldn't exist. Dig until you hit a syscall, a struct, a state machine, a bytecode, a real piece of timing. That's where the post lives.
- **Show the source.** Real CPython snippets, real strace, real `dis.dis` output, real benchmark numbers. Fabrication is a fatal sin. If you don't have the number, either run it or say you don't.
- **Earn every visual.** Diagrams pay rent in topology, simultaneity, or timing. If prose can carry the lesson, prose carries it. A static SVG that just re-narrates the paragraph next to it is decoration.
- **Bridge from what I know.** I've written Go for years. Use it. Goroutine vs coroutine, channel vs Future, runtime preemption vs cooperative — these analogies are load-bearing. Don't be cute about it; just use them where they help.
- **End every post with a bridge.** Even standalone posts. Where would a curious reader go next? Name it.

## Step 3 — Workflow (we proved this works on the Python series)

1. **Narrative spine.** What question does each section answer? Why is it in *this* order?
2. **Rough content dump.** Bullets per section. Real code, real refs. Ugly is fine.
3. **Structure pass.** Fit content to scaffold (prose / code / table / diagram slot). Pacing — where's the density peak, where's the breathing room?
4. **Visual triage.** Mark each section: text-only / static visual / interactive widget. **Justify each visual.** What does it earn over prose?
5. **Build.**
6. **Critique pass.** Read cold, as a stranger. Hunt for: hand-waving, fabricated numbers, claims I can't back, density cliffs, broken transitions, slop signals.
7. **Polish.** Typography rhythm, transitions, copy.

Track with TaskCreate. Mark done as you go. Don't batch.

## Step 4 — Dos

- Pull quotes for the post's actual *thesis*. One per post, max. A typographic breather that isolates the single most important takeaway of a section.
- **Distinct containers for cognition.** Reader tells narrative from code from mental model from danger at a glance. Three callout flavours, no more: info (mental models, analogies), warn (subtle traps, misconceptions), trap (this will bite you). Colors come from the palette dice — *semantics* are fixed.
- Tables for axis comparisons (3+ things × 3+ properties). Always beats a paragraph.
- Code blocks for code. Real syntax highlighting via spans, not a heavy lib.
- Numbered sections (§1, §2…). The reader can navigate. The TOC writes itself.
- **A real TOC block when the post has 7+ sections.** Decimal-leading-zero (`01`, `02`…) in monospace, anchor links to section IDs. It doubles as a thesis preview — the reader skims it and decides whether to commit.
- **Header strip with site identity + theme toggle.** Explicit toggle beats `prefers-color-scheme` alone — it reads as a designed object, not a passive setting. Pair with a thin reading-progress bar *only* on posts >10 min.
- `code` *inside* prose for any identifier, syscall, flag. It signals "this is a real name, not jargon."
- A "things to take with you" list before the bridge. Five bullets max. Each one a load-bearing claim.

## Step 5 — Don'ts

- **No Inter, no Roboto, no Helvetica.** Slop signal. Default to Crimson Pro + JetBrains Mono unless the dice say otherwise.
- **No purple/violet accents.** Same reason. The Tailwind defaults are dead.
- **No gradient text on headings.** Ever.
- **No glowing/pulsing/breathing animations.** Anything that animates without a click is decoration.
- **No "intro" paragraphs that summarise what the post will cover.** Open in medias res. Trust the reader.
- **No "in conclusion."** Bridge or list. Pick one.
- **No emoji.** Anywhere. Unless I explicitly ask.
- **No fabricated numbers.** Real measurement or no number.
- **No tutorial register.** "Let's…", "First we…", "As you can see…" — strip all of it.
- **No framework SPAs.** Pages are static HTML files. Vanilla JS where needed.

## Step 6 — Variety bank

Rotate. Don't reuse the last one.

**Palettes (commit to one):**
- Paper/ink — cream `#faf6f0`, terracotta `#b8472a`, deep teal `#1e5f5c` *(used: Python series)*
- Blueprint — deep slate `#1a2332`, cyan `#5fb3d9`, paper rule lines
- Dusk — `#1f1a2e` ground, peach `#f4a261`, slate-blue `#577590`
- Forest paper — `#f0ebe1`, moss `#4a6c3c`, oxblood `#7a2e2e`
- Reykjavík winter — near-white `#f5f3ee`, glacier `#5a7a8a`, dark indigo `#1e2a4a`
- Marrakech — terracotta deeper `#a93c20`, mustard `#c89b3c`, midnight `#1a1d2e`
- Kyoto twilight — washi `#ebe1d2`, persimmon `#d96e3c`, ink `#1a1612`

**Font pairings:**
- Crimson Pro + JetBrains Mono *(scholarly, used)*
- Instrument Serif + IBM Plex Mono *(refined, editorial)*
- DM Sans + Fira Code *(precise, technical)*
- Bricolage Grotesque + Fragment Mono *(bold, characterful)*
- EB Garamond + Berkeley Mono *(timeless)*
- Newsreader + JetBrains Mono *(news-paper)*

**Layout rhythms:**
- Single column, narrow (720px), generous line-height *(default)*
- Asymmetric — wide diagram lane, narrow prose lane
- Sidenotes (Tufte) — marginalia for asides and source refs
- Sectional cards — each §N is its own bordered block

## Step 7 — Interactivity rules

Interactivity is **progressive disclosure**, not decoration. A static diagram is a map; a stepper is a guided tour. The reader controls the pace of complexity, or there's no point.

Use interactivity only when the lesson is *timing*, *parameter sensitivity*, *causality*, or *prediction-then-reveal*. Specifically:

- **Yes:** race conditions (scrub time, see the outcome change), event loops (step through), parameter sliders (tune work duration, watch stall grow), state machines (click through states), **flip-cards** for "predict the behavior" grids (reader commits to a guess before the verdict — earns engagement), **tabs** when there's one logical slot with multiple genuine variants to compare (e.g. `select` vs `poll` vs `epoll`). Tabs are *not* for sequential content — that's hidden chapters.
- **No:** "run this code" buttons, syntax-highlight-toggling, anything that lets the reader edit prose, decorative motion, auto-playing animations that don't stop.

**Budget:** total JS ≤ 40KB minified. anime.js for sequenced reveals. htm+preact only if a widget has 3+ pieces of state. Otherwise vanilla JS + RAF.

**Every interactive widget must have an informative resting state.** If a reader doesn't touch it, they should still get the lesson.

## Step 8 — Examples and anti-examples from our work

- **Good:** Part 2 §4 — paraphrased `_run_once` in 25 lines + diagram showing the 6 steps + two paragraphs of consequence. *That's* density that pays.
- **Good:** Part 2 §6 — caught fabricated benchmark numbers in the critique pass, ran the real benchmark, found the *better* metric (loop stall, not p50 latency), rewrote the section. The rewrite is more interesting than the original because reality was.
- **Bad (almost shipped):** The original §6 numbers were three significant figures of fiction. Would've been the worst kind of slop — confidently wrong.
- **Good:** Part 1 §2 refcount race diagram — encodes simultaneity, which prose can't. *Earned.*
- **Bad (avoided):** A "module structure" diagram of asyncio. Reader doesn't need a map of `events.py` vs `base_events.py`. Cut.

## Step 9 — Pre-ship checklist

Run through this cold. If any answer is no, fix before shipping.

- [ ] Did I roll the dice? Did I commit to it?
- [ ] Can I name one mechanism the reader didn't know going in?
- [ ] Is every number real?
- [ ] Does every diagram earn its place by carrying topology, simultaneity, or timing?
- [ ] Is there a Go bridge where it helps?
- [ ] Is the first paragraph already *inside* the topic, not introducing it?
- [ ] Does the bridge name something specific?
- [ ] Did I read it cold and look for slop?

## Augmenting this skill — the component library

`skills/explainer/library/` holds reusable building blocks: the theme toggle, the numbered TOC, flip-card grids, step-through controls, tab switchers, the reading-progress bar. Things that aren't *about* any one post but recur across them.

**When to extract.** Don't extract before second use. One use is a custom thing; two is a pattern; three means the library entry was overdue. If you build something genuinely reusable while writing a post — extract it as you go. If you're unsure, leave it inline. Wrong abstractions are more expensive than duplication.

**What belongs.** Chrome and interaction primitives: header/nav, TOC, theme toggle, progress bar, tab switcher, flip-card grid, step controls, swimlane Gantt shells. Things whose contract is "here is a slot, fill it."

**What doesn't.** Pull quotes, content callouts, topic-specific diagrams. Those are local to a post — copying churns nothing because each one is bespoke anyway.

**Rules for a library component:**

- **Single file** at `skills/explainer/library/<name>.html`. HTML + scoped CSS + vanilla JS in one file. Pasteable. A reader should grasp it in 30 seconds.
- **Themed only via CSS custom properties.** Use the same variable names host pages use: `--bg`, `--bg-tint`, `--surface`, `--text`, `--text-dim`, `--accent`, `--teal`, `--border`. Never hardcode a color. The component inherits the host's palette dice roll — that's the point.
- **No external runtime deps** beyond fonts the host page already loads. No npm, no build step, no CDN libraries.
- **JS budget: ≤ 2 KB per component.** Vanilla. No frameworks. If it doesn't fit, it's a feature not a primitive — keep it in the post.
- **Informative resting state** (same as Step 7). A reader who never interacts with it still gets the lesson.
- **One `data-*` attribute as the public API where possible.** E.g. `<button data-theme-toggle>`. Lets the host wire it without reading internals.
- **Top-of-file comment block** stating: purpose, public CSS vars consumed, public attributes, one-line example usage. Three lines max.

**`library/README.md`** is the index. One line per component: name, purpose, where first used. If the index grows past 20 entries the library is too granular — collapse.

**Discipline:** when you copy a component into a new post, *update it back in the library* if you found a refinement. The library is the canonical version, not a snapshot. If a refinement is post-specific, leave the library alone and fork it inline.

## Footer

This skill is mine. If it ever starts producing the same-looking page twice in a row, the variety step is broken. Fix it before the next post.
