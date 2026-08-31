# ADR-0009: Favourites are ordered, newest first

- **Status**: Accepted
- **Date**: 2026-08-31

## Context

Favourites were stored as a single `symbol` attribute and returned as
`Set<String>`. `MarketsFilter` pinned them above the rest but, having no ordering
information, kept the order of the API's symbol list.

The requirement was to show recently added favourites at the top. A `Set` cannot
express that, so this needed a storage change, not just a sort.

## Decision

`FavoriteSymbolEntity` gains `dateAdded`, optional so lightweight migration
succeeds without a default value for existing rows. `CoreDataFavoritesRepository`
sorts by it descending; the protocol returns `[String]` ordered newest first.

`dateAdded` does not leave the data layer. The domain contract becomes
"favourites, in display order", and `MarketsFilter` respects the order it is
given rather than knowing about dates:

```swift
let pinned = favorites.compactMap { name in matched.first { $0.name == name } }
let rest = matched.filter { !favorites.contains($0.name) }
```

Re-favouriting a removed symbol writes a fresh `dateAdded`, so it returns to the
top. This is a product decision, covered by
`toggle_reAddingRemovedSymbol_movesItToTop`.

## Consequences

Ordering is decided where the data lives, by the store, and the domain stays
date-free. `CoreDataFavoritesRepositoryTests` became meaningful: comparing `Set`s
never checked order at all.

Costs. Membership tests are now linear rather than hashed. Deliberate: the filter
runs on load, category change, debounced search and toggle — not per frame and
not per cell — and at roughly 500 symbols against 20 favourites the dominant cost
in that function is `localizedCaseInsensitiveContains`, not the lookup. A rank
dictionary was written and then removed as unjustified machinery.

Newest-first also reshuffles: every addition pushes existing favourites down.
Oldest-first would be stable. The storage change is identical either way, so the
direction is one `ascending:` away from reversal.

## Alternatives considered

**Keep the `Set` and add a parallel ordered array.** Two sources of truth for one
fact.

**Sort in the domain.** Would require exposing `dateAdded` through the repository
protocol, putting a persistence detail into the domain contract for no gain.
