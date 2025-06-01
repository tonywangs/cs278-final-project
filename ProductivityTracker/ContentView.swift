import SwiftUI
import FirebaseCore
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    
    init() {
        print("AuthViewModel initialized")
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isAuthenticated = user != nil
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showLanding = true
    @State private var showLogin = false
    
    var body: some View {
        Group {
            if showLanding {
                LandingView(onStart: {
                    withAnimation { showLanding = false }
                    // After landing, decide whether to show login or main app
                    if !authViewModel.isAuthenticated {
                        showLogin = true
                    }
                })
            } else if showLogin || !authViewModel.isAuthenticated {
                LoginView()
                    .environmentObject(authViewModel)
                    .onAppear {
                        print("LoginView shown")
                        print("isAuthenticated: \(authViewModel.isAuthenticated)")
                    }
                    .onChange(of: authViewModel.isAuthenticated) { isAuth in
                        if isAuth {
                            showLogin = false
                        }
                    }
            } else {
                TabView {
                    SocialFeedView()
                        .tabItem {
                            Label("Friends", systemImage: "person.2")
                        }
                    ProductivityGridView()
                        .tabItem {
                            Label("Today", systemImage: "calendar")
                        }
                    ProfileView(onLoginTap: {
                        showLogin = true
                    })
                        .environmentObject(authViewModel)
                        .tabItem {
                            Label("Profile", systemImage: "person.crop.circle")
                        }
                }
                .background(Theme.parchment.ignoresSafeArea())
                .environment(\.font, .custom("Georgia", size: 18))
                .onAppear {
                    print("Main TabView appeared")
                }
            }
        }
        .onAppear {
            print("ContentView appeared")
            print("Initial showLanding value: \(showLanding)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
      static var previews: some View {
          ContentView()
              .previewDevice("iPhone 16")
      }
  }
 