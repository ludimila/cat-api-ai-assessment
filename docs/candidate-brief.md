# CatBudget — take-home in the room

You have **two hours** and a **token budget**. Read this page fully before you
start prompting. Reading it costs you nothing; guessing costs you tokens.

## What this is

`starter/` is a small SwiftUI app that lists cat breeds from
[The Cat API](https://thecatapi.com/). It builds, it runs, and its search is
broken. Your job is to fix the break and then ship as much of the feature menu
as you can afford.

You will use Claude Code. Every feature it is capable of is fair game: plan
mode, subagents, `/clear`, `/compact`, editing `CLAUDE.md`, hooks, custom
commands. Hand-writing code yourself is also fair game and often cheaper.

## The rules

1. **Two hours wall clock.** The interviewer calls time.
2. **A hard token budget.** Run `make budget` at any point to see it. When the
   budget is gone the session ends, even if time remains.
3. **Working code only.** Every feature you claim must build and run on the
   simulator in front of the interviewer. Code that does not build scores zero.
   Half-finished work scores zero. There is no partial credit for intent.
4. **Talk while you work.** Say what you are about to ask for and why. This is
   an assessment of judgment, not typing speed.

### How the budget is counted

Not all tokens cost the same, so the meter weights them the way the API prices
them:

| Category | Weight |
|---|---|
| Uncached input | x1 |
| Cache write | x1.25 |
| Cache read | x0.1 |
| Output | x5 |

The consequences are worth internalising before you start. Output is the
expensive one, so asking for a whole file when you needed four lines is the
single most costly habit. A long context is cheap to re-read and expensive to
build, so `/clear` between unrelated tasks helps and `/clear` in the middle of
one hurts. Reading a large file into context is paid for once at cache-write
rates and then forever after at cache-read rates.

## Task 0 — mandatory, gates everything else

**20 points. No feature below counts until this is done.**

The breed search returns the wrong results. Type `sib`, then quickly type over
it to make `siam`, and the list can settle on Siberian: the response for the
query you abandoned arrives last and overwrites the one you actually asked for.

Ship three things:

1. A fix that makes the **last query the user typed** the one that wins,
   reliably, not merely usually.
2. Cancellation of work that is no longer wanted.
3. **An async unit test that fails against the current code and passes against
   yours.** `Tests/CatBudgetTests/Support/StubURLProtocol.swift` is already in
   the project and lets you give each stubbed response its own delay. The test
   must await a real signal from the code. A test that passes because you slept
   long enough is not a test, and it will be read as one.

You will probably find that the code as written gives a test nothing to await.
Fixing that is part of the task.

## The menu

Pick what you like, in any order, once Task 0 is green. The starter renders no
images at all; favourites and votes work off each breed's `reference_image_id`,
which every breed already carries, so you can ship those without touching the
image feature.

| Points | Feature | Accepted when |
|---|---|---|
| 25 | **Breed images** | Each row shows its breed's image, loaded from the CDN and cached by the system. Opening a breed shows a scrollable gallery that pages correctly: no duplicates, no gaps, and it stops at the end rather than paging into nothing. |
| 20 | **Favourites, optimistic** | A heart on the row toggles instantly. `POST` / `DELETE /v1/favourites`. A failed call rolls the UI back. `GET` restores state on launch. |
| 20 | **Repository tests** | A seam between the view and the network, tested through `StubURLProtocol`: success, decode failure, HTTP error, and cancellation. |
| 15 | **Vote** | `POST /v1/votes` with a stable `sub_id`. The result is visible on the row. |
| 15 | **Concurrent startup** | Breeds and favourites load in parallel with `async let` or a task group. One loading state, one error path, no half-populated UI. |
| 10 | **Offline cache** | The last good breed list shows when the network fails. You state your invalidation rule out loud. |
| 10 | **Swift 6** | Language mode 6 with every diagnostic resolved, not silenced. There is more than one concurrency problem in this project. |

## Scoring

```
feature score = Σ (points × quality)        quality ∈ {0, 0.5, 1}
efficiency    = feature score ÷ (weighted tokens ÷ 100,000)
```

Both numbers are reported. A candidate who ships 60 points cheaply and one who
ships 90 points expensively are having different conversations with us, and
both are better than 30 points at any price. Beyond the arithmetic you are
scored on prompt quality, cost judgment, verification, and code quality; the
rubric is in `docs/rubric.md` and you are welcome to read it now.

## Setup

```bash
cd starter
make generate    # writes Secrets.xcconfig from ../.env, runs xcodegen
make build
make test
make run         # installs and launches on the simulator
make budget      # your meter
```

If no Cat API key is configured the app serves `Fixtures/breeds.json` with
simulated latency, so everything still runs. The search race reproduces in that
mode too.

## Cat API cheat sheet

Base URL `https://api.thecatapi.com/v1`. Every endpoint requires the header
`x-api-key`; without it you get `403`. The free tier allows 10,000 requests per
month, so avoid loops that poll.

| Method | Path | Notes |
|---|---|---|
| GET | `/breeds?limit=&page=` | Full breed list |
| GET | `/breeds/search?q=` | Name search |
| GET | `/images/search?breed_ids=&limit=&page=&order=` | Images for a breed. Read the `pagination-count` response header, and read the note below before you page |
| GET | `/images/{image_id}` | One image, including the breed's `reference_image_id` |
| GET | `/favourites?sub_id=` | Your favourites |
| POST | `/favourites` | Body `{"image_id": "...", "sub_id": "..."}` |
| DELETE | `/favourites/{favourite_id}` | Id comes from the POST or GET response |
| POST | `/votes` | Body `{"image_id": "...", "sub_id": "...", "value": 1}`; `-1` votes down |
| GET | `/votes?sub_id=` | Your votes |

`sub_id` is a string you choose to namespace your data. Pick one, keep it
stable, do not regenerate it per launch.

Image URLs point at a public CDN, so `AsyncImage` loads them without a key and
without a custom transport. One thing to satisfy yourself about before you
build on it: image search does not promise a stable order across calls. If you
paginate, prove to yourself that page two really is page two.

A breed decodes as:

```json
{
  "id": "siam",
  "name": "Siamese",
  "origin": "Thailand",
  "temperament": "Active, Agile, Clever",
  "description": "...",
  "life_span": "12 - 15",
  "reference_image_id": "ai6Jps4sx"
}
```

`POST /favourites` answers with `{"message": "SUCCESS", "id": 123456}`, and
that `id` is what `DELETE` needs.

## When time is called

Leave the repository where it is and do not clear or delete your Claude Code
session. The transcript is how the budget is audited, and we read it with you
in the debrief rather than behind your back.
