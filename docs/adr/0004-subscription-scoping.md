# ADR-0004: Scope subscriptions per consumer and per category

- **Status**: Accepted
- **Date**: 2026-08-31

## Context

Same bug report as ADR-0003, in the other direction: a symbol had no price in the
list but did have one on its detail screen — and after visiting that screen once,
the price appeared in the list too, permanently.

Three defects compounded.

1. The screens subscribed to different sets. The list used
   `symbols.quotableNames`, filtered by `hasData`; the detail screen used
   `[symbol.name]` with no filter. A symbol with `hasData == false` was never
   requested by the list, but was requested by the detail screen — and the server
   answered.
2. `subscribedSymbols` was a single `Set` that only grew via `formUnion`, cleared
   only when *all* consumers left. The list screen lives for the whole session,
   so it was never cleared.
3. Because the repository broadcasts every quote to every consumer, one visit to
   a detail screen permanently added that symbol to the list's data.

Behaviour therefore depended on navigation history, which is why it looked
intermittent.

## Decision

**Per-consumer subscriptions.** `[UUID: Set<String>]` replaces the single set.
The union is recomputed on subscribe and on termination, so leaving a screen
shrinks the subscription.

**One source for the visible set and the subscription.** The ViewModel derives
subscribed symbols from `MarketsFilter` with the current category and favourites
and an empty query — the same call that produces the visible list. Changing
category re-subscribes immediately; `resubscribeIfNeeded` compares the computed
set against the current one and does nothing when they match, so a switch that
resolves to the same symbols costs nothing.

The search query is deliberately excluded: searching is transient and must not
churn the subscription.

## Consequences

Behaviour no longer depends on where the user has been. The subscription is as
narrow as the visible category, which is the point — the default category is not
`All`, so the session starts narrow.

Re-subscribing creates a new consumer, which means ADR-0003's replay fires and
category switches render immediately.

Costs. Prices for a category you are not looking at go stale while you are away;
the badge reports it. Set-equality is the only guard against churn — flicking
through segments issues a `Subscribe` per distinct set, which is acceptable at
the current category count but is the thing to debounce if it ever bites. And this rests on an unverified assumption: that the hub's
`Subscribe` **replaces** a subscription rather than adding to it. There is no
`Unsubscribe` call in the client. If `Subscribe` turns out to be additive, the
narrowing saves nothing and an explicit `Unsubscribe` is required.

## Alternatives considered

**Subscribe to every symbol.** Tried first, and it did fix the reported symptom.
Rejected as the steady state: it maximises feed volume for data no one is
looking at.

**Make the detail screen respect `hasData` too.** Consistent, and one line — but
it removes a price the server demonstrably has. See ADR-0005.
