//
//  Poller.swift
//  GPSTraking
//
//  Created by Artem Shapovalov on 01.05.2026.
//

import Foundation

final class Poller {
    var timer: Timer?
    var interval: TimeInterval
    var block: (() -> ())?
    
    init(_ interval: TimeInterval) {
        self.interval = interval
    }
    
    func start(block: @escaping () -> ()) {
        self.block = block
        let timer = Timer(timeInterval: interval,
                          repeats: true)
        { [weak self] _ in
            self?.block?()
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }
}
