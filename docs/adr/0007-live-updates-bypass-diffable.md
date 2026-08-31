# ADR-0007: Live updates bypass the diffable data source

- **Status**: Accepted
- **Date**: 2026-08-31

## Context

With the tick interval lowered to 0.2 s the list visibly jumped while scrolling.

Two causes. The compositional layout declared
`heightDimension: .estimated(120)` while the cell's constraints produce roughly
63 pt — `quoteStackView` is 12 + (19.09 + 4 + 15.51) + 12. Unmeasured cells were
therefore sized at nearly double their real height, so content size shrank as
cells came into view and the scroll drifted underneath the finger.

Compounding it, every tick went through `snapshot.reconfigureItems` +
`dataSource.apply`, forcing a re-measure and content-size recalculation five
times per second on top of the scroll.

## Decision

Two changes.

The estimate matches the cell: `estimatedRowHeight = 64`, kept next to the layout
with a comment tying it to the cell, since a wide miss is what causes drift.

Per-tick updates write straight into on-screen cells and never touch a snapshot:

```swift
for indexPath in collectionView.indexPathsForVisibleItems {
    guard
        let symbol = dataSource.itemIdentifier(for: indexPath),
        let cell = collectionView.cellForItem(at: indexPath) as? MarketCollectionViewCell
    else { continue }

    cell.configure(with: viewModel.row(for: symbol), showsSeparator: indexPath.item > 0)
}
```

Snapshots remain the mechanism for anything structural — category changes,
search, favourites reordering.

## Consequences

Scrolling stays smooth at 5 updates per second, and the update cost is
proportional to visible cells rather than to a diff. Cells scrolled back in are
refreshed by the normal dequeue path, so no data is missed.

Costs. The cell must be reconfigurable idempotently. The favourite star sits
inside an item the diff considers unchanged, so `onChange` now also calls the
direct update — visible in the code as a deliberate pairing rather than an
accident. And the row-height constant duplicates knowledge the cell's constraints
already encode; a comment guards it, a test does not.

## Alternatives considered

**Absolute item height.** Removes self-sizing entirely and is defensible since
the fonts are fixed rather than Dynamic Type. Rejected for now because the cell's
stacks are pinned to their superview's vertical edges, so forcing a taller box
would stretch the arranged subviews. Revisit together with those constraints.

**Skip updates while the user drags.** Treats the symptom, and freezes prices
exactly when the user is looking at them.
