# Architecture decision records

Why the code is the way it is. Each record is immutable once accepted: when a
decision changes, add a new ADR and mark the old one
`Superseded by ADR-XXXX` instead of rewriting its rationale. The value is
knowing what was decided at the time, and on what evidence.

Write one when a choice constrains future code, or when a reader would otherwise
ask "why on earth is it done this way". Not for routine fixes.

| # | Decision | Status |
| --- | --- | --- |
| [0001](0001-mvvm-clean-coordinator.md) | MVVM + Clean layering with a coordinator | Accepted |
| [0002](0002-mainactor-default-isolation.md) | MainActor default isolation instead of actors | Superseded by 0012 |
| [0003](0003-replay-latest-quote.md) | Replay the latest quote to new subscribers | Accepted |
| [0004](0004-subscription-scoping.md) | Scope subscriptions per consumer and per category | Accepted |
| [0005](0005-quote-outranks-hasdata.md) | A real quote outranks `hasData` metadata | Accepted |
| [0006](0006-viewmodels-own-asynchrony.md) | ViewModels own asynchrony and report errors | Accepted |
| [0007](0007-live-updates-bypass-diffable.md) | Live updates bypass the diffable data source | Accepted |
| [0008](0008-use-case-layer.md) | Introduce a use-case layer | Superseded by 0010 |
| [0009](0009-ordered-favourites.md) | Favourites are ordered, newest first | Accepted |
| [0010](0010-use-case-shape.md) | One protocol, one `execute`, extracted on a second caller | Superseded by 0011 |
| [0011](0011-no-use-case-layer.md) | No use-case layer — ViewModels call repositories | Accepted |
| [0012](0012-explicit-mainactor.md) | Explicit `@MainActor` instead of default isolation | Accepted |
| [0013](0013-single-event-channel.md) | One event channel per ViewModel instead of separate callbacks | Accepted |

Numbering is sequential and never reused. Use [the template](template.md).
