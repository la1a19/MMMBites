//
//  AuthTextField.swift
//  MMMBites
//
//  Created by Lila Lansang on 3/6/2026.
//

import SwiftUI

enum AuthFieldType {
    case plain
    case password
}

struct AuthTextField: View {
    let label: String       // the label on top
    let placeholder: String // hint inside
    @Binding var input: String
    var type: AuthFieldType = .plain
    var icon: String? = nil

    @FocusState private var isFocused: Bool
    @State private var showPassword = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(AppFont.caption)
                .foregroundColor(isFocused ? AppColor.primary : AppColor.inkMuted)
                .padding(.leading, 6)
                .animation(AppAnimation.quick, value: isFocused)

            HStack(spacing: 10) {
                if let icon {
                    Image(systemName: icon)
                        .foregroundColor(isFocused ? AppColor.primary : AppColor.inkFaint)
                        .font(.clash(16, weight: .medium))
                        .animation(AppAnimation.quick, value: isFocused)
                }

                Group {
                    if type == .password && !showPassword {
                        SecureField(placeholder, text: $input)
                    } else {
                        TextField(placeholder, text: $input)
                    }
                }
                .font(AppFont.body)
                .foregroundColor(AppColor.ink)
                .focused($isFocused)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif

                if type == .password && !input.isEmpty {
                    Button {
                        showPassword.toggle()
                        Haptics.tap()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(AppColor.inkFaint)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                    .fill(Color.white.opacity(isFocused ? 0.95 : 0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                    .stroke(
                        isFocused ? AppColor.primary.opacity(0.6) : Color.white.opacity(0.5),
                        lineWidth: isFocused ? 1.5 : 1
                    )
            )
            .shadow(
                color: isFocused ? AppColor.primary.opacity(0.18) : Color.black.opacity(0.04),
                radius: isFocused ? 10 : 4,
                y: 3
            )
            .animation(AppAnimation.snappy, value: isFocused)
            .animation(AppAnimation.snappy, value: input.isEmpty)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        AuthTextField(label: "Email", placeholder: "example@gmail.com", input: .constant(""), icon: "envelope.fill")
        AuthTextField(label: "Password", placeholder: "••••••••", input: .constant("secret"), type: .password, icon: "lock.fill")
    }
    .padding()
    .background(AppBackground())
}
