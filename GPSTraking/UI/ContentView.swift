//
//  ContentView.swift
//  GPSTraking
//
//  Created by Artem Shapovalov on 29.04.2026.
//

import SwiftUI
import CoreData

struct ContentView: View {
    
    enum ContentState {
        case loading
        case offline
        case online
        
        var text: String {
            switch self {
            case .loading:
                return "loading"
            case .offline:
                return "offline"
            case .online:
                return "online"
            }
        }
        
        var color: Color {
            switch self {
            case .loading, .offline:
                return .gray
            case .online:
                return .green
            }
        }
    }
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.trackerId, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    let mapModel = MapViewModel()
    @State private var state = ContentState.loading
    @State private var snackbarVisible = false
    private let poller = Poller(5)

    var body: some View {
        NavigationStack {
            main()
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        HStack {
                            Circle()
                                .foregroundStyle(state.color)
                                .frame(width: 10, height: 10)
                            Text(state.text)
                                .frame(width: 80)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    ToolbarItem(placement: .bottomBar) {
                        if state == .loading {
                            ProgressView().padding(.horizontal)
                        } else {
                            NavigationLink {
                                MapView(model: mapModel)
                            } label: {
                                Image(systemName: "map")
                            }
                            .padding(.horizontal)
                        }
                    }
                }
        }
        .task {
            await load()
            poller.start {
                Task {
                    await pollTrackerGPS()
                }
            }
        }
        .refreshable {
            await load()
        }
        .snackbar(isPresented: $snackbarVisible, message: "Can't load trackers")
    }
    
    @ViewBuilder
    private func main() -> some View {
        if items.isEmpty {
            Label("No trackers", systemImage: "trash")
        } else {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        TrackerDetailView(tracker: item)
                    } label: {
                        Text(item.label ?? "")
                    }
                }
            }
        }
    }
    
    private func load() async {
        do {
            state = .loading
            try await Storage.shared.receiveTracks(viewContext)
            mapModel.trackers = Array(items)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                state = .online
            }
        } catch {
            state = .offline
            withAnimation {
                snackbarVisible = true
            }
        }
    }
    
    private func pollTrackerGPS() async {
        try? await Storage.shared.pollTrackGPS(viewContext)
        mapModel.trackers = Array(items)
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
