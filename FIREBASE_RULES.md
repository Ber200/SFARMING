# Firebase Realtime Database Security Rules

## Fix for Permission Denied Error

The error `[firebase_database/permission-denied] permission_denied at /users` occurs because the default Firebase rules deny all access. You need to update your Firebase Realtime Database rules.

## Steps to Fix:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **sfarming-5eb0e**
3. Navigate to **Realtime Database** → **Rules** tab
4. Replace the existing rules with the following:

```json
{
  "rules": {
    "users": {
      ".read": "auth != null",
      ".write": "auth != null",
      "$userId": {
        ".read": "auth != null && ($userId == auth.uid || root.child('users').child(auth.uid).child('role').val() == 'admin')",
        ".write": "auth != null && ($userId == auth.uid || root.child('users').child(auth.uid).child('role').val() == 'admin')"
      }
    },
    "detections": {
      ".read": "auth != null",
      ".write": "auth != null",
      "$detectionId": {
        ".read": "auth != null && (data.child('userId').val() == auth.uid || root.child('users').child(auth.uid).child('role').val() == 'admin')",
        ".write": "auth != null && (data.child('userId').val() == auth.uid || root.child('users').child(auth.uid).child('role').val() == 'admin')"
      }
    },
    "treatments": {
      ".read": "auth != null",
      ".write": "auth != null",
      "$treatmentId": {
        ".read": "auth != null && (data.child('userId').val() == auth.uid || root.child('users').child(auth.uid).child('role').val() == 'admin')",
        ".write": "auth != null && (data.child('userId').val() == auth.uid || root.child('users').child(auth.uid).child('role').val() == 'admin')"
      }
    },
    "soil_data": {
      ".read": "auth != null",
      ".write": "auth != null",
      "$userId": {
        ".read": "auth != null && ($userId == auth.uid || root.child('users').child(auth.uid).child('role').val() == 'admin')",
        ".write": "auth != null && ($userId == auth.uid || root.child('users').child(auth.uid).child('role').val() == 'admin')"
      }
    },
    "notifications": {
      ".read": "auth != null",
      ".write": "auth != null",
      ".indexOn": ["userId", "eventKey"],
      "$notificationId": {
        ".read": "auth != null && (data.child('userId').val() == auth.uid || root.child('users').child(auth.uid).child('role').val() == 'admin')",
        ".write": "auth != null && (data.child('userId').val() == auth.uid || root.child('users').child(auth.uid).child('role').val() == 'admin')"
      }
    },
    "admin_settings": {
      ".read": "auth != null",
      ".write": "auth != null && root.child('users').child(auth.uid).child('role').val() == 'admin'",
      "$key": {
        ".read": "auth != null",
        ".write": "auth != null && root.child('users').child(auth.uid).child('role').val() == 'admin'"
      }
    }
  }
}
```

## Rule Explanation:

- **Users**: Authenticated users can read/write their own data. Admins can read/write all user data.
- **Detections**: Users can read/write their own detections. Admins can read/write all detections.
- **Treatments**: Users can read/write their own treatments. Admins can read/write all treatments.
- **Soil Data**: Users can read/write their own soil data. Admins can read/write all soil data.
- **Notifications**: Users can read/write their own notification records (the Notification Center). Admins can read/write all records (used for broadcasts). The `userId` + `eventKey` indexes power the per-farmer query and deduplication.
- **Admin Settings**: Any authenticated user can read (`admin_settings/model` is read by farmers to pick up deployed models; `map_boundary` by the farm map); only admins can write.

## Important Notes:

- All operations require authentication (`auth != null`)
- Users can only modify their own data unless they are admins
- Admin role is checked from the `users/{userId}/role` field
- After updating rules, click **Publish** to apply changes

> **Device tokens**: the app stores this device's FCM token under `users/{uid}/devices/{token}` (see `NOTIFICATIONS_SETUP.md`). The existing `users/$userId` rule already allows a farmer to write their own `devices` node; admins can read it for future push-server use.

## Firebase Storage Rules (for treatment photo proof)

1. Go to **Firebase Console** → **Storage** → **Rules**
2. Add rules to allow authenticated users to upload treatment proof images:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /treatment_proofs/{fileName} {
      allow read, write: if request.auth != null;
    }
    match /models/{any=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
        && request.resource.size < 50 * 1024 * 1024;
    }
  }
}
```

- `treatment_proofs` — farmer proof-of-treatment uploads.
- `models` — trained `.tflite` + `labels.txt` deployed from the admin Model Trainer (any authenticated user may read; only the admin app performs uploads). Download URLs returned by `getDownloadURL()` work without read rules regardless.

## Testing:

After applying these rules:
1. Log in as a regular farmer user - should be able to access their own data
2. Log in as an admin user - should be able to access all data
3. The Farmer Management screen should now work without permission errors

## Additional Rules Notes for New Features

To support the latest admin/farmer updates (archive/unarchive, duplicate prevention, dashboard filters), keep these checks in your rules:

- `treatments` should include `.indexOn: ["userId", "scheduleDate"]`
- Treatment writes should validate required fields:
  - `userId`
  - `disease`
  - `scheduleDate`
  - `status`
  - `type`
- Admin users must retain write access to:
  - treatment status changes (`pending`, `approved`, `completed`, `cancelled`)
  - archive toggles (`archived: true/false`)

Recommended write validation snippet for each treatment item:

```json
"treatments": {
  ".indexOn": ["userId", "scheduleDate"],
  "$treatmentId": {
    ".read": "auth != null && (data.child('userId').val() == auth.uid || root.child('users').child(auth.uid).child('role').val() == 'admin')",
    ".write": "auth != null && (data.child('userId').val() == auth.uid || root.child('users').child(auth.uid).child('role').val() == 'admin')",
    ".validate": "newData.hasChildren(['userId','disease','scheduleDate','status','type'])"
  }
}
```
