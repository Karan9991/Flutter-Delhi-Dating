# Firebase setup

1. Create a Firebase project and add an iOS + Android app.
2. Download `google-services.json` and place it in `android/app/`.
3. Download `GoogleService-Info.plist` and place it in `ios/Runner/`.
4. Deploy the rules in this folder:
   - `firestore.rules`
   - `storage.rules`
5. Enable Email/Password in Firebase Authentication.
6. Enable Firebase Cloud Messaging for the project.

Notes:
- The matching check is done client-side.
- In this project configuration, FCM HTTP v1 calls are made directly from the Flutter app.
