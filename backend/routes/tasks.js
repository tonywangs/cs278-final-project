const router = require('express').Router();
const Task = require('../models/task.model');

// Get all tasks
router.route('/').get(async (req, res) => {
  try {
    const tasksSnapshot = await req.app.locals.db.collection('tasks').get();
    const tasks = tasksSnapshot.docs.map(doc => Task.fromFirestore(doc));
    res.json(tasks);
  } catch (err) {
    res.status(400).json('Error: ' + err);
  }
});

// Add new task
router.route('/add').post(async (req, res) => {
  try {
    const taskData = req.body;
    Task.validate(taskData);
    
    const task = new Task(taskData);
    const docRef = await req.app.locals.db.collection('tasks').add(task.toFirestore());
    
    res.json({ id: docRef.id, message: 'Task added!' });
  } catch (err) {
    res.status(400).json('Error: ' + err);
  }
});

// Get task by id
router.route('/:id').get(async (req, res) => {
  try {
    const doc = await req.app.locals.db.collection('tasks').doc(req.params.id).get();
    if (!doc.exists) {
      return res.status(404).json('Task not found');
    }
    res.json(Task.fromFirestore(doc));
  } catch (err) {
    res.status(400).json('Error: ' + err);
  }
});

// Delete task
router.route('/:id').delete(async (req, res) => {
  try {
    await req.app.locals.db.collection('tasks').doc(req.params.id).delete();
    res.json('Task deleted.');
  } catch (err) {
    res.status(400).json('Error: ' + err);
  }
});

// Update task
router.route('/update/:id').post(async (req, res) => {
  try {
    const taskData = req.body;
    Task.validate(taskData);
    
    const task = new Task(taskData);
    await req.app.locals.db.collection('tasks').doc(req.params.id).update(task.toFirestore());
    
    res.json('Task updated!');
  } catch (err) {
    res.status(400).json('Error: ' + err);
  }
});

module.exports = router; 