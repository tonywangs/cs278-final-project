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
    
    var body: some View {
        if showLanding {
            LandingView(onStart: { withAnimation { showLanding = false } })
        } else if !authViewModel.isAuthenticated {
            LoginView()
                .environmentObject(authViewModel)
                .onAppear {
                    print("LoginView shown")
                    print("isAuthenticated: \(authViewModel.isAuthenticated)")
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
            }
            .background(Theme.parchment.ignoresSafeArea())
            .environment(\.font, .custom("Georgia", size: 18))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
      static var previews: some View {
          ContentView()
              .previewDevice("iPhone 16")
      }
  }
 