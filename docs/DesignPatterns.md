# Design patterns

Patterns actually in the codebase, why they are here, and when not to reach for
them. SOLID is the yardstick, not a checklist to satisfy per file.

## Coordinator

`AppCoordinator` owns the navigation stack and all transitions. Screens announce
intent through closures — `MarketsViewController.onSymbolSelected` — and never
construct or push another screen. Adding a destination touches the coordinator
only.

It also owns cross-screen chrome: it merges reachability from `NetworkMonitor`
with feed state from the markets module and drives `StatusNavigationController`.
Neither screen knows the other exists.

## MVVM with closure bindings

No Combine, no Rx, no observable macros. A ViewModel exposes typealias'd
callbacks; the ViewController assigns them in `bindViewModel()`. The ViewModel
imports no UIKit and is testable without a view.

The ViewModel owns asynchrony: public methods are synchronous, tasks are stored
and cancelled, failures arrive via `onError`. See
[ADR-0006](adr/0006-viewmodels-own-asynchrony.md).

## Repository

Domain declares the protocol, Data implements it. `MarketsRepository` hides that
the symbol list is HTTP while quotes are a SignalR stream — callers see
`fetchSymbols()` and `updates(for:)`.

## Multicast AsyncStream

`RemoteMarketsRepository` keeps one `[UUID: Consumer]`, where a `Consumer` is a
continuation plus the symbols it asked for, and fans one feed out to any number
of consumers. A consumer registers on subscribe, is dropped on stream
termination, and the union of subscribed symbols is recomputed on both events.
The last consumer leaving disconnects the socket.

The per-consumer symbol set exists only to build that union — `broadcast` sends
every update to every consumer. A consumer that cares about one symbol filters
for it, as `SymbolDetailViewModel` does.

Two rules that came from bugs: a new consumer is replayed the cached latest quote
([ADR-0003](adr/0003-replay-latest-quote.md)), and the symbol set shrinks when a
consumer leaves ([ADR-0004](adr/0004-subscription-scoping.md)) — a set that only
grows makes behaviour depend on navigation history.

## Throttle / coalesce

`TickThrottle` keys pending ticks by symbol, so a burst collapses to the latest
value per symbol and flushes on an interval. This is what makes a firehose feed
affordable for a table.

## Strategy as a namespace

Pure rules are plain `enum` namespaces with static members —
`MarketsFilter`, `MarketsMapper`, `MarketStatus`'s initialiser. No instances, no
state, no isolation, trivial to test. Prefer this to a protocol plus a class when
there is only one implementation and no need to swap it.

## Presentation model

`MarketsProcessor` maps domain values to a `MarketRow` of display-ready strings,
so the cell contains no formatting and no branching on market semantics. The row
is a value type; the cell is dumb.

The boundary is strict: thresholds and market rules belong in the domain. When
staleness logic drifted into the processor it was moved out to `MarketStatus`.

## Dependency container

`AppContainer` is the only wiring in the app: shared collaborators built lazily,
screens assembled from them, one file. Constructor injection everywhere and no
default values on the parameters — production wiring names every collaborator, so
grep for a type shows every place it is built. No service locator, no resolver,
nothing global.

## Generic base view controller

`BaseViewController<MainView: UIView>` creates the view and returns it from
`loadView`, so `mainView` is strongly typed and `viewDidLoad` never casts.

## Patterns deliberately not used

- **Actors in the data layer** — default MainActor isolation already serialises
  it; actors would force `await` into synchronous callbacks and permit tick
  reordering. [ADR-0002](adr/0002-mainactor-default-isolation.md)
- **A use-case layer** — tried, measured, removed. The protocols had one
  conformance and no double, and the only stateful one was really a subscription
  manager belonging to a ViewModel.
  [ADR-0011](adr/0011-no-use-case-layer.md)
- **Combine / Rx** — `AsyncStream` covers the one streaming need.
- **An event bus** — closures with explicit ownership beat implicit broadcast.
- **A generic networking abstraction over `NetworkClient`** — the current seam is
  already enough to test against.
