//
//  TickThrottle.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//
import Foundation

@MainActor
final class TickThrottle {
    
    typealias OnTicks = ([MarketTickDTO]) -> Void
    
    private let interval: Duration
    private var pendingTicks: [String: MarketTickDTO] = [:]
    private var task: Task<Void, Never>?
    
    var onTicks: OnTicks?
    
    init(interval: Duration = .milliseconds(100)) {
        self.interval = interval
    }
    
    deinit {
        task?.cancel()
    }
    
    /// Starts periodically delivering pending ticks at the configured interval.
    func start() {
        guard task == nil else { return }
        
        let interval = interval
        
        task = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: interval)
                
                guard !Task.isCancelled else { return }
                
                self?.sendPendingTicks()
            }
        }
    }
    
    /// Stops periodic tick delivery and discards all pending ticks.
    func stop() {
        task?.cancel()
        task = nil
        pendingTicks.removeAll()
    }
    
    /// Adds a market tick, replacing any pending tick for the same symbol.
    /// - Parameter tick: The market tick to queue.
    func add(_ tick: MarketTickDTO) {
        pendingTicks[tick.symbol] = tick
    }
    
    /// Delivers all pending ticks and clears the pending collection.
    private func sendPendingTicks() {
        guard !pendingTicks.isEmpty else { return }
        
        let ticks = Array(pendingTicks.values)
        pendingTicks.removeAll(keepingCapacity: true)
        
        onTicks?(ticks)
    }
}
