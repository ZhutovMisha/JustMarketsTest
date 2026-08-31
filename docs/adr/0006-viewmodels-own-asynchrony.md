# ADR-0006: ViewModels own asynchrony and report errors

- **Status**: Accepted
- **Date**: 2026-08-31

## Context

ViewModels exposed `async throws` methods, so every call site was a
ViewController wrapping the call in `Task { do { … } catch { showAlert(…) } }`.
Four such blocks existed across two screens. The controllers therefore owned
task lifetime, cancellation and error presentation policy — none of which is view
work, and none of which is testable without a controller.

Nothing cancelled those tasks. Calling `loadData()` twice ran two loads
concurrently, both assigning `self.symbols`; last writer won.

## Decision

Public ViewModel methods are synchronous and return `Void`. The ViewModel starts
its own `Task`, stores it, cancels it in `deinit`, and reports failures through
`onError`. ViewControllers contain no `Task` and no `do`/`catch`:

```swift
viewModel.onError = { [weak self] error in
    self?.showAlert(message: error.localizedDescription)
}
```

Re-entrancy is per operation, not uniform. A load supersedes the previous one, so
`loadData()` and `selectInterval(_:)` cancel their predecessor. A favourite
toggle must reach the store even if another tap follows, so it is deliberately
not cancellable — cancelling mid-write can leave Core Data saved and in-memory
state disagreeing.

**Cancellation is not a failure.** Before reporting a caught error, check
`Task.isCancelled`; the loading indicator is likewise only reset when not
cancelled, since a newer load already owns it.

## Consequences

Controllers shrank to binding and rendering. `toggleFavorite(for:)` and
`reconfigureRow(named:)` disappeared from `MarketsViewController` entirely — the
cell calls the ViewModel directly. Task lifetime and error policy are now unit
testable.

Costs. Fire-and-forget calls mean tests must wait on an observable outcome rather
than `await` the call, which is what `loadAndWait(_:)` and `wait(until:)` are for.
And the re-entrancy rule is per method rather than uniform, so adding an
operation means deciding which kind it is.

## Alternatives considered

**Keep `async throws` and wrap in a `Task` inside the ViewModel.** Tried; the
signature then lies — the body neither suspends nor throws — while still forcing
`try await` on callers. Combined with an empty `catch`, it silently swallowed
failures: spinner stops, screen blank, no explanation.

**A single `isCancellable` flag for all operations.** Simpler to state, wrong for
favourites, which must not be cancelled.
