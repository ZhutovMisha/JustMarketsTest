//
//  MarketsEventSpy.swift
//  JustMarketsTests
//
//  Created by Zhutov Mykhailo on 01.09.2026.
//

@testable import JustMarkets

@MainActor
final class MarketsEventSpy {
    
    // Event cannot be Equatable — it carries an Error.
    enum Message: Equatable {
        
        case changed
        case rowsUpdated
        case loading(Bool)
        case connection(MarketConnectionState)
        case failed
    }
    
    private(set) var messages: [Message] = []
    
    init(_ viewModel: MarketsViewModel) {
        let previous = viewModel.onEvent
        
        viewModel.onEvent = { [weak self] event in
            previous?(event)
            
            self?.messages.append(Message(event))
        }
    }
}

// MARK: - Private

private extension MarketsEventSpy.Message {
    
    init(_ event: MarketsViewModel.Event) {
        switch event {
        case .changed:
            self = .changed
            
        case .rowsUpdated:
            self = .rowsUpdated
            
        case .loading(let isLoading):
            self = .loading(isLoading)
            
        case .connection(let state):
            self = .connection(state)
            
        case .failed:
            self = .failed
        }
    }
}
