# Hourglass - Social Productivity Tracker

A productivity tracking iOS app that gamifies time management through social accountability and visual progress tracking.

**Video Demo**: [bit.ly/cs278hourglass](youtu.be/gj5VHRDr-i8)  
**Liveness Demo**: [youtube.com/shorts/PxyfM8p-abk](https://www.youtube.com/shorts/PxyfM8p-abk) 

## What It Does

**Hourglass** helps users track productive activities while building accountability through social features:

- **Activity Tracking**: Log time spent on customizable productivity categories with visual grid-based interface
- **Social Feed**: Share progress with friends and view their productivity updates in real-time
- **Profile Management**: Follow/unfollow users, upload profile pictures, manage social connections
- **Productivity Visualization**: Color-coded time blocks showing daily/weekly productivity patterns
- **User Authentication**: Secure login/signup with profile customization

## Technical Implementation

### Frontend (iOS)
- **SwiftUI** - Native iOS interface with MVVM architecture
- **Firebase SDK** - Authentication, Firestore database, and cloud storage
- **Real-time Updates** - Live social feed and productivity data synchronization

### Backend (Node.js)
- **Express.js** - RESTful API server
- **Firebase Admin** - Server-side Firebase integration
- **Modular Routes** - Separate endpoints for users, productivity data, and tasks

### Database
- **Firebase Firestore** - NoSQL cloud database for real-time data
- **Firebase Storage** - Profile image hosting
- **Firebase Auth** - User management and security

### Key Features
- Real-time social feed with productivity sharing
- Customizable activity categories with color coding
- Profile picture uploads with image processing
- Follow/unfollow system with user discovery
- Time-based productivity logging and visualization

## Architecture

```
iOS App (SwiftUI) ↔ Firebase Services ↔ Node.js API
                      ↓
               Firestore Database
```

The app uses a hybrid approach: direct Firebase integration for real-time features and a Node.js backend for complex business logic, ensuring scalable social functionality with responsive user experience. 
