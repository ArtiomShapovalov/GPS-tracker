//
//  Encryption.swift
//  GPSTraking
//
//  Created by Artem Shapovalov on 29.04.2026.
//

import CryptoKit
import Security
import Foundation

enum CryptoError: Error {
    case encryptionFailed
    case decryptionFailed
    case keyGenerationFailed
    case keyRetrievalFailed
}

struct Encryption {
    private let keyTag = "com.chatplatform.encryptionKey"
    private let keySize = SymmetricKeySize.bits256
    private var key: SymmetricKey?
    
    private mutating func getEncryptionKey() throws -> SymmetricKey {
        if let key {
            return key
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyTag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess, let keyData = item as? Data {
            let sKey = SymmetricKey(data: keyData)
            self.key = sKey
            return sKey
        }
        
        let sKey = SymmetricKey(size: keySize)
        let keyData = sKey.withUnsafeBytes { Data(Array($0)) }
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyTag,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        
        guard addStatus == errSecSuccess else { throw CryptoError.keyGenerationFailed }
        
        key = sKey
        return sKey
    }
    
    mutating func encrypt(_ data: Data) throws -> Data {
        let key = try getEncryptionKey()
        let sealedBox = try AES.GCM.seal(data, using: key)
        
        guard let combined = sealedBox.combined
        else { throw CryptoError.encryptionFailed }
        
        return combined
    }
    
    mutating func decrypt(_ data: Data) throws -> Data {
        let key = try getEncryptionKey()
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    mutating func encryptString(_ string: String) throws -> Data {
        let data = string.data(using: .utf8)
        
        guard let data else { throw CryptoError.encryptionFailed }
        
        return try encrypt(data)
    }
    
    mutating func decryptString(_ data: Data) throws -> String {
        let decryptedData = try decrypt(data)
        let str = String(data: decryptedData, encoding: .utf8)
        
        guard let str else { throw CryptoError.decryptionFailed }
        
        return str
    }
}
