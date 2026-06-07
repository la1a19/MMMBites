//
//  LoginViewModel.swift
//  MMMBites
//
//  Created by Lila Lansang on 4/6/2026.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class LoginViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var passwordResetSent = false
    @Published var currentUser: User?
    @Published var friendSearchResults: [User] = []
    @Published var friendSearchMessage = ""
    @Published var isSearchingFriends = false

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private let database = Firestore.firestore()

    init() {
        // Single source of truth: mirror Firebase's session state.
        // Fires immediately with the current user, then on every change.
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.isLoggedIn = (user != nil)
                if let uid = user?.uid {
                    await self?.fetchCurrentUser(uid: uid)
                } else {
                    self?.currentUser = nil
                    self?.friendSearchResults = []
                }
            }
        }
    }

    private func fetchCurrentUser(uid: String) async {
        do {
            let snapshot = try await database
                .collection("users")
                .document(uid)
                .getDocument()
            currentUser = try snapshot.data(as: User.self)
        } catch {
            errorMessage = "Couldn't load user profile: \(error.localizedDescription)"
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
            showError = true
        }
    }

    func forgotPassword(email: String) async {
        errorMessage = ""
        passwordResetSent = false
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Enter your email first"
            showError = true
            return
        }
        do {
            try await Auth.auth().sendPasswordReset(withEmail: trimmed)
            passwordResetSent = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func searchUsers(matching query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        friendSearchMessage = ""
        friendSearchResults = []

        guard trimmed.count >= 2 else {
            friendSearchMessage = "Type at least 2 characters"
            return
        }

        guard let currentUserID = Auth.auth().currentUser?.uid else {
            friendSearchMessage = "Log in before adding friends"
            return
        }

        isSearchingFriends = true
        defer { isSearchingFriends = false }

        do {
            let snapshot = try await database
                .collection("users")
                .whereField("username", isGreaterThanOrEqualTo: trimmed)
                .whereField("username", isLessThanOrEqualTo: trimmed + "\u{f8ff}")
                .limit(to: 12)
                .getDocuments()

            let existingFriendIDs = Set(currentUser?.friendIDs ?? [])
            friendSearchResults = snapshot.documents.compactMap { document in
                guard var user = try? document.data(as: User.self) else { return nil }
                user.id = user.id ?? document.documentID
                guard let userID = user.id,
                      userID != currentUserID,
                      !existingFriendIDs.contains(userID) else {
                    return nil
                }
                return user
            }

            if friendSearchResults.isEmpty {
                friendSearchMessage = "No matching users found"
            }
        } catch {
            friendSearchMessage = error.localizedDescription
        }
    }

    func addFriend(_ user: User) async {
        guard let currentUserID = Auth.auth().currentUser?.uid,
              let friendID = user.id else {
            friendSearchMessage = "Couldn't add this user"
            return
        }

        do {
            _ = try await database.runTransaction { transaction, _ in
                let currentRef = self.database.collection("users").document(currentUserID)
                let friendRef = self.database.collection("users").document(friendID)

                transaction.updateData([
                    "friendIDs": FieldValue.arrayUnion([friendID])
                ], forDocument: currentRef)

                transaction.updateData([
                    "friendIDs": FieldValue.arrayUnion([currentUserID])
                ], forDocument: friendRef)

                return nil
            }

            if currentUser?.friendIDs.contains(friendID) == false {
                currentUser?.friendIDs.append(friendID)
            }
            friendSearchResults.removeAll { $0.id == friendID }
            friendSearchMessage = "Added \(user.username)"
        } catch {
            friendSearchMessage = error.localizedDescription
        }
    }

    func addFriend(userID: String) async {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            friendSearchMessage = "Log in before adding friends"
            return
        }

        guard userID != currentUserID else {
            friendSearchMessage = "That's your own QR"
            return
        }

        guard currentUser?.friendIDs.contains(userID) != true else {
            friendSearchMessage = "You're already friends"
            return
        }

        do {
            let snapshot = try await database
                .collection("users")
                .document(userID)
                .getDocument()

            guard var user = try? snapshot.data(as: User.self) else {
                friendSearchMessage = "Couldn't find that user"
                return
            }

            user.id = user.id ?? snapshot.documentID
            await addFriend(user)
        } catch {
            friendSearchMessage = error.localizedDescription
        }
    }

    func removeFriend(_ user: User) async {
        guard let currentUserID = Auth.auth().currentUser?.uid,
              let friendID = user.id else {
            friendSearchMessage = "Couldn't remove this friend"
            return
        }

        do {
            _ = try await database.runTransaction { transaction, _ in
                let currentRef = self.database.collection("users").document(currentUserID)
                let friendRef = self.database.collection("users").document(friendID)

                transaction.updateData([
                    "friendIDs": FieldValue.arrayRemove([friendID])
                ], forDocument: currentRef)

                transaction.updateData([
                    "friendIDs": FieldValue.arrayRemove([currentUserID])
                ], forDocument: friendRef)

                return nil
            }

            currentUser?.friendIDs.removeAll { $0 == friendID }
            friendSearchResults.removeAll { $0.id == friendID }
            friendSearchMessage = "Removed \(user.username)"
        } catch {
            friendSearchMessage = error.localizedDescription
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
