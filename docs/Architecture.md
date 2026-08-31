# Architecture

MVVM + Clean layering, with a coordinator owning navigation.

```
App          SceneDelegate → AppCoordinator → AppContainer
Presentation ViewController ⇄ ViewModel → (Processor, Filter)
Domain       models, repository protocols, rules
Data         repositories, DTOs, mappers, endpoints, live feed services
Core         network, storage, design system, shared UI, extensions
```

Dependencies point inwards. Domain knows nothing about Data or Presentation;
Data implements protocols the Domain declares.

## Layers

**App** — `SceneDelegate` builds one `AppCoordinator`, which owns the
`StatusNavigationController` and all navigation. `AppContainer` is the single
wiring file: it holds the lazily created shared collaborators (network client,
repositories, Core Data stack) and assembles screens from them. Screens expose
intent as closures (`onSymbolSelected`, `onConnectionStateChanged`) and never
push anything themselves.

**Presentation** — a `ViewModel` per screen holds state, calls repositories
directly, and notifies through typealias'd closures. There is no use-case layer
between the two: [ADR-0011](adr/0011-no-use-case-layer.md). A `ViewController` binds those
closures, forwards user intent, and owns no state beyond view plumbing. Its view
is a `BaseViewController<MainView>` generic, so `loadView` returns a typed view.

`MarketsProcessor` turns domain values into display strings. It formats and does
nothing else — no thresholds, no branching on market semantics.

**Domain** — value types (`MarketSymbol`, `MarketQuote`, `MarketCandle`),
repository protocols — the only seam the app has, and the one every test double
stands on — and pure rules: `MarketsFilter` (category, search,
favourite pinning) and `MarketStatus` (live / stale / closed / no data). All
`nonisolated`, all trivially testable, no framework imports beyond Foundation.

**Data** — `RemoteMarketsRepository` combines HTTP (symbol list) with the live
feed, caches the latest quote per symbol, and multicasts updates as
`AsyncStream<MarketsUpdate>` to any number of consumers.
`MarketsWebSocket` wraps SignalR behind `MarketsQuotesDataSource`.
`TickThrottle` coalesces ticks per symbol and flushes on an interval.
`CoreDataFavoritesRepository` persists favourites ordered by `dateAdded`.
Each feature owns its own DTOs, mapping and endpoints — the detail screen's live
under `Features/Detail/Data`, not in the markets feature.

**Core** — `AFNetworkClient` behind the `NetworkClient` protocol, `Endpoint`
descriptions per feature, `CoreDataStack`, `NetworkMonitor`, `Theme`, and the
`BaseView` / `BaseViewController` / `BaseCollectionViewCell` primitives.

## Live data flow

```
SignalR "ReceiveTick"
  → MarketsWebSocket (hops to MainActor)
  → TickThrottle.add          coalesce: last tick wins per symbol
  → flush on interval
  → RemoteMarketsRepository   map DTO → domain, cache latest, multicast
  → AsyncStream<MarketsUpdate>
  → ViewModel.apply           accumulate quotes
  → onRowsUpdated             direct cell update, no snapshot
```

Two properties this flow guarantees, both of which fixed real bugs:

- **A new subscriber gets current state, not just the next change.** The
  repository replays its cached quotes on subscribe, so pushing the detail
  screen shows a price immediately instead of waiting for the next tick.
- **The subscription follows the visible category.** Switching segments
  re-subscribes to exactly the symbols that category can show, derived from the
  same `MarketsFilter` call that produces the list.

See [ADR-0003](adr/0003-replay-latest-quote.md) and
[ADR-0004](adr/0004-subscription-scoping.md).

## Concurrency

The app target sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Classes without
an explicit annotation — view models, repositories, the socket wrapper, the
throttle — are MainActor-isolated. Domain value types and pure rule namespaces
are explicitly `nonisolated`.

The data layer is therefore already serialised, which is why it is written with
plain classes and not actors. Converting them to actors would force `await` into
synchronous callbacks and allow tick reordering. The reasoning is in
[ADR-0002](adr/0002-mainactor-default-isolation.md).

## Composition

A ViewModel takes repository protocols through a `Dependencies` struct and
composes them itself: `MarketsViewModel.loadData()` calls `fetchSymbols()` and
`favorites()`, and `resubscribeIfNeeded()` derives the subscribed symbols from
the same `MarketsFilter.symbols` call that builds the visible list.

There is no use-case layer, and adding one needs a second ViewModel wanting the
same composed operation — not one screen touching two repositories. The record
of removing it, and of what was tried before, is
[ADR-0011](adr/0011-no-use-case-layer.md).
