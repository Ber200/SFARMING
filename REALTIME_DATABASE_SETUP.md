# Firebase Realtime Database Setup Guide

## Overview

This project uses **Firebase Realtime Database** for real-time data synchronization. Realtime Database is a cloud-hosted NoSQL database that stores data as JSON and synchronizes in real-time.

## Step 1: Enable Realtime Database in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **Realtime Database** (in the left sidebar)
4. Click **Create Database**
5. Choose a location (select closest to your users)
6. Choose **Start in test mode** (for development) or **Production mode**
7. Click **Enable**

## Step 2: Verify Dependencies

The dependency is already in `pubspec.yaml`:
```yaml
firebase_database: ^10.1.0
```

Run:
```bash
flutter pub get
```

## Step 3: Realtime Database Security Rules

Set up security rules in Firebase Console → Realtime Database → Rules tab:

### Production Rules (Recommended)

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid || root.child('users').child(auth.uid).child('role').val() === 'admin'",
        ".write": "$uid === auth.uid || root.child('users').child(auth.uid).child('role').val() === 'admin'"
      }
    },
    "detections": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "treatments": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "soil_data": {
      "$uid": {
        ".read": "$uid === auth.uid || root.child('users').child(auth.uid).child('role').val() === 'admin'",
        ".write": "$uid === auth.uid"
      }
    },
    "admin_settings": {
      ".read": "auth != null",
      ".write": "auth != null && root.child('users').child(auth.uid).child('role').val() === 'admin'"
    }
  }
}
```

### Development/Test Rules (Temporary)

```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```

⚠️ **Warning**: Test mode allows anyone to read/write. Use only for development!

## Step 4: Database Structure

Your Realtime Database structure should look like this:

```
{
  "users": {
    "userId1": {
      "name": "John Doe",
      "email": "john@example.com",
      "role": "farmer",
      "farmLocation": "Panabo City",
      "createdAt": 1234567890
    },
    "userId2": {
      "name": "Admin User",
      "email": "admin@example.com",
      "role": "admin",
      "createdAt": 1234567890
    }
  },
  "detections": {
    "detectionId1": {
      "userId": "userId1",
      "imageUrl": "https://...",
      "disease": "Bacterial Leaf Blight",
      "confidence": 0.95,
      "timestamp": 1234567890,
      "notes": "Optional notes"
    }
  },
  "treatments": {
    "treatmentId1": {
      "userId": "userId1",
      "disease": "Bacterial Leaf Blight",
      "scheduleDate": 1234567890,
      "status": "pending",
      "type": "treatment",
      "notes": "Apply copper-based bactericides",
      "createdAt": 1234567890
    }
  },
  "soil_data": {
    "userId1": {
      "ph": 6.5,
      "moisture": 45.0,
      "timestamp": 1234567890
    }
  },
  "admin_settings": {
    "map_boundary": [
      { "lat": 7.3, "lng": 125.6 }
    ],
    "model": {
      "version": "model_1700000000000",
      "timestamp": 1700000000000,
      "classes": ["Bacterial Leaf Blight", "Healthy"],
      "modelUrl": "https://firebasestorage.googleapis.com/...",
      "labelsUrl": "https://firebasestorage.googleapis.com/...",
      "active": true
    }
  }
}
```

## Step 5: Using FirebaseService

The `FirebaseService` class is already created at `lib/services/firebase_service.dart`.

### Example Usage:

```dart
import 'package:smartfarming/services/firebase_service.dart';

final firebaseService = FirebaseService();

// Save detection
final detectionId = await firebaseService.saveDetection(detectionModel);

// Get user data stream
firebaseService.getUserDataStream(userId).listen((user) {
  print('User: ${user?.name}');
});

// Get treatments
firebaseService.getTreatmentsByUser(userId).listen((treatments) {
  print('Treatments: ${treatments.length}');
});
```

## Step 6: Database URL Configuration

1. In Firebase Console → Realtime Database
2. Copy your database URL (e.g., `https://your-project-id-default-rtdb.firebaseio.com/`)
3. Update `lib/core/config/firebase_config_stub.dart` with the database URL:

```dart
static FirebaseOptions get web => const FirebaseOptions(
  apiKey: 'YOUR_WEB_API_KEY',
  appId: 'YOUR_WEB_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  databaseURL: 'https://your-project-id-default-rtdb.firebaseio.com/', // Add this
  storageBucket: 'YOUR_STORAGE_BUCKET',
  authDomain: 'YOUR_AUTH_DOMAIN',
);
```

Do the same for `android` and `ios` configurations.

## Step 7: Initialize Database Reference

The service already initializes the database reference:

```dart
final DatabaseReference _database = FirebaseDatabase.instance.ref();
```

Make sure Firebase is initialized in `main.dart`:

```dart
await Firebase.initializeApp(
  options: FirebaseConfig.currentPlatform,
);
```

## Step 8: Testing Connection

Test your Realtime Database connection:

```dart
import 'package:firebase_database/firebase_database.dart';

final database = FirebaseDatabase.instance.ref();
final snapshot = await database.child('test').get();
print('Database connected: ${snapshot.exists}');
```

## Features of Realtime Database

✅ **Real-time synchronization** - Data updates instantly across all clients
✅ **Offline support** - Works offline and syncs when online
✅ **Simple structure** - JSON tree structure
✅ **Low latency** - Fast read/write operations
✅ **Built-in security** - Security rules for access control

## Common Operations

### Reading Data

```dart
// Single read
final snapshot = await database.child('users').child(userId).get();
if (snapshot.exists) {
  final data = snapshot.value as Map;
  print(data['name']);
}

// Real-time listener
database.child('users').child(userId).onValue.listen((event) {
  final data = event.snapshot.value as Map;
  print('Updated: ${data['name']}');
});
```

### Writing Data

```dart
// Set data
await database.child('users').child(userId).set({
  'name': 'John Doe',
  'email': 'john@example.com',
});

// Update specific fields
await database.child('users').child(userId).update({
  'name': 'Jane Doe',
});

// Push (auto-generate key)
final ref = database.child('detections').push();
await ref.set(detectionData);
```

### Querying Data

```dart
// Order by and filter
final query = database
    .child('detections')
    .orderByChild('userId')
    .equalTo(userId)
    .limitToLast(10);

query.onValue.listen((event) {
  // Handle results
});
```

## Troubleshooting

### Error: Permission denied
- Check security rules
- Verify user is authenticated
- Ensure rules allow the operation

### Error: Database not found
- Verify database URL is correct
- Check Firebase project configuration
- Ensure database is enabled in Firebase Console

### Data not syncing
- Check internet connection
- Verify security rules allow read/write
- Check Firebase Console for errors
- Ensure Firebase is properly initialized

### Offline persistence not working
- Realtime Database has built-in offline support
- Data is cached locally automatically
- Syncs when connection is restored

## Best Practices

1. **Use security rules** - Never use test mode in production
2. **Structure data efficiently** - Flatten data structure when possible
3. **Index queries** - Create indexes for frequently queried fields
4. **Monitor usage** - Check Firebase Console for read/write usage
5. **Handle errors** - Always wrap database operations in try-catch
6. **Clean up listeners** - Cancel streams when not needed

## Differences: Realtime Database vs Firestore

| Feature | Realtime Database | Firestore |
|---------|------------------|-----------|
| Structure | JSON tree | Document collections |
| Queries | Limited | Advanced queries |
| Real-time | Yes | Yes |
| Offline | Built-in | Built-in |
| Cost | Pay per GB | Pay per read/write |
| Best for | Simple, real-time data | Complex queries, scalability |

## Next Steps

1. ✅ Enable Realtime Database in Firebase Console
2. ✅ Set up security rules
3. ✅ Configure database URL in Firebase config
4. ✅ Test database connection
5. ✅ Start using FirebaseService in your app

Your `FirebaseService` is already configured and ready to use!
