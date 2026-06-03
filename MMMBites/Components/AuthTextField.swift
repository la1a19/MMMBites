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
    let placeholder : String //the grey hint text
    @Binding var input : String //user input
    var type : AuthFieldType = .plain //default to plain, unless passed as secure
    
    
    
    var body: some View {
        Group {
            if type == .password {
                SecureField (placeholder, text: $input)
            } else {
                TextField(placeholder, text: $input)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .autocorrectionDisabled()
        #if os(iOS)
        .textInputAutocapitalization(.never)
        #endif
    }
}

#Preview {
    AuthTextField(placeholder: "Email", input: .constant(""))
        .padding()
}
