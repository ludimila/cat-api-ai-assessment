# CatBudget

A SwiftUI app for iOS 17 that lists cat breeds from
[The Cat API](https://thecatapi.com/). It builds, it runs, and its search is
broken.

You have **two hours** and exactly two tasks. Read this page fully before you
start prompting; reading costs you nothing and guessing costs you time.

## Setup

```bash
cd starter
make generate    # writes Secrets.xcconfig from the API key, runs xcodegen
make build
make test        # 2 tests, both passing
make run         # installs and launches on the simulator
```

The key is read from `../.env/cat` (a file holding the bare key) or from a
`../.env` file with a `CAT_API_KEY=...` line. With no key the app serves
`Fixtures/breeds.json` with simulated latency, so everything still runs.

## The rules

1. **Two hours wall clock.**
2. **Working code only.** Anything you say is done must build and run on the
   simulator in front of me. "Done" means you watched it work, not that the
   model said so.
3. **Use Claude Code however you like.** Plan mode, subagents, `/clear`,
   editing `CLAUDE.md`, hooks. Writing code by hand is also fair game and often
   faster than explaining it.
4. **Talk while you work.** Say what you are about to ask for and why. This is
   an assessment of judgment, not typing speed.

Afterwards we go through your session together: what you asked for, what you
accepted, and what you checked. Nothing is inspected behind your back, so leave
the session open when time is called.

---

## Task 1 — fix the search race

The breed search shows the wrong results. Type `sib`, then quickly type over it
to make `siam`, and the list can settle on Siberian: the response for the query
you abandoned arrives last and overwrites the one you actually asked for.

Ship three things:

1. A fix that makes the **last query typed** the one that wins, reliably rather
   than usually.
2. Cancellation of work that is no longer wanted.
3. **An async unit test that fails against the current code and passes against
   yours.** `Tests/CatBudgetTests/Support/StubURLProtocol.swift` is already in
   the project and gives each stubbed response its own delay. The test must
   await a real signal from the code. A test that passes because you slept long
   enough is not a test, and I will read it as one.

You will find that the code as written gives a test nothing to await. Fixing
that is part of the task.

---

## Task 2 — show breed images

The app renders no images. Add them.

**Accepted when** each row shows its breed's image, and opening a breed shows a
scrollable gallery that pages correctly: no duplicates, no gaps, and it stops at
the end rather than paging into nothing.

### How to call the image endpoints

Base URL `https://api.thecatapi.com/v1`, header `x-api-key` on every request.
Without the header you get `403`.

**One image, the breed's own cover.** Every breed already carries a
`reference_image_id`.

```
GET /images/ai6Jps4sx
```

```json
{
  "id": "ai6Jps4sx",
  "url": "https://cdn2.thecatapi.com/images/ai6Jps4sx.jpg",
  "width": 1110,
  "height": 811
}
```

**Many images for one breed.** `breed_ids` takes the breed's `id`, such as
`beng` or `siam`.

```
GET /images/search?breed_ids=beng&limit=10&page=0&order=ASC
```

```json
[
  { "id": "J2PmlIizw", "url": "https://cdn2.thecatapi.com/images/J2PmlIizw.jpg",
    "width": 1920, "height": 1080 }
]
```

The response is a bare array. The **total count is not in the body**; it arrives
in the `pagination-count` response header, alongside `pagination-page` and
`pagination-limit`. Bengal has 22 images.

Three things worth knowing before you build on this:

The image files sit on a public CDN. `cdn2.thecatapi.com` needs no API key and
no custom transport, so `AsyncImage` loads a `url` straight from the JSON.

**Image search does not promise a stable order.** Satisfy yourself about what
the default ordering actually does before you paginate, and prove to yourself
that page two really is page two. This is the part of the task most likely to
ship broken.

`limit` caps at 100 for a single request, and the free tier allows 10,000
requests per month, so avoid anything that polls.

### Reference: a breed

```json
{
  "id": "siam",
  "name": "Siamese",
  "origin": "Thailand",
  "temperament": "Active, Agile, Clever",
  "life_span": "12 - 15",
  "reference_image_id": "ai6Jps4sx"
}
```

---

## What is being assessed

Not whether you can write Swift. Two hours is enough for both tasks, so the
interesting part is everything around them: how precisely you direct the model,
what you read versus what you search, whether you verify a claim before
repeating it, and what you choose to do yourself.

## When time is called

Leave the repository where it is and do not clear or delete your Claude Code
session.
