//
//  Snackbar.swift
//  GPSTraking
//
//  Created by Artem Shapovalov on 30.04.2026.
//

import SwiftUI

struct SnackbarModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let duration: TimeInterval
    let dispatchHelper = DispatchHelper()
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if isPresented {
                    SnackbarView(message: message) {
                        dispatchHelper.item?.cancel()
                        withAnimation(.spring()) {
                            isPresented = false
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        dispatchHelper.item?.cancel()
                        let newDispatchItem = DispatchWorkItem {
                            withAnimation {
                                isPresented = false
                            }
                        }
                        dispatchHelper.item = newDispatchItem
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration,
                                                      execute: newDispatchItem)
                    }
                }
            }
            .animation(.spring(), value: isPresented)
    }
}

struct SnackbarView: View {
    let message: String
    let onDismiss: () -> Void

    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.8))
            .cornerRadius(20)
            .padding(.bottom, 50)
            .offset(y: dragOffset)
            .gesture(
                DragGesture(minimumDistance: 10)
                    .updating($dragOffset) { value, state, _ in
                        let translation = value.translation.height
                        if translation > 0 {
                            state = translation
                        }
                    }
                    .onEnded { value in
                        let translation = value.translation.height
                        let velocity = value.predictedEndTranslation.height
                        if translation > 60 || velocity > 500 {
                            onDismiss()
                        }
                    }
            )
            .animation(.interactiveSpring(), value: dragOffset)
    }
}

extension View {
    func snackbar(isPresented: Binding<Bool>,
                  message: String,
                  duration: TimeInterval = 5.0)
    -> some View {
        modifier(SnackbarModifier(isPresented: isPresented,
                                  message: message,
                                  duration: duration))
    }
}
