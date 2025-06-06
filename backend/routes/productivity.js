const router = require('express').Router();
const ProductivityEntry = require('../models/productivity.model');

// Save/update user's hourglass data
router.route('/save').post(async (req, res) => {
  try {
    const { userId, username, hourglassData } = req.body;
    
    // Validate required fields
    if (!userId || !hourglassData) {
      return res.status(400).json('User ID and hourglass data are required');
    }
    
    const today = new Date();
    today.setHours(0, 0, 0, 0); // Start of today
    
    const entry = new ProductivityEntry({
      userId,
      username,
      date: today,
      hourglassData,
      lastUpdated: new Date()
    });
    
    ProductivityEntry.validate(entry);
    
    // Use date-based document ID for easy querying
    const docId = `${userId}_${today.toISOString().split('T')[0]}`;
    
    await req.app.locals.db
      .collection('productivity')
      .doc(docId)
      .set(entry.toFirestore(), { merge: true });
    
    res.json({ message: 'Hourglass data saved successfully', id: docId });
  } catch (err) {
    res.status(400).json('Error: ' + err);
  }
});

// Get user's hourglass data for today
router.route('/:userId').get(async (req, res) => {
  try {
    const { userId } = req.params;
    const targetDate = new Date();
    targetDate.setHours(0, 0, 0, 0);
    
    const docId = `${userId}_${targetDate.toISOString().split('T')[0]}`;
    const doc = await req.app.locals.db.collection('productivity').doc(docId).get();
    
    if (!doc.exists) {
      return res.status(404).json('No hourglass data found for this date');
    }
    
    const entry = ProductivityEntry.fromFirestore(doc);
    res.json(entry.toFeedFormat());
  } catch (err) {
    res.status(400).json('Error: ' + err);
  }
});

// Get user's hourglass data for a specific date
router.route('/:userId/:date').get(async (req, res) => {
  try {
    const { userId, date } = req.params;
    const targetDate = new Date(date);
    targetDate.setHours(0, 0, 0, 0);
    
    const docId = `${userId}_${targetDate.toISOString().split('T')[0]}`;
    const doc = await req.app.locals.db.collection('productivity').doc(docId).get();
    
    if (!doc.exists) {
      return res.status(404).json('No hourglass data found for this date');
    }
    
    const entry = ProductivityEntry.fromFirestore(doc);
    res.json(entry.toFeedFormat());
  } catch (err) {
    res.status(400).json('Error: ' + err);
  }
});

// Get feed data for a user (based on who they follow)
router.route('/feed/:userId').get(async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Get user's following list
    const userDoc = await req.app.locals.db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return res.status(404).json('User not found');
    }
    
    const userData = userDoc.data();
    const following = userData.following || [];
    
    if (following.length === 0) {
      return res.json([]); // No one to follow
    }
    
    // Get today's date for filtering
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayStr = today.toISOString().split('T')[0];
    
    // Get productivity entries for all followed users
    const feedEntries = [];
    const batchSize = 10; // Firestore has limits on 'in' queries
    
    for (let i = 0; i < following.length; i += batchSize) {
      const batch = following.slice(i, i + batchSize);
      const docIds = batch.map(uid => `${uid}_${todayStr}`);
      
      // Get documents in this batch
      for (const docId of docIds) {
        try {
          const doc = await req.app.locals.db.collection('productivity').doc(docId).get();
          if (doc.exists) {
            const entry = ProductivityEntry.fromFirestore(doc);
            feedEntries.push(entry.toFeedFormat());
          }
        } catch (err) {
          console.log(`Error fetching ${docId}:`, err);
          // Continue with other entries
        }
      }
    }
    
    // Sort by most recent update (lastUpdated timestamp)
    feedEntries.sort((a, b) => new Date(b.lastUpdated) - new Date(a.lastUpdated));
    
    res.json(feedEntries);
  } catch (err) {
    res.status(400).json('Error: ' + err);
  }
});

// Get hourglass history for a user (past days)
router.route('/history/:userId').get(async (req, res) => {
  try {
    const { userId } = req.params;
    const { days = 7 } = req.query; // Default to last 7 days
    
    const entries = [];
    const today = new Date();
    
    for (let i = 0; i < parseInt(days); i++) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      date.setHours(0, 0, 0, 0);
      
      const docId = `${userId}_${date.toISOString().split('T')[0]}`;
      
      try {
        const doc = await req.app.locals.db.collection('productivity').doc(docId).get();
        if (doc.exists) {
          const entry = ProductivityEntry.fromFirestore(doc);
          entries.push(entry.toFeedFormat());
        }
      } catch (err) {
        console.log(`Error fetching history for ${docId}:`, err);
      }
    }
    
    // Sort by date (most recent first)
    entries.sort((a, b) => new Date(b.date) - new Date(a.date));
    
    res.json(entries);
  } catch (err) {
    res.status(400).json('Error: ' + err);
  }
});

module.exports = router; 