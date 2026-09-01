# ADR-0013: One event channel per ViewModel instead of separate callbacks

- **Status**: Accepted
- **Date**: 2026-09-01

## Context

`MarketsViewModel` published five independent optional closures: `onChange`,
`onRowsUpdated`, `onLoadingChanged`, `onConnectionChanged`, `onError`. Each had
exactly one subscriber — `MarketsViewController.bindViewModel()`.

Three call sites repeated the same three statements in the same order:

```swift
refreshVisibleSymbols()
onChange?()
resubscribeIfNeeded()
```

in `loadData()`, `selectCategory(_:)` and `toggleFavorite(for:)`. The order is
not incidental. `onChange` is what makes the controller apply a snapshot, and
`resubscribeIfNeeded` is what tells the feed which symbols to send
([ADR-0004](0004-subscription-scoping.md)). Rendering has to happen first, or
the list is asked to draw symbols whose subscription has not been established.
Nothing in the type expressed that: a fourth mutation could have called the
three in any order and still compiled.

Separate channels also made the sequence unobservable from a test. A test could
assert that a given callback fired, never that `.changed` preceded the
resubscription. `loadAndWait` had to swap out `onLoadingChanged` and put it back
afterwards to detect a finished load, precisely because there was no channel
carrying the whole story.

Combine was considered for this and rejected — see Alternatives.

## Decision

**A ViewModel publishes one `onEvent` closure carrying a nested `Event` enum.**

```swift
typealias OnEvent = (Event) -> Void

enum Event {
    case changed
    case rowsUpdated
    case loading(Bool)
    case connection(MarketConnectionState)
    case failed(Error)
}

var onEvent: OnEvent?
```

The controller binds once and switches. The switch is exhaustive, so a new case
is a compile error at every consumer rather than a callback nobody assigned.

**The ordering contract has one enforcement point.** The repeated triple is now
`publishChange()`, the single private method that recomputes the visible set,
emits `.changed`, then reconciles the subscription. `applySearch` deliberately
does not call it: a query narrows the visible list but never the subscription,
again per ADR-0004.

**Both ViewModels adopt it.** `SymbolDetailViewModel` had the same shape — four
closures, one consumer, and the same render-then-subscribe ordering in
`performLoad()`. Its `Event` keeps `.changed` and `.quoteChanged` separate even
though the controller renders identically for both, because a reload and a live
tick are different things and the chart will eventually care.

**It does not apply below the presentation layer, or to single-callback types.**
The rule is: more than one output, one consumer, and an ordering or
all-or-nothing binding relationship between them. What was checked and left
alone:

| Type | Why it stays |
| --- | --- |
| `MarketsQuotesDataSource.onTick` / `onConnectionChanged` | Two outputs, but they are routed to different places — ticks into `TickThrottle`, state straight through. Merging them would force `RemoteMarketsRepository` to unpack an enum only to split it again. The merge already exists one layer up, as `MarketsUpdate`. |
| `MarketsViewController.onSymbolSelected` / `onConnectionStateChanged` | Two outputs to `AppCoordinator`, but no ordering between navigation and a connection banner, and no harm in binding one without the other. |
| `MarketCollectionViewCell.onFavoriteTapped`, `SegmentControl.OnSelect`, `SplashViewController.OnFinished`, `SplashMainView.OnAnimationFinished`, `TickThrottle.onTicks` | One callback each. A one-case enum is strictly worse than a closure. |

## Consequences

`bindViewModel` is one assignment instead of five, and the controller can no
longer be half-bound — previously, forgetting one closure was silent.
`publishChange()` removed six lines of duplication and put the render-then-
subscribe order in one readable place, with the reason next to it.

Tests can now assert sequences. `MarketsEventSpy` records events into an
`Equatable` `Message`, and `loadMarkets_always_emitsEventsInRenderThenSubscribeOrder`
pins `[.loading(true), .changed, .loading(false)]` against the repository's
`[.fetchSymbols, .observeUpdates([...])]` — the ADR-0004 ordering is a test, not
a comment.

The cost is real. A consumer that cares about one event still receives all of
them and pays a switch to discard the rest. Adding a case forces every consumer
to handle it even when it is irrelevant to them — with five separate closures,
an uninterested screen simply left one unassigned. And because `Event` carries
an `Error`, it cannot be `Equatable`; the test spy mirrors it into a parallel
enum that drops the error payload, which is duplication that has to be kept in
step by hand.

That trade is worth taking while a ViewModel has one consumer. If a second
screen ever binds to `MarketsViewModel` and needs a genuinely different subset,
this decision is the one to revisit.

## Alternatives considered

**Keep five closures.** Zero churn, and each consumer takes only what it wants.
Rejected because the ordering coupling stays invisible and untestable, which is
the actual defect — the count of closures was only the symptom.

**Combine.** `@Published` / `PassthroughSubject` on the ViewModel, `sink` in the
controller. Rejected on four grounds. There is nothing to compose: five outputs,
one subscriber each, and the composition already happens inside the ViewModel.
The one operator that would earn its place, `debounce` on search, is already
`Task.sleep` with an injected `searchDebounce`, testable against a real time
budget without also injecting a `Scheduler`. It would put two asynchrony models
in one type — the repository hands over an `AsyncStream`, and asynchrony is
`async`/`await` by [ADR-0006](0006-viewmodels-own-asynchrony.md) — and bridging
loses the explicit `Task.isCancelled` checks that keep a superseded load from
surfacing as an alert. Finally, `Publisher` failure is terminal while `onError`
here is repeatable, so the error channel would go unused (`Failure == Never`)
anyway. Combine stays out until a second subscriber or real operator composition
appears; the project imports it nowhere today.

**`@Observable` / observation tracking.** Aimed at SwiftUI. This app is UIKit by
[ADR-0001](0001-mvvm-clean-coordinator.md), and `withObservationTracking` in a
controller is more ceremony than a closure, with no exhaustiveness check.
