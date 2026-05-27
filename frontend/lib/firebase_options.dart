// Firebase project credentials supplied at build time via --dart-define.
//
// Android setup checklist:
//   1. Place google-services.json in android/app/
//   2. In android/build.gradle add:
//        classpath 'com.google.gms:google-services:4.4.0'   (inside buildscript > dependencies)
//   3. In android/app/build.gradle add at the very bottom:
//        apply plugin: 'com.google.gms.google-services'
//
// iOS setup checklist:
//   1. Place GoogleService-Info.plist in ios/Runner/ (add via Xcode, not just file copy)
//   2. In Xcode → Signing & Capabilities → add "Push Notifications" capability
//   3. In Xcode → Signing & Capabilities → add "Background Modes" and tick
//      "Background fetch" and "Remote notifications"
//
// Build with:
//   flutter run \
//     --dart-define=FIREBASE_PROJECT_ID=medgraph-app \
//     --dart-define=FIREBASE_MESSAGING_SENDER_ID=1234567890 \
//     --dart-define=FIREBASE_API_KEY=AIza... \
//     --dart-define=FIREBASE_APP_ID_ANDROID=1:1234567890:android:abc... \
//     --dart-define=FIREBASE_APP_ID_IOS=1:1234567890:ios:def... \
//     --dart-define=FIREBASE_STORAGE_BUCKET=medgraph-app.appspot.com

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return ios;
    }
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: ''),
    appId: String.fromEnvironment(
      'FIREBASE_APP_ID_ANDROID',
      defaultValue: '1:000000000000:android:0000000000000000000000',
    ),
    messagingSenderId: String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: '',
    ),
    projectId: String.fromEnvironment(
      'FIREBASE_PROJECT_ID',
      defaultValue: 'medgraph-app',
    ),
    storageBucket: String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
      defaultValue: '',
    ),
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_IOS_API_KEY',
      defaultValue: '',
    ),
    appId: String.fromEnvironment(
      'FIREBASE_APP_ID_IOS',
      defaultValue: '1:000000000000:ios:0000000000000000000000',
    ),
    messagingSenderId: String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: '',
    ),
    projectId: String.fromEnvironment(
      'FIREBASE_PROJECT_ID',
      defaultValue: 'medgraph-app',
    ),
    storageBucket: String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
      defaultValue: '',
    ),
    iosBundleId: String.fromEnvironment(
      'FIREBASE_IOS_BUNDLE_ID',
      defaultValue: 'com.medgraph.app',
    ),
  );
}
