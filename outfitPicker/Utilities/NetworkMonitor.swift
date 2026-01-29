//
//  NetworkMonitor.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//  Network Connectivity Monitoring
//

import Foundation
import Network
import SwiftUI

// MARK: - Network Monitor

@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published private(set) var isConnected: Bool = true
    @Published private(set) var connectionType: ConnectionType = .unknown
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
    
    private init() {
        startMonitoring()
    }
    
    nonisolated func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let connected = path.status == .satisfied
            let connType = self.getConnectionType(path)
            Task { @MainActor in
                self.isConnected = connected
                self.connectionType = connType
            }
        }
        monitor.start(queue: queue)
    }
    
    nonisolated func stopMonitoring() {
        monitor.cancel()
    }
    
    nonisolated private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        }
        return .unknown
    }
}

// MARK: - Offline Banner View

struct OfflineBanner: View {
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @State private var isVisible: Bool = false
    
    var body: some View {
        Group {
            if !networkMonitor.isConnected {
                HStack(spacing: 12) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 16, weight: .semibold))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("You're Offline")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Some features are unavailable")
                            .font(.system(size: 12))
                            .opacity(0.8)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Haptic feedback
                        HapticFeedback.light()
                    }) {
                        Text("Retry")
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.9), Color.gray.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: networkMonitor.isConnected)
    }
}

// MARK: - Compact Offline Indicator

struct OfflineIndicator: View {
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 6) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 12, weight: .semibold))
                Text("Offline")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.gray.opacity(0.8))
            .clipShape(Capsule())
        }
    }
}

// MARK: - View Modifier for Offline Handling

struct OfflineModifier: ViewModifier {
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    let offlineContent: () -> AnyView
    
    func body(content: Content) -> some View {
        if networkMonitor.isConnected {
            content
        } else {
            offlineContent()
        }
    }
}

extension View {
    /// Shows alternative content when offline
    func whenOffline<OfflineView: View>(@ViewBuilder content: @escaping () -> OfflineView) -> some View {
        modifier(OfflineModifier(offlineContent: { AnyView(content()) }))
    }
    
    /// Disables the view when offline
    func disableWhenOffline() -> some View {
        modifier(DisableWhenOfflineModifier())
    }
}

struct DisableWhenOfflineModifier: ViewModifier {
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    
    func body(content: Content) -> some View {
        content
            .disabled(!networkMonitor.isConnected)
            .opacity(networkMonitor.isConnected ? 1.0 : 0.5)
    }
}

// MARK: - Offline Overlay for Blocked Features

struct OfflineFeatureOverlay: View {
    let featureName: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.cleanTextTertiary)
            
            Text("\(featureName) Requires Internet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.cleanTextPrimary)
            
            Text("Connect to the internet to use this feature")
                .font(.system(size: 14))
                .foregroundColor(.cleanTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cleanBackground.opacity(0.95))
    }
}

// MARK: - Previews

#Preview("Offline Banner") {
    VStack {
        OfflineBanner()
        Spacer()
    }
    .background(Color.cleanBackground)
}

#Preview("Offline Indicator") {
    OfflineIndicator()
        .padding()
        .background(Color.cleanBackground)
}
