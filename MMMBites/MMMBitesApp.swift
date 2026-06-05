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

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isLoggedIn {
                    AlbumsView()
                } else {
                    WelcomeView()
                }
            }
            .environmentObject(authViewModel)
        }
    }
}
