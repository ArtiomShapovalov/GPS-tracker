//
//  MapView.swift
//  GPSTraking
//
//  Created by Artem Shapovalov on 01.05.2026.
//

import SwiftUI
import MapKit
import Combine

final class MapViewModel: ObservableObject {
    @Published var trackers: [Item] = []
}

struct MapView: View {
    @State private var cameraPosition: MapCameraPosition = .automatic
    @ObservedObject var model: MapViewModel
    
    var body: some View {
        Map(position: $cameraPosition) {
            ForEach(model.trackers) { tracker in
                Annotation(tracker.label ?? "", coordinate: getCoord(tracker)) {
                    TrackerMapImg(tracker: tracker)
                }
            }
        }
        .mapStyle(.standard)
        .onAppear {
            guard let region = calculateRegion(for: model.trackers.map { $0 }) else {
                return
            }
            withAnimation {
                cameraPosition = .region(region)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if !model.trackers.isEmpty {
                Button(action: resetCameraPosition) {
                    Image(systemName: "location.viewfinder")
                        .padding(12)
                        .background(.background)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding()
            }
        }
    }
    
    private func getCoord(_ item: Item) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: CLLocationDegrees(item.lat),
                               longitude: CLLocationDegrees(item.lng))
    }

    private func calculateRegion(for trackers: [Item]) -> MKCoordinateRegion? {
        guard !trackers.isEmpty else { return nil }
        
        var minLat = trackers[0].lat
        var maxLat = trackers[0].lat
        var minLng = trackers[0].lng
        var maxLng = trackers[0].lng
        
        for tracker in trackers {
            minLat = min(minLat, tracker.lat)
            maxLat = max(maxLat, tracker.lat)
            minLng = min(minLng, tracker.lng)
            maxLng = max(maxLng, tracker.lng)
        }
        
        let latPadding = (maxLat - minLat) * 0.1
        let lngPadding = (maxLng - minLng) * 0.1
        
        let centerLat = (minLat + maxLat) / 2
        let centerLng = (minLng + maxLng) / 2
        let spanLat = (maxLat - minLat) + latPadding * 2
        let spanLng = (maxLng - minLng) + lngPadding * 2
        
        let minSpan: Float = 0.01
        let finalSpanLat = max(spanLat, minSpan)
        let finalSpanLng = max(spanLng, minSpan)
        
        let center = CLLocationCoordinate2D(latitude: CLLocationDegrees(centerLat),
                                            longitude: CLLocationDegrees(centerLng))
        let span = MKCoordinateSpan(latitudeDelta: CLLocationDegrees(finalSpanLat),
                                    longitudeDelta: CLLocationDegrees(finalSpanLng))
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    private func resetCameraPosition() {
        if let region = calculateRegion(for: model.trackers.map { $0 }) {
            withAnimation {
                cameraPosition = .region(region)
            }
        }
    }
}
