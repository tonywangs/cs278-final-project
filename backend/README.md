# Productivity Tracker Backend

A Firebase-powered backend API for the Productivity Tracker iOS app.

## Setup for Team Development

1. Install dependencies:
```bash
npm install
```

2. Set up Firebase (Each team member should do this individually):
   - Go to the [Firebase Console](https://console.firebase.google.com/)
   - Create a new project (or use an existing one)
   - Go to Project Settings > Service Accounts
   - Click "Generate New Private Key"
   - Save the downloaded JSON file as `serviceAccountKey.json` in the backend directory
   - ⚠️ DO NOT commit this file to git! It's already in .gitignore

3. Deploy to Firebase:
   - Install Firebase CLI: `npm install -g firebase-tools`
   - Login to Firebase: `firebase login`
   - Initialize Firebase: `firebase init`
   - Deploy: `firebase deploy`

## Security Notes

- Never commit `serviceAccountKey.json` to the repository
- Each team member should maintain their own Firebase project and credentials
- For production, consider using environment variables or a secure secret management system

## API Endpoints

### Tasks

- GET `/api/tasks` - Get all tasks
- POST `/api/tasks/add` - Create a new task
- GET `/api/tasks/:id` - Get a specific task
- DELETE `/api/tasks/:id` - Delete a task
- POST `/api/tasks/update/:id` - Update a task

## Task Schema

```javascript
{
  title: String,        // required
  description: String,  // optional
  completed: Boolean,   // defaults to false
  createdAt: Date,     // defaults to current date
  dueDate: Date,       // optional
  priority: String     // enum: ['low', 'medium', 'high'], defaults to 'medium'
}
```

## Local Development

To run the server locally:

1. Make sure you have the `serviceAccountKey.json` file in place (your own Firebase credentials)
2. Start the server:
```bash
node server.js
```

The server will run on port 5000 by default. 