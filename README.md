# Pulse - Flutter Dating App

Pulse is a production-ready Flutter dating app with Firebase Authentication, Firestore, and Storage. It includes onboarding, discover swipes, matches, and real-time chat.

## Features
- Email/password authentication
- Profile onboarding with photos and interests
- Profile basics (pronouns, job, education, height)
- Discover feed with swipe actions
- Matches list with last message preview
- Real-time chat powered by Firestore
- Firebase Cloud Messaging (chat, match, and like push notifications)
- Settings with discovery + notification toggles
- Safety + privacy placeholders for launch requirements

## Setup
1. Install dependencies:
   - `flutter pub get`
2. Firebase:
   - Add `android/app/google-services.json`
   - Add `ios/Runner/GoogleService-Info.plist`
   - Deploy Firestore/Storage rules in `firebase/`
3. Configure FCM HTTP v1 client credentials:
   - Open `lib/config/fcm_http_v1_config.dart`
   - Ensure `kFcmServiceAccountAssetPath` points to your JSON file in `lib/config/`
   - Ensure `kEnableUnsafeClientSideFcm = true`
4. Update app identifiers:
   - Android: `applicationId` in `android/app/build.gradle.kts`
   - iOS: `PRODUCT_BUNDLE_IDENTIFIER` in `ios/Runner.xcodeproj`
5. Run:
   - `flutter run`

## Publishing checklist
- Replace the app icon and splash screen.
- Update `android:label` in `android/app/src/main/AndroidManifest.xml`.
- Update `CFBundleDisplayName` in `ios/Runner/Info.plist`.
- Add your Privacy Policy and Terms of Service.
- Configure App Store / Play Store listings.
- Set up release signing for Android and iOS.

## Firebase data model
- `users/{uid}`: profile document
  - `fcmTokens`: array of push tokens
  - `settings`: push/message/match/like notification preferences
- `swipes/{uid}/liked/{otherUid}`
- `swipes/{uid}/passed/{otherUid}`
- `swipes/{uid}/likedBy/{otherUid}`
- `matches/{matchId}`
- `matches/{matchId}/messages/{messageId}`

## Notes
Matching is client-side for simplicity. For tighter security, move match creation and like-checks into a trusted backend endpoint and restrict `/swipes` reads further.
This build sends FCM HTTP v1 directly from the app by using a service-account key in the client (not recommended for production security).
