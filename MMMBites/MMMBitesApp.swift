//
//  MMMBitesApp.swift
//  MMMBites
//
//  Created by Lila Lansang on 3/6/2026.
//

import SwiftUI
import FirebaseCore

@main
struct MMMBitesApp: App {
    @StateObject private var authViewModel = LoginViewModel()
    @AppStorage("pref.appearance") private var appearanceRaw: String = AppearanceMode.system.rawValue

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isLoggedIn {
                    MainAlbumsContainerView()
                } else {
                    WelcomeView()
                }
            }
            .environmentObject(authViewModel)
            .preferredColorScheme(colorScheme(for: AppearanceMode(rawValue: appearanceRaw) ?? .system))
        }
    }

    private func colorScheme(for mode: AppearanceMode) -> ColorScheme? {
        switch mode {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}
