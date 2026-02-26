# AI Content Assistant

A production-ready Flutter Android app that generates viral content ideas, hooks, scripts, titles, descriptions, and hashtags using Google Gemini API.

## Features

### Core Features

1. **Generate Screen**
   - Platform selection (YouTube, Shorts, Reels, TikTok)
   - Niche and target audience input
   - Duration selection with word count guidelines
   - Tone selection (Casual, Funny, Serious, Emotional, Informative, Corporate)
   - Goal selection (Views, Followers, Sales, Comments)
   - Topic input (max 500 characters)
   - Generate 10 AI-powered content ideas

2. **Detail Screen**
   - 3 attention-grabbing hooks
   - 5 alternative titles
   - Full script breakdown (Intro, Problem, Solution, Example, CTA)
   - SEO-optimized description
   - 10 relevant hashtags
   - Copy buttons for each section
   - Export to JSON
   - Regenerate option

3. **History**
   - Store last 200 generations
   - Newest first sorting
   - Favorite items
   - Clear history option
   - Export history to JSON

4. **Settings**
   - Language selection (TR/EN)
   - Theme mode (Light/Dark/System)
   - Daily free usage counter (3 detail generations per UTC day)
   - API key input with secure storage
   - API key test button

## Tech Stack

- **Flutter**: 3.16.0+ (Material 3)
- **Android**: min SDK 26
- **State Management**: Riverpod
- **Local Database**: Isar
- **Network**: Dio
- **Secure Storage**: flutter_secure_storage
- **Connectivity**: connectivity_plus

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models
│   ├── enums/                   # Enum definitions
│   │   ├── platform_type.dart
│   │   ├── duration_type.dart
│   │   ├── tone_type.dart
│   │   ├── goal_type.dart
│   │   └── app_language.dart
│   ├── content_idea.dart        # Content idea model
│   ├── content_detail.dart      # Content detail model
│   ├── generation_request.dart  # Request model
│   ├── history_item.dart        # Isar history entity
│   ├── app_settings.dart        # Settings model
│   └── api_response.dart        # API response wrapper
├── services/                    # Business logic
│   ├── secure_storage_service.dart
│   ├── database_service.dart
│   ├── gemini_service.dart
│   └── connectivity_service.dart
├── providers/                   # Riverpod providers
│   ├── settings_provider.dart
│   ├── generation_provider.dart
│   ├── history_provider.dart
│   └── connectivity_provider.dart
├── screens/                     # UI screens
│   ├── generate_screen.dart
│   ├── detail_screen.dart
│   ├── history_screen.dart
│   └── settings_screen.dart
├── widgets/                     # Reusable widgets
│   ├── custom_dropdown.dart
│   ├── custom_text_field.dart
│   ├── loading_button.dart
│   ├── idea_card.dart
│   ├── collapsible_section.dart
│   ├── list_collapsible_section.dart
│   ├── error_widget.dart
│   └── empty_state.dart
└── utils/                       # Utilities
    ├── input_validator.dart
    ├── copy_helper.dart
    └── export_helper.dart
```

## Setup Instructions

### Prerequisites

1. Install Flutter 3.16.0 or higher
2. Install Android Studio with Android SDK
3. Set up an Android emulator or connect a physical device

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ai_content_assistant
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code**
   ```bash
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Building for Production

**Debug APK:**
```bash
flutter build apk --debug
```

**Release APK:**
```bash
flutter build apk --release
```

**App Bundle:**
```bash
flutter build appbundle --release
```

## API Key Setup

1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create a new API key
3. Open the app and go to Settings
4. Enter your API key and tap "Save"
5. Tap "Test Key" to verify it works

**Note**: Without an API key, the app runs in mock mode with sample data.

## Daily Free Limit

- 3 detail generations per UTC day without an API key
- Limit resets at midnight UTC
- Add your own API key for unlimited generations

## Stability Features

1. **Never Crash**
   - All JSON parsing wrapped in try/catch
   - Graceful error handling

2. **Request Management**
   - Only one request at a time
   - Buttons disabled while loading
   - 800ms debounce on taps

3. **Network Safety**
   - 30-second timeout
   - 1 retry for timeout/5xx
   - Proper error messages for 401/403/429
   - Offline detection

4. **State Safety**
   - Check mounted before updating UI
   - Ignore outdated responses
   - Cancel request if user navigates away

5. **Performance Safety**
   - History capped at 200 items
   - Scrollable long texts
   - Avoid rebuild loops
   - Use const constructors

6. **Daily Limit Protection**
   - UTC-based tracking
   - Secure storage
   - Clock rollback protection

7. **Input Sanitation**
   - Trim whitespace
   - Max 500 characters
   - Escape special characters
   - Treat user input as content only

8. **Security**
   - Never log API key
   - No verbose logging in release
   - Secure storage for sensitive data

## Manual Test Scenarios

### 1. Success Flow
**Steps:**
1. Open app
2. Fill in all form fields
3. Tap "Generate Ideas"
4. Wait for 10 ideas to appear
5. Tap "Generate Details" on any idea
6. Verify all sections load correctly

**Expected:** Ideas and details generate successfully, UI updates smoothly

### 2. Invalid API Key
**Steps:**
1. Go to Settings
2. Enter invalid API key (e.g., "invalid_key_123")
3. Tap "Test Key"

**Expected:** Error message "Invalid API key. Please check your API key in settings."

### 3. Timeout
**Steps:**
1. Enable airplane mode or disconnect internet
2. Try to generate ideas
3. Wait 30+ seconds

**Expected:** Timeout error message with retry option

### 4. Offline
**Steps:**
1. Enable airplane mode
2. Open Generate screen
3. Observe offline warning
4. Try to tap "Generate Ideas"

**Expected:** Button disabled, offline warning visible

### 5. JSON Corruption
**Steps:**
1. Use mock mode (no API key)
2. Generate ideas
3. Verify mock data displays correctly

**Expected:** App handles mock data gracefully, no crashes

### 6. Rapid Taps
**Steps:**
1. Fill form
2. Rapidly tap "Generate Ideas" multiple times

**Expected:** Only one request sent, debounce prevents multiple requests

### 7. Long Script
**Steps:**
1. Select 8m duration
2. Generate ideas
3. Generate details
4. Scroll through full script

**Expected:** Script generates with 1200-1600 words, scrolls smoothly

### 8. Limit Exceeded
**Steps:**
1. Generate details 3 times without API key
2. Try to generate details a 4th time

**Expected:** Daily limit warning, suggestion to add API key

### 9. Navigation During Loading
**Steps:**
1. Start generating ideas
2. While loading, switch to History tab
3. Return to Generate tab

**Expected:** Request continues or cancels gracefully, no UI issues

### 10. Mock Mode
**Steps:**
1. Ensure no API key is set
2. Generate ideas
3. Verify mock data appears
4. Check Settings shows "Mock Mode"

**Expected:** App works with mock data, UI fully functional

## CI/CD

The project includes GitHub Actions workflow (`.github/workflows/android.yml`) that:

1. Runs on push to main/develop branches
2. Runs on pull requests to main
3. Performs code analysis
4. Runs tests
5. Builds APK and App Bundle
6. Uploads artifacts

## Dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.4.9
  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1
  dio: ^5.4.0
  flutter_secure_storage: ^9.0.0
  connectivity_plus: ^5.0.2
  google_fonts: ^6.1.0
  flutter_animate: ^4.3.0
  shimmer: ^3.0.0
  intl: ^0.18.1
  uuid: ^4.2.1
  json_annotation: ^4.8.1
  freezed_annotation: ^2.4.1
  share_plus: ^7.2.1
  path_provider: ^2.1.1
  permission_handler: ^11.1.0
```

## License

MIT License - feel free to use this project for personal or commercial purposes.

## Troubleshooting

### Build Issues

**Error: `flutter.sdk not set`**
- Create `android/local.properties` file with:
  ```
  flutter.sdk=/path/to/flutter
  ```

**Error: Isar build failures**
- Run: `flutter clean && flutter pub get`
- Then: `flutter packages pub run build_runner build --delete-conflicting-outputs`

**Error: Gradle sync failed**
- Ensure Java 17 is installed and set as default
- Run: `flutter doctor -v` to verify setup

### Runtime Issues

**App crashes on startup**
- Check `flutter doctor` for missing dependencies
- Ensure Android SDK is properly configured

**API requests failing**
- Check internet connection
- Verify API key in Settings
- Check API status at [Google AI Studio](https://makersuite.google.com)

**History not saving**
- Ensure app has storage permissions
- Check device storage space

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Support

For issues and feature requests, please use the GitHub issue tracker.

---

**Built with Flutter and ❤️**