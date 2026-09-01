//
//  MarketsWebSocket.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

import Foundation
import SignalRClient

private final class MarketsHubDelegate: HubConnectionDelegate {
    
    var onStateChanged: MarketsQuotesDataSource.OnConnectionChanged?
    
    func connectionDidOpen(hubConnection: HubConnection) {
        onStateChanged?(.connected)
    }
    
    func connectionDidFailToOpen(error: Error) {
        onStateChanged?(.disconnected)
    }
    
    func connectionDidClose(error: Error?) {
        onStateChanged?(.disconnected)
    }
    
    func connectionWillReconnect(error: Error) {
        onStateChanged?(.connecting)
    }
    
    func connectionDidReconnect() {
        onStateChanged?(.connected)
    }
}

final class MarketsWebSocket: MarketsQuotesDataSource {
    
    var onTick: OnTick?
    var onConnectionChanged: OnConnectionChanged?
    
    private enum Constants {
        
        static let receiveTick = "ReceiveTick"
        static let subscribe = "Subscribe"
        static let receiveSubscriptionState = "ReceiveSubscriptionState"
    }
    
    private static let url = URL(string: "https://biquote.io/hubs/tick")!
    
    private let hubConnection: HubConnection
    private let hubDelegate: MarketsHubDelegate
    private var symbols: [String] = []
    private var isStarted = false
    
    init() {
        let hubDelegate = MarketsHubDelegate()
        self.hubDelegate = hubDelegate
        
        hubConnection = HubConnectionBuilder(url: Self.url)
            .withHubConnectionOptions { $0.callbackQueue = .main }
            .withLogging(minLogLevel: .warning)
            .withAutoReconnect()
            .withHubConnectionDelegate(delegate: hubDelegate)
            .build()
        
        hubConnection.on(method: Constants.receiveTick) { [weak self] (tick: MarketTickDTO) in
            MainActor.assumeIsolated {
                self?.onTick?(tick)
            }
        }
        
        hubConnection.on(method: Constants.receiveSubscriptionState) { _ in }
        
        hubDelegate.onStateChanged = { [weak self] state in
            Task { @MainActor in
                self?.handle(state)
            }
        }
    }
    
    func connect(symbols: [String]) {
        guard !isStarted else {
            guard symbols != self.symbols else { return }
            
            self.symbols = symbols
            subscribe()
            
            return
        }
        
        self.symbols = symbols
        isStarted = true
        
        onConnectionChanged?(.connecting)
        hubConnection.start()
    }
    
    func disconnect() {
        isStarted = false
        symbols = []
        
        hubConnection.stop()
    }
    
    private func handle(_ state: MarketConnectionState) {
        if state == .disconnected {
            isStarted = false
        }
        
        onConnectionChanged?(state)
        
        guard state == .connected else { return }
        
        subscribe()
    }
    
    private func subscribe() {
        guard !symbols.isEmpty else { return }
        
        hubConnection.invoke(method: Constants.subscribe, arguments: [symbols]) { [weak self] error in
            guard error != nil else { return }
            
            self?.handle(.disconnected)
        }
    }
}
