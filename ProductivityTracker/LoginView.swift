import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        ZStack {
            Theme.parchment.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                Text("hourglass")
                    .font(.custom("Georgia-Bold", size: 32))
                    .foregroundColor(Theme.logoColor)
                    .padding(.bottom, 8)
                Text("Welcome to Productivity Tracker")
                    .font(.title3)
                    .foregroundColor(Theme.darkAccentColor)
                    .padding(.bottom, 16)
                
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding(.horizontal)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                }
                
                Button(action: signIn) {
                    Text("Sign In")
                        .font(.custom("Georgia-Bold", size: 20))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.darkAccentColor)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                
                Button(action: { showSignUp = true }) {
                    Text("Don't have an account? Sign Up")
                        .foregroundColor(Theme.logoColor)
                        .font(.system(size: 16, weight: .medium))
                }
                Spacer()
            }
            .padding(.vertical)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showSignUp) {
                SignUpView()
            }
        }
    }
    
    private func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        ZStack {
            Theme.parchment.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                Text("Create Account")
                    .font(.custom("Georgia-Bold", size: 28))
                    .foregroundColor(Theme.logoColor)
                    .padding(.bottom, 8)
                
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding(.horizontal)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                }
                
                Button(action: signUp) {
                    Text("Sign Up")
                        .font(.custom("Georgia-Bold", size: 20))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.darkAccentColor)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                Spacer()
            }
            .padding(.vertical)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
        }
    }
    
    private func signUp() {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            showError = true
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                showError = true
            } else {
                dismiss()
            }
        }
    }
} 
