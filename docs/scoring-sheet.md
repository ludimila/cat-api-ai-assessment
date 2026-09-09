# Scoring sheet

Copy this file per candidate. Fill in the rubric from what you watched, then
paste the meter numbers. That order matters.

```
Candidate:
Date:
Interviewer:
Starter commit:
Model pinned:
Ran against:   [ ] live API   [ ] fixtures
```

## Task 0 — gate

| Check | Result |
|---|---|
| Last query reliably wins | pass / fail |
| Cancels superseded work | pass / fail |
| Guards on current query, not cancellation alone | pass / fail |
| Async test awaits a real signal, not a sleep | pass / fail |
| Test fails against the original code | verified / not shown |

**Task 0 points (0 / 10 / 20):** ______

If Task 0 failed, the menu scores zero. Record the menu attempts anyway; they
still tell you how the candidate works.

## Menu

| Feature | Max | Quality (0 / 0.5 / 1) | Points | Note |
|---|---|---|---|---|
| Breed images | 25 | | | Paged without duplicates? |
| Favourites, optimistic | 20 | | | |
| Repository tests | 20 | | | |
| Vote | 15 | | | |
| Concurrent startup | 15 | | | |
| Offline cache | 10 | | | |
| Swift 6 | 10 | | | |

**Feature score (Task 0 + menu):** ______ of 135

## Meter

From `python3 tools/budget.py --project-dir <starter> --since <start> --json`.

| Metric | Value |
|---|---|
| Weighted tokens | |
| Uncached input | |
| Cache write | |
| Cache read | |
| Output | |
| Prompts | |
| Assistant turns | |
| Sessions / clears | |
| Compactions | |
| Subagent turns | |
| Output:input ratio | |

**Efficiency = feature score ÷ (weighted ÷ 100,000):** ______

## Rubric

| Dimension | Weight | Score 1–4 | Evidence |
|---|---|---|---|
| Prompt quality | 35% | | |
| Cost judgment | 30% | | |
| Verification | 20% | | |
| Code quality | 15% | | |

**Weighted rubric score:** ______ of 4

A senior hire reaches 3 everywhere and 4 somewhere. A 1 on Verification is
disqualifying regardless of the feature score.

## Moments

Two or three specific things they did, with the minute mark. Concrete beats
adjectival: "at 0:38 rewrote the prompt after reading why the first answer was
wrong, instead of resending it" is worth more to the next reader than
"good prompting".

1.
2.
3.

## Debrief

How well did they account for their own session? Did the explanation match the
transcript?

## Recommendation

```
[ ] Strong hire   [ ] Hire   [ ] No hire   [ ] No hire, would reconsider for a different level
```

One paragraph. Lead with the decision, then the reason it is not the other one.
