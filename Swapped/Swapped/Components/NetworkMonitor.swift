//
//  NetworkMonitor.swift
//  Just Swap
//
//  Created by Donovan Holmes on 10/12/24.
//

import Foundation
import Network

class NetworkMonitor {
    let monitor = NWPathMonitor()
    let queue = DispatchQueue.global(qos: .background)

    init() {
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                print("We're connected!")
            } else {
                print("No connection.")
            }
        }
        monitor.start(queue: queue)
    }
}

// Usage
let networkMonitor = NetworkMonitor()
