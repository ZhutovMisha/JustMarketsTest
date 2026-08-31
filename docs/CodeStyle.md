# Code style

## Closures are always a typealias

Every closure-typed property, parameter and callback gets a named type. Inline
function types in property declarations are not used.

```swift
// yes
typealias OnFavoriteTapped = () -> Void
var onFavoriteTapped: OnFavoriteTapped?

// no
var onFavoriteTapped: (() -> Void)?
```

Name them for the event, not the signature: `OnChange`, `OnError`, `OnTick`,
`OnConnectionChanged`. Declare them in the type that publishes the event; a
consumer refers to `MarketsQuotesDataSource.OnTick`.

## Member order

Inside a type, top to bottom:

1. `typealias`
2. nested `struct` / `enum` (public)
3. public computed properties
4. public stored properties
5. private nested `struct` / `enum`
6. private computed properties
7. private stored properties
8. `init`, then `deinit`
9. public methods
10. private methods

```swift
final class MarketsViewModel {

    typealias OnChange = () -> Void
    typealias OnError = (Error) -> Void

    struct Dependencies {
        let marketsRepository: MarketsRepository
        let favoritesRepository: FavoritesRepository
        let processor: MarketsProcessor
    }

    var emptyMessage: String? { ... }        // public computed

    var onChange: OnChange?                  // public stored
    var onError: OnError?

    private enum Constants { ... }           // private nested

    private var isEmpty: Bool { ... }        // private computed

    private let dependencies: Dependencies   // private stored
    private var symbols: [MarketSymbol] = []

    init(dependencies: Dependencies) { ... }

    deinit { ... }
}
```

Private helpers may instead live in a `private extension` below the type, under
a `// MARK: - Private` heading. Either form is fine; do not mix both in one file.

## Protocols

Add one where there is a seam that is actually used: a test double, or a second
implementation. `NetworkClient` and `MarketsQuotesDataSource` earn theirs — they
hide Alamofire and SignalR and both have spies. A protocol with a single
conformance and no double is deleted rather than kept for symmetry.

## Extensions carry a MARK

Every extension gets a `// MARK: -` heading naming what it is. Protocol
conformance lives in its own extension so the primary declaration stays about
the type's own API.

```swift
// MARK: - UICollectionViewDelegate

extension MarketsViewController: UICollectionViewDelegate {
    ...
}

// MARK: - UISearchBarDelegate

extension MarketsViewController: UISearchBarDelegate {
    ...
}

// MARK: - Private

private extension MarketsViewModel {
    ...
}
```

The heading is the protocol name for a conformance (`// MARK: - FavoritesRepository`),
otherwise what the extension groups (`// MARK: - Private`,
`// MARK: - Composition Layout Setup`).

Exception: a file whose entire contents is one extension — `UIControl+Action.swift`,
`UIViewController+Alert.swift` — needs no heading. The filename already says what the
file is, and a MARK with nothing to separate it from is noise. Add one as soon as
a second declaration joins the file.

## Formatting

- Four spaces, no tabs. One blank line between members.
- `guard` bodies on their own lines; a blank line before the statement that
  follows a multi-line `guard`.
- **Parameter layout by count.** One or two parameters stay on a single line.
  Three or more go one per line, closing paren on its own line. Applies to
  declarations and call sites alike.

  ```swift
  // 1–2 parameters: one line
  func configure(with row: MarketRow, showsSeparator: Bool)
  func price(_ price: Decimal?, digits: Int) -> String

  // 3+ parameters: one per line
  func makeRow(
      symbol: MarketSymbol,
      quote: MarketQuote?,
      status: MarketStatus,
      isFavorite: Bool
  ) -> MarketRow

  let row = processor.makeRow(
      symbol: symbol,
      quote: quote,
      status: status,
      isFavorite: isFavorite
  )
  ```

  A trailing closure does not count towards the parameter total. If collapsing
  one or two parameters would push the line past roughly 100 characters — nested
  calls with long argument labels do — keep it wrapped; readability wins over the
  count.
- `// MARK: - Name` to separate protocol conformances and private sections.
- Type inference for obvious literals; explicit types on stored properties whose
  value is not literal.

## Naming

- Booleans read as assertions: `isActive`, `hasData`, `showsSeparator`.
- Factory methods are `make…`: `makeRow`, `makeLayout`, `makeMarketsSection`.
- Domain rule namespaces are plural nouns with static members: `MarketsFilter`,
  `MarketsMapper`. Plain `enum` — no instances, no isolation.
- Repository implementations carry their source: `RemoteMarketsRepository`,
  `CoreDataFavoritesRepository`.

## Concurrency

- Isolation is opt-in: annotate `@MainActor` on the types that need the main
  thread. Leave value types and pure rules unannotated.
- Stored `Task`s are cancelled in `deinit`.
- `Task { [weak self] in … }` unless the task is short and self-contained.
- Check `Task.isCancelled` before turning a caught error into user-visible state.
