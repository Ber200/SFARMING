# AgriGuide AI (Gemini) Setup

The **AI Farm Assistant** bubble (bottom-right on every farmer screen) is powered
by the Google **Gemini** REST API. It answers in the app's active language
(English / Filipino / Cebuano) and automatically posts a soil/environment
analysis into the chat after the farmer saves pH, moisture, or humidity
readings.

## 1. Get a Gemini API key

1. Go to [Google AI Studio](https://aistudio.google.com/apikey).
2. Click **Create API key** and choose a Google Cloud project.
3. Copy the key (starts with `AIza...`).

> The key is **never stored or committed** in the repo. It is injected at
> build/run time via `--dart-define`.

## 2. Run with the key

```bash
# Android / iOS
flutter run --dart-define=GEMINI_API_KEY=AIza...

# Web
flutter run -d chrome --dart-define=GEMINI_API_KEY=AIza...
```

> Do **not** hard-code the key anywhere in `lib/`. The app reads it from
> `String.fromEnvironment('GEMINI_API_KEY')` (see `lib/config/gemini_config.dart`).

## 3. Configure the model (optional)

`lib/config/gemini_config.dart` defaults to the free-tier model:

- `model = 'gemini-2.5-flash'` — good quality, lower free quota.
- Swap to `'gemini-2.5-flash-lite'` for a higher free quota with a smaller model.

## 4. What happens if the key is missing

The chat screen shows a friendly "not set up yet" banner and nothing is sent.
The floating bubble still appears so farmers see the assistant exists.

## 5. Offline / limits

- When the device is offline the auto soil-analysis is skipped and chat replies
  fail with a clear "you are offline" message.
- On HTTP 429 the app shows a "request limit reached" message with a Retry
  button. Requests time out after 30 seconds.

## 6. Where the code lives

| Concern              | File                                             |
| -------------------- | ------------------------------------------------ |
| Key, model, prompt   | `lib/config/gemini_config.dart`                  |
| Chat message model   | `lib/models/chat_message_model.dart`             |
| REST client          | `lib/services/gemini_service.dart`               |
| Chat state           | `lib/providers/chat_provider.dart`               |
| Chat history (Hive)  | `lib/services/local_storage_service.dart`        |
| Chat screen          | `lib/screens/mobile/ai/ai_chat_screen.dart`      |
| Floating bubble      | `lib/widgets/ai_assistant_bubble.dart`           |
| Bubble overlay       | `lib/app/farmer_app.dart` (`_AssistantOverlay`)  |
| Soil auto-analysis   | `lib/screens/mobile/soil/soil_monitoring_screen.dart` |
| Translated strings   | `lib/core/l10n/app_localizations.dart` (`ai_*`)  |
