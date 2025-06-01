import SwiftUI
import FirebaseFirestore

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    var onLoginTap: (() -> Void)? = nil
    
    @State private var username: String = ""
    @State private var friends: [String] = []
    @State private var searchUsername: String = ""
    @State private var searchResult: (uid: String, username: String)? = nil
    @State private var errorMessage: String? = nil
    
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
                        fetchFriends(uid: user.uid)
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
                        Text("Friends")
                            .font(.headline)
                            .foregroundColor(Theme.darkAccentColor)
                        if friends.isEmpty {
                            Text("No friends yet.")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(friends, id: \.self) { friend in
                                Text(friend)
                                    .foregroundColor(Theme.logoColor)
                            }
                        }
                    }
                    // Friend search and add section
                    Divider().padding(.vertical, 8)
                    VStack(spacing: 8) {
                        TextField("Enter username to add", text: $searchUsername)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .padding(.horizontal)
                        Button("Search") {
                            searchUser(byUsername: searchUsername) { result in
                                if let result = result {
                                    searchResult = result
                                    errorMessage = nil
                                } else {
                                    searchResult = nil
                                    errorMessage = "User not found."
                                }
                            }
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
                                Button("Add Friend") {
                                    if let user = authViewModel.user {
                                        if friends.contains(result.username) {
                                            errorMessage = "Already a friend."
                                        } else {
                                            addFriend(currentUID: user.uid, friendUID: result.uid)
                                            errorMessage = nil
                                            searchUsername = ""
                                            searchResult = nil
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
    // Fetch the user's friends (usernames)
    func fetchFriends(uid: String) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { doc, error in
            if let data = doc?.data(), let friendUIDs = data["friends"] as? [String] {
                // Fetch usernames for each friend UID
                let group = DispatchGroup()
                var friendNames: [String] = []
                for fuid in friendUIDs {
                    group.enter()
                    db.collection("users").document(fuid).getDocument { fdoc, _ in
                        if let fdata = fdoc?.data(), let uname = fdata["username"] as? String {
                            friendNames.append(uname)
                        }
                        group.leave()
                    }
                }
                group.notify(queue: .main) {
                    friends = friendNames
                }
            }
        }
    }
    // Search for a user by username
    func searchUser(byUsername username: String, completion: @escaping ((uid: String, username: String)?) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { snapshot, error in
            if let doc = snapshot?.documents.first {
                completion((uid: doc.documentID, username: username))
            } else {
                completion(nil)
            }
        }
    }
    // Add a friend (by UID)
    func addFriend(currentUID: String, friendUID: String) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(currentUID)
        let friendRef = db.collection("users").document(friendUID)
        userRef.updateData([
            "friends": FieldValue.arrayUnion([friendUID])
        ])
        friendRef.updateData([
            "friends": FieldValue.arrayUnion([currentUID])
        ])
        // Refresh friends list
        fetchFriends(uid: currentUID)
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