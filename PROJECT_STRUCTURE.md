# SMARTFARMING Project Structure

## Overview

This document describes the project structure and architecture of the SMARTFARMING application.

## Architecture

The project follows **Clean Architecture** principles with clear separation of concerns:

```
lib/
├── core/                    # Core functionality and configuration
│   ├── config/             # Configuration files (Firebase, Cloudinary, etc.)
│   ├── routes/             # App routing configuration
│   └── theme/              # App theme and styling
├── models/                 # Data models
├── services/               # Business logic and external services
├── providers/              # State management (Provider pattern)
├── screens/                # UI screens
│   ├── auth/               # Authentication screens
│   ├── mobile/             # Mobile app screens
│   │   ├── detection/      # Disease detection screens
│   │   ├── treatment/      # Treatment scheduling screens
│   │   ├── soil/           # Soil monitoring screens
│   │   ├── weather/        # Weather screens
│   │   └── reports/        # Reports and analytics
│   └── admin/              # Admin dashboard screens
├── widgets/                # Reusable UI widgets
├── utils/                  # Utility functions and helpers
└── main.dart               # App entry point
```

## Key Components

### Models (`lib/models/`)
- `user_model.dart` - User data model
- `detection_model.dart` - Disease detection results
- `treatment_model.dart` - Treatment schedules
- `soil_data_model.dart` - Soil monitoring data
- `weather_model.dart` - Weather information
- `disease_info_model.dart` - Disease information and treatment protocols

### Services (`lib/services/`)
- `firebase_service.dart` - Firebase operations (Auth, Database)
- `cloudinary_service.dart` - Image upload to Cloudinary
- `tflite_service.dart` - TensorFlow Lite model inference
- `weather_service.dart` - Weather API integration
- `notification_service.dart` - Push and local notifications

### Providers (`lib/providers/`)
- `auth_provider.dart` - Authentication state management
- `detection_provider.dart` - Disease detection state
- `treatment_provider.dart` - Treatment scheduling state
- `soil_provider.dart` - Soil monitoring state
- `weather_provider.dart` - Weather data state

### Screens (`lib/screens/`)

#### Authentication
- `splash_screen.dart` - App splash screen
- `login_screen.dart` - User login
- `register_screen.dart` - User registration
- `forgot_password_screen.dart` - Password reset

#### Mobile App
- `dashboard_screen.dart` - Main dashboard
- `detection_screen.dart` - Disease detection
- `detection_result_screen.dart` - Detection results display
- `treatment_calendar_screen.dart` - Treatment calendar
- `add_treatment_screen.dart` - Schedule treatment
- `soil_monitoring_screen.dart` - Soil data monitoring
- `weather_screen.dart` - Weather forecast
- `reports_screen.dart` - Analytics and reports

#### Admin Dashboard
- `admin_dashboard_screen.dart` - Admin overview
- `farmer_management_screen.dart` - Manage farmers
- `detection_records_screen.dart` - View all detections
- `model_trainer_screen.dart` - Model training interface

## Data Flow

1. **User Interaction** → Screen Widget
2. **Screen Widget** → Provider (State Management)
3. **Provider** → Service (Business Logic)
4. **Service** → Firebase/External API
5. **Response** → Provider → Screen Widget → UI Update

## State Management

The app uses **Provider** pattern for state management:
- Each feature has its own provider
- Providers extend `ChangeNotifier`
- Screens consume providers using `Consumer` or `Provider.of`

## Firebase Structure

```
users/
  {userId}/
    name, email, role, farmLocation, createdAt

detections/
  {detectionId}/
    userId, imageUrl, disease, confidence, timestamp, notes

treatments/
  {treatmentId}/
    userId, disease, scheduleDate, status, notes, type, createdAt

soil_data/
  {userId}/
    ph, moisture, timestamp
```

## Offline Support

- TFLite model runs locally (no internet required for detection)
- Hive for local storage of pending uploads
- Automatic sync when internet is available
- Local caching of disease information

## Security

- Firebase Authentication for user management
- Role-based access control (Farmer/Admin)
- Firebase Realtime Database rules
- Secure Cloudinary upload presets

## Performance Optimizations

- Image compression before upload
- Lazy loading of lists
- Const widgets where possible
- Isolate for model inference
- Pagination for admin dashboard
- Caching for weather data
