# CatBudget — senior iOS AI-usage assessment

A two-hour live pairing exercise that measures how a senior iOS engineer uses
an AI coding agent, not whether they can write Swift.

The candidate gets a small SwiftUI app built on [The Cat API](https://thecatapi.com/),
a deliberately broken search, a menu of features priced in points, and a hard
token budget. Because tokens cost points, the exercise makes prompt quality,
context management, and verification discipline visible and comparable.

## Running a session

```bash
git clone <this repo> ~/catbudget-session      # same path every time
cd ~/catbudget-session
cp .env.example .env                           # paste a real Cat API key
cd starter && make build && make test          # 2 tests must pass
```

Then hand the candidate `docs/candidate-brief.md`, note the start time, and
follow `docs/interviewer-guide.md`.

At any point:

```bash
make budget                                    # the candidate's meter
python3 tools/budget.py --project-dir starter --since 2026-09-09T14:00 --json
```

## What is here

| Path | What it is |
|---|---|
| `docs/candidate-brief.md` | Handed to the candidate at the start |
| `docs/rubric.md` | Four scored dimensions with anchors |
| `docs/interviewer-guide.md` | Timeline, what to watch, debrief questions |
| `docs/scoring-sheet.md` | Copy per candidate |
| `starter/` | The app. Builds, runs, and has two seeded bugs |
| `tools/budget.py` | Reads Claude Code transcripts, reports weighted spend |
| `tools/reference/` | Solutions and proofs. **Interviewer only** |

## The seeded bugs

A stale-result race in the breed search, which is the candidate's mandatory
first task, and an unguarded shared cache that only surfaces under Swift 6 mode
or Thread Sanitizer, which is a bonus almost nobody finds.

Both are verified rather than asserted. The reference test fails against the
starter and passes against the fix, and the sanitizer names `BreedCache.store`
as a Swift access race. See `docs/interviewer-guide.md`.

## Before the first candidate

Set the token cap by piloting the exercise with one internal engineer. The
default of 1,500,000 weighted tokens is a starting guess, not a measurement.
Aim for a strong performance to land at 70–90% of the cap.

## Keys

`.env` is gitignored and holds `CAT_API_KEY`. `make generate` reads it and
writes `starter/Secrets.xcconfig`, which is also gitignored. Neither the key nor
the generated Xcode project is ever committed. With no real key the app falls
back to `starter/Fixtures/breeds.json`, so a session survives the API being
down.
