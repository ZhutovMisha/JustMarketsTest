# JustMarkets

iOS app for live market quotes. Symbol list with categories, search and
favourites; detail screen with a candlestick chart. Quotes stream over a SignalR
hub and are throttled before reaching the UI.

## Demo

https://github.com/user-attachments/assets/e09169ea-b542-45bb-b3ce-3d9b8728185f

## Features

- **Live quotes** — price and day change update in place, without reloading the list
- **Categories** — All, Favorites, Forex, Crypto, Stocks, Indices, Commodities, Futures
- **Search** — debounced 300 ms, case-insensitive on the symbol name
- **Favourites** — persisted in Core Data, newest first, pinned to the top
- **Detail screen** — candlestick chart with 1m / 5m / 15m / 30m / 1H / 4H / 1D
  intervals, quote and contract specifications
- **Offline mode** — the app detects loss of connectivity and says so
- **Market status** — every symbol reports whether its price can be trusted

## Offline and connection state

`NWPathMonitor` watches the network and the SignalR delegate reports the feed.
The navigation bar is the single place both surface:

| State | Bar |
| --- | --- |
| Network or feed lost | red, "No connection" |
| Recovered after a loss | green, "Connected", clears after 2 s |
| Normal | default |

Lose the connection mid-session and the list stays on screen with its last
prices, flagged stale once they age past 60 s. The last quote per symbol is held
in memory and replayed to any screen opened between ticks, so a detail screen
never opens blank ([ADR-0003](docs/adr/0003-replay-latest-quote.md)).

Favourites are the only thing persisted (Core Data). The symbol list is fetched
at launch and not cached, so a cold start with no network shows an error rather
than a stored list.

## Market status

Whether a price can be trusted is a domain rule, not server metadata
([ADR-0005](docs/adr/0005-quote-outranks-hasdata.md)):

| Status | Meaning |
| --- | --- |
| `live` | quote newer than 60 s |
| `stale` | quote older than 60 s — shown, but flagged |
| `closed` | no data and the market runs on sessions (Forex, stocks) |
| `noData` | no data on a 24/7 market (crypto) |

A real quote always outranks the server's `hasData` flag: if a price is
arriving, the market is live regardless of what the metadata claims.

## API

Public [Biquote](https://biquote.io) API. No key, no auth.

**REST** — `https://biquote.io/api`

| Method | Path | Returns |
| --- | --- | --- |
| GET | `/symbols` | all instruments: name, description, type, digits, `isActive`, `hasData` |
| GET | `/symbols/{symbol}` | contract specification for one symbol |
| GET | `/{symbol}/ohlc?interval={1m…1D}&limit=100` | OHLC bars for the chart |

**SignalR hub** — `https://biquote.io/hubs/tick`

| Direction | Method | Purpose |
| --- | --- | --- |
| invoke | `Subscribe([symbols])` | set the symbols to stream |
| receive | `ReceiveTick` | one tick: bid, ask, mid, day change % |
| receive | `ReceiveSubscriptionState` | current subscription state |

Ticks arrive far faster than the UI needs, so `TickThrottle` coalesces them to
the latest tick per symbol on a 100 ms flush. The subscribed set is derived from
the same filter that produces the visible list, so the two can never disagree
([ADR-0004](docs/adr/0004-subscription-scoping.md)).

## Requirements

- Xcode 26+, iOS 17.0+
- No Apple Developer account: no signing team is configured, runs on the Simulator

## Running

```sh
git clone https://github.com/ZhutovMisha/JustMarketsTest.git
cd JustMarketsTest
open JustMarkets.xcodeproj
```

Pick an iPhone simulator and run. SPM resolves dependencies on first open.

```sh
# build
xcodebuild -project JustMarkets.xcodeproj -scheme JustMarkets \
  -destination 'generic/platform=iOS Simulator' build

# test — substitute a simulator you have installed
xcodebuild -project JustMarkets.xcodeproj -scheme JustMarkets \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.5' test
```

20 behaviour tests in Swift Testing, 2 memory-leak checks in XCTest (which needs
`addTeardownBlock`). CI runs the suite on every push and pull request.

## Architecture

MVVM + Clean layers with a coordinator. Each feature splits three ways:

```
Features/Markets/
├── Data/          DTOs, mappers, repositories, socket, throttle
├── Domain/        value types, repository protocols, pure rules
└── Presentation/  view model, view controller, views, formatting
```

Domain holds value types and pure rules (`MarketsFilter`, `MarketStatus`) with no
framework imports. Repository protocols are the only seam. No use-case layer —
view models take repositories and compose them.

| Document | Covers |
| --- | --- |
| [Architecture](docs/Architecture.md) | layers, wiring, data flow |
| [Code style](docs/CodeStyle.md) | member order, naming, closures |
| [Testing](docs/Testing.md) | what is tested, doubles, async helpers |
| [Design patterns](docs/DesignPatterns.md) | patterns in use |
| [ADRs](docs/adr/README.md) | why things are the way they are |

## Built with

UIKit, programmatic layout, no SwiftUI or storyboards for app screens.
[SnapKit](https://github.com/SnapKit/SnapKit) ·
[Alamofire](https://github.com/Alamofire/Alamofire) ·
[SignalR-Client-Swift](https://github.com/moozzyk/SignalR-Client-Swift) ·
[DGCharts](https://github.com/ChartsOrg/Charts) ·
[Lottie](https://github.com/airbnb/lottie-ios)
