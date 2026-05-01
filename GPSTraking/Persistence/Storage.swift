//
//  Storage.swift
//  GPSTraking
//
//  Created by Artem Shapovalov on 30.04.2026.
//

import Foundation
import CoreData
import SwiftUI

struct Storage {
    static let shared = Storage()
    
    private init() {}
    
    func receiveTracks(_ viewContext: NSManagedObjectContext) async throws {
        let request = Item.fetchRequest()
        let items = try viewContext.fetch(request)
        let trackers = try await API.shared.trackerList()
        let existingItemsDict = Dictionary(uniqueKeysWithValues: items.map { ($0.trackerId, $0) })
        
        for tracker in trackers {
            guard let label = tracker.label else { continue }
            guard let id = tracker.id else { continue }
            
            if let existingItem = existingItemsDict[Int64(id)] {
                existingItem.label = label
                existingItem.model = tracker.source?.model
                existingItem.deviceId = tracker.source?.deviceId
                if let gps = tracker.gps {
                    if let lat = gps.location?.lat {
                        existingItem.lat = lat
                    }
                    if let lng = gps.location?.lng {
                        existingItem.lng = lng
                    }
                    if let heading = gps.heading {
                        existingItem.heading = Int16(heading)
                    }
                    if gps.location?.lat != nil && gps.location?.lng != nil {
                        existingItem.visible = true
                    }
                }
                continue
            }
            
            let newItem = Item(context: viewContext)
            newItem.trackerId = Int64(id)
            newItem.label = label
            newItem.model = tracker.source?.model
            newItem.deviceId = tracker.source?.deviceId
            if tracker.gps?.location?.lat != nil,
                tracker.gps?.location?.lng != nil
            {
                newItem.visible = true
                newItem.lat = tracker.gps?.location?.lat ?? 0
                newItem.lng = tracker.gps?.location?.lng ?? 0
            }
            newItem.heading = Int16(tracker.gps?.heading ?? -1)
        }
        
        let ids = trackers
            .map { $0.id }
            .compactMap { $0 }
            .map { Int64($0) }
        let trackerIds = Set(ids)
        for item in items where !trackerIds.contains(item.trackerId) {
            viewContext.delete(item)
        }
        
        try viewContext.save()
    }
    
    func pollTrackGPS(_ viewContext: NSManagedObjectContext) async throws {
        let request = Item.fetchRequest()
        let items = try viewContext.fetch(request)
        let ids = items.map { Int($0.trackerId) }
        let gps = try await API.shared.trackerGetStates(for: ids)
        for item in items {
            let id = item.trackerId
            let gpsInfo = gps["\(id)"]
            if let lat = gpsInfo?.location?.lat {
                item.lat = lat
            }
            if let lng = gpsInfo?.location?.lng {
                item.lng = lng
            }
            if let heading = gpsInfo?.heading {
                item.heading = Int16(heading)
            }
        }
        
        /// Uncomment to test ``MapView`` UI updates
        /*
        for i in items {
            i.lat = Float.random(in: 40...53)
            i.lng = Float.random(in: 12...22)
            i.heading = Int16.random(in: 0...360)
        }
        */

        try viewContext.save()
    }
}
