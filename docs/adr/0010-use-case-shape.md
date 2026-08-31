# ADR-0010: One protocol, one `execute`, extracted on a second caller

- **Status**: Superseded by [ADR-0011](0011-no-use-case-layer.md)
- **Date**: 2026-08-31

Supersedes [ADR-0008](0008-use-case-layer.md), which introduced use cases
selectively but left them concrete and unshaped.

## Context

ADR-0008 added two use cases and deliberately gave them no protocols, reasoning
that tests build the real use cases over repository spies so no seam was needed.
That is true but leaves two problems.

The trigger for extraction was a judgement call — "carries composition or a
rule" — which is not something a reviewer can check. And without a protocol the
ViewModel is coupled to a concrete type, so a ViewModel test cannot stub the
operation; it has to know which repositories that operation happens to use.

The shape also varied: `execute()` on one, `updates(for:category:favorites:)` on
the other.

## Decision

**Extraction trigger.** A repository operation moves into a use case as soon as
it has a **second distinct caller**. Two call sites inside one type do not count
— `candles(for:interval:)` is called twice by `SymbolDetailViewModel` and stays
on the repository, because a wrapper there would be a one-line pass-through.

**Shape.** A use case is a protocol declaring exactly one function named
`execute`, plus one implementation prefixed `Default`. Its collaborators —
repositories, other use cases — are injected through `init`. One use case is one
operation; a second operation means a second use case.

```swift
protocol LoadMarketsUseCase: Sendable {
    
    func execute() async throws -> MarketsSnapshot
}

final class DefaultLoadMarketsUseCase: LoadMarketsUseCase { ... }
```

Applied now, this yields three:

| Use case | Why it exists |
| --- | --- |
| `LoadMarketsUseCase` | composes two repositories concurrently |
| `ObserveMarketQuotesUseCase` | owns the category-to-symbols rule and the "do not resubscribe to an unchanged set" invariant |
| `ObserveSymbolQuotesUseCase` | second caller of `updates(for:)`; narrows the shared feed to one instrument |

`toggle`, `details` and `candles` each have a single caller and stay on their
repositories.

## Consequences

The trigger is now mechanical: count the callers. No debate per case, and the
answer does not depend on who is reading.

The third use case earned more than the rule required. `SymbolDetailViewModel`
had been unwrapping `MarketsUpdate` and filtering by its own symbol; that moved
into `ObserveSymbolQuotesUseCase`, which returns `AsyncStream<MarketQuote>`. The
ViewModel's `apply` went from two guards to two lines, and a second consumer
interested in one instrument no longer re-implements the filtering.

Costs. Every use case is now two declarations instead of one, and the `Default`
prefix is a naming tax with no meaning of its own — it exists because the good
name went to the protocol. Protocols also make it possible to stub a use case in
a ViewModel test, which is a sharper seam but a weaker test: stubbing the
composition means nothing verifies it. Prefer building the real use case over
repository spies, as the current tests do, and stub only when the real thing is
awkward.

## Alternatives considered

**Keep them concrete (ADR-0008).** Fewer types, and the composition stays under
test. Rejected because the ViewModel then names concrete collaborators, and
because "when is something a use case" stayed a matter of taste.

**Extract on the second call site rather than the second caller.** Simpler to
count, but it fires on `candles(for:interval:)` and produces a pass-through —
exactly the ceremony ADR-0008 was written to avoid.

**A single `ObserveQuotesUseCase` with a request enum.** One type instead of two,
at the price of an `execute` that branches on its argument — two operations
wearing one name.
