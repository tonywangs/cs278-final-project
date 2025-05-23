# Productivity Tracker Backend

A simple backend API for the Productivity Tracker iOS app.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Create a `.env` file in the root directory with the following content:
```
PORT=5000
MONGODB_URI=mongodb://localhost:27017/productivity-tracker
```

3. Make sure MongoDB is installed and running on your system.

4. Start the server:
```bash
node server.js
```

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