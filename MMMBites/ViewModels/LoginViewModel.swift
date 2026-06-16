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
                    await self?.fetchCurrentUser(uid: uid)
                    self?.startFriendRequestListeners(for: uid)
                } else {
                    self?.activeSessionUserID = nil
                    self?.memoryBoardHintSeenUserIDsForSession.removeAll()
                    self?.currentUser = nil
                    self?.friendSearchResults = []
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

    private func fetchCurrentUser(uid: String) async {
        // Sign-ups race the auth state listener: createUser fires the listener
        // immediately, but the Firestore user doc is written a moment later.
        // Retry a few times so a brand-new account doesn't land in the app
        // with currentUser unset.
        for attempt in 0..<4 {
            do {
                let snapshot = try await database
                    .collection("users")
                    .document(uid)
                    .getDocument()
                if snapshot.exists {
                    var user = try snapshot.data(as: User.self)
                    // Backfill the email field if it was missing on older docs.
                    if user.email == nil, let authEmail = Auth.auth().currentUser?.email {
                        user.email = authEmail
                        try? await database
                            .collection("users")
                            .document(uid)
                            .setData(["email": authEmail], merge: true)
                    }
                    currentUser = user
                    return
                }
            } catch {
                errorMessage = "Couldn't load user profile: \(error.localizedDescription)"
                return
            }

            if attempt < 3 {
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
        }
        // Doc never appeared. Leave currentUser nil silently — surfacing an
        // error here would also fire on legitimate edge cases (e.g. a
        // half-cleaned-up account) and isn't actionable for the user.
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
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

            currentUser?.friendIDs.removeAll { $0 == friendID }
            friendSearchResults.removeAll { $0.id == friendID }
            friendSearchMessage = "Removed \(user.username)"
        } catch {
            friendSearchMessage = error.localizedDescription
            ToastCenter.shared.showError("Couldn't remove friend. Try again.")
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
