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
    
    /// Reports that the hub connection has opened.
    /// - Parameter hubConnection: The hub connection that opened.
    func connectionDidOpen(hubConnection: HubConnection) {
        onStateChanged?(.connected)
    }
    
    /// Reports that the connection could not be opened.
    func connectionDidFailToOpen(error: Error) {
        onStateChanged?(.disconnected)
    }
    
    /// Reports that the connection has closed.
    /// - Parameter error: The error associated with closing the connection, if any.
    func connectionDidClose(error: Error?) {
        onStateChanged?(.disconnected)
    }
    
    /// Reports that the connection is attempting to reconnect.
    /// - Parameter error: The error that caused the reconnection attempt.
    func connectionWillReconnect(error: Error) {
        onStateChanged?(.connecting)
    }
    
    /// Notifies observers that the connection has been re-established.
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
    
    /// Starts the market data connection for the specified symbols or updates the existing subscription.
    /// - Parameter symbols: The market symbols to subscribe to.
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
    
    /// Disconnects from the market data stream and clears the subscribed symbols.
    func disconnect() {
        isStarted = false
        symbols = []
        
        hubConnection.stop()
    }
    
    /// Processes a connection state update, forwards it to observers, and subscribes to the configured symbols when connected.
    /// - Parameter state: The current market connection state.
    private func handle(_ state: MarketConnectionState) {
        if state == .disconnected {
            // Terminal: SignalR has exhausted its retry ladder and closed. The
            // symbols are kept so a later connect() can start a fresh hub,
            // which the isStarted guard would otherwise make unreachable.
            isStarted = false
        }
        
        onConnectionChanged?(state)
        
        guard state == .connected else { return }
        
        subscribe()
    }
    
    /// Subscribes to updates for the configured symbols.
    /// An invocation failure transitions the connection to the disconnected state.
    private func subscribe() {
        guard !symbols.isEmpty else { return }
        
        hubConnection.invoke(method: Constants.subscribe, arguments: [symbols]) { [weak self] error in
            guard error != nil else { return }
            
            // Same terminal transition as a close, so the state stays coherent.
            self?.handle(.disconnected)
        }
    }
}
