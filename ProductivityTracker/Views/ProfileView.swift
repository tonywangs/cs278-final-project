import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    var onLoginTap: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            Theme.parchment.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                Text("Profile")
                    .font(.custom("Georgia-Bold", size: 32))
                    .foregroundColor(Theme.logoColor)
                    .padding(.bottom, 8)
                
                if let email = authViewModel.user?.email {
                    VStack(spacing: 8) {
                        Text("Username")
                            .font(.headline)
                            .foregroundColor(Theme.darkAccentColor)
                        Text(email)
                            .font(.title3)
                            .foregroundColor(Theme.logoColor)
                            .padding(.bottom, 16)
                    }
                    Button(action: {
                        authViewModel.signOut()
                    }) {
                        Text("Log Out")
                            .font(.custom("Georgia-Bold", size: 20))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.darkAccentColor)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                } else {
                    Text("Not logged in")
                        .foregroundColor(.gray)
                    if let onLoginTap = onLoginTap {
                        Button(action: {
                            onLoginTap()
                        }) {
                            Text("Log In")
                                .font(.custom("Georgia-Bold", size: 20))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Theme.darkAccentColor)
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                    }
                }
                Spacer()
            }
            .padding(.vertical)
        }
    }
} 