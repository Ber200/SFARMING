import 'package:firebase_core/firebase_core.dart';

FirebaseOptions get android => const FirebaseOptions(
      apiKey: 'AIzaSyCRXJymIODOWSCQrnwMbinmq1u2ImBrfQU', // Android-specific API key from google-services.json
      appId: '1:550642869405:android:1a8beaf0b1e4f9adc16074',
      messagingSenderId: '550642869405',
      projectId: 'sfarming-5eb0e',
      databaseURL: 'https://sfarming-5eb0e-default-rtdb.asia-southeast1.firebasedatabase.app',
      storageBucket: 'sfarming-5eb0e.firebasestorage.app',
    );

FirebaseOptions get ios => const FirebaseOptions(
      apiKey: 'AIzaSyDw88LZFPbJyFkXNQVTWBDy_GwZ9kp5M-w', // Use web API key as placeholder, replace when iOS app is added
      appId: '1:550642869405:ios:YOUR_IOS_APP_ID', // Add iOS app in Firebase Console to get this
      messagingSenderId: '550642869405',
      projectId: 'sfarming-5eb0e',
      databaseURL: 'https://sfarming-5eb0e-default-rtdb.asia-southeast1.firebasedatabase.app',
      storageBucket: 'sfarming-5eb0e.firebasestorage.app',
    );

FirebaseOptions get web => const FirebaseOptions(
      apiKey: 'AIzaSyDw88LZFPbJyFkXNQVTWBDy_GwZ9kp5M-w',
      appId: '1:550642869405:web:8ffa60a1c1a45cf6c16074',
      messagingSenderId: '550642869405',
      projectId: 'sfarming-5eb0e',
      databaseURL: 'https://sfarming-5eb0e-default-rtdb.asia-southeast1.firebasedatabase.app',
      storageBucket: 'sfarming-5eb0e.firebasestorage.app',
      authDomain: 'sfarming-5eb0e.firebaseapp.com',
    );

// Stub function for web
FirebaseOptions getMobilePlatform() => web;
