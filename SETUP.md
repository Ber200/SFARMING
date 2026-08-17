# SMARTFARMING Setup Guide

## Prerequisites

1. Flutter SDK (latest stable version)
2. Android Studio / VS Code with Flutter extensions
3. Firebase account
4. Cloudinary account
5. OpenWeatherMap API key (optional, for weather features)

## Setup Steps

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Firebase Configuration

1. Create a Firebase project at https://console.firebase.google.com
2. Enable Authentication (Email/Password)
3. Create Realtime Database
4. Enable Cloud Messaging
5. Download `google-services.json` and place it in `android/app/`
6. Update `lib/core/config/firebase_config.dart` with your Firebase credentials

### 3. Cloudinary Configuration

1. Create a Cloudinary account at https://cloudinary.com
2. Get your Cloud Name, API Key, and API Secret
3. Create an upload preset
4. Update `lib/core/config/cloudinary_config.dart` with your credentials

### 4. Weather API (Optional)

1. Get API key from https://openweathermap.org/api
2. Update `lib/services/weather_service.dart` with your API key

### 5. TFLite Model

1. Place your MobileNetV2 model file as `assets/models/model.tflite`
2. Ensure `assets/models/labels.txt` contains the disease labels (already created)

### 6. Android Configuration

1. Update `android/app/build.gradle` with your package name if needed
2. Ensure minimum SDK is 21 or higher

### 7. Run the App

```bash
# For Android
flutter run

# For Web
flutter run -d chrome
```

## Firebase Database Rules

Set up your Firebase Realtime Database rules:

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
    }
  }
}
```

## Troubleshooting

### Model Loading Issues
- Ensure model file is in `assets/models/model.tflite`
- Check that labels.txt matches your model's output classes
- Verify model input size (should be 224x224 for MobileNetV2)

### Firebase Issues
- Verify `google-services.json` is in the correct location
- Check Firebase project settings
- Ensure all Firebase services are enabled

### Image Upload Issues
- Verify Cloudinary credentials
- Check upload preset permissions
- Ensure internet connectivity

## Notes

- The app supports offline mode for disease detection (model runs locally)
- Treatment schedules sync when internet is available
- Admin dashboard is web-only (Flutter Web)
- Mobile app is Android-focused but can be adapted for iOS
