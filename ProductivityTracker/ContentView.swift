import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    private let db = Firestore.firestore()
    
    init() {
        print("AuthViewModel initialized")
        Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            self?.isAuthenticated = firebaseUser != nil
            
            if let firebaseUser = firebaseUser {
                // Load user profile from Firestore
                self?.loadUserProfile(for: firebaseUser)
            } else {
                self?.user = nil
            }
        }
    }
    
    private func loadUserProfile(for firebaseUser: FirebaseAuth.User) {
        print("Loading user profile for uid: \(firebaseUser.uid)")
        
        db.collection("users").document(firebaseUser.uid).getDocument { [weak self] document, error in
            if let error = error {
                print("Error loading user profile: \(error)")
                return
            }
            
            if let document = document, document.exists {
                do {
                    print("Document data: \(document.data() ?? [:])")
                    let userData = try document.data(as: User.self)
                    print("Successfully decoded user: \(userData.username)")
                    DispatchQueue.main.async {
                        self?.user = userData
                    }
                } catch {
                    print("Error decoding user data: \(error)")
                    print("Document data: \(document.data() ?? [:])")
                    
                    // Try to create missing profile from existing Firebase user
                    if let email = firebaseUser.email {
                        print("Attempting to recreate user profile...")
                        self?.createUserProfile(for: firebaseUser, username: email.components(separatedBy: "@").first ?? "User")
                    }
                }
            } else {
                print("User profile not found in Firestore for uid: \(firebaseUser.uid)")
                // User profile doesn't exist - create one
                if let email = firebaseUser.email {
                    print("Creating new user profile...")
                    self?.createUserProfile(for: firebaseUser, username: email.components(separatedBy: "@").first ?? "User")
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    func createUserProfile(for firebaseUser: FirebaseAuth.User, username: String) {
        let newUser = User(from: firebaseUser, username: username)
        print("Creating user profile for: \(newUser.username) with uid: \(newUser.uid)")
        
        // Use setData with merge to handle any existing partial data
        let userData: [String: Any] = [
            "uid": newUser.uid,
            "email": newUser.email,
            "username": newUser.username,
            "following": newUser.following,
            "followers": newUser.followers,
            "createdAt": newUser.createdAt,
            "lastActive": newUser.lastActive
        ]
        
        db.collection("users").document(firebaseUser.uid).setData(userData, merge: true) { [weak self] error in
            if let error = error {
                print("Error creating user profile: \(error)")
            } else {
                print("User profile created successfully")
                DispatchQueue.main.async {
                    self?.user = newUser
                }
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showLanding = true
    @State private var showLogin = false
    @State private var selectedTab = 0 // 0: Social, 1: Hourglass, 2: Profile
    
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
                TabView(selection: $selectedTab) {
                    SocialFeedView()
                        .tabItem {
                            Label("Friends", systemImage: "person.2")
                        }
                        .tag(0)
                    ProductivityGridView()
                        .tabItem {
                            Label("Today", systemImage: "calendar")
                        }
                        .tag(1)
                    ProfileView(onLoginTap: {
                        showLogin = true
                    })
                        .environmentObject(authViewModel)
                        .tabItem {
                            Label("Profile", systemImage: "person.crop.circle")
                        }
                        .tag(2)
                }
                .background(Theme.parchment.ignoresSafeArea())
                .environment(\.font, .custom("Georgia", size: 18))
                .onAppear {
                    print("Main TabView appeared")
                    setupNotificationObserver()
                }
            }
        }
        .onAppear {
            print("ContentView appeared")
            print("Initial showLanding value: \(showLanding)")
        }
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SwitchToHourglassTab"),
            object: nil,
            queue: .main
        ) { _ in
            selectedTab = 1 // Switch to hourglass tab
        }
    }
}

struct ContentView_Previews: PreviewProvider {
      static var previews: some View {
          ContentView()
              .previewDevice("iPhone 16")
      }
  }
 