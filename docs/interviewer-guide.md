# Interviewer guide

Read this before the session. The candidate reads `candidate-brief.md`; they
may also read `rubric.md`. This file is yours.

## What the exercise is actually measuring

The app is not the point. Any competent senior can add a favourites toggle. The
point is the two hours of decisions around it: what to delegate, what to read,
when to stop, and whether "it works" is a claim they earned. The token budget
exists to make those decisions visible and costly, because without a price
everyone looks disciplined.

## Before the candidate arrives

- [ ] `git clone` the repo fresh to a fixed path. Use the same path for every
      candidate so transcripts are comparable.
- [ ] Put a working key in `.env`. Confirm `make build` and `make test` pass and
      `make run` launches.
- [ ] Confirm `make test` shows **2 passing tests**. If it shows 3, a reference
      file leaked out of `tools/reference/` into the test target.
- [ ] Note the start time. You will pass it to the meter as `--since`.
- [ ] Confirm the pinned model in `starter/.claude/settings.json` matches what
      every other candidate used.
- [ ] Have `tools/reference/` open for yourself, and closed to them.

## The seeded bugs

Two, deliberately. Neither is a trick; both are ordinary bugs that survive code
review in real apps.

**The stale-result race** in `BreedsViewModel.queryChanged()` is the mandatory
task. Every keystroke starts a `Task` that is never stored and never cancelled,
and the completion applies its result without checking whether the query that
produced it is still current. Last response wins, not last query. It reproduces
by hand against the network and against the fixture, and deterministically in a
test with per-response delays.

The instructive part is that cancellation alone does not fix it. A request can
be past its final suspension point when `cancel()` lands, so the guard on
"is this still the current query" is load-bearing. A candidate who cancels but
does not guard has written a fix that fails under load, and a candidate who
only adds a debounce has made the bug rarer while telling you it is gone.
`tools/reference/BreedsViewModel.fixed.swift` shows the full solution and
`tools/reference/RaceProofTests.swift` is the test that separates a real fix
from a hopeful one. Verified: the reference test fails against the starter with
`("["Siberian"]") is not equal to ("["Siamese"]")` and passes against the fix.

**The data race** in `BreedCache.shared` is the bonus. A `static let` on a
non-`Sendable` class with an unguarded dictionary, written from every decode,
which means written from several cooperative-pool threads at once. It is
invisible in Swift 5 mode, a hard error in Swift 6 mode, and Thread Sanitizer
reports it as `Swift access race in BreedCache.store`. That is verified too:
`tools/reference/TSanProbe.swift` reproduces it. Most candidates will never see
this. The ones who reach for Swift 6 mode or turn on the sanitizer will, and
that is worth a great deal.

## Timeline

| Minutes | What happens | What you are watching |
|---|---|---|
| 0–10 | Setup, key, meter demo, brief | Do they read the brief or start typing? |
| 10–20 | Their planning window | Whether a plan exists at all, and whether it survives contact |
| 20–45 | Task 0 | See below |
| 45–105 | The menu | Order, spend, and when they cut a loss |
| 105–120 | Debrief | Whether they can account for their own session |

If they are still on Task 0 at minute 60, say so once, neutrally, and let them
decide. Do not rescue them. How a senior handles being behind is data.

## Watching Task 0

The richest twenty-five minutes of the session. Specifically:

Do they reproduce the bug before prompting about it, or do they forward the
brief's description to the model and let it guess? Reproducing costs two
minutes and buys a correct diagnosis.

Do they hand the model the diagnosis or ask for it? Both can be right. Asking
is right when they genuinely do not know; asking when they do know is paying
output rates for something they already had.

Does the fix cancel, guard, or both? Ask them, if it is not obvious from the
diff, whether cancellation alone would be enough. The answer separates people
who understand structured concurrency from people who have seen it.

Does the test await something real? The starter deliberately gives a test
nothing to await, so a correct answer involves changing the shape of the code,
not just adding an assertion. If they add `Task.sleep(for: .seconds(2))` and
call it done, note it. It is the single most common wrong answer and it will
pass, which is exactly why it matters.

Did they touch `BreedCache` unprompted?

## Watching the image feature

At 25 points it is the biggest item on the menu and the one most likely to be
attempted first. It also contains the only trap the candidate is warned about
without being told the answer: `/v1/images/search` orders randomly by default,
so paging without `order=ASC` silently returns overlapping pages. The brief
tells them to satisfy themselves that page two is really page two. Watch what
they do with that sentence.

The three outcomes, in ascending order of what they tell you. Some candidates
ignore it and ship duplicates, which the acceptance criteria catches. Some read
the API docs and add `order=ASC` because the documentation said so. A few
actually check: call the same page twice, notice the ids differ, and fix it
from evidence. The last group is small and worth paying attention to, because
that is the habit that catches the bugs nobody warned them about.

The total count arrives in the `pagination-count` header, not the body, so a
correct implementation stops at the end instead of paging into an empty array.
Details are in `DEFECTS.md`.

## Debrief questions

Open the transcript and the meter together and go through it with them. This is
a conversation, not an audit.

- Why that feature order?
- Which prompt was the most expensive, and was it worth it?
- You cleared at minute 50 and not at minute 80. What was different?
- What did you write by hand instead of asking for, and why that line?
- What would you put in `CLAUDE.md` if you started this again tomorrow?
- Would cancellation alone have fixed the search?
- Is there another concurrency problem in this project?
- If you had one more hour, what would you spend it on?

## Signals

**Red.** Reading whole files, or the same file twice, to answer something a
search would settle. Retrying a failed prompt unchanged. Accepting diffs
unread. Claiming a feature works without building it. Never opening the meter.
A subagent dispatched for a rename. A race "fix" that is only a debounce. A
test that passes on timing luck. Arguing with the model instead of rewriting
the prompt.

**Green.** A plan before spending. Acceptance criteria in the first prompt.
Searching instead of reading. Asking for the failing test first. Reading every
diff. Putting durable facts in `CLAUDE.md` rather than repeating them.
Abandoning an approach out loud when it stops paying. Turning on Thread
Sanitizer. Catching the model repeating a wrong assumption and correcting the
record. Saying "I don't know, let me check" about their own code.

**Neither, though it looks like one.** High prompt counts are not by themselves
good or bad. Many small precise prompts and few large well-formed ones are both
defensible. Ask which they were doing and why before you score it.

## Fairness

Hold constant across candidates: the pinned model, the starter commit, the
clone path, the API key, the machine, and the cap. Say the same sentence about
the budget to everyone.

If the Cat API is down or the key is exhausted, leave `CAT_API_KEY` at
`your-key-here`. The app then serves `Fixtures/breeds.json` with simulated
latency, the race still reproduces, and every menu item except the live
favourites and votes calls still works. Tell the candidate this has happened
and drop favourites and votes from the menu for them. Do not let one candidate
run against fixtures and another against the network without recording it.

## Scoring after

Fill in `scoring-sheet.md` while the session is fresh, before you discuss the
candidate with anyone else. Score the four rubric dimensions from what you
watched, then paste the meter numbers in. Do it in that order; the numbers are
persuasive out of proportion to what they actually tell you.
