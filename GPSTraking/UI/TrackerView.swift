//
//  TrackerView.swift
//  GPSTraking
//
//  Created by Artem Shapovalov on 30.04.2026.
//

import SwiftUI

struct TrackerDetailView: View {
    @ObservedObject var tracker: Item
    private var blockedStr: String {
        tracker.blocked == true ? "Yes" : "No"
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    Label("Model", systemImage: "cpu")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(tracker.model ?? "—")
                        .fontWeight(.medium)
                }
                
                HStack {
                    Label("Device ID", systemImage: "qrcode")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(tracker.deviceId ?? "—")
                        .font(.body.monospaced())
                }
                
                if tracker.visible {
                    HStack {
                        Label("Location", systemImage: "map")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(tracker.lat):\(tracker.lng)")
                            .font(.system(size: 12).monospaced())
                        if tracker.heading >= 0 {
                            Text("\(tracker.heading)°")
                                .font(.body.monospaced())
                                .padding(.leading)
                        }
                    }
                }
            }
                
            DisclosureGroup("More Info") {
                DetailRow(title: "ID", value: "\(tracker.trackerId)")
                DetailRow(title: "Blocked", value: blockedStr)
                if let creationDate = tracker.creationDate {
                    DetailRow(title: "Creation Date", value: creationDate.string)
                }
                if let phone = tracker.phone {
                    DetailRow(title: "Phone", value: phone)
                }
            }
            
        }
        .navigationTitle(tracker.label ?? "Tracker Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }
}
