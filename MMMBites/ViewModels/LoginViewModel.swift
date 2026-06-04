//
//  LoginViewModel.swift
//  MMMBites
//
//  Created by Lila Lansang on 4/6/2026.
//

import SwiftUI
import FirebaseAuth
import Combine

class LoginViewModel : ObservableObject {
    @Published var isLoggedIn = false
    @Published var errorMessage = ""
    
    func login(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
          guard let self = self else { return }
          
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                self.isLoggedIn = true
            }
        }
    }
    
    func signup(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
          guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                self.isLoggedIn = true
            }
        }
    }
    
    func forgotPassword(email: String) {
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
          guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func rememberPassword(email: String, password: String) {
        
    }
    
    func logout() {
        try? Auth.auth().signOut()
        self.isLoggedIn = false
    }
}
