// Task model for Firestore
class Task {
  constructor(data = {}) {
    this.title = data.title || '';
    this.description = data.description || '';
    this.completed = data.completed || false;
    this.createdAt = data.createdAt || new Date();
    this.dueDate = data.dueDate || null;
    this.priority = data.priority || 'medium';
  }

  static validate(data) {
    if (!data.title) {
      throw new Error('Title is required');
    }
    if (data.priority && !['low', 'medium', 'high'].includes(data.priority)) {
      throw new Error('Priority must be low, medium, or high');
    }
    return true;
  }

  toFirestore() {
    return {
      title: this.title,
      description: this.description,
      completed: this.completed,
      createdAt: this.createdAt,
      dueDate: this.dueDate,
      priority: this.priority
    };
  }

  static fromFirestore(doc) {
    const data = doc.data();
    return new Task({
      ...data,
      id: doc.id
    });
  }
}

module.exports = Task; 