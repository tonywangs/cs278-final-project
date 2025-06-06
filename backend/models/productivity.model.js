// ProductivityEntry model for Firestore
class ProductivityEntry {
  constructor(data = {}) {
    this.userId = data.userId || '';
    this.username = data.username || '';
    this.date = data.date || new Date();
    this.hourglassData = data.hourglassData || {}; // Object mapping hour -> activity
    this.lastUpdated = data.lastUpdated || new Date();
    this.visibility = data.visibility || 'followers'; // 'followers' or 'private'
  }

  static validate(data) {
    if (!data.userId) {
      throw new Error('User ID is required');
    }
    if (!data.hourglassData || typeof data.hourglassData !== 'object') {
      throw new Error('Hourglass data is required');
    }
    return true;
  }

  toFirestore() {
    return {
      userId: this.userId,
      username: this.username,
      date: this.date,
      hourglassData: this.hourglassData,
      lastUpdated: this.lastUpdated,
      visibility: this.visibility
    };
  }

  static fromFirestore(doc) {
    const data = doc.data();
    return new ProductivityEntry({
      ...data,
      id: doc.id
    });
  }

  // Convert to format expected by iOS app
  toFeedFormat() {
    return {
      id: this.id,
      userId: this.userId,
      username: this.username,
      date: this.date,
      entries: this.convertHourglassToEntries(),
      lastUpdated: this.lastUpdated
    };
  }

  // Convert hourglass object format to array format expected by iOS
  convertHourglassToEntries() {
    const entries = [];
    for (let hour = 0; hour < 24; hour++) {
      if (this.hourglassData[hour]) {
        const activity = this.hourglassData[hour];
        // Create entry for each 30-minute slot in the hour
        entries.push({
          timeSlot: hour * 2,
          category: activity
        });
        entries.push({
          timeSlot: hour * 2 + 1,
          category: activity
        });
      }
    }
    return entries;
  }
}

module.exports = ProductivityEntry; 