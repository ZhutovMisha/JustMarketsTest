# JustMarkets

iOS trading app showing live market quotes. Symbol list with categories, search
and favourites; detail screen with a candlestick chart. Quotes arrive over a
SignalR hub and are throttled before reaching the UI.

## Stack

- Swift 6, iOS 17+, UIKit (no SwiftUI), programmatic layout via SnapKit
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — everything is MainActor unless
  explicitly marked `nonisolated`. Read [ADR-0002](docs/adr/0002-mainactor-default-isolation.md)
  before reaching for an `actor`.
- Alamofire (HTTP), SignalR-Client-Swift (live feed), DGCharts (chart)
- Swift Testing (`@Suite` / `@Test` / `#expect`), not XCTest

## Commands

```sh
# build
xcodebuild -project JustMarkets.xcodeproj -scheme JustMarkets \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.5' build

# full suite
xcodebuild -project JustMarkets.xcodeproj -scheme JustMarkets \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.5' test

# one suite
xcodebuild ... -only-testing:JustMarketsTests/MarketsFilterTests test
```

## Documentation

| Document | Use it for |
| --- | --- |
| [Architecture](docs/Architecture.md) | Layers, module wiring, data flow |
| [Code style](docs/CodeStyle.md) | Member order, naming, closure rules |
| [Testing](docs/Testing.md) | What to test, doubles, async helpers |
| [Design patterns](docs/DesignPatterns.md) | Patterns in use and when to apply them |
| [ADRs](docs/adr/README.md) | Why things are the way they are |

## Rules

**Style** — full detail in [Code style](docs/CodeStyle.md).

- Every closure type is a `typealias`. No inline `((Foo) -> Void)?` properties.
- Member order: `typealias`, nested `struct`/`enum`, public computed, public
  stored, private nested types, private computed, private stored.
- Add a protocol only where there is a real seam: a test double or a second
  implementation. A protocol with one conformance and no double is deleted.

**ViewModels own asynchrony.** Public methods are synchronous and return `Void`;
the ViewModel starts its own `Task`, stores it, cancels it in `deinit`, and
reports failures through `onError`. ViewControllers contain no `Task` and no
`do`/`catch` — they bind callbacks and render. See
[ADR-0006](docs/adr/0006-viewmodels-own-asynchrony.md).

**Cancellation is not an error.** Before reporting a caught error, check
`Task.isCancelled` — a superseded load must not surface an alert, and must not
stop an indicator a newer load already owns.

**There is no use-case layer.** A ViewModel takes repository protocols and
composes them itself. The repository is the seam — every repository protocol has
a spy, and that is what tests stub. A use case comes back only when two
ViewModels need the same composed operation. See
[ADR-0011](docs/adr/0011-no-use-case-layer.md).

**Formatting stays in the processor, rules stay in the domain.**
`MarketsProcessor` formats numbers and nothing else. Business rules such as
staleness live in the domain (`MarketStatus`).

**One source of truth for the visible set and the subscription.** The symbols
subscribed to the feed are derived from `MarketsFilter` with the same category
and favourites as the visible list. Two independent filters is what produced a
real bug where a symbol had a price on one screen and not the other —
[ADR-0004](docs/adr/0004-subscription-scoping.md).

**Live updates never go through a diffable snapshot.** Per-tick updates write
directly into visible cells. `reconfigureItems` + `apply` re-measures cells and
recomputes content size, which fights the scroll —
[ADR-0007](docs/adr/0007-live-updates-bypass-diffable.md).

## Before saying it works

- Run the full suite. Report the actual numbers.
- Run it at least twice. This suite has a history of load-dependent flakiness:
  timing tests must wait on a real time budget, never on bare `Task.yield()`.
- The user often has files open in Xcode. Read a file immediately before
  rewriting it — an Xcode save can otherwise clobber the edit, and it has.

## Recording decisions

A material decision gets an ADR in `docs/adr/`, numbered, following
[the template](docs/adr/template.md). Material means: it constrains future code,
or a reader would otherwise ask "why on earth is it done this way". Do not write
an ADR for a routine fix. When a decision is reversed, set the old ADR's status
to `Superseded by ADR-XXXX` rather than editing its rationale — the record is
what was decided at the time.
