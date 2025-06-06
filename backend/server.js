const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Initialize Firebase Admin
let serviceAccount;
let db;

try {
  serviceAccount = require('./serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  db = admin.firestore();
  console.log('Firebase initialized successfully');
} catch (error) {
  console.warn('Warning: serviceAccountKey.json not found. Running in mock mode.');
  // Create a mock db object for testing
  db = {
    collection: () => ({
      doc: () => ({
        get: () => Promise.resolve({ exists: false }),
        set: () => Promise.resolve(),
        update: () => Promise.resolve()
      }),
      where: () => ({
        get: () => Promise.resolve({ empty: true, docs: [] })
      }),
      add: () => Promise.resolve({ id: 'mock-id' })
    })
  };
}

// Make db available to routes
app.locals.db = db;

// Routes
const tasksRouter = require('./routes/tasks');
const usersRouter = require('./routes/users');
const productivityRouter = require('./routes/productivity');

app.use('/api/tasks', tasksRouter);
app.use('/api/users', usersRouter);
app.use('/api/productivity', productivityRouter);

// Basic route
app.get('/', (req, res) => {
  res.json({ message: 'Welcome to Productivity Tracker API' });
});

// Start server
app.listen(port, () => {
  console.log(`Server is running on port: ${port}`);
}); 