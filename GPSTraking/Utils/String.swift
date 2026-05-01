//
//  String.swift
//  GPSTraking
//
//  Created by Artem Shapovalov on 29.04.2026.
//

import Foundation

extension String {
    func url(query: [String: String?]?) -> URL? {
        guard var components = URLComponents(string: self) else {
            return nil
        }
        
        if let query {
            var items = components.queryItems ?? []
            for (key, value) in query {
                items.append(URLQueryItem(name: key, value: value))
            }
            components.queryItems = items
        }
        
        return components.url
    }
}
