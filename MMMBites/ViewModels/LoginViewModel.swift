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
    @Published var incomingRequests: [FriendRequest] = []
    @Published var outgoingRequests: [FriendRequest] = []

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var currentUserListener: ListenerRegistration?
    private var incomingRequestListener: ListenerRegistration?
    private var outgoingRequestListener: ListenerRegistration?
    private var activeSessionUserID: String?
    private var memoryBoardHintSeenUserIDsForSession: Set<String> = []
    private let database = Firestore.firestore()

    init() {
        // Single source of truth: mirror Firebase's session state.
        // Fires immediately with the current user, then on every change.
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.isLoggedIn = (user != nil)
                if let uid = user?.uid {
                    self?.startLoginSessionIfNeeded(for: uid)
                    self?.startCurrentUserListener(for: uid)
                    self?.startFriendRequestListeners(for: uid)
                } else {
                    self?.activeSessionUserID = nil
                    self?.memoryBoardHintSeenUserIDsForSession.removeAll()
                    self?.currentUser = nil
                    self?.friendSearchResults = []
                    self?.stopCurrentUserListener()
                    self?.stopFriendRequestListeners()
                }
            }
        }
    }

    private func startLoginSessionIfNeeded(for userID: String) {
        guard activeSessionUserID != userID else { return }
        activeSessionUserID = userID
        memoryBoardHintSeenUserIDsForSession.removeAll()
    }

    func shouldPresentMemoryBoardInteractionHint() -> Bool {
        guard let userID = currentUser?.id ?? activeSessionUserID else { return false }
        guard !memoryBoardHintSeenUserIDsForSession.contains(userID) else { return false }

        memoryBoardHintSeenUserIDsForSession.insert(userID)
        return true
    }

    // Real-time listener for the signed-in user's own profile doc. Replaces
    // a one-shot fetch so that changes made by other clients — most notably
    // friend accepts that mutate this user's `friendIDs` — show up live
    // without requiring a logout/login.
    private func startCurrentUserListener(for uid: String) {
        currentUserListener?.remove()
        currentUserListener = database
            .collection("users")
            .document(uid)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }
                    if let error {
                        print("[LoginViewModel] current user listen error: \(error)")
                        return
                    }
                    guard let snapshot, snapshot.exists else {
                        // Sign-up race: the auth listener fires before the
                        // Firestore doc is written. The listener keeps watching
                        // and will populate `currentUser` once the doc appears.
                        return
                    }
                    do {
                        var user = try snapshot.data(as: User.self)
                        // Backfill the email field if it was missing on older docs.
                        if user.email == nil, let authEmail = Auth.auth().currentUser?.email {
                            user.email = authEmail
                            try? await self.database
                                .collection("users")
                                .document(uid)
                                .setData(["email": authEmail], merge: true)
                        }
                        self.currentUser = user
                    } catch {
                        print("[LoginViewModel] current user decode error: \(error)")
                    }
                }
            }
    }

    private func stopCurrentUserListener() {
        currentUserListener?.remove()
        currentUserListener = nil
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        currentUserListener?.remove()
        incomingRequestListener?.remove()
        outgoingRequestListener?.remove()
    }

    private func startFriendRequestListeners(for userID: String) {
        stopFriendRequestListeners()

        incomingRequestListener = database.collection("friendRequests")
            .whereField("toUserId", isEqualTo: userID)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    if let error {
                        print("[LoginViewModel] incoming request error: \(error)")
                        return
                    }
                    self?.incomingRequests = snapshot?.documents.compactMap {
                        try? $0.data(as: FriendRequest.self)
                    } ?? []
                }
            }

        outgoingRequestListener = database.collection("friendRequests")
            .whereField("fromUserId", isEqualTo: userID)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    if let error {
                        print("[LoginViewModel] outgoing request error: \(error)")
                        return
                    }
                    self?.outgoingRequests = snapshot?.documents.compactMap {
                        try? $0.data(as: FriendRequest.self)
                    } ?? []
                }
            }
    }

    private func stopFriendRequestListeners() {
        incomingRequestListener?.remove()
        outgoingRequestListener?.remove()
        incomingRequestListener = nil
        outgoingRequestListener = nil
        incomingRequests = []
        outgoingRequests = []
    }

    func login(email: String, password: String) async {
        errorMessage = ""
        passwordResetSent = false
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try await Auth.auth().signIn(withEmail: trimmedEmail, password: password)
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
        } catch let error as NSError {
            // Silently treat "user not found" as success — surfacing it would
            // let anyone enumerate which emails are registered.
            if error.code != AuthErrorCode.userNotFound.rawValue {
                errorMessage = error.localizedDescription
                showError = true
                return
            }
        }
        passwordResetSent = true
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
            let pendingOutgoing = Set(outgoingRequests.map(\.toUserId))
            let pendingIncoming = Set(incomingRequests.map(\.fromUserId))
            friendSearchResults = snapshot.documents.compactMap { document in
                guard var user = try? document.data(as: User.self) else { return nil }
                user.id = user.id ?? document.documentID
                guard let userID = user.id,
                      userID != currentUserID,
                      !existingFriendIDs.contains(userID),
                      !pendingOutgoing.contains(userID),
                      !pendingIncoming.contains(userID) else {
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

    func sendFriendRequest(to user: User) async {
        guard let currentUserID = Auth.auth().currentUser?.uid,
              let friendID = user.id,
              let me = currentUser else {
            friendSearchMessage = "Couldn't send request"
            return
        }

        guard friendID != currentUserID else {
            friendSearchMessage = "That's you"
            return
        }

        guard !me.friendIDs.contains(friendID) else {
            friendSearchMessage = "You're already friends"
            return
        }

        // If they've already sent us a request, accept it instead of creating
        // a duplicate outgoing one — feels natural and avoids stuck states.
        if let pendingIncoming = incomingRequests.first(where: { $0.fromUserId == friendID }) {
            await acceptFriendRequest(pendingIncoming)
            return
        }

        guard !outgoingRequests.contains(where: { $0.toUserId == friendID }) else {
            friendSearchMessage = "Request already sent"
            return
        }

        let docID = FriendRequest.documentID(fromUserId: currentUserID, toUserId: friendID)
        let request = FriendRequest(
            id: docID,
            fromUserId: currentUserID,
            toUserId: friendID,
            fromUsername: me.username,
            fromAvatarData: me.avatarData,
            toUsername: user.username,
            toAvatarData: user.avatarData
        )

        do {
            try database.collection("friendRequests").document(docID).setData(from: request)
            friendSearchResults.removeAll { $0.id == friendID }
            friendSearchMessage = "Request sent to \(user.username)"
        } catch {
            friendSearchMessage = error.localizedDescription
        }
    }

    func sendFriendRequest(toUserID userID: String) async {
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
            await sendFriendRequest(to: user)
        } catch {
            friendSearchMessage = error.localizedDescription
        }
    }

    func acceptFriendRequest(_ request: FriendRequest) async {
        guard let currentUserID = Auth.auth().currentUser?.uid,
              currentUserID == request.toUserId,
              let docID = request.id else {
            friendSearchMessage = "Couldn't accept request"
            return
        }

        do {
            _ = try await database.runTransaction { transaction, _ in
                let meRef = self.database.collection("users").document(currentUserID)
                let themRef = self.database.collection("users").document(request.fromUserId)
                let requestRef = self.database.collection("friendRequests").document(docID)

                transaction.updateData([
                    "friendIDs": FieldValue.arrayUnion([request.fromUserId])
                ], forDocument: meRef)

                transaction.updateData([
                    "friendIDs": FieldValue.arrayUnion([currentUserID])
                ], forDocument: themRef)

                transaction.deleteDocument(requestRef)
                return nil
            }

            if currentUser?.friendIDs.contains(request.fromUserId) == false {
                currentUser?.friendIDs.append(request.fromUserId)
            }
            friendSearchMessage = "You're now friends with \(request.fromUsername)"
        } catch {
            friendSearchMessage = error.localizedDescription
        }
    }

    func declineFriendRequest(_ request: FriendRequest) async {
        guard let docID = request.id else { return }
        do {
            try await database.collection("friendRequests").document(docID).delete()
        } catch {
            friendSearchMessage = error.localizedDescription
        }
    }

    func cancelFriendRequest(_ request: FriendRequest) async {
        guard let docID = request.id else { return }
        do {
            try await database.collection("friendRequests").document(docID).delete()
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

            // Best-effort revoke shared-album access on both sides. Not atomic
            // with the friendship removal — if any per-album write fails, the
            // friendship is still gone and the user can retry by unfriending
            // again. Without this step the ex-friend would keep seeing every
            // shared album and its memories.
            await revokeSharedAlbumAccess(currentUserID: currentUserID, friendID: friendID)

            currentUser?.friendIDs.removeAll { $0 == friendID }
            friendSearchResults.removeAll { $0.id == friendID }
            friendSearchMessage = "Removed \(user.username)"
        } catch {
            friendSearchMessage = error.localizedDescription
            ToastCenter.shared.showError("Couldn't remove friend. Try again.")
        }
    }

    private func revokeSharedAlbumAccess(currentUserID: String, friendID: String) async {
        do {
            // My owned albums that include the friend — remove them. I'm owner
            // so the rule allows arbitrary friendIds edits.
            let myAlbums = try await database.collection("albums")
                .whereField("ownerId", isEqualTo: currentUserID)
                .getDocuments()
            for doc in myAlbums.documents {
                let friendIds = (doc.data()["friendIds"] as? [String]) ?? []
                guard friendIds.contains(friendID) else { continue }
                try? await doc.reference.updateData([
                    "friendIds": FieldValue.arrayRemove([friendID])
                ])
            }

            // Albums I'm a friend on, owned by the friend — remove myself. Rule
            // allows self-removal from any album's friendIds.
            let sharedAlbums = try await database.collection("albums")
                .whereField("friendIds", arrayContains: currentUserID)
                .getDocuments()
            for doc in sharedAlbums.documents {
                guard (doc.data()["ownerId"] as? String) == friendID else { continue }
                try? await doc.reference.updateData([
                    "friendIds": FieldValue.arrayRemove([currentUserID])
                ])
            }
        } catch {
            print("[LoginViewModel] revoke shared album access error: \(error)")
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateCustomTags(_ tags: [String]) async {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        do {
            try await database.collection("users").document(currentUserID).setData(
                ["customTags": tags],
                merge: true
            )
            currentUser?.customTags = tags
        } catch {
            errorMessage = error.localizedDescription
            ToastCenter.shared.showError("Couldn't save tags. Try again.")
        }
    }

    func updateAvatar(_ data: Data?) async {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }

        let base64String: String?
        if let data, let resized = Self.resizedAvatarData(from: data) {
            base64String = resized.base64EncodedString()
        } else {
            base64String = nil
        }

        do {
            try await database.collection("users").document(currentUserID).setData(
                ["avatarData": base64String as Any],
                merge: true
            )
            currentUser?.avatarData = base64String
        } catch {
            errorMessage = "Couldn't save profile photo: \(error.localizedDescription)"
            showError = true
            ToastCenter.shared.showError("Couldn't save profile photo.")
        }
    }

    /// Down-samples to a 256-pt square JPEG so the base64 string fits comfortably
    /// in a Firestore document.
    private static func resizedAvatarData(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let target: CGFloat = 256
        let targetSize = CGSize(width: target, height: target)
        let aspect = image.size.width / max(image.size.height, 1)
        let drawRect: CGRect
        if aspect > 1 {
            let width = target * aspect
            drawRect = CGRect(x: (target - width) / 2, y: 0, width: width, height: target)
        } else {
            let height = target / aspect
            drawRect = CGRect(x: 0, y: (target - height) / 2, width: target, height: height)
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let resized = renderer.image { _ in
            image.draw(in: drawRect)
        }
        return resized.jpegData(compressionQuality: 0.75)
    }
}
