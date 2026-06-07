//
//  EditProfileView.swift
//  MMMBites
//
//  Created by Lila Lansang on 6/6/2026.
//

import SwiftUI
import PhotosUI
import FirebaseFirestore
import FirebaseAuth

struct EditProfileView: View {
    @EnvironmentObject var viewModel: LoginViewModel
    @Environment(\.dismiss) var dismiss

    @State private var username = ""
    @State private var errorMessage = ""
    @State private var isSaving = false

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    
    var body: some View {
        let currentAvatarData = viewModel.currentUser?.avatarData
        let currentAvatarURL = viewModel.currentUser?.avatarURL

        return NavigationView {
            VStack(spacing: 0) {
                Text("Edit Profile")
                    .font(.title)
                    .bold()
                    .padding(.top, 24)

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    ZStack(alignment: .bottomTrailing) {
                        Group {
                            if let data = selectedImageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage).resizable().scaledToFill()
                            } else if let b64 = currentAvatarData,
                                      let data = Data(base64Encoded: b64),
                                      let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage).resizable().scaledToFill()
                            } else if let urlString = currentAvatarURL,
                                      let url = URL(string: urlString) {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Color.gray.opacity(0.2)
                                }
                            } else {
                                Image("minion").resizable().scaledToFill()
                            }
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())

                        Image(systemName: "camera.fill")
                            .font(.callout)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black)
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 16)
                .onChange(of: selectedPhotoItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            selectedImageData = data
                        }
                    }
                }

                Group {
                    AuthTextField(label: "Username", placeholder: "", input: $username)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal, 24)
                }
                
                PrimaryButton(title: isSaving ? "Saving..." : "Save") {
                    Task { await saveProfile() }
                }
                .padding(.horizontal, 50)
                .padding(.vertical, 30)
                
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            // pre-fill fields with current user data
            username = viewModel.currentUser?.username ?? ""
        }
    }
    
    private func saveProfile() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isSaving = true
        defer { isSaving = false }

        var updates: [String: Any] = [
            "username": username
        ]

        // If a new photo was picked: resize, JPEG-compress, base64-encode,
        // and save the string straight to the user doc. Keeps everything on the free Firestore tier.
        var newAvatarBase64: String?
        if let imageData = selectedImageData,
           let uiImage = UIImage(data: imageData),
           let compressed = uiImage.resizedToFit(maxDimension: 200).jpegData(compressionQuality: 0.7) {
            newAvatarBase64 = compressed.base64EncodedString()
            updates["avatarData"] = newAvatarBase64
        }

        do {
            try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .updateData(updates)

            // Update local cache so UI reflects changes immediately.
            viewModel.currentUser?.username = username
            if let newAvatarBase64 {
                viewModel.currentUser?.avatarData = newAvatarBase64
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private extension UIImage {
    /// Returns a copy scaled so its longest side equals `maxDimension`, preserving aspect ratio.
    func resizedToFit(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return self }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

#Preview {
    EditProfileView()
        .environmentObject(LoginViewModel())
}
