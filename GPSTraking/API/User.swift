//
//  User.swift
//  GPSTraking
//
//  Created by Artem Shapovalov on 29.04.2026.
//

import Foundation

extension API {
    struct AuthBody: Encodable {
        var login: String
        var password: String
    }
    
    struct Hash: Decodable {
        var hash: String?
    }
    
    func userAuth() async throws -> String {
        let endpoint = "https://\(domain)/v2/user/auth"
        let body = AuthBody(login: "demo-eu@navixy.com", password: "123456")
        let fetcher = Fetcher<AuthBody>()
        let (_, data) = try await fetcher.post(endpoint, bodyParams: body)
        
        guard let data else {
            throw Fetcher<AuthBody>.Failure.unexpectedResponse
        }
        
        let hash = try decoder.decode(Hash.self, from: data)
        
        guard let hashStr = hash.hash else {
            throw Fetcher<AuthBody>.Failure.unexpectedResponse
        }
        
        ud.set(hashStr, forKey: udHashKey)
        return hashStr
    }
}
