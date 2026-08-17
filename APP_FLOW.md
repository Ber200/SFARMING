# SFARM — Application Flow

> **Stack:** Flutter · Provider · Firebase Auth + Firestore + Realtime DB · TFLite  
> **Platforms:** Android (Farmer App) · Web (Admin App)  
> **Last updated:** February 2026

---

## Table of Contents

1. [App Entry Point](#1-app-entry-point)
2. [Farmer App Flow](#2-farmer-app-flow)
   - [2.1 Splash & Auth Gate](#21-splash--auth-gate)
   - [2.2 Authentication Screens](#22-authentication-screens)
   - [2.3 Main Dashboard](#23-main-dashboard)
   - [2.4 Disease Detection](#24-disease-detection)
   - [2.5 Treatment Scheduling](#25-treatment-scheduling)
   - [2.6 Soil Monitoring](#26-soil-monitoring)
   - [2.7 Weather](#27-weather)
   - [2.8 Reports & Analytics](#28-reports--analytics)
   - [2.9 Profile & Settings](#29-profile--settings)
3. [Admin Web App Flow](#3-admin-web-app-flow)
   - [3.1 Admin Splash & Auth Gate](#31-admin-splash--auth-gate)
   - [3.2 Admin Dashboard](#32-admin-dashboard)
   - [3.3 Farmer Management](#33-farmer-management)
   - [3.4 Detection Records](#34-detection-records)
   - [3.5 Admin Calendar](#35-admin-calendar)
   - [3.6 Admin Soil & Weather](#36-admin-soil--weather)
4. [Navigation Map — Farmer App](#4-navigation-map--farmer-app)
5. [Navigation Map — Admin Web App](#5-navigation-map--admin-web-app)
6. [Global Systems](#6-global-systems)

---

## 1. App Entry Point

```
main.dart
│
├── kIsWeb + URL contains "admin" or ?app=admin
│   └── AdminWebApp  →  [Admin Flow]
│
└── (default)
    └── FarmerApp    →  [Farmer Flow]
```

`main.dart` checks the platform and URL at startup. Both apps share the same Firebase project but run completely separate widget trees, providers, and route maps.

---

## 2. Farmer App Flow

### 2.1 Splash & Auth Gate

```
FarmerSplashScreen  (animated pulsing logo, ~2s)
│
├── Firebase Auth → user is signed in AND role == 'farmer'
│   └── ──► Dashboard
│
└── Not signed in  OR  role == 'admin'
    └── ──► Login
```

> Admin accounts are explicitly blocked from the farmer app. If an admin somehow reaches this splash, they are redirected to Login.

---

### 2.2 Authentication Screens

```
Login Screen
│
├── [Forgot Password?]  ──►  ForgotPasswordScreen
│   └── Enter email → Firebase sends reset link → "Back to Login" → pop()
│
├── [Sign Up]  ──►  RegisterScreen
│   ├── Fill: Name, Email, Password, Confirm Password
│   ├── Role is hardcoded as 'farmer'
│   └── Success  ──►  Dashboard (pushReplacementNamed)
│
└── [Login]
    ├── Firebase Auth sign-in
    ├── Check role — if 'admin': show error snackbar, sign out, stay on Login
    └── Role == 'farmer'  ──►  Dashboard (pushReplacementNamed)
```

---

### 2.3 Main Dashboard

The Dashboard is the **root screen** of the farmer app. It hosts the bottom navigation bar.

```
Dashboard  (BottomNavigationBar — 4 tabs)
│
├── Tab 0 — Dashboard  (current)
│   ├── [Detect Disease] button  ──►  DetectionScreen
│   ├── Latest Detection card    ──►  (display only)
│   ├── Next Treatment card
│   │   └── [View All]  ──►  TreatmentCalendarScreen
│   ├── Soil card  ──►  SoilMonitoringScreen
│   └── Weather card  ──►  WeatherDetailsScreen
│
├── Tab 1 — Schedule  ──►  TreatmentCalendarScreen
├── Tab 2 — Reports   ──►  ReportsScreen
└── Tab 3 — Profile   ──►  ProfileScreen
```

**Bottom Navigation Bar:**

| Index | Icon | Label | Destination |
|-------|------|-------|-------------|
| 0 | `dashboard` | Dashboard | `DashboardScreen` |
| 1 | `calendar_today` | Schedule | `TreatmentCalendarScreen` |
| 2 | `analytics` | Reports | `ReportsScreen` |
| 3 | `person` | Profile | `ProfileScreen` |

---

### 2.4 Disease Detection

```
DetectionScreen
│
├── [Take Photo]  ──►  CameraDetectionScreen
│   └── Capture image → run TFLite model → DetectionResultScreen
│
└── [Choose from Gallery]
    └── Image picker → run TFLite model → DetectionResultScreen

DetectionResultScreen
│   Displays:
│   ├── Detected disease name
│   ├── Confidence percentage
│   ├── Description, symptoms, causes, prevention
│   └── Treatment protocol
│
├── [Schedule Treatment]  ──►  AddTreatmentScreen (with disease pre-filled)
└── [Search Google]  ──►  Opens browser (external)
```

**Detection result is saved to Firestore automatically** before navigating to the result screen.

---

### 2.5 Treatment Scheduling

```
TreatmentCalendarScreen
│   Displays:
│   ├── Monthly calendar (table_calendar)
│   ├── Treatments for selected day listed below
│   └── Each treatment card: name, time, notes, status
│
├── [FAB / Add Treatment]  ──►  AddTreatmentScreen
│   └── Returns true on save → calendar reloads
│
├── [Mark Complete]  → confirmation dialog → updates Firestore
└── [Delete]         → confirmation dialog → removes from Firestore

AddTreatmentScreen
│   Form fields:
│   ├── Treatment Name
│   ├── Date & Time picker
│   └── Notes (optional)
│
├── Weather check: if rain expected → shows warning dialog
│   ├── [Proceed anyway]  → save and pop(true)
│   └── [Cancel]          → stay on form
│
└── [Save]  → save to Firestore → pop(true) → calendar reloads
```

---

### 2.6 Soil Monitoring

```
SoilMonitoringScreen
│   Displays:
│   ├── pH Level card (color-coded: optimal / low / high)
│   └── Moisture card (color-coded: optimal / low / high)
│
├── [Tap any card]  ──►  Modal Bottom Sheet
│   ├── Detailed reading with status description
│   ├── Recommendations for the farmer
│   └── "Soil & Disease Relationship" section
│       └── Explains how current pH/moisture affects disease risk
│
└── [Manual Update button]
    └── Form dialog → enter new pH / moisture → save to Realtime DB
```

---

### 2.7 Weather

```
WeatherScreen
│   Displays:
│   ├── Animated status banner: GOOD / WARNING / BAD
│   ├── Temperature, humidity, wind speed, rainfall
│   └── Farming recommendation (safe to spray / delay / avoid)
│
└── [Tap status banner]  ──►  WeatherDetailsScreen
    └── Extended forecast, hourly breakdown, detailed conditions
```

---

### 2.8 Reports & Analytics

```
ReportsScreen  (read-only analytics, no sub-navigation)
│
├── Statistics row
│   ├── Total Detections
│   ├── Pending Treatments
│   └── Treatment Completion Rate (%)
│
├── Disease Distribution  →  Pie chart (fl_chart)
├── Monthly Detection Trend  →  Bar chart (fl_chart)
├── Disease Statistics breakdown  →  List
│
└── Treatment Coordination Analysis
    ├── Weather status (GOOD / WARNING / BAD)
    ├── Rain probability warning
    ├── Soil moisture level
    └── Overall recommendation for scheduling
```

---

### 2.9 Profile & Settings

```
ProfileScreen
│
├── [Edit Profile card]
│   └── Bottom sheet / dialog → update name, farm location → save to Firestore
│
├── [Farm Location card]
│   └── Text input → save location string to Firestore
│
├── [Settings card]
│   └── App preferences (notifications toggle, etc.)
│
├── [Language card]  ──►  Language Bottom Sheet
│   ├── English
│   ├── Filipino / Tagalog
│   └── Cebuano / Bisaya
│   └── Select → LanguageProvider.setLanguage() → entire app re-renders instantly
│
└── [Logout]
    └── Confirmation dialog
        ├── [Cancel]  → dismiss
        └── [Confirm] → Firebase signOut → Login (pushReplacementNamed)
```

---

## 3. Admin Web App Flow

The Admin app runs on web only. It has **no bottom navigation bar** — all navigation is done via quick-action cards and the AppBar back button.

### 3.1 Admin Splash & Auth Gate

```
AdminSplashScreen
│
├── Firebase Auth → user signed in AND role == 'admin'
│   └── ──► AdminDashboard
│
└── Not signed in  OR  role != 'admin'
    └── ──► AdminLogin
```

---

### 3.2 Admin Dashboard

```
AdminDashboard  (home screen for admin)
│
├── AppBar → [Profile icon]  ──►  AdminProfileScreen
│
├── Stats row (read-only)
│   ├── Total Farmers
│   ├── Total Detections
│   └── Pending Treatments
│
├── Disease Distribution chart  (read-only)
│
└── Quick Action Cards
    ├── [Farmers]       ──►  FarmerManagementScreen
    ├── [Detections]    ──►  DetectionRecordsScreen
    ├── [Calendar]      ──►  AdminCalendarScreen
    └── [Soil & Weather]──►  AdminSoilWeatherScreen
```

---

### 3.3 Farmer Management

```
FarmerManagementScreen
│   Streams all users with role == 'farmer' from Firestore
│
├── Each farmer card shows: name, email, farm location, join date
├── [View] button  → detail dialog (read-only)
├── [Edit] button  → edit dialog (placeholder — not yet implemented)
└── [Delete] button → confirmation dialog (placeholder — not yet implemented)
```

---

### 3.4 Detection Records

```
DetectionRecordsScreen
│   Streams all detection records system-wide from Firestore
│
├── Each record shows: leaf image, disease name, confidence %, date, farmer ID
├── [Details] button  → (stub — no-op)
└── [Download] button → (stub — no-op)
```

---

### 3.5 Admin Calendar

```
AdminCalendarScreen
│   System-wide view of all scheduled treatments across all farmers
│
└── Calendar with treatment events per farmer (read-only view)
```

---

### 3.6 Admin Soil & Weather

```
AdminSoilWeatherScreen
│   Aggregated view of soil sensor data and weather conditions
│
├── Soil pH and moisture readings
└── Current weather status and forecast
```

---

## 4. Navigation Map — Farmer App

```
FarmerSplashScreen
        │
        ▼
  ┌─────────────┐     ┌────────────────────┐     ┌──────────────────┐
  │  LoginScreen│────►│   RegisterScreen   │     │ForgotPasswordScr.│
  └─────────────┘     └────────────────────┘     └──────────────────┘
        │
        ▼
  ┌─────────────────────────────────────────────────────────────────┐
  │                     DashboardScreen  (Tab 0)                    │
  │  ┌──────────────┐  ┌──────────────┐  ┌──────────┐  ┌────────┐  │
  │  │  Detection   │  │  Treatment   │  │  Soil    │  │Weather │  │
  │  │  Screen      │  │  Calendar    │  │  Monitor │  │Screen  │  │
  │  └──────┬───────┘  └──────┬───────┘  └──────────┘  └───┬────┘  │
  │         │                 │                              │       │
  │         ▼                 ▼                              ▼       │
  │  DetectionResult   AddTreatment              WeatherDetails      │
  │  Screen            Screen                    Screen              │
  │         │                                                        │
  │         ▼                                                        │
  │  (Schedule Treatment) ──► AddTreatmentScreen                    │
  └─────────────────────────────────────────────────────────────────┘
        │              │                │
     Tab 1          Tab 2            Tab 3
        │              │                │
        ▼              ▼                ▼
  TreatmentCal.  ReportsScreen    ProfileScreen
                                       │
                               Language Bottom Sheet
                               (EN / FIL / CEB)
```

---

## 5. Navigation Map — Admin Web App

```
AdminSplashScreen
        │
        ▼
  AdminLoginScreen
        │
        ▼
  AdminDashboard ──────────────────────────────────────┐
        │                                               │
        ├──► FarmerManagementScreen                     │
        ├──► DetectionRecordsScreen                     │
        ├──► AdminCalendarScreen                        │
        ├──► AdminSoilWeatherScreen                     │
        └──► AdminProfileScreen (via AppBar icon) ──────┘
```

---

## 6. Global Systems

### Language Switching

Language selection is available from `ProfileScreen → Language card`. It applies **instantly and globally** across the entire farmer app without any restart.

```
User selects language in ProfileScreen
        │
        ▼
LanguageProvider.setLanguage(AppLanguage.filipino)
        │
        ├── notifyListeners()  (immediate)
        │       │
        │       ▼
        │   Consumer<LanguageProvider> at FarmerApp root rebuilds
        │       │
        │       ▼
        │   MaterialApp.locale = Locale('fil')
        │       │
        │       ▼
        │   All widgets re-render with Filipino strings
        │
        └── SharedPreferences.setString('app_language', 'fil')  (persisted)
```

**Supported languages:**

| Language | Code | Display Name |
|----------|------|--------------|
| English | `en` | English |
| Filipino / Tagalog | `fil` | Filipino / Tagalog |
| Cebuano / Bisaya | `ceb` | Cebuano / Bisaya |

---

### Authentication & Role Guard

| Role | App | Blocked From |
|------|-----|--------------|
| `farmer` | FarmerApp (Android) | Admin web routes |
| `admin` | AdminWebApp (Web) | Farmer app (redirected to Login) |

Firebase Auth is the source of truth. Both splash screens check the role from Realtime Database before proceeding.

---

### Data Flow

```
Sensor / Camera / User Input
        │
        ▼
Provider (DetectionProvider / TreatmentProvider / SoilProvider / WeatherProvider)
        │
        ├── Reads from: Firebase Realtime DB, Firestore, TFLite model, Weather API
        └── Writes to:  Firestore (detections, treatments), Realtime DB (soil)
                │
                ▼
        Widgets consume via Consumer<T> or context.read<T>()
```

---

### Fallback Behaviors

| Scenario | Behavior |
|----------|----------|
| No internet | Cached Hive data shown; network error message displayed |
| Sensor offline | "Sensor offline" label shown in soil screen |
| Weather API fails | "Weather data unavailable" message shown |
| Missing translation key | Falls back to English → then raw key (never crashes) |
| Admin tries farmer app | Signed out, redirected to Login with error snackbar |
| Farmer tries admin URL | AdminSplashScreen redirects to AdminLogin |
