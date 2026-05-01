//
//  Tracker.swift
//  GPSTraking
//
//  Created by Artem Shapovalov on 29.04.2026.
//

import Foundation

extension API {
    struct TrackerResponse: Decodable {
        var success: Bool?
        var list: [Tracker]?
        
        struct Tracker: Decodable {
            var id: Int?
            var label: String?
            var groupId: Int?
            var clone: Bool?
            var source: Source?
            var tagBindings: [TagBinding]?
            var gps: GPS?
            
            struct Source: Decodable {
                var statusListingId: Int?
                var id: Int?
                var creationDate: String?
                var blocked: Bool?
                var deviceId: String?
                var tariffId: Int?
                var model: String?
                var tariffEndDate: String?
                var phone: String?
            }
            
            struct TagBinding: Decodable {
                var tagId: Int?
                var ordinal: Int?
            }
        }
    }
    
    func trackerList(retry: Int = 0) async throws -> [TrackerResponse.Tracker] {
        let endpoint = "https://\(domain)/v2/tracker/list"
        let hash = try await getHash()
        let body = HashBody(hash: hash)
        let fetcher = Fetcher() { [self] (body: inout HashBody) in
            body.hash = try await userAuth()
        }
        let (_, data) = try await fetcher.post(endpoint, bodyParams: body)
        guard let data else {
            throw Fetcher<HashBody>.Failure.unexpectedResponse
        }
        let decoded = try decoder.decode(TrackerResponse.self, from: data)
        guard var trackers = decoded.list else {
            throw Fetcher<HashBody>.Failure.unexpectedResponse
        }
        
        let ids: [Int] = trackers
            .map { $0.id }
            .compactMap { $0 }
        
        if let gps = try? await trackerGetStates(for: ids) {
            for i in 0..<trackers.count {
                guard let id = trackers[i].id else { continue }
                trackers[i].gps = gps["\(id)"]
            }
        }
        
        return trackers
    }
    
    class TrackerStatesBody: HashBody {
        var trackers: [Int]
        var listBlocked: Bool
        var allowNotExist: Bool
        init(trackers: [Int],
             listBlocked: Bool,
             allowNotExist: Bool,
             hash: String)
        {
            self.trackers = trackers
            self.listBlocked = listBlocked
            self.allowNotExist = allowNotExist
            super.init(hash: hash)
        }
    }
    
    struct TrackerStatesResponse: Decodable {
        var states: [String: State?]?
        
        struct State: Decodable {
            var gps: GPS?
            
            struct GPS: Decodable {
                var heading: Int?
                var location: Location?
                
                struct Location: Decodable {
                    var lat: Float?
                    var lng: Float?
                }
            }
        }
    }
    
    typealias GPS = TrackerStatesResponse.State.GPS
    func trackerGetStates(for trackers: [Int]) async throws -> [String: GPS] {
        let endpoint = "https://\(domain)/v2/tracker/get_states"
        let hash = try await getHash()
        let body = TrackerStatesBody(trackers: trackers,
                                     listBlocked: true,
                                     allowNotExist: true,
                                     hash: hash)
        let fetcher = Fetcher() { [self] (body: inout TrackerStatesBody) in
            body.hash = try await userAuth()
        }
        let (_, data) = try await fetcher.post(endpoint, bodyParams: body)
        guard let data else {
            throw Fetcher<TrackerStatesBody>.Failure.unexpectedResponse
        }
        let decoded = try decoder.decode(TrackerStatesResponse.self, from: data)
        var gps: [String: GPS] = [:]
        guard let states = decoded.states else {
            throw Fetcher<TrackerStatesBody>.Failure.unexpectedResponse
        }
        for item in states {
            guard let info = item.value?.gps else { continue }
            gps[item.key] = info
        }
        return gps
    }
}
