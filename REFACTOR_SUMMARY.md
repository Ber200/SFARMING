# Refactor Summary: Admin Mobile → Web Dashboard

## Overview

The system is now split into:
- **Mobile App (Android/iOS)** → Farmer/User only. No admin features.
- **Web Dashboard** → Admin only. All admin features.

## 1. Mobile App (Farmer-Only)

### Removed
- All admin routes, screens, and navigation
- Admin role option in registration (now always `farmer`)
- Admin dashboard, farmer management, detection records, model trainer, admin profile

### Kept
- Login, Register, Forgot Password
- Dashboard (soil, weather, detections, treatments)
- Disease detection (camera, gallery)
- Treatment scheduling (calendar, add treatment)
- Soil monitoring (humidity, pH)
- Weather
- Reports & analytics
- Profile

### Routing
- `FarmerSplashScreen` → If authenticated (farmer) → Dashboard, else → Login
- `FarmerLoginScreen` → On success → Dashboard (admin users are told to use Web)
- `RegisterScreen` → Always creates farmer account, no role selector

### Glassmorphism
- Login screen uses glass containers and gradient background
- Farmer splash uses glass decoration
- Theme uses `AppTheme.glassDecoration()` for cards

---

## 2. Web Dashboard (Admin-Only)

### Entry
- **main.dart** – Main app (Farmer). On web, loads Admin only when path contains `/admin` or `?app=admin`
- **main_admin.dart** – Admin-only entry. Run with: `flutter run -t lib/main_admin.dart -d chrome`

### Routes
- `AdminSplashScreen` → If authenticated (admin) → Admin Dashboard, else → Admin Login
- `AdminLoginScreen` → Admin-only login (farmers get "Access denied")
- Admin Dashboard, Farmer Management, Detection Records, Model Trainer, Admin Profile
- **Admin Calendar** – Treatment calendar with approve/reschedule/cancel
- **Admin Soil & Weather** – Soil (humidity, pH) and weather for all farmers

### Features
1. **User Management** – View, edit, delete farmers
2. **Treatment Management** – Admin Calendar with:
   - Daily / Weekly / Monthly views
   - Filter by status (Pending, Approved, Completed, Cancelled) and type
   - Approve, Reschedule, Cancel, Mark Complete
   - Real-time updates via Firebase
3. **Disease/Detection Records** – View all detections
4. **Soil & Weather** – Per-farmer soil (humidity, pH/acidity) and area weather
5. **Model Trainer** – Placeholder for model training
6. **Admin Profile** – Admin profile management

### Treatment Flow
- Farmer books treatment → Stored in Firebase with `status: 'pending'`
- Admin sees new bookings in real time in the calendar
- Admin can: Approve, Reschedule, Cancel, or Mark Complete
- Status values: `pending` → `approved` → `completed` or `cancelled`

### Glassmorphism
- Admin theme with indigo/blue palette
- Glass-style cards and containers
- Gradient backgrounds
- `adminWebTheme` and `adminWebDarkTheme` in `AppTheme`

---

## 3. Files Created/Modified

### New Files
- `lib/main_admin.dart` – Admin-only entry point
- `lib/app/farmer_app.dart` – Farmer MaterialApp
- `lib/app/admin_web_app.dart` – Admin Web MaterialApp
- `lib/screens/splash/farmer_splash_screen.dart`
- `lib/screens/splash/admin_splash_screen.dart`
- `lib/screens/auth/farmer_login_screen.dart`
- `lib/screens/admin/admin_login_screen.dart`
- `lib/screens/admin/admin_calendar_screen.dart` – Treatment calendar
- `lib/screens/admin/admin_soil_weather_screen.dart` – Soil & weather

### Modified
- `lib/main.dart` – Main app (Farmer). Web admin at `/admin` or `?app=admin`
- `lib/core/routes/app_routes.dart` – `farmerRoutes` and `adminWebRoutes`
- `lib/core/theme/app_theme.dart` – `adminWebTheme`, `adminWebDarkTheme`, admin colors
- `lib/screens/auth/register_screen.dart` – Role fixed to `farmer`, role selector removed
- `lib/screens/admin/admin_dashboard_screen.dart` – Calendar, Soil & Weather, glass UI, logout → adminLogin
- `lib/services/firebase_service.dart` – `updateTreatmentSchedule()` added

---

## 4. Run Instructions

### Main App (Farmer – Mobile & Web)
```bash
flutter run -d android    # Android
flutter run -d chrome     # Web at /
flutter build web        # Build for web
```

### Web Admin (separate path)
```bash
# Option 1: Query param (same build)
# Open: http://localhost:port/?app=admin

# Option 2: Admin-only entry point
flutter run -t lib/main_admin.dart -d chrome

# Option 3: Build admin for /admin path
flutter build web -t lib/main_admin.dart --base-href /admin/
```

## 5. Primary Color
- All themes use **#41644A** as the primary color.

---

## 6. Humidity, Acidity (pH), and Weather

- **Admin Soil & Weather** – Lists all farmers with:
  - Soil moisture (%)
  - Soil pH
  - Status (OK/LOW/HIGH)
  - Area weather (Panabo City): temperature, humidity, condition, rain probability, wind
- **Farmer Soil Monitoring** – Existing soil monitoring with disease relationship
- **Farmer Weather** – Existing weather and weather details

---

## 7. Real-Time Updates

- Firebase Realtime Database streams for treatments and detections
- New farmer treatments appear in the admin calendar in real time
- No extra push setup required for basic real-time behavior
