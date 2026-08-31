# ADR-0001: MVVM + Clean layering with a coordinator

- **Status**: Accepted
- **Date**: 2026-08-29

## Context

A trading app with live data: a symbol list with categories, search and
favourites, plus a detail screen with a chart. Quotes stream continuously, so
presentation logic and feed plumbing will both grow. The app is UIKit and
programmatic; there is no SwiftUI requirement.

Two things needed to be true from the start: the rules that decide what a user
sees must be testable without a simulator screen, and swapping the transport
(HTTP, socket, cache) must not reach into screens.

## Decision

Four layers, dependencies pointing inwards.

- **Domain** owns value types, repository protocols, and pure rules. No
  framework imports beyond Foundation.
- **Data** implements the Domain protocols, owns DTOs, mappers and transports.
- **Presentation** is one ViewModel per screen plus a passive ViewController.
  ViewModels hold state and expose typealias'd closures; ViewControllers bind and
  render.
- **App** wires everything: `AppDependencies` for shared collaborators,
  `ModuleFactory` for screen assembly, `AppCoordinator` for navigation.

Screens never navigate. They expose intent (`onSymbolSelected`) and the
coordinator decides.

## Consequences

Domain rules — filtering, staleness, ordering — are pure functions tested in
microseconds, which is where most test value sits. Adding a screen touches the
factory and the coordinator, not existing screens.

The cost is indirection: reading one user action end to end crosses four files,
and a small feature needs more scaffolding than a monolithic controller would.
Accepted because the live-data plumbing would otherwise leak into view code.

## Alternatives considered

**Controllers talking straight to services.** Faster for the first screen, but
the rules that matter would live in UIKit classes and would not be testable
without a view.

**SwiftUI + observable state.** Fine architecture, wrong constraints — the
project is UIKit, and the chart library in use is UIKit-based.
