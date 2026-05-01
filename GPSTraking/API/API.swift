//
//  API.swift
//  GPSTraking
//
//  Created by Artem Shapovalov on 29.04.2026.
//

import Foundation

final class API {
    static let shared = API()
    
    var domain: String { "api.eu.navixy.com" }
    var encription = Encryption()
    let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()
    var ud: UserDefaults { UserDefaults.standard }
    var udHashKey: String { UserDefaults.Keys.sessionHash.rawValue }
    
    private init() {}
    
    class HashBody: Encodable {
        var hash: String
        init(hash: String) {
            self.hash = hash
        }
    }
    
    func getHash() async throws -> String {
        if let hash = ud.data(forKey: udHashKey) {
            return try encription.decryptString(hash)
        }
        
        return try await userAuth()
    }
}
