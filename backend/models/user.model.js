// User model for Firestore
class User {
  constructor(data = {}) {
    this.uid = data.uid || '';
    this.email = data.email || '';
    this.username = data.username || '';
    this.following = data.following || []; // Array of UIDs this user follows
    this.followers = data.followers || []; // Array of UIDs following this user
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