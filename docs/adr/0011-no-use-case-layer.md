# ADR-0011: No use-case layer — ViewModels call repositories

- **Status**: Accepted
- **Date**: 2026-08-31

Supersedes [ADR-0010](0010-use-case-shape.md), and with it the layer
[ADR-0008](0008-use-case-layer.md) introduced. Adopts the alternative ADR-0008
listed and rejected: "No use cases, ever."

## Context

ADR-0010 gave every use case a protocol so that "a ViewModel test can stub the
operation". An audit of the test suite showed that seam was never used: every
test builds the `Default` implementation over a repository spy
(`MarketsViewModelTests`, `MarketsViewControllerTests`). Three protocols existed
with one conformance each and no double — which CLAUDE.md says is a protocol to
delete.

The extraction trigger did not hold up either. `LoadMarketsUseCase` had exactly
one caller, so by ADR-0010's own rule it should never have been extracted. The
two `Observe*` use cases did have a second-caller story, but what they contained
was thin: one derived a symbol list from `MarketsFilter` and compared it with the
previous one, the other filtered an enum case out of a stream.

`DefaultObserveMarketQuotesUseCase` was the clearest signal. It held mutable
state (`subscribedNames`) and therefore was not an operation at all but a
subscription manager wearing a use case's name. That state describes what one
screen is currently showing, so it belongs to that screen's ViewModel.

## Decision

**There is no use-case layer.** A ViewModel depends on repository protocols
directly and composes them itself. `Features/Markets/Domain/UseCases` is deleted.

Where the removed use cases went:

| Was | Now |
| --- | --- |
| `LoadMarketsUseCase` | two repository calls in `MarketsViewModel.loadData()` |
| `ObserveMarketQuotesUseCase` | `MarketsViewModel.resubscribeIfNeeded()`, which owns `subscribedNames` |
| `ObserveSymbolQuotesUseCase` | the `for await` loop in `SymbolDetailViewModel.observeQuotes()` |

The [ADR-0004](0004-subscription-scoping.md) invariant is unchanged and still
has one enforcement point: `resubscribeIfNeeded` derives the subscribed names
from the same `MarketsFilter.symbols` call that produces the visible list,
with the query excluded. It now sits next to the state it guards.

**The seam is the repository.** Repository protocols stay, because every one of
them has a test double: `MarketsRepositorySpy`, `FavoritesRepositorySpy`,
`NetworkClientSpy`, `QuotesDataSourceSpy`. A ViewModel test stubs data by
stubbing a repository, which is what the suite already did through the use cases.

**A use case comes back only with a second consumer of composed logic** — two
ViewModels needing the same multi-repository operation. One screen composing two
repositories is not that.

## Consequences

`MarketsViewModel` grew by about ten lines and gained the resubscription state;
in exchange three files, three protocols and three `Default` classes are gone,
and the call from screen to data is one hop instead of two. Nothing in the test
suite had to be rewritten beyond constructing the ViewModel with repositories
instead of use cases — which is itself the evidence that the layer carried no
behaviour of its own.

The cost is that `SymbolDetailViewModel` now filters the update stream inline. If
a third screen needs a single-symbol stream, that loop becomes a
`quotes(for:)` method on `MarketsRepository` rather than a new use case.
