# Firestore Setup Guide

## Overview

This project now supports **Firestore** (Cloud Firestore) in addition to Realtime Database. Firestore is a NoSQL document database that offers better scalability and querying capabilities.

## Step 1: Enable Firestore in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **Firestore Database**
4. Click **Create Database**
5. Choose **Start in test mode** (for development) or **Production mode**
6. Select a location (choose closest to your users)
7. Click **Enable**

## Step 2: Install Dependencies

The dependency has been added to `pubspec.yaml`:
```yaml
cloud_firestore: ^4.13.6
```

Run:
```bash
flutter pub get
```

## Step 3: Firestore Security Rules

Set up Firestore security rules in Firebase Console → Firestore Database → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null && 
                     (request.auth.uid == userId || 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
      allow write: if request.auth != null && 
                      (request.auth.uid == userId || 
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
    
    // Detections collection
    match /detections/{detectionId} {
      allow read, write: if request.auth != null;
    }
    
    // Treatments collection
    match /treatments/{treatmentId} {
      allow read, write: if request.auth != null;
    }
    
    // Soil data collection
    match /soil_data/{userId} {
      allow read: if request.auth != null && 
                     (request.auth.uid == userId || 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Step 4: Using Firestore Service

The `FirestoreService` class has been created at `lib/services/firestore_service.dart`.

### Example Usage:

```dart
import 'package:smartfarming/services/firestore_service.dart';

final firestoreService = FirestoreService();

// Save detection
final detectionId = await firestoreService.saveDetection(detectionModel);

// Get user data stream
firestoreService.getUserDataStream(userId).listen((user) {
  print('User: ${user?.name}');
});

// Get treatments
firestoreService.getTreatmentsByUser(userId).listen((treatments) {
  print('Treatments: ${treatments.length}');
});
```

## Step 5: Update Models for Firestore

Firestore uses `Timestamp` instead of milliseconds. The models have been updated to support both formats.

### Converting Realtime Database to Firestore

If you want to migrate from Realtime Database to Firestore:

1. Update providers to use `FirestoreService` instead of `FirebaseService`
2. Models already support both timestamp formats
3. Data structure remains the same

## Differences: Realtime Database vs Firestore

| Feature | Realtime Database | Firestore |
|---------|------------------|-----------|
| Structure | JSON tree | Document collections |
| Queries | Limited | Advanced queries |
| Scalability | Good | Excellent |
| Offline | Built-in | Built-in |
| Real-time | Yes | Yes |
| Cost | Pay per GB | Pay per read/write |

## Firestore Indexes

Some queries may require composite indexes. Firebase will prompt you to create them when needed, or you can create them manually in Firebase Console → Firestore → Indexes.

Common indexes needed:
- `detections` collection: `userId` + `timestamp` (descending)
- `treatments` collection: `userId` + `scheduleDate`

## Testing

1. Test Firestore connection:
```dart
final firestore = FirebaseFirestore.instance;
final testDoc = await firestore.collection('test').doc('test').get();
print('Firestore connected: ${testDoc.exists}');
```

2. Verify rules are working correctly
3. Test offline persistence
4. Monitor usage in Firebase Console

## Troubleshooting

### Error: Missing or insufficient permissions
- Check Firestore security rules
- Verify user is authenticated
- Check role-based access

### Error: Index required
- Create the required index in Firebase Console
- Wait for index to build (can take a few minutes)

### Offline persistence not working
- Firestore offline persistence is enabled by default
- Check device storage space
- Verify internet connectivity for sync
