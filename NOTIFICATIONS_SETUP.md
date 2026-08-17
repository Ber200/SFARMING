# Notification System Setup Guide

The SMARTFARMING notification system has three delivery paths, all rooted in
**one persisted record per event** in the Firebase Realtime Database:

| Path | When it fires | What it delivers |
| --- | --- | --- |
| **Realtime listener** | App open / foreground | Real-time update of the Notification Center + unread badge |
| **Local exact-alarm** | App closed/backgrounded | Treatment & fertilization reminders (1 day / 1 hour before) — Android alarms survive reboot |
| **FCM foreground messages** | App open | Immediate local notification for server-pushed messages (wired for a future push server) |

No Cloud Functions / billing are required: the feature is fully functional with
in-app + local notifications, and device tokens are stored so a push server can
be added later without app changes.

---

## 1. Firebase Realtime Database

Apply the rules in `FIREBASE_RULES.md` (includes the new `notifications` node
with `userId` + `eventKey` indexes). The `notifications` collection holds one
record per farmer per event:

```json
{
  "userId": "farmer_uid",
  "type": "weatherAdvisory",        // treatmentReminder | fertilizerReminder | farmActivity
                                   // weatherAdvisory | weatherUpdate | tip | adminAnnouncement
  "title": "Heavy Rain Advisory",
  "body": "Heavy rain expected on Fri, Aug 14...",
  "actionRoute": "/weather-details",
  "relatedId": "2026-08-14",
  "eventKey": "weather|<uid>|2026-08-14|heavy-rain",
  "read": false,
  "readAt": null,
  "createdAt": 1755200000000
}
```

- `eventKey` is globally unique and **deduplicates** repeated writes (e.g. the
  15-minute weather refresh never re-creates an advisory for the same day).
- Admin announcements are **fanned out** into one record per farmer
  (`notification_repository.dart` → `broadcastToFarmers`), so farmers only ever
  query their own `userId` node.

## 2. Firebase Cloud Messaging (FCM)

1. In the Firebase Console → **Project settings → Cloud Messaging**: if the
   Firebase Android app has no FCM credentials yet, **Add an Android app**
   matching this package, then download the new `google-services.json` into
   `android/app/`. (The current `google-services.json` already references the
   project; a missing `google_app_id` means FCM isn't configured for the app.)
2. Make sure `firebase_messaging` is in `pubspec.yaml` (already present).
3. No server setup is required for the current feature.

### Device token registration

On login, `NotificationProvider.bindUser(userId)` calls
`NotificationService.registerDeviceToken(userId)`, which stores the token under
`users/{uid}/devices/{token}`. The token is refreshed automatically
(`onTokenRefresh`) and removed on logout. A future push server can read these
tokens to send closed-app messages for any notification type.

### Foreground messages

`FirebaseMessaging.onMessage` shows a local notification and persists a record
(deduped by `eventKey`). To push a message later, include these `data` keys:

```json
{
  "userId": "farmer_uid",
  "type": "weatherAdvisory",
  "title": "Heavy Rain Advisory",
  "body": "...",
  "actionRoute": "/weather-details",
  "relatedId": "2026-08-14",
  "eventKey": "weather|<uid>|2026-08-14|heavy-rain"
}
```

### Background / terminated

`firebaseMessagingBackgroundHandler` (top-level, registered in
`notification_service.dart`) writes the incoming record so it appears in the
center on next open.

## 3. Android

`android/app/src/main/AndroidManifest.xml` includes:
- `POST_NOTIFICATIONS` (Android 13+ runtime permission)
- `SCHEDULE_EXACT_ALARM` + `RECEIVE_BOOT_COMPLETED` (exact local reminders that
  survive reboot)

Notification channels (per spec):
- `alerts` — Alerts (weather/soil warnings)
- `reminders` — Reminders (treatment/fertilization)
- `updates` — Information (weather updates, tips, announcements)

## 4. What generates notifications

| Source | File | Records |
| --- | --- | --- |
| Treatment / fertilization schedule | `treatment_provider.dart` `_scheduleTreatmentReminders` | Reminder (1 day + 1 hour before) + local exact-alarm |
| Treatment completed | `treatment_provider.dart` `markAsCompleted*` | `farmActivity` record |
| Weather forecast (heavy rain / ≥35°C) | `weather_provider.dart` `_maybeSendWeatherAdvisory` | `weatherAdvisory` record + local alert |
| Rain warning (existing) | `weather_provider.dart` `_maybeSendRainWarning` | Local alert |
| SMARTFARMING tip | `notification_provider.dart` `_maybeGenerateTip` | `tip` record (max once / 3 days) |
| Admin announcement | `admin_announcement_screen.dart` | `adminAnnouncement` broadcast to all farmers |

## 5. Manual test checklist

1. **Notification Center**: log in as a farmer → open the bell → center groups
   records into Today / Yesterday / Earlier with relative timestamps.
2. **Unread badge**: bell shows the count; tapping a record marks it read and
   navigates; "Mark all as read" clears the badge.
3. **Treatment reminder (closed app)**: schedule a treatment for tomorrow in the
   farmer app → kill the app → the "Reminder (Tomorrow)" local notification
   fires at the right time.
4. **Weather advisory**: with weather alerts enabled and a forecast containing
   heavy rain / ≥35°C, the farmer gets an advisory in the center + a local alert.
5. **Admin broadcast**: log into the admin portal → Announcements → send →
   log in as a farmer → the announcement appears in the center.
6. **No scan notifications**: a detection/scan never creates a notification.
7. **FCM (optional, server pending)**: send a data message from the Firebase
   console targeting a registered token → appears in the center on next open.
