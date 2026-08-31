# ADR-0005: A real quote outranks `hasData` metadata

- **Status**: Accepted
- **Date**: 2026-08-31

## Context

`MarketSymbol.hasData` comes from the `/symbols` endpoint. `MarketStatus`
consulted it first: no `hasData` meant `noData` for crypto and `closed`
otherwise, regardless of whether a quote had arrived.

While fixing ADR-0004 we established that the server streams ticks for a symbol
whose `hasData` is `false`, as soon as you subscribe. So the flag is either stale
or means something other than "currently quoting".

Once subscriptions stopped filtering on `hasData`, the old precedence became
self-contradictory: a live price under a `NO DATA` badge.

## Decision

An actual quote decides the status. With a quote, the status is `live` or `stale`
by age. Only in the absence of any quote does `hasData` act as the fallback —
`noData` for crypto, `closed` for session-based markets.

## Consequences

The badge stops contradicting the number next to it. Metadata now fills a gap
rather than overriding observation, which is the right precedence for a feed
where the metadata is a periodic snapshot and the tick is the truth.

The cost: a genuinely closed market that emitted one late tick reads as `live`
until the staleness threshold passes. Bounded by that threshold, and preferable
to labelling real data as absent.

## Alternatives considered

**Keep `hasData` authoritative and stop subscribing to those symbols.** Internally
consistent, and it was the status quo — but it hides prices the server is
willing to send, which is what the user reported as a bug.
