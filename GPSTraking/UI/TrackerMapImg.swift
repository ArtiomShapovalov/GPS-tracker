//
//  TrackerMapImg.swift
//  GPSTraking
//
//  Created by Artem Shapovalov on 01.05.2026.
//

import SwiftUI

struct TrackerMapImg: View {
    @ObservedObject var tracker: Item
    
    var body: some View {
        Image(systemName: getAnnotationImageName(tracker))
            .font(.title2)
            .foregroundColor(.blue)
            .rotationEffect(.degrees(Double(tracker.heading)))
            .shadow(radius: 2)
            .background(
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 34, height: 34)
                    .shadow(radius: 2)
            )
            .overlay {
                if let label = tracker.label {
                    Text(label)
                        .font(.system(size: 11).monospaced())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .background(Capsule().fill(.gray))
                        .frame(width: 100)
                        .padding(.top, 40)
                }
            }
    }
    
    private func getAnnotationImageName(_ item: Item) -> String {
        item.visible ? "arrow.up.circle.fill" : "circle.fill"
    }
}
