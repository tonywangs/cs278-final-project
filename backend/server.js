const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Initialize Firebase Admin
let serviceAccount;
try {
  serviceAccount = require('./serviceAccountKey.json');
} catch (error) {
  console.error('Error: serviceAccountKey.json not found. Please make sure you have downloaded your Firebase service account key.');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Make db available to routes
app.locals.db = db;

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