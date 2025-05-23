const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB connection
const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/productivity-tracker';
mongoose.connect(uri)
  .then(() => console.log('MongoDB connection established'))
  .catch(err => console.log('MongoDB connection error:', err));

// Routes
const tasksRouter = require('./routes/tasks');
app.use('/api/tasks', tasksRouter);

// Basic route
app.get('/', (req, res) => {
  res.json({ message: 'Welcome to Productivity Tracker API' });
});

// Start server
app.listen(port, () => {
  console.log(`Server is running on port: ${port}`);
}); 