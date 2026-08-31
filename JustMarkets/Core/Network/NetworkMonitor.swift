//
//  NetworkMonitor.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import Foundation
import Network

final class NetworkMonitor {
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "JustMarkets.NetworkMonitor")
    
    private var isStarted = false
    
    deinit {
        monitor.cancel()
    }
    
    func isConnected() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            monitor.pathUpdateHandler = { path in
                continuation.yield(path.status == .satisfied)
            }
            
            continuation.onTermination = { [monitor] _ in
                monitor.pathUpdateHandler = nil
            }
            
            guard isStarted else {
                isStarted = true
                monitor.start(queue: queue)
                
                return
            }
            
            continuation.yield(monitor.currentPath.status == .satisfied)
        }
    }
}
