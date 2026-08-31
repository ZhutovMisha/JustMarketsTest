//
//  TickThrottle.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//
import Foundation

final class TickThrottle {
    
    typealias OnTicks = ([MarketTickDTO]) -> Void
    
    private let interval: Duration
    private var pendingTicks: [String: MarketTickDTO] = [:]
    private var task: Task<Void, Never>?
    
    var onTicks: OnTicks?
    
    init(interval: Duration = .milliseconds(200)) {
        self.interval = interval
    }
    
    deinit {
        task?.cancel()
    }
    
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
    
    func stop() {
        task?.cancel()
        task = nil
        pendingTicks.removeAll()
    }
    
    func add(_ tick: MarketTickDTO) {
        pendingTicks[tick.symbol] = tick
    }
    
    private func sendPendingTicks() {
        guard !pendingTicks.isEmpty else { return }
        
        let ticks = Array(pendingTicks.values)
        pendingTicks.removeAll(keepingCapacity: true)
        
        onTicks?(ticks)
    }
}
