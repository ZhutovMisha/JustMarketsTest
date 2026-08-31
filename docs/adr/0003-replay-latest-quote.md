# ADR-0003: Replay the latest quote to new subscribers

- **Status**: Accepted
- **Date**: 2026-08-31

## Context

A user reported: the list shows a price for a symbol, the detail screen for that
same symbol shows a placeholder until you wait there.

The repository only relayed *changes*. `TickThrottle` cleared pending ticks on
every flush, so nothing in the system held "the current price". The list
accumulated quotes in a dictionary over the screen's lifetime; the detail
ViewModel started from `nil`. A new subscriber therefore had to wait for the next
tick on its exact symbol — minutes for an illiquid instrument.

## Decision

`RemoteMarketsRepository` keeps `latestQuotes: [String: MarketQuote]`, updated on
each flush before broadcasting. `updates(for:)` yields a snapshot of the cached
quotes for the requested symbols immediately after registering the consumer.

Cache entries are not evicted when consumers disconnect. `updatedAt` is
preserved, so `MarketStatus` marks a replayed value `stale` once it ages past the
threshold rather than presenting it as fresh.

## Consequences

Pushing the detail screen shows a price instantly, matching the list. Switching
categories shows last known prices instead of placeholders, which also made the
category-scoped subscription in ADR-0004 viable.

The cost: the repository now holds state proportional to the number of symbols
ever seen, and a subscriber can receive a value older than its subscription. The
staleness badge is what keeps that honest — the alternative, hiding old values,
shows the user nothing when we do know something.

## Alternatives considered

**Pass the last known quote into the detail module.** Works for that one screen
and leaves the general problem — every future consumer would re-solve it.

**Handle the hub's `ReceiveSubscriptionState` message.** Possibly the correct
source of truth, and the server may already send a snapshot there. The handler is
currently a diagnostic `print`. If the payload does carry quotes, prefer it over
the client-side cache and supersede this ADR.
