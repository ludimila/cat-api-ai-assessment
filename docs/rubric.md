# Rubric

Four dimensions, scored 1 to 4 each, then weighted. The hard metrics from
`make budget` inform the score but never set it on their own: a candidate can
burn tokens well and save them badly.

| Dimension | Weight |
|---|---|
| Prompt quality | 35% |
| Cost judgment | 30% |
| Verification | 20% |
| Code quality | 15% |

A senior hire should reach 3 on every dimension and 4 on at least one. A 1 on
Verification is disqualifying on its own, whatever the feature score.

---

## Prompt quality — 35%

Whether they can direct a model precisely, and whether they recover well when
it goes wrong.

**1 — Wishing.** Prompts are outcomes without constraints: "fix the search",
"make it work", "add favourites". Whole files pasted into the prompt when a
path would do. When the answer is wrong the same prompt is sent again, louder.
No acceptance criteria ever stated, so nothing the model returns can be judged.

**2 — Describing.** Prompts name the file and the goal. Constraints appear
after the model has already guessed wrong. Retries add one missing fact at a
time, so the same task takes four rounds. Accepts the model's framing of the
problem without pushing back.

**3 — Directing.** Goal, constraints, and acceptance criteria in the first
prompt. Names the files in scope and the files that are not. Asks for a plan
before code on anything non-trivial. When a reply is wrong, diagnoses why the
prompt allowed it and rewrites rather than repeats.

**4 — Collaborating.** All of the above, plus supplies the diagnosis rather
than asking for it where they already know it, and asks for the diagnosis where
they do not. Puts durable facts into `CLAUDE.md` instead of repeating them each
turn. Asks for the failing test before the fix. Notices when the model is
confidently repeating a wrong assumption and corrects the record explicitly
rather than working around it.

---

## Cost judgment — 30%

Whether they treat context as a resource with a price.

**1 — Oblivious.** One unbroken thread for two hours. Reads whole files, and
often the same file repeatedly, to answer questions a `grep` would settle.
Never opens the meter. Delegates one-line edits to the model. Spends heavily on
the cheapest feature on the menu.

**2 — Aware.** Checks the meter, usually after a surprise. Clears
occasionally, at arbitrary points. Some sense that big reads cost something,
but no plan behind when to pay.

**3 — Deliberate.** Chose the feature order before spending anything, and can
say why. Clears between unrelated features and deliberately does not clear
inside one. Reads targeted ranges rather than whole files. Writes trivial code
by hand. Checks the meter before a large ask, not after.

**4 — Strategic.** Treats budget as a design constraint on the work itself:
picks an implementation that is cheap to verify, front-loads the context that
will be reused, and lets the cache do the work. Uses subagents only for
genuinely independent work and can explain why the isolation was worth the
duplicated context. Abandons a line of attack when it stops paying, and says so
out loud rather than sinking more tokens into it.

---

## Verification — 20%

Whether "done" means anything when they say it.

**1 — Trusting.** Accepts diffs unread. Claims a feature works without
building it. Reports success from the model's summary rather than from output
they saw.

**2 — Spot-checking.** Builds sometimes. Skims diffs. Notices breakage when it
is loud, misses it when it is quiet. Tests only when reminded.

**3 — Disciplined.** Reads every diff before accepting. Builds and runs before
claiming anything. Writes or requests a test for behaviour that matters. Checks
responses against the real API rather than assuming the shape.

**4 — Adversarial.** Writes the failing test first and watches it fail, so the
test is known to test something. Checks the error path, not only the happy one.
Distrusts a green suite that went green too easily and looks for why. Can state
what would falsify their claim that the feature works.

---

## Code quality — 15%

Judged lightly, because the model wrote much of it. What matters is what they
accepted.

**1 — Whatever compiled.** Networking inside the view. Force unwraps on
decoded data. No error states. Conventions in the file ignored.

**2 — Serviceable.** Roughly the right shape, inconsistently applied.
Concurrency works by accident rather than design.

**3 — Sound.** A clean seam between transport and view state. `async`/`await`
used correctly, cancellation respected. Errors surfaced to the UI. Matches the
conventions already in the starter rather than importing new ones.

**4 — Considered.** The seam is testable because it was designed to be. State
mutation is isolated deliberately, not by accident of where a `Task` happened
to run. Names and structure make the next change obvious.

---

## Hard metrics

Copy these from `make budget --json` into the scoring sheet. They are evidence
for the narrative score, not a substitute for it.

| Metric | Read it as |
|---|---|
| Weighted tokens | Total spend |
| Feature points ÷ (weighted ÷ 100k) | Efficiency, the headline number |
| Prompts | Very low with high spend means long unguided agent runs |
| Sessions / clears | Zero over two hours is a finding |
| Compactions | Compaction is the budget telling you they never cleared |
| Output:input ratio | High means asking for bulk; very low means reading, not building |
| Subagent turns | Cheap isolation or expensive duplication; ask which |

## Calibration

Run one internal engineer through the full two hours before the first
candidate. Set the cap so that a strong performance lands at 70–90% of it, and
adjust any feature whose points clearly do not match its cost. Re-check after
every three candidates.
