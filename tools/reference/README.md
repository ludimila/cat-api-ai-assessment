# Reference solutions — interviewer only

Do not show these to a candidate, and do not let them into
`starter/Tests/CatBudgetTests/`. They live here precisely so the test target
does not compile them: `starter/project.yml` only picks up sources under
`starter/`.

| File | What it is |
|---|---|
| `BreedsViewModel.fixed.swift` | The full Task 0 solution, with the reasoning in comments |
| `RaceProofTests.swift` | The test that separates a real fix from a hopeful one |
| `TSanProbe.swift` | Reproduces the `BreedCache` data race under Thread Sanitizer |

## Reproducing the stale-result race

```bash
cp tools/reference/RaceProofTests.swift starter/Tests/CatBudgetTests/
cd starter && make test
```

Expected against the shipped starter:

```
XCTAssertEqual failed: ("["Siberian"]") is not equal to ("["Siamese"]")
```

Now apply the fix and watch it pass:

```bash
cp tools/reference/BreedsViewModel.fixed.swift \
   starter/Sources/CatBudget/Features/Breeds/BreedsViewModel.swift
make test
```

**Restore the starter afterwards**, or the next candidate gets a fixed app:

```bash
cd .. && git checkout starter/ && rm -f starter/Tests/CatBudgetTests/RaceProofTests.swift
cd starter && make generate
```

## Reproducing the cache data race

```bash
cp tools/reference/TSanProbe.swift starter/Tests/CatBudgetTests/
cd starter && make generate
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  -project CatBudget.xcodeproj -scheme CatBudget \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -enableThreadSanitizer YES 2>&1 | grep -A3 ThreadSanitizer
```

Expected:

```
WARNING: ThreadSanitizer: Swift access race
SUMMARY: ... in CatBudget.BreedCache.store(_: Swift.Array<CatBudget.Breed>, for: Swift.String)
```

Remove the probe and regenerate when you are done.

## Grading Task 0

The fix has three parts and they are not equally weighted.

Cancelling the superseded task is necessary but not sufficient. A request that
is already past its last suspension point will still deliver its result after
`cancel()` lands, so the guard comparing the completed query against the
current one is what actually makes the fix correct. A candidate who cancels
without guarding has written something that passes a slow test and fails under
real typing. Award half.

A debounce is not a fix. It reduces how often the race is reachable and changes
nothing about the ordering. If they present it as a fix, ask what happens when
two requests are in flight anyway. Award zero for correctness, and judge the
answer to that question on its own merits.

Making search awaitable is the part that separates a senior from a competent
mid. The starter deliberately offers a test nothing to await, so an honest test
requires reshaping the code. A candidate who sleeps instead has produced a test
that passes for reasons unrelated to their fix, which is worth discussing in
the debrief rather than silently marking down.
