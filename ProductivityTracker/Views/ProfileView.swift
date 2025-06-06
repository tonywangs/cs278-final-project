import SwiftUI
import FirebaseFirestore

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    var onLoginTap: (() -> Void)? = nil
    
    @State private var username: String = ""
    @State private var following: [UserProfile] = []
    @State private var searchUsername: String = ""
    @State private var searchResult: UserProfile? = nil
    @State private var errorMessage: String? = nil
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Theme.parchment.ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                Text("Profile")
                    .font(.custom("Georgia-Bold", size: 32))
                    .foregroundColor(Theme.logoColor)
                    .padding(.bottom, 8)
                
                if let user = authViewModel.user {
                    VStack(spacing: 8) {
                        Text("Username")
                            .font(.headline)
                            .foregroundColor(Theme.darkAccentColor)
                        HStack(spacing: 8) {
                            Text(username)
                                .font(.title3)
                                .foregroundColor(Theme.logoColor)
                            TextField("New username", text: $searchUsername)
                                .font(.system(size: 14))
                                .frame(width: 100)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                            Button(action: {
                                changeUsername(newUsername: searchUsername, uid: user.uid)
                            }) {
                                Text("Change")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Theme.darkAccentColor)
                                    .cornerRadius(6)
                            }
                        }
                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        Text(user.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .onAppear {
                        fetchUserProfile(uid: user.uid)
                        fetchFollowing(uid: user.uid)
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
                    Divider().padding(.vertical, 8)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Following")
                            .font(.headline)
                            .foregroundColor(Theme.darkAccentColor)
                        if following.isEmpty {
                            Text("Not following anyone yet.")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(following) { user in
                                HStack {
                                    Text("@\(user.username)")
                                        .foregroundColor(Theme.logoColor)
                                    Spacer()
                                    Button("Unfollow") {
                                        unfollowUser(currentUID: authViewModel.user?.uid ?? "", targetUID: user.uid)
                                    }
                                    .foregroundColor(.red)
                                    .font(.caption)
                                }
                            }
                        }
                    }
                    // Friend search and add section
                    Divider().padding(.vertical, 8)
                    VStack(spacing: 8) {
                        TextField("Enter username to follow", text: $searchUsername)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .padding(.horizontal)
                        Button("Search") {
                            searchUser(byUsername: searchUsername)
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Theme.darkAccentColor)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        if let result = searchResult {
                            HStack {
                                Text("@\(result.username)")
                                    .foregroundColor(Theme.logoColor)
                                Spacer()
                                Button("Follow") {
                                    if let user = authViewModel.user {
                                        if following.contains(where: { $0.uid == result.uid }) {
                                            errorMessage = "Already following."
                                        } else {
                                            followUser(currentUID: user.uid, targetUID: result.uid)
                                        }
                                    }
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Theme.logoColor)
                                .cornerRadius(8)
                            }
                            .padding(.horizontal)
                        }
                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                        }
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
    
    // Fetch the user's username
    func fetchUserProfile(uid: String) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { doc, error in
            if let data = doc?.data(), let uname = data["username"] as? String {
                username = uname
            }
        }
    }
    // Fetch the user's following list
    func fetchFollowing(uid: String) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { doc, error in
            if let data = doc?.data(), let followingUIDs = data["following"] as? [String] {
                // Fetch usernames for each followed UID
                let group = DispatchGroup()
                var followingDetails: [UserProfile] = []
                for fuid in followingUIDs {
                    group.enter()
                    db.collection("users").document(fuid).getDocument { fdoc, _ in
                        if let fdata = fdoc?.data(), let uname = fdata["username"] as? String {
                            followingDetails.append(UserProfile(uid: fuid, username: uname))
                        }
                        group.leave()
                    }
                }
                group.notify(queue: .main) {
                    self.following = followingDetails
                }
            }
        }
    }
    
    // Search for a user by username
    func searchUser(byUsername username: String) {
        guard !username.isEmpty else { return }
        
        isLoading = true
        let db = Firestore.firestore()
        
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { snapshot, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let doc = snapshot?.documents.first {
                    self.searchResult = UserProfile(uid: doc.documentID, username: username)
                    self.errorMessage = nil
                } else {
                    self.searchResult = nil
                    self.errorMessage = "User not found."
                }
            }
        }
    }
    
    // Follow a user
    func followUser(currentUID: String, targetUID: String) {
        let db = Firestore.firestore()
        let currentUserRef = db.collection("users").document(currentUID)
        let targetUserRef = db.collection("users").document(targetUID)
        
        // Use batch to update both users atomically
        let batch = db.batch()
        
        batch.updateData([
            "following": FieldValue.arrayUnion([targetUID])
        ], forDocument: currentUserRef)
        
        batch.updateData([
            "followers": FieldValue.arrayUnion([currentUID])
        ], forDocument: targetUserRef)
        
        batch.commit { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Failed to follow user: \(error.localizedDescription)"
                } else {
                    self.errorMessage = nil
                    self.searchUsername = ""
                    self.searchResult = nil
                    // Refresh following list
                    self.fetchFollowing(uid: currentUID)
                }
            }
        }
    }
    
    // Unfollow a user
    func unfollowUser(currentUID: String, targetUID: String) {
        let db = Firestore.firestore()
        let currentUserRef = db.collection("users").document(currentUID)
        let targetUserRef = db.collection("users").document(targetUID)
        
        // Use batch to update both users atomically
        let batch = db.batch()
        
        batch.updateData([
            "following": FieldValue.arrayRemove([targetUID])
        ], forDocument: currentUserRef)
        
        batch.updateData([
            "followers": FieldValue.arrayRemove([currentUID])
        ], forDocument: targetUserRef)
        
        batch.commit { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Failed to unfollow user: \(error.localizedDescription)"
                } else {
                    self.errorMessage = nil
                    // Refresh following list
                    self.fetchFollowing(uid: currentUID)
                }
            }
        }
    }
    // Change username if not taken
    func changeUsername(newUsername: String, uid: String) {
        guard !newUsername.isEmpty else {
            errorMessage = "Username cannot be empty."
            return
        }
        let db = Firestore.firestore()
        // Check if username is taken
        db.collection("users").whereField("username", isEqualTo: newUsername).getDocuments { snapshot, error in
            if let snapshot = snapshot, snapshot.documents.isEmpty {
                // Not taken, update
                db.collection("users").document(uid).updateData(["username": newUsername]) { err in
                    if let err = err {
                        errorMessage = "Failed to update username: \(err.localizedDescription)"
                    } else {
                        username = newUsername
                        errorMessage = nil
                        searchUsername = ""
                    }
                }
            } else {
                errorMessage = "Username is already taken."
            }
        }
    }
}