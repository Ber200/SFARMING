# SMARTFARMING

A Dual-Platform Flutter Capstone System for Rice Crop Disease Detection, Soil Health Monitoring, Weather-Integrated Treatment Scheduling, and Outbreak GIS Mapping.

---

## 📌 Overview

**SMARTFARMING** connects rice farmers in the field with agricultural administrators through real-time cloud synchronization, on-device machine learning, and GIS map visualizations:
- **Rice Leaf Disease Detection**: On-device TensorFlow Lite image classification (`Healthy`, `Bacterial Leaf Blight`, `Brown Spot`, `Sheath Blight`).
- **Soil Health Scanning**: LCD camera OCR & color signature analyzer for 6-in-1 physical soil detectors (pH, moisture, temperature, fertility, sunlight, humidity).
- **Weather & Crop Advisory**: 7-day meteorological forecasts integrated with treatment safety warnings.
- **Treatment & Fertilization Tracker**: Task calendars with photo proof and GPS tagging upon completion.
- **Outbreak GIS Mapping**: Exact latitude/longitude disease markers placed over farm boundary polygons.
- **Multi-Language Support**: English, Tagalog (Filipino), and Bisaya (Cebuano).

---

## 📱 Applications & Entry Points

The project uses a dual-entry point architecture within a single unified Flutter repository:

### 1. Farmer Mobile Application
- **Target Platform**: Android & iOS (Flutter Mobile)
- **Main Entry Point**: [`lib/main.dart`](lib/main.dart)
- **Features**: On-device TFLite disease inference, offline-first Hive storage (`LocalStorageService`), camera LCD soil detector scanner, treatment completion with camera proof and GPS, AI crop advisory.

### 2. Admin Web Panel
- **Target Platform**: Web (Flutter Web)
- **Main Entry Point**: [`lib/main_admin.dart`](lib/main_admin.dart)
- **Features**: Outbreak GIS mapping with exact GPS scan pins, workload volume analytics, farmer account & boundary management, treatment approval/archive management.

---

## 🛠 Technology Stack

- **Frontend**: Flutter 3.x (Dart), Provider state management
- **Backend & Database**: Firebase Realtime Database, Firebase Authentication, Firebase Storage, Firestore
- **Media CDN**: Cloudinary (unsigned image uploads) & Firebase Storage fallback
- **On-Device ML**: TensorFlow Lite (`.tflite`) for rice foliar disease classification
- **Generative AI**: Google Gemini AI (weather advisory, soil analysis, treatment recommendations)
- **Offline Storage & Sync**: Hive (`LocalStorageService`) & `SyncService`
- **Charts & GIS**: `fl_chart`, Google Maps Flutter, custom Canvas marker rendering

---

## 🗄 Firebase Realtime Database Architecture

- `/detections`: Disease scan logs (`userId`, `disease`, `confidence`, `imageUrl`, `latitude`, `longitude`, `timestamp`, `isArchived`).
- `/treatments`: Scheduled field treatments & fertilization activities (`userId`, `disease`, `remedy`, `scheduleDate`, `status`, `photoProofUrl`, `completedAt`, `latitude`, `longitude`).
- `/soil_data`: Sensor logs (`userId`, `phLevel`, `moisture`, `temperature`, `fertility`, `sunlight`, `humidity`, `timestamp`).
- `/users`: Farmer and administrator profiles (`name`, `email`, `role`, `farmName`, `cropType`, `boundaryCoordinates`).

---

## 💻 Local Development

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run Code Analysis & Tests
```bash
flutter analyze
flutter test
```

### 3. Run Farmer Mobile App
```bash
# Debug mode
flutter run -t lib/main.dart

# With optional Gemini API Key:
flutter run -t lib/main.dart --dart-define=GEMINI_API_KEY=YOUR_GEMINI_KEY
```

### 4. Run Admin Web App
```bash
# Chrome Web target
flutter run -d chrome -t lib/main_admin.dart
```

---

## 🚀 Production Web Build & Vercel Deployment

### Build the Web Admin Bundle
```bash
flutter build web --release -t lib/main_admin.dart
```
The compiled static assets are output to `build/web/`.

### Vercel Deployment
1. Connect this repository to [Vercel](https://vercel.com).
2. Configure the project settings:
   - **Framework Preset**: `Other`
   - **Build Command**: `flutter build web --release -t lib/main_admin.dart`
   - **Output Directory**: `build/web`
3. Add your Vercel production domain to **Firebase Authentication** $\rightarrow$ **Authorized Domains** in the Firebase Console.

---

## 🔒 Security Guidelines

- **No Secrets in Code**: Never commit raw API secrets, private keys, or service-account JSON files to Git.
- **Client Configuration**: Firebase client configurations (`google-services.json`, `firebase_config.dart`) are public client identifiers protected by Firebase Authentication and Firebase Security Rules.
- **Environment Variables**: Pass sensitive keys at build/run time using `--dart-define=GEMINI_API_KEY=...` or Vercel environment variables.
