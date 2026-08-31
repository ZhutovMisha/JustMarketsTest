# ADR-0008: Introduce a use-case layer

- **Status**: Superseded by [ADR-0010](0010-use-case-shape.md)
- **Date**: 2026-08-31

## Context

The target architecture is "MVVM + Clean with use cases", but no use-case layer
exists. `MarketsViewModel` and `SymbolDetailViewModel` call repository protocols
directly.

Auditing what a use case would actually wrap, the candidates split cleanly.

**Real orchestration — two:**

- *Load markets*: `marketsRepository.fetchSymbols()` and
  `favoritesRepository.favorites()` in parallel, from two different
  repositories, combined into one result. The ViewModel currently owns this
  composition.
- *Observe quotes for a category*: deciding **which** symbols a category needs is
  a domain rule. It lives in the ViewModel today as `subscribableNames()`, which
  calls `MarketsFilter` with an empty query. ADR-0004 exists because that set
  once drifted from the visible list; the invariant currently has no single owner.

**Pass-throughs — everything else:** toggling a favourite, fetching candles,
fetching the symbol list. One repository call each, no rules, no composition.
Wrapping them adds a type, a protocol and a test double per method while adding
no meaning, and lengthens every call chain by a hop.

*Load symbol details* sits between: it composes `details` and `candles` in
parallel, but both come from the same repository.

## Decision

Introduce use cases selectively, where they carry composition or a rule:

1. `LoadMarketsUseCase` — symbols + favourites in parallel, returning a
   `Snapshot`.
2. `ObserveMarketQuotesUseCase` — owns the category-to-symbols rule *and* the
   "do not resubscribe to an unchanged set" invariant. It returns
   `AsyncStream<MarketsUpdate>?`, where `nil` means the live subscription already
   covers the requested set.

Leave single-call operations on the repository protocols: `toggleFavorite` still
goes to `FavoritesRepository`. Revisit *load symbol details* if the detail screen
grows a third source.

Do **not** add a use case per repository method.

**No protocols for these two.** Per the seam rule in
[Code style](../CodeStyle.md), a protocol earns its place where a double or a
second implementation exists. Tests build the real use cases over
`MarketsRepositorySpy` and `FavoritesRepositorySpy`, so the seam is already one
layer down and the composition gets exercised rather than stubbed out. Add a
protocol the day a test needs to stub a use case itself.

## Consequences

`MarketsViewModel` lost `subscribedNames`, `subscribableNames()` and
`observeUpdates(for:)`; `resubscribeIfNeeded()` is now a single call plus the
stream task. The ADR-0004 invariant has exactly one owner, so a second screen
that subscribes cannot re-derive it differently — which is how that bug happened.

Two new types, no new protocols, no new doubles.

The cost of selectivity is inconsistency — some ViewModel calls go through a use
case, some straight to a repository. A reviewer expecting textbook Clean will see
that as a gap. The alternative is uniformity bought with roughly four
pass-through types.

The remaining inconsistency is intentional: favourite toggling still calls its
repository directly. A reviewer expecting textbook Clean will read that as a gap;
the alternative is roughly four pass-through types that add no meaning.

## Alternatives considered

**A use case for every repository method.** Uniform and textbook. Explicitly
rejected in review as machinery that would worsen the test suite rather than
improve it.

**No use cases, ever.** Defensible for this size — but leaves the ADR-0004
invariant without an owner, and leaves the stated architecture describing
something the code does not do.
