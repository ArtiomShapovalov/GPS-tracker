    //
    //  Fetcher.swift
    //  GPSTraking
    //
    //  Created by Artem Shapovalov on 29.04.2026.
    //

import Foundation

final class Fetcher<T: Encodable> {
    typealias AsyncResult = (URLResponse, Data?)
    
    enum Failure: Error {
        case cantBuildRequest
        case unexpectedResponse
        case sessionExpired
        case urlError(URLError)
        case unexpectedError
    }
    
    private let session = URLSession.shared
    private var jsonContentType: String { "application/json" }
    private var refreshSession: (inout T) async throws -> ()
    private lazy var encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()
    
    init(refreshSession:  @escaping (inout T) async throws -> () = { _ in }) {
        self.refreshSession = refreshSession
    }
    
    func post(_ endpoint: String,
              bodyParams: T,
              retry: Int = 0)
    async throws -> AsyncResult {
        let data = try? encoder.encode(bodyParams)
        
        guard let data else {
            throw Failure.cantBuildRequest
        }
        guard let url = URL(string: endpoint) else {
            throw Failure.cantBuildRequest
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue(jsonContentType, forHTTPHeaderField: "Content-Type")
        request.setValue(jsonContentType, forHTTPHeaderField: "Accept")
        
        let json = try? JSONSerialization.jsonObject(with: data)
        debugPrint("Fetcher>>Request>>Endpoint>>")
        debugPrint(endpoint)
        debugPrint("Fetcher>>Request>>Body>>")
        debugPrint(bodyParams)
        debugPrint(json as? [String: Any] ?? [:])

        do {
            let res = try await call(request: &request)
            return res
        } catch {
            guard let error = error as? Failure else {
                throw Failure.unexpectedError
            }
            
            switch error {
            case .sessionExpired:
                var body = bodyParams
                try await refreshSession(&body)
                return try await post(endpoint,
                                      bodyParams: body,
                                      retry: retry + 1)
            default:
                throw Failure.unexpectedError
            }
        }
    }
    
    func call(request: inout URLRequest, retry: Int = 0) async throws -> AsyncResult {
        let (data, response) = try await session.data(for: request)
        
        let json = try? JSONSerialization.jsonObject(with: data)
        debugPrint("Fetcher>>Response>>")
        debugPrint(response)
        debugPrint("Fetcher>>Data>>")
        debugPrint(json as? [String: Any] ?? [:])

        if let res = response as? HTTPURLResponse,
           [400, 401, 403].contains(res.statusCode) {
            throw Failure.sessionExpired
        }
        
        if data.count == 0 {
            return (response, nil)
        }
        
        return (response, data)
    }
}
