// User model for Firestore
class User {
  constructor(data = {}) {
    this.uid = data.uid || '';
    this.email = data.email || '';
    this.username = data.username || '';
    this.following = data.following || []; // Array of UIDs this user follows
    this.followers = data.followers || []; // Array of UIDs following this user
    this.blocked = data.blocked || []; // Array of UIDs this user has blocked
    this.profileImageURL = data.profileImageURL || null; // URL for profile picture
    this.createdAt = data.createdAt || new Date();
    this.lastActive = data.lastActive || new Date();
  }

  static validate(data) {
    if (!data.email) {
      throw new Error('Email is required');
    }
    if (!data.username) {
      throw new Error('Username is required');
    }
    return true;
  }

  toFirestore() {
    return {
      uid: this.uid,
      email: this.email,
      username: this.username,
      following: this.following,
      followers: this.followers,
      blocked: this.blocked,
      profileImageURL: this.profileImageURL,
      createdAt: this.createdAt,
      lastActive: this.lastActive
    };
  }

  static fromFirestore(doc) {
    const data = doc.data();
    return new User({
      ...data,
      uid: doc.id
    });
  }
}

module.exports = User; 