# A Fable prompt for Mine For Cards

Owner, 2026-10-05: *"FUCK IT GIVE ME A FABLE PROMPT... ONLY $100"*

§1 is what $100 actually buys and what it cannot buy. §2 is the API settings.
**§3 is the prompt.** §4 is three pre-scoped jobs to drop into it.

---

# 1. What $100 of Fable buys, and the one thing it cannot

Claude Fable 5.1 (`claude-fable-5-1`) is **$10 per million input tokens, $50 per
million output**, with cached input re-reads at **$0.25**. Measured against this
repo:

| thing | size | cost |
|---|---|---|
| all of `src/` (739k words, 210 modules) | ~1.0M tokens | **$10** cold, **$0.25** cached |
| `MineServer.server.luau` alone (16,733 lines) | ~250k tokens | $2.50 cold |
| all of `docs/` (42k words) | ~56k tokens | $0.56 cold |
| a substantial reply (15k tokens out) | — | $0.75 |

So $100 is roughly **one full-repo read plus 80–100 real working turns.** That is
not a toy budget; it is a work session. Caching is what makes it go far, so keep
the big context stable and put the varying part of each request last.

**What it cannot buy: an engine.** The two P0 items are "swing into locked rock
at layer 500 and confirm the panel" and "play the branch". No model solves those
— they need Roblox Studio on a machine. **Do not spend the $100 on P0.** Spend it
on the work that is pure reasoning over code, which is most of P1.

**Spend it on one scoped job, not on "continue the project."** Fable runs long
turns at high effort; pointed at something vague it will spend real money
exploring. §4 has three jobs that are each worth the money.

---

# 2. API settings that matter

```python
client.messages.stream(                    # stream: turns here run minutes
    model="claude-fable-5-1",
    max_tokens=64000,
    output_config={"effort": "xhigh"},     # long-horizon code work
    betas=["server-side-fallback-2026-07-01"],
    fallbacks="default",                   # safety classifier may decline; route around it
    system=[{"type": "text", "text": PROMPT,
             "cache_control": {"type": "ephemeral"}}],   # cache the big prefix
    messages=[...],
)
```

Five things that are different on Fable and will 400 the request or quietly cost
you quality:

- **Do not send `thinking`.** Thinking is always on. `{type: "disabled"}` and
  `{type: "enabled", budget_tokens: N}` both return 400. Control depth with
  `output_config.effort` instead — `xhigh` for this work, `low`/`medium` for
  routine passes.
- **No assistant prefill.** Returns 400. Use `output_config.format` if you need
  structured output.
- **No forced tool use.** `tool_choice` `any` or `tool` returns 400. Use `auto`
  plus an instruction naming the tool, and `strict: true` on the tool.
- **The raw chain of thought never comes back.** Default `display` is
  `"omitted"`, which looks like a long silence. Set
  `thinking: {"display": "summarized"}`… no — set `display` inside the thinking
  object only if you send one, which you should not; instead accept the silence
  or use `display: "updates"` under beta `thinking-display-updates-2026-08-18`
  for between-tool progress notes.
- **30-day retention is required.** Fable is not available under zero data
  retention unless Anthropic has authorised it; a ZDR org gets a 400.

**Do not over-prescribe.** Prompts written for older models — numbered steps,
"first do X then do Y" — measurably *reduce* Fable's output quality. State the
goal, the constraints and the facts, then get out of the way. That is why the
prompt below reads nothing like the step-by-step one in `START-HERE.md`.

---

# 3. The prompt

Paste everything between the rules. Replace the JOB block with one from §4.

---

You are taking over a Roblox game called **Mine For Cards** — placeId
73982848847016, owned by the Mine For Cards group (35326298). The repo is
`VeyrixCasino/PullAPick`; work on branch `claude/vigilant-fermi-aucqjy` and
nowhere else. It is a Rojo 7.7 source tree: `default.project.json` maps `src/`
onto Roblox services, 210 Luau modules.

The game is a mining loop — swing at blocks, blocks drop ore, ore forges a better
pickaxe *of that ore*, better pickaxes reach deeper layers, deeper layers hold
rarer ore — with packs, pets, skins, traits, charms, a skill tree and rebirths
layered on top. It is three weeks from an intended launch.

**What you cannot do, so plan around it rather than discovering it.** You have no
Roblox engine. The place file holds Workspace, Lighting, Teams, TextChatService
and `ToolModels_50`, none of which are in git, so `rojo build` from this repo
produces a place that opens empty. 101 commits of work on this branch have
essentially never been loaded into Roblox — exactly one change has ever been
confirmed in-engine. Treat the branch as plausible and unproven, and never report
something as working because it type-checks.

**Four things about this codebase that have each cost days:**

`MineServer.server.luau` sits near Luau's ceiling of 200 top-level locals.
Declaring more breaks compilation with an error that does not say so. The
established workaround is hanging new things off an existing table — `Dig.Traits`,
`Dig.Layers`, `Dig.QUAKE`.

A `local` referenced above its own declaration does not error in Luau. It
compiles as a global read and is `nil` at runtime, silently. This has caused at
least three bugs here, including crafting a tool silently unequipping it. When
something is mysteriously nil, check declaration order first.

A stat key is live save data. Keys like `fossilFind` are stored on saved runes and
gear in player data, so renaming one is a save migration, not a refactor.

Client and server name the same round-trip differently. There is no typed remote
layer — the router is a string compare on `action` — so the server fires
`seamGate` and the client replies `buySeam`. Grepping one name finds half a chain
and looks like proof of absence. That exact mistake made a working feature the
project's top-priority bug for a week.

**The verification suite is `tools/verify/`, 23 checks.** Run
`bash tools/verify/syntax.sh` first and never skip it: 11 of the checks shell out
to the luau binary it fetches, and without it they print "skipping" and exit 0.
Then `bash tools/verify/suite.sh`, which reports DID NOT RUN separately from pass
for that reason. `trap.js` fails on a clean tree and is a known pre-existing
failure. Three checks still assert over possibly-empty match sets —
`skilltree.js:48`, `skilltree.js:100`, `forge-snap.js:63`. One check, `check.js`,
reads `upgrade-calculator.html` rather than `MineConfig`, and that HTML is a
deleted 121-ore roster, so anything it "verifies" about ore or gems is measuring
a design that no longer exists.

**Read these before forming an opinion, in whatever order serves you:**
`docs/START-HERE.md`, `AGENTS.md`, `CLAUDE.md`, `docs/TODO.md` section 0 (locked
rules — settled decisions, not suggestions), `docs/OPEN.md` (every open task,
prioritised), `docs/BALANCE-MEASURED.md` (measured boost ceilings),
`docs/BLOCKED.md` (what needs the owner). If `transcripts/OWNER-MESSAGES.md`
exists it is every message the owner has sent, verbatim — the real requirements
document, and it wins wherever `docs/` disagrees with it.

**How the owner works.** They are on Windows PowerShell: `&&` is not a statement
separator and `<angle brackets>` are a reserved operator, so a command containing
either will not run. They do not know their repo path and should not need to.
They supply their own icons. Asset uploads go to the group, never the personal
account. They would rather hear "this is blocked and here is the one sentence
that unblocks it" than a hedge. End every reply with the current todo list.

**Verify claims in the code before acting on them.** The docs here are careful but
they are not the code, and "the code already does X" has been wrong more than
once — in both directions.

### JOB

<< drop one §4 block here >>

Work it to completion. Commit in logical pieces with messages that explain why,
not what. Push to `claude/vigilant-fermi-aucqjy`. If you hit something genuinely
ambiguous, do everything that does not depend on the answer, then ask one sharp
question rather than guessing or stopping.

---

# 4. Three jobs each worth the money

### JOB A — close the layer-1 gaps (highest value, fully specified)

> The owner specified the boost system as two layers:
> `final = base × (1 + L1) × (1 + L2)`, where L1 is skills+skins+tools+traits and
> L2 is equipment+pets. Everything inside a layer adds; the layers multiply.
> `MineBoostLayers.luau` documents it and the owner's worked example.
>
> **Only two of L1's four named sources are actually wired.** There are exactly
> four `Layers.add` calls in the server: pets (`MineServer:2298`), hats and face
> (`:2302`), the equipped tool's trait (`:2364`), and skills filtered to five keys
> (`:2385`). Skins write straight onto the boost table via
> `MineTemper.applyTemper` (`:2578`, `:2593`), bypassing both layers. Tools never
> enter `T1` at all. And the five-key filter passes
> `mineSpeed, dirtBreak, walkSpeed, luck, rareOre` while the tree grants twenty —
> `swingRate` at +698%, `coinBonus` at +997% and `gemFind` at +506% all bypass the
> layer system and multiply on the base. `walkSpeed` is in the filter and no node
> grants it, so it is a dead key the owner already asked to remove.
>
> Wire skins and tools into L1, widen the filter to every stat the tree actually
> grants, drop the dead key, and keep chance stats additive —
> `MineCards.ADDITIVE_STATS` is the list and `MineBoostLayers` deliberately never
> second-guesses it. Then recompute the L1 ceiling on `dirtBreak` and say how far
> it moves from the measured ×17.55, because the owner's approved L2 budget
> (hat 80, face 100, pet 375 at SSS → ×15.65) was signed off against that number.
> Add a check under `tools/verify/` that fails if a named L1 source stops
> reaching L1.

### JOB B — the charms rewrite

> 164 charms exist, generated from the ore roster rather than authored — two per
> ore, five shapes, conditions. The owner's verdict: *"charms shoukld not juist be
> a huge family on clones. they would each be different and special in their own
> way. rather the merging it should cost gems."*
>
> Cut to roughly 24 hand-authored charms, each with its own rule rather than a
> parameterised instance of a shared shape. Merging costs gems. Legacy ids that
> saves already hold must still load — `<ore>_charm` is the variant-1 id — and the
> legacy 31 (15 zone-grant, 15 gem-pack, 1 limited) need a decision you argue for
> rather than assume. `docs/AUDIT.md` has the reasoning so far and
> `roadmap/CHARMS.md` is on disk from a merge, but `docs/TODO.md` section 0 wins
> wherever they disagree. Propose the 24 with their rules before implementing, in
> one message, and say which existing charm each replaces.

### JOB C — make coins matter

> Coins are near-useless. The economy has three currencies and only two jobs: ore
> is power, gems are gambling. Selling ore yields gems and that is the only gem
> faucet. Rebirth's base 2× coin multiplier is to be removed.
>
> Design coins a job that does not cannibalise either of the others, implement it,
> and show the arithmetic for a player at 15 minutes, 1 hour, 4 hours and 24 hours
> against `docs/ROADMAP.md`. Potions exist end to end already and are the obvious
> sink; argue for or against them rather than assuming. Flat-table prices that the
> ore value curve will outrun are the failure mode to avoid —
> `MineOrePouch.gemValue` is anchored on work (a rock's HP over the ore's yield)
> and the zone and rune gem prices are still flat tables that will fall behind it.
