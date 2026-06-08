# Build & Platform Configuration

## Prerequisites
- Flutter **3.24+** (Dart 3.4+) on the stable channel
- Android Studio / Xcode for device builds
- (Optional) A Firebase project — see [`FIREBASE_SETUP.md`](FIREBASE_SETUP.md)

## Generate native folders
This repo ships `lib/`, `pubspec.yaml`, assets and docs. Generate the platform
projects without overwriting `lib/`:
```bash
flutter create --org com.carcarepro --project-name carcare_pro --platforms=android,ios,web .
flutter pub get
flutter analyze
```

---

## Android

### `android/app/build.gradle` (or `build.gradle.kts`)
```gradle
android {
    compileSdk = 34

    defaultConfig {
        applicationId = "com.carcarepro.app"
        minSdk = 23          // firebase_auth needs 23; notifications need 21+
        targetSdk = 34
        multiDexEnabled = true
    }

    compileOptions {
        // flutter_local_notifications >= 17 requires core library desugaring
        coreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.2")
}
```

### `android/app/src/main/AndroidManifest.xml`
Inside `<manifest>` (before `<application>`):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```
Inside `<application>` (for scheduled reminders to survive reboot):
```xml
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```
> The app schedules **inexact** alarms, so `SCHEDULE_EXACT_ALARM` is **not**
> required. Add it only if you switch to exact scheduling.

### Firebase on Android (only if enabled)
`flutterfire configure` adds `google-services.json` and the Gradle plugin lines.
Because the app passes explicit `DefaultFirebaseOptions`, the google‑services
plugin is optional, but recommended for full compatibility.

---

## iOS

### `ios/Podfile`
```ruby
platform :ios, '13.0'
```

### `ios/Runner/Info.plist`
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>CarCare Pro needs photo access to attach vehicle and document images.</string>
<key>NSCameraUsageDescription</key>
<string>CarCare Pro needs camera access to capture documents.</string>
```
For **Google Sign‑In**, add the reversed client id URL scheme (printed by
`flutterfire configure`):
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array><string>com.googleusercontent.apps.XXXXXX': REPLACE_WITH_REVERSED_CLIENT_ID</string></array>
  </dict>
</array>
```

### `ios/Runner/AppDelegate.swift` — local notifications
```swift
import UIKit
import Flutter
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### Capabilities (Xcode → Signing & Capabilities)
- **Sign in with Apple** (for Apple auth)
- **Push Notifications** is *not* needed for local notifications.

---

## Build commands
```bash
flutter run                              # debug, offline mode
flutter run --dart-define=ENABLE_FIREBASE=true
flutter build apk --release              # Android APK
flutter build appbundle --release        # Play Store
flutter build ios --release              # iOS (macOS only)
```

## Troubleshooting
| Symptom | Fix |
|---------|-----|
| `version solving failed` for `intl` | `flutter pub upgrade --major-versions` (your Flutter SDK pins a specific `intl`). |
| `Default FirebaseApp is not initialized` | You enabled Firebase without running `flutterfire configure`, or with placeholder `firebase_options.dart`. Configure it, or keep `ENABLE_FIREBASE=false`. |
| Notifications not firing on Android 13+ | Grant the runtime notification permission (the app requests it). |
| Desugaring error on Android build | Ensure `coreLibraryDesugaringEnabled` + the `desugar_jdk_libs` dependency above. |
| Google Fonts not loading offline | `google_fonts` fetches on first run; bundle the `.ttf` and add a `fonts:` section to ship fully offline. |
