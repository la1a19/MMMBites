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
                "displayName": trimmedUsername,
                "friendIDs": []
            ]

            try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .setData(userData)

            // Firebase auto-signs-in the new user. Sign them out so they have to
            // log in explicitly with their fresh credentials.
            try? Auth.auth().signOut()

            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
