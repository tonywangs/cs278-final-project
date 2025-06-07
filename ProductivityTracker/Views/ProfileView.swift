import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    var onLoginTap: (() -> Void)? = nil
    
    @State private var username: String = ""
    @State private var following: [UserProfile] = []
    @State private var followers: [UserProfile] = []
    @State private var blocked: [UserProfile] = []
    @State private var searchUsername: String = ""
    @State private var searchResult: UserProfile? = nil
    @State private var errorMessage: String? = nil
    @State private var isLoading = false
    @State private var showingSettings = false
    @State private var showingBlockedUsers = false
    @State private var currentUserProfileImageURL: String? = nil
    
    var body: some View {
        ZStack {
            Theme.parchment.ignoresSafeArea()
            
            if let user = authViewModel.user {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            // Profile Image
                            ProfileImageView(
                                imageURL: currentUserProfileImageURL,
                                username: username.isEmpty ? "User" : username,
                                size: 80
                            )
                            
                            // User Info
                            VStack(spacing: 4) {
                                Text("@\(username)")
                                    .font(.custom("Georgia-Bold", size: 24))
                                    .foregroundColor(Theme.logoColor)
                                
                                Text(user.email ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            // Settings Button
                            Button(action: { showingSettings = true }) {
                                HStack {
                                    Image(systemName: "gearshape.fill")
                                    Text("Settings")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Theme.darkAccentColor)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(20)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Following Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(Theme.logoColor)
                                Text("Following")
                                    .font(.custom("Georgia-Bold", size: 20))
                                    .foregroundColor(Theme.darkAccentColor)
                                Spacer()
                                Text("\(following.count)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Theme.logoColor)
                                    .cornerRadius(12)
                            }
                            
                            if following.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 32))
                                        .foregroundColor(.gray)
                                    Text("Not following anyone yet")
                                        .foregroundColor(.gray)
                                        .font(.subheadline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(following) { userProfile in
                                        FollowingUserCard(
                                            userProfile: userProfile,
                                            onUnfollow: {
                                                unfollowUser(currentUID: user.uid, targetUID: userProfile.uid)
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        
                        // Followers Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "person.fill.badge.plus")
                                    .foregroundColor(Theme.logoColor)
                                Text("Followers")
                                    .font(.custom("Georgia-Bold", size: 20))
                                    .foregroundColor(Theme.darkAccentColor)
                                Spacer()
                                Text("\(followers.count)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Theme.logoColor)
                                    .cornerRadius(12)
                            }
                            
                            if followers.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 32))
                                        .foregroundColor(.gray)
                                    Text("No followers yet")
                                        .foregroundColor(.gray)
                                        .font(.subheadline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(followers) { userProfile in
                                        FollowerUserCard(
                                            userProfile: userProfile,
                                            isFollowingBack: following.contains(where: { $0.uid == userProfile.uid }),
                                            onFollowBack: {
                                                followUser(currentUID: user.uid, targetUID: userProfile.uid)
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        
                        // Find Users Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(Theme.logoColor)
                                Text("Find Users")
                                    .font(.custom("Georgia-Bold", size: 20))
                                    .foregroundColor(Theme.darkAccentColor)
                                Spacer()
                                
                                // Blocked Users button
                                Button(action: { showingBlockedUsers = true }) {
                                    Image(systemName: "person.fill.xmark")
                                        .foregroundColor(.red)
                                        .font(.system(size: 16))
                                }
                            }
                            
                            VStack(spacing: 12) {
                                HStack {
                                    TextField("Enter username", text: $searchUsername)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                    
                                    Button("Search") {
                                        searchUser(byUsername: searchUsername)
                                        errorMessage = nil
                                    }
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Theme.logoColor)
                                    .cornerRadius(8)
                                    .disabled(searchUsername.trimmingCharacters(in: .whitespaces).isEmpty)
                                    .opacity(searchUsername.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1.0)
                                }
                                
                                if let result = searchResult {
                                    SearchResultCard(
                                        userProfile: result,
                                        isAlreadyFollowing: following.contains(where: { $0.uid == result.uid }),
                                        isBlocked: blocked.contains(where: { $0.uid == result.uid }),
                                        onFollow: {
                                            followUser(currentUID: user.uid, targetUID: result.uid)
                                        },
                                        onBlock: {
                                            blockUser(currentUID: user.uid, targetUID: result.uid)
                                        },
                                        onUnblock: {
                                            unblockUser(currentUID: user.uid, targetUID: result.uid)
                                        }
                                    )
                                }
                                
                                if let error = errorMessage {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.red)
                                        Text(error)
                                            .foregroundColor(.red)
                                            .font(.caption)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                }
                .onAppear {
                    fetchUserProfile(uid: user.uid)
                    fetchFollowing(uid: user.uid)
                    fetchFollowers(uid: user.uid)
                    fetchBlocked(uid: user.uid)
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView(username: $username, user: user)
                }
                .sheet(isPresented: $showingBlockedUsers) {
                    BlockedUsersView(
                        blocked: blocked,
                        onUnblock: { targetUID in
                            unblockUser(currentUID: user.uid, targetUID: targetUID)
                        }
                    )
                }
            } else {
                // Not logged in state
                VStack(spacing: 24) {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        Text("Profile")
                            .font(.custom("Georgia-Bold", size: 32))
                            .foregroundColor(Theme.logoColor)
                        
                        Text("Please log in to view your profile")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    
                    if let onLoginTap = onLoginTap {
                        Button(action: onLoginTap) {
                            Text("Log In")
                                .font(.custom("Georgia-Bold", size: 20))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Theme.darkAccentColor)
                                .cornerRadius(12)
                                .padding(.horizontal, 40)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Firestore Methods
    
    func fetchUserProfile(uid: String) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { doc, error in
            DispatchQueue.main.async {
                if let data = doc?.data(), let uname = data["username"] as? String {
                    self.username = uname
                    self.currentUserProfileImageURL = data["profileImageURL"] as? String
                } else {
                    print("Error fetching user profile: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
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
                        if let fdata = fdoc?.data() {
                            // Try to get username, fallback to email if username doesn't exist
                            let uname = fdata["username"] as? String ?? 
                                       (fdata["email"] as? String)?.components(separatedBy: "@").first ?? 
                                       "Unknown User"
                            let profileImageURL = fdata["profileImageURL"] as? String
                            followingDetails.append(UserProfile(uid: fuid, username: uname, profileImageURL: profileImageURL))
                        }
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    self.following = followingDetails.sorted { $0.username < $1.username }
                }
            }
        }
    }
    
    func fetchFollowers(uid: String) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { doc, error in
            if let data = doc?.data(), let followersUIDs = data["followers"] as? [String] {
                // Fetch usernames for each followed UID
                let group = DispatchGroup()
                var followersDetails: [UserProfile] = []
                
                for fuid in followersUIDs {
                    group.enter()
                    db.collection("users").document(fuid).getDocument { fdoc, _ in
                        if let fdata = fdoc?.data() {
                            // Try to get username, fallback to email if username doesn't exist
                            let uname = fdata["username"] as? String ?? 
                                       (fdata["email"] as? String)?.components(separatedBy: "@").first ?? 
                                       "Unknown User"
                            let profileImageURL = fdata["profileImageURL"] as? String
                            followersDetails.append(UserProfile(uid: fuid, username: uname, profileImageURL: profileImageURL))
                        }
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    self.followers = followersDetails.sorted { $0.username < $1.username }
                }
            }
        }
    }
    
    func searchUser(byUsername username: String) {
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isLoading = true
        let db = Firestore.firestore()
        
        db.collection("users").whereField("username", isEqualTo: username.trimmingCharacters(in: .whitespaces)).getDocuments { snapshot, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let doc = snapshot?.documents.first {
                    let data = doc.data()
                    let profileImageURL = data["profileImageURL"] as? String
                    let foundUser = UserProfile(uid: doc.documentID, username: username.trimmingCharacters(in: .whitespaces), profileImageURL: profileImageURL)
                    
                    // Check if current user has blocked this user or vice versa
                    if let currentUser = Auth.auth().currentUser {
                        self.checkBlockingStatus(currentUID: currentUser.uid, targetUID: foundUser.uid) { isBlocked in
                            if isBlocked {
                                self.searchResult = nil
                                self.errorMessage = "User '@\(username.trimmingCharacters(in: .whitespaces))' not found"
                            } else {
                                self.searchResult = foundUser
                                self.errorMessage = nil
                            }
                        }
                    } else {
                        self.searchResult = foundUser
                        self.errorMessage = nil
                    }
                } else {
                    self.searchResult = nil
                    self.errorMessage = "User '@\(username.trimmingCharacters(in: .whitespaces))' not found"
                }
            }
        }
    }
    
    func checkBlockingStatus(currentUID: String, targetUID: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let group = DispatchGroup()
        var isBlocked = false
        
        // Check if current user blocked target
        group.enter()
        db.collection("users").document(currentUID).getDocument { doc, _ in
            if let data = doc?.data(), let blocked = data["blocked"] as? [String] {
                if blocked.contains(targetUID) {
                    isBlocked = true
                }
            }
            group.leave()
        }
        
        // Check if target blocked current user
        group.enter()
        db.collection("users").document(targetUID).getDocument { doc, _ in
            if let data = doc?.data(), let blocked = data["blocked"] as? [String] {
                if blocked.contains(currentUID) {
                    isBlocked = true
                }
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(isBlocked)
        }
    }
    
    func followUser(currentUID: String, targetUID: String) {
        // First check blocking status
        checkBlockingStatus(currentUID: currentUID, targetUID: targetUID) { isBlocked in
            if isBlocked {
                self.errorMessage = "Cannot follow this user"
                return
            }
            
            let db = Firestore.firestore()
            let currentUserRef = db.collection("users").document(currentUID)
            let targetUserRef = db.collection("users").document(targetUID)
            
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
                        self.fetchFollowing(uid: currentUID)
                        self.fetchFollowers(uid: currentUID)
                    }
                }
            }
        }
    }
    
    func unfollowUser(currentUID: String, targetUID: String) {
        let db = Firestore.firestore()
        let currentUserRef = db.collection("users").document(currentUID)
        let targetUserRef = db.collection("users").document(targetUID)
        
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
                    self.fetchFollowing(uid: currentUID)
                    self.fetchFollowers(uid: currentUID)
                }
            }
        }
    }
    
    func blockUser(currentUID: String, targetUID: String) {
        let db = Firestore.firestore()
        let currentUserRef = db.collection("users").document(currentUID)
        let targetUserRef = db.collection("users").document(targetUID)
        
        let batch = db.batch()
        
        // Add to blocked list and remove from following
        batch.updateData([
            "blocked": FieldValue.arrayUnion([targetUID]),
            "following": FieldValue.arrayRemove([targetUID])
        ], forDocument: currentUserRef)
        
        // Remove current user from target's followers and following
        batch.updateData([
            "followers": FieldValue.arrayRemove([currentUID]),
            "following": FieldValue.arrayRemove([currentUID])
        ], forDocument: targetUserRef)
        
        batch.commit { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Failed to block user: \(error.localizedDescription)"
                } else {
                    self.errorMessage = nil
                    self.searchUsername = ""
                    self.searchResult = nil
                    self.fetchFollowing(uid: currentUID)
                    self.fetchFollowers(uid: currentUID)
                    self.fetchBlocked(uid: currentUID)
                }
            }
        }
    }
    
    func unblockUser(currentUID: String, targetUID: String) {
        let db = Firestore.firestore()
        let currentUserRef = db.collection("users").document(currentUID)
        
        currentUserRef.updateData([
            "blocked": FieldValue.arrayRemove([targetUID])
        ]) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Failed to unblock user: \(error.localizedDescription)"
                } else {
                    self.errorMessage = nil
                    self.searchUsername = ""
                    self.searchResult = nil
                    self.fetchBlocked(uid: currentUID)
                }
            }
        }
    }
    
    func fetchBlocked(uid: String) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { doc, error in
            if let data = doc?.data(), let blockedUIDs = data["blocked"] as? [String] {
                let group = DispatchGroup()
                var blockedDetails: [UserProfile] = []
                
                for buid in blockedUIDs {
                    group.enter()
                    db.collection("users").document(buid).getDocument { bdoc, _ in
                        if let bdata = bdoc?.data() {
                            let uname = bdata["username"] as? String ?? 
                                       (bdata["email"] as? String)?.components(separatedBy: "@").first ?? 
                                       "Unknown User"
                            let profileImageURL = bdata["profileImageURL"] as? String
                            blockedDetails.append(UserProfile(uid: buid, username: uname, profileImageURL: profileImageURL))
                        }
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    self.blocked = blockedDetails.sorted { $0.username < $1.username }
                }
            }
        }
    }
}

// MARK: - Component Views

struct FollowingUserCard: View {
    let userProfile: UserProfile
    let onUnfollow: () -> Void
    @State private var showingUnfollowAlert = false
    
    var body: some View {
        HStack {
            ProfileImageView(
                imageURL: userProfile.profileImageURL,
                username: userProfile.username,
                size: 40
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("@\(userProfile.username)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.darkAccentColor)
                
                Text("Following")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: { showingUnfollowAlert = true }) {
                Text("Following")
                    .font(.caption)
                    .foregroundColor(Theme.logoColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.logoColor.opacity(0.1))
                    .cornerRadius(16)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
        .alert("Unfollow @\(userProfile.username)?", isPresented: $showingUnfollowAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Unfollow", role: .destructive) {
                onUnfollow()
            }
        } message: {
            Text("You will no longer see their hourglass updates in your feed.")
        }
    }
}

struct SearchResultCard: View {
    let userProfile: UserProfile
    let isAlreadyFollowing: Bool
    let isBlocked: Bool
    let onFollow: () -> Void
    let onBlock: () -> Void
    let onUnblock: () -> Void
    
    var body: some View {
        HStack {
            ProfileImageView(
                imageURL: userProfile.profileImageURL,
                username: userProfile.username,
                size: 40
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("@\(userProfile.username)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.darkAccentColor)
                
                Text(isBlocked ? "Blocked" : (isAlreadyFollowing ? "Following" : "Available"))
                    .font(.caption)
                    .foregroundColor(isBlocked ? .red : .gray)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if isBlocked {
                    Button(action: onUnblock) {
                        Text("Unblock")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                    }
                } else {
                    if isAlreadyFollowing {
                        Text("Following")
                            .font(.caption)
                            .foregroundColor(Theme.logoColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.logoColor.opacity(0.1))
                            .cornerRadius(12)
                    } else {
                        Button(action: onFollow) {
                            Text("Follow")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Theme.darkAccentColor)
                                .cornerRadius(12)
                        }
                    }
                    
                    Button(action: onBlock) {
                        Image(systemName: "person.fill.xmark")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .padding(6)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6).opacity(0.3))
        .cornerRadius(12)
    }
}

struct FollowerUserCard: View {
    let userProfile: UserProfile
    let isFollowingBack: Bool
    let onFollowBack: () -> Void
    
    var body: some View {
        HStack {
            ProfileImageView(
                imageURL: userProfile.profileImageURL,
                username: userProfile.username,
                size: 40
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("@\(userProfile.username)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.darkAccentColor)
                
                Text(isFollowingBack ? "Mutual following" : "Follows you")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if isFollowingBack {
                Text("Following")
                    .font(.caption)
                    .foregroundColor(Theme.logoColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.logoColor.opacity(0.1))
                    .cornerRadius(16)
            } else {
                Button(action: onFollowBack) {
                    Text("Follow Back")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.logoColor)
                        .cornerRadius(16)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Binding var username: String
    let user: User
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var newUsername: String = ""
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil
    @State private var isLoading = false
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    @State private var isUploadingImage = false
    @State private var currentProfileImageURL: String? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.parchment.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Settings")
                            .font(.custom("Georgia-Bold", size: 28))
                            .foregroundColor(Theme.logoColor)
                        
                        Text("Manage your account preferences")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    // Profile Picture Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "camera.circle")
                                .foregroundColor(Theme.logoColor)
                            Text("Profile Picture")
                                .font(.custom("Georgia-Bold", size: 18))
                                .foregroundColor(Theme.darkAccentColor)
                            Spacer()
                        }
                        
                        VStack(spacing: 16) {
                            // Current Profile Picture
                            ProfileImageView(
                                imageURL: currentProfileImageURL,
                                username: username,
                                size: 80
                            )
                            
                            // Photo Picker
                            PhotosPicker(
                                selection: $selectedPhoto,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                HStack {
                                    if isUploadingImage {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Uploading...")
                                    } else {
                                        Image(systemName: "photo.badge.plus")
                                        Text("Change Profile Picture")
                                    }
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(isUploadingImage ? Color.gray : Theme.logoColor)
                                .cornerRadius(10)
                            }
                            .disabled(isUploadingImage)
                            
                            // Remove Picture Button (only show if user has a profile picture)
                            if currentProfileImageURL != nil {
                                Button(action: removeProfilePicture) {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Remove Picture")
                                    }
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                }
                                .disabled(isUploadingImage)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    
                    // Username Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(Theme.logoColor)
                            Text("Username")
                                .font(.custom("Georgia-Bold", size: 18))
                                .foregroundColor(Theme.darkAccentColor)
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Current:")
                                    .foregroundColor(.gray)
                                Text("@\(username)")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Theme.logoColor)
                                Spacer()
                            }
                            
                            VStack(spacing: 8) {
                                TextField("Enter new username", text: $newUsername)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .disabled(isLoading)
                                
                                Button(action: changeUsername) {
                                    if isLoading {
                                        HStack {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                            Text("Updating...")
                                        }
                                    } else {
                                        Text("Update Username")
                                    }
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(newUsername.trimmingCharacters(in: .whitespaces).isEmpty || isLoading ? 
                                          Color.gray : Theme.darkAccentColor)
                                .cornerRadius(10)
                                .disabled(newUsername.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                            }
                            
                            if let error = errorMessage {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text(error)
                                        .foregroundColor(.red)
                                        .font(.caption)
                                }
                            }
                            
                            if let success = successMessage {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(success)
                                        .foregroundColor(.green)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    
                    // Account Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "gear")
                                .foregroundColor(Theme.logoColor)
                            Text("Account")
                                .font(.custom("Georgia-Bold", size: 18))
                                .foregroundColor(Theme.darkAccentColor)
                            Spacer()
                        }
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Email:")
                                    .foregroundColor(.gray)
                                Text(user.email)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Theme.darkAccentColor)
                                Spacer()
                            }
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            Button(action: { authViewModel.signOut() }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Sign Out")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red)
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.logoColor)
                }
            }
        }
        .onAppear {
            newUsername = ""
            errorMessage = nil
            successMessage = nil
            fetchCurrentProfileImage()
        }
        .onChange(of: selectedPhoto) { _ in
            Task {
                await uploadProfilePicture()
            }
        }
    }
    
    private func changeUsername() {
        let trimmedUsername = newUsername.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedUsername.isEmpty else {
            errorMessage = "Username cannot be empty"
            return
        }
        
        guard trimmedUsername != username else {
            errorMessage = "This is already your current username"
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        let db = Firestore.firestore()
        
        // Check if username is taken
        db.collection("users").whereField("username", isEqualTo: trimmedUsername).getDocuments { snapshot, error in
            DispatchQueue.main.async {
                if let snapshot = snapshot, snapshot.documents.isEmpty {
                    // Username not taken, update it
                    db.collection("users").document(user.uid).updateData(["username": trimmedUsername]) { err in
                        self.isLoading = false
                        
                        if let err = err {
                            self.errorMessage = "Failed to update: \(err.localizedDescription)"
                        } else {
                            self.username = trimmedUsername
                            self.successMessage = "Username updated successfully!"
                            self.newUsername = ""
                            
                            // Clear success message after 3 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                self.successMessage = nil
                            }
                        }
                    }
                } else {
                    self.isLoading = false
                    self.errorMessage = "Username '@\(trimmedUsername)' is already taken"
                }
            }
        }
    }
    
    private func fetchCurrentProfileImage() {
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).getDocument { document, error in
            DispatchQueue.main.async {
                if let document = document,
                   let data = document.data(),
                   let profileImageURL = data["profileImageURL"] as? String {
                    self.currentProfileImageURL = profileImageURL
                }
            }
        }
    }
    
    private func uploadProfilePicture() async {
        guard let selectedPhoto = selectedPhoto else { return }
        
        await MainActor.run {
            isUploadingImage = true
            errorMessage = nil
            successMessage = nil
        }
        
        do {
            if let data = try await selectedPhoto.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                
                // Resize image to reasonable size (max 800x800)
                let resizedImage = resizeImage(image: uiImage, targetSize: CGSize(width: 800, height: 800))
                guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
                    await MainActor.run {
                        isUploadingImage = false
                        errorMessage = "Failed to process image"
                    }
                    return
                }
                
                // Upload to Firebase Storage with proper bucket configuration
                let storage = Storage.storage()
                let storageRef = storage.reference()
                
                // Use timestamp to make filename unique and avoid conflicts
                let timestamp = Int(Date().timeIntervalSince1970)
                let filename = "\(user.uid)_\(timestamp).jpg"
                let profileImagesRef = storageRef.child("profile_images/\(filename)")
                
                // Set metadata for the upload
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpeg"
                metadata.customMetadata = ["userId": user.uid]
                
                print("Uploading profile image to: profile_images/\(filename)")
                
                let uploadTask = try await profileImagesRef.putDataAsync(imageData, metadata: metadata)
                print("Upload completed, getting download URL...")
                
                let downloadURL = try await profileImagesRef.downloadURL()
                print("Download URL obtained: \(downloadURL.absoluteString)")
                
                // Update Firestore with new profile image URL
                let db = Firestore.firestore()
                try await db.collection("users").document(user.uid).updateData([
                    "profileImageURL": downloadURL.absoluteString
                ])
                
                print("Firestore updated successfully")
                
                await MainActor.run {
                    currentProfileImageURL = downloadURL.absoluteString
                    isUploadingImage = false
                    successMessage = "Profile picture updated successfully!"
                    
                    // Clear success message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.successMessage = nil
                    }
                }
            }
        } catch {
            await MainActor.run {
                isUploadingImage = false
                print("Profile picture upload error: \(error)")
                if let storageError = error as NSError? {
                    print("Storage error code: \(storageError.code)")
                    print("Storage error domain: \(storageError.domain)")
                    print("Storage error description: \(storageError.localizedDescription)")
                    print("Storage error userInfo: \(storageError.userInfo)")
                }
                
                // Provide more specific error messages
                let errorDescription = error.localizedDescription
                if errorDescription.contains("object") || errorDescription.contains("permission") {
                    errorMessage = "Upload failed due to storage permissions. Please check Firebase Storage rules."
                } else if errorDescription.contains("network") {
                    errorMessage = "Upload failed due to network error. Please check your connection."
                } else {
                    errorMessage = "Failed to upload profile picture: \(errorDescription)"
                }
            }
        }
    }
    
    private func removeProfilePicture() {
        isUploadingImage = true
        errorMessage = nil
        successMessage = nil
        
        let db = Firestore.firestore()
        
        // Remove from Firestore
        db.collection("users").document(user.uid).updateData([
            "profileImageURL": FieldValue.delete()
        ]) { error in
            DispatchQueue.main.async {
                self.isUploadingImage = false
                
                if let error = error {
                    self.errorMessage = "Failed to remove profile picture: \(error.localizedDescription)"
                } else {
                    self.currentProfileImageURL = nil
                    self.successMessage = "Profile picture removed successfully!"
                    
                    // Clear success message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.successMessage = nil
                    }
                }
            }
        }
    }
    
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}