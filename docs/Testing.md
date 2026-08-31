# Testing

Swift Testing, not XCTest: `@Suite`, `@Test`, `#expect`. 48 tests today, all
green, and they are expected to stay that way on every run.

## What is worth testing

Priority, highest first:

1. **Domain rules** — `MarketsFilter`, `MarketStatus`. Pure functions, no setup,
   highest value per line.
2. **Subscription lifecycle** — who is subscribed after a screen appears,
   changes category, or goes away. Two real bugs lived here.
3. **Tick coalescing** — `TickThrottle` keeping only the latest tick per symbol.
4. **ViewModel state transitions** — load, search, category change, favourite
   toggle, incoming quote.
5. **Formatting** — `MarketsProcessor`, with a fixed locale.

Not worth testing: UIKit layout, constraint values, trivial cell wiring,
getters. Twenty strong tests beat sixty tests on accessors.

## Naming

`method_condition_expectedOutcome`:

```swift
func loadData_fetchesThenObservesSelectedCategoryOnly()
func updates_whenOneConsumerEnds_resubscribesWithoutItsSymbols()
func init_withQuote_ignoresStaleHasDataMetadata()
```

## Doubles

Spies live in `JustMarketsTests/Helpers`, are `@MainActor`, record an enum
`Message` per call, and expose stubbing knobs. Assert on the recorded sequence,
not on call counts:

```swift
#expect(markets.messages == [.fetchSymbols, .observeUpdates(["EURUSD"])])
```

**A double must behave like production.** `NetworkClientSpy` decodes with
`NetworkConfiguration.makeDefaultDecoder()`, not a bare `JSONDecoder`, so key
and date strategies are exercised. A double that diverges silently stops
protecting the thing it stands in for.

## Async helpers

`TestHelpers.swift` provides:

- `wait(until:)` — polls a condition with a **real time budget** (yield plus a
  1 ms sleep per attempt). It must never be bare `Task.yield()`: two throttle
  tests passed only because unrelated parallel load happened to stretch the
  yields past the interval, and failed the moment suite composition changed.
- `settle()` — a bounded number of yields, for letting already-scheduled work run
  when there is no condition to observe.
- `loadAndWait(_:)` — starts `loadData()` and waits for the view model to
  report loading finished. Use this instead of guessing at yield counts.

Since view models own their tasks, public calls return immediately. Follow every
fire-and-forget call with `wait(until:)` on an observable outcome.

## Determinism

- Inject a fixed `Locale` into `MarketsProcessor`; never assert on device locale.
- Pass `now` explicitly to `MarketStatus`; never let a test read the clock.
- Pass `.zero` for `searchDebounce`.
- Do not depend on defaults you do not control. Five tests broke when
  `selectedCategory`'s default changed; they now call `selectCategory` explicitly.

## Leaks

`viewController_whenReleased_doesNotLeak` holds weak references, releases the
controller and asserts both it and its view are gone. It caught a genuine retain
cycle: a compositional-layout section provider capturing `self`. Add a leak test
for any screen whose view owns a closure the framework retains.

Ordering matters: let the subject reach its suspension point before resuming a
stubbed continuation, or the pending task keeps the subject alive and the test
fails for the wrong reason.

```swift
sut?.loadViewIfNeeded()
await wait { markets.messages.contains(.fetchSymbols) }
markets.completeLoading(with: [makeSymbol("EURUSD")])
```

## Before declaring green

Run the whole suite at least twice and report the real numbers. This suite has a
history of load-dependent flakiness; a single green run is not evidence.
