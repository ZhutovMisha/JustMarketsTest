# ADR-0002: MainActor default isolation instead of actors

- **Status**: Accepted
- **Date**: 2026-08-30

## Context

Swift 6, strict concurrency. The app target sets
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so every declaration is MainActor
unless explicitly `nonisolated`.

The data layer looks like classic shared mutable state:
`RemoteMarketsRepository` holds consumer continuations and a quote cache,
`TickThrottle` holds pending ticks. The instinct is to make both actors.

Inspecting the actual call paths shows there is no unsynchronised access. The
SignalR hub is built with `callbackQueue = .main`; the tick handler asserts this
with `MainActor.assumeIsolated`; stream termination hops through
`Task { @MainActor in }`. Every mutation already happens on the main actor.

## Decision

Keep the data layer as MainActor-isolated classes. Do not convert
`RemoteMarketsRepository`, `TickThrottle` or `MarketsWebSocket` to actors.

Mark domain value types and pure rule namespaces explicitly `nonisolated`. Do
not add `@MainActor` where default isolation already supplies it.

## Consequences

Synchronous callbacks stay synchronous. `updates(for:)` can register a consumer
and return a stream in one step, with no window where the stream is handed out
before the subscription exists.

The cost: mapping and formatting run on the main thread. At present that is one
throttled flush per interval over a bounded symbol set — measured against a
firehose, not assumed cheap. If profiling shows main-thread pressure, the fix is
to mark `AFNetworkClient` `nonisolated` and move the parse off-main, not to wrap
the repository in an actor.

## Alternatives considered

**Make the repository an actor.** Rejected on two grounds. `updates(for:)` is
synchronous and mutates state, so it would become `async` or wrap its body in a
`Task` — adding the callback→Task→method hops we were trying to remove. Worse,
`throttle.add(tick)` is called from a synchronous callback; via
`Task { await … }` each tick becomes an independently scheduled task, and since
pending ticks are last-write-wins per symbol, an older tick could overwrite a
newer one. An actor would introduce a correctness bug where none existed.

**Move the whole chain off the main actor.** Coherent, and the right answer if
profiling ever demands it: drop `callbackQueue = .main`, make socket → throttle →
repository `nonisolated`, hop to MainActor once at the ViewModel boundary. Larger
change, no evidence it is needed.
