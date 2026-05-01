//
//  Date.swift
//  GPSTraking
//
//  Created by Artem Shapovalov on 30.04.2026.
//

import Foundation

extension Date {
    var string: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: self)
    }
}
