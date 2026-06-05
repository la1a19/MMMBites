//
//  LoginViewModel.swift
//  MMMBites
//
//  Created by Lila Lansang on 4/6/2026.
//

import SwiftUI
import FirebaseAuth
import Combine

@MainActor
class LoginViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var errorMessage = ""
    @Published var passwordResetSent = false

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        // Single source of truth: mirror Firebase's session state.
        // Fires immediately with the current user, then on every change.
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.isLoggedIn = (user != nil)
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func login(email: String, password: String) async {
        errorMessage = ""
        passwordResetSent = false
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func forgotPassword(email: String) async {
        errorMessage = ""
        passwordResetSent = false
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Enter your email first"
            return
        }
        do {
            try await Auth.auth().sendPasswordReset(withEmail: trimmed)
            passwordResetSent = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
