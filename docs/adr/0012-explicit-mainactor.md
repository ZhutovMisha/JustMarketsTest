# ADR-0012: Explicit `@MainActor` instead of default isolation

- **Status**: Accepted
- **Date**: 2026-08-31

## Context

[ADR-0002](0002-mainactor-default-isolation.md) chose Swift 6 with
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so every declaration was
MainActor-isolated unless marked `nonisolated`. That worked, but the ceremony it
demanded grew with the code:

- Domain value types, DTOs and pure rule namespaces each needed `nonisolated`,
  which is noise on types that have no state to protect.
- Test helpers needed `nonisolated`, `@unchecked Sendable` and, once a leak
  tracker was attempted as a Swift Testing trait, `nonisolated(nonsending)` and
  `@concurrent` to satisfy `TestScoping`.
- Reading the code, isolation was invisible: a class was MainActor because of a
  build setting, not because anything in the file said so.

The build setting also hid where isolation actually matters. `TickThrottle` owns
a repeating `Task`, `MarketsWebSocket` receives callbacks on the main queue, and
`RemoteMarketsRepository` mutates state from both — those three are the reason
the data layer is main-thread, and nothing in their source said as much.

## Decision

Build in Swift 5 language mode with no default isolation. Isolation is opt-in:
annotate `@MainActor` on the types that genuinely need the main thread — view
models, repositories, the socket wrapper, the throttle, the coordinator, the
container, and the quotes data source protocol. Leave everything else
unannotated: value types, DTOs, mappers, `MarketsFilter`, `MarketStatus`,
`MarketsProcessor`.

Runtime hops stay. `onTermination` on an `AsyncStream` continuation runs off the
main actor, so its teardown still goes through `Task { @MainActor in … }`.
Removing the annotation from a type that starts a `Task` would move that work
off the main thread — the annotations are load-bearing, not decorative.

## Consequences

The isolation of a type is now readable in its own source, and the domain layer
is free of concurrency keywords entirely.

The cost is real and worth stating: Swift 5 mode drops strict concurrency
checking. The four errors that caught the `onTermination` teardown writing to
MainActor state from a `@Sendable` closure would not be raised today. That class
of bug now has to be found by reading, not by the compiler.

`AppContainer` had to stop using `lazy var` for its dependencies — lazy property
initialisers are nonisolated, so they cannot call MainActor initialisers. It
builds everything eagerly in `init` instead, which is fine for a container
created once at launch.
