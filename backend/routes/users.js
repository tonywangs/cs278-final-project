const router = require('express').Router();
const User = require('../models/user.model');

// Get user profile by UID
router.route('/:uid').get(async (req, res) => {
  try {
    const doc = await req.app.locals.db.collection('users').doc(req.params.uid).get();
    if (!doc.exists) {
      return res.status(404).json('User not found');
    }
    res.json(User.fromFirestore(doc));
  } catch (err) {
    res.status(400).json('Error: ' + err);
  }
});

// Search users by username
router.route('/search/:username').get(async (req, res) => {
  try {
    const snapshot = await req.app.locals.db.collection('users')
      .where('username', '==', req.params.username)
      .get();
    
    if (snapshot.empty) {
      return res.status(404).json('User not found');
    }
    
    const user = User.fromFirestore(snapshot.docs[0]);
    res.json({
      uid: user.uid,
      username: user.username
    });
  } catch (err) {
    res.status(400).json('Error: ' + err);
  }
});

// Follow a user
router.route('/:uid/follow').post(async (req, res) => {
  try {
    const { targetUid } = req.body;
    const currentUid = req.params.uid;
    
    if (currentUid === targetUid) {
      return res.status(400).json('Cannot follow yourself');
    }
    
    const db = req.app.locals.db;
    const batch = db.batch();
    
    // Add targetUid to current user's following list
    const currentUserRef = db.collection('users').doc(currentUid);
    batch.update(currentUserRef, {
      following: require('firebase-admin').firestore.FieldValue.arrayUnion(targetUid)
    });
    
    // Add currentUid to target user's followers list
    const targetUserRef = db.collection('users').doc(targetUid);
    batch.update(targetUserRef, {
      followers: require('firebase-admin').firestore.FieldValue.arrayUnion(currentUid)
    });
    
    await batch.commit();
    res.json({ message: 'User followed successfully' });
  } catch (err) {
    res.status(400).json('Error: ' + err);
  }
});

// Unfollow a user
router.route('/:uid/unfollow').post(async (req, res) => {
  try {
    const { targetUid } = req.body;
    const currentUid = req.params.uid;
    
    const db = req.app.locals.db;
    const batch = db.batch();
    
    // Remove targetUid from current user's following list
    const currentUserRef = db.collection('users').doc(currentUid);
    batch.update(currentUserRef, {
      following: require('firebase-admin').firestore.FieldValue.arrayRemove(targetUid)
    });
    
    // Remove currentUid from target user's followers list
    const targetUserRef = db.collection('users').doc(targetUid);
    batch.update(targetUserRef, {
      followers: require('firebase-admin').firestore.FieldValue.arrayRemove(currentUid)
    });
    
    await batch.commit();
    res.json({ message: 'User unfollowed successfully' });
  } catch (err) {
    res.status(400).json('Error: ' + err);
  }
});

// Get user's following list
router.route('/:uid/following').get(async (req, res) => {
  try {
    const doc = await req.app.locals.db.collection('users').doc(req.params.uid).get();
    if (!doc.exists) {
      return res.status(404).json('User not found');
    }
    
    const user = User.fromFirestore(doc);
    const followingDetails = [];
    
    // Get details for each followed user
    for (const followedUid of user.following) {
      const followedDoc = await req.app.locals.db.collection('users').doc(followedUid).get();
      if (followedDoc.exists) {
        const followedUser = User.fromFirestore(followedDoc);
        followingDetails.push({
          uid: followedUser.uid,
          username: followedUser.username
        });
      }
    }
    
    res.json(followingDetails);
  } catch (err) {
    res.status(400).json('Error: ' + err);
  }
});

// Get user's followers list
router.route('/:uid/followers').get(async (req, res) => {
  try {
    const doc = await req.app.locals.db.collection('users').doc(req.params.uid).get();
    if (!doc.exists) {
      return res.status(404).json('User not found');
    }
    
    const user = User.fromFirestore(doc);
    const followerDetails = [];
    
    // Get details for each follower
    for (const followerUid of user.followers) {
      const followerDoc = await req.app.locals.db.collection('users').doc(followerUid).get();
      if (followerDoc.exists) {
        const followerUser = User.fromFirestore(followerDoc);
        followerDetails.push({
          uid: followerUser.uid,
          username: followerUser.username
        });
      }
    }
    
    res.json(followerDetails);
  } catch (err) {
    res.status(400).json('Error: ' + err);
  }
});

module.exports = router; 