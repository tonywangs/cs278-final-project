const mongoose = require('mongoose');

const Schema = mongoose.Schema;

const taskSchema = new Schema({
  title: { type: String, required: true },
  description: { type: String, required: false },
  completed: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now },
  dueDate: { type: Date, required: false },
  priority: { type: String, enum: ['low', 'medium', 'high'], default: 'medium' }
});

const Task = mongoose.model('Task', taskSchema);

module.exports = Task; 