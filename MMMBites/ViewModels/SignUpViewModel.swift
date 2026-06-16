//
//  SignUpViewModel.swift
//  MMMBites
//
//  Created by Lila Lansang on 4/6/2026.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class SignUpViewModel: ObservableObject {
    @Published var errorMessage = ""
    @Published var isLoading = false

    func signUp(
        username: String,
        email: String,
        password: String,
        confirmPassword: String
    ) async -> Bool {
        errorMessage = ""

        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedUsername.isEmpty,
              !trimmedEmail.isEmpty,
              !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return false
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords don't match"
            return false
        }

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return false
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await Auth.auth().createUser(
                withEmail: trimmedEmail,
                password: password
            )
            let uid = result.user.uid

            let userData: [String: Any] = [
                "id": uid,
                "username": trimmedUsername,
                "email": trimmedEmail,
                "friendIDs": [],
                "createdAt": FieldValue.serverTimestamp()
            ]

            do {
                try await Firestore.firestore()
                    .collection("users")
                    .document(uid)
                    .setData(userData)
            } catch {
                // Roll back the Auth account so the same email can be reused
                // on retry — otherwise the user is locked out with an orphan
                // Auth record and no Firestore profile.
                try? await result.user.delete()
                throw error
            }

            // Keep the new user signed in — Firebase auto-signs them in on
            // createUser and the auth state listener will land them in the
            // app's main view directly.
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}


