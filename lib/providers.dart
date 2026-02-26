import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'models/like_item.dart';
import 'models/match_item.dart';
import 'models/user_profile.dart';
import 'models/user_settings.dart';
import 'services/auth_service.dart';
import 'services/chat_presence_service.dart';
import 'services/chat_service.dart';
import 'services/delhi_access_service.dart';
import 'services/fcm_http_v1_service.dart';
import 'services/firestore_service.dart';
import 'services/matching_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);
final storageProvider = Provider<FirebaseStorage>(
  (ref) => FirebaseStorage.instance,
);
final firebaseMessagingProvider = Provider<FirebaseMessaging>(
  (ref) => FirebaseMessaging.instance,
);
final localNotificationsPluginProvider =
    Provider<FlutterLocalNotificationsPlugin>(
      (ref) => FlutterLocalNotificationsPlugin(),
    );
final chatPresenceServiceProvider = Provider<ChatPresenceService>((ref) {
  final service = ChatPresenceService();
  ref.onDispose(service.dispose);
  return service;
});

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.read(firebaseAuthProvider)),
);
final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(ref.read(firestoreProvider)),
);
final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(ref.read(storageProvider)),
);
final delhiAccessServiceProvider = Provider<DelhiAccessService>(
  (ref) => DelhiAccessService(),
);
final matchingServiceProvider = Provider<MatchingService>(
  (ref) => MatchingService(
    ref.read(firestoreProvider),
    ref.read(fcmHttpV1ServiceProvider),
  ),
);
final chatServiceProvider = Provider<ChatService>(
  (ref) => ChatService(
    ref.read(firestoreProvider),
    ref.read(fcmHttpV1ServiceProvider),
  ),
);
final fcmHttpV1ServiceProvider = Provider<FcmHttpV1Service>((ref) {
  final service = FcmHttpV1Service(ref.read(firestoreProvider));
  ref.onDispose(service.dispose);
  return service;
});
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService(
    messaging: ref.read(firebaseMessagingProvider),
    auth: ref.read(firebaseAuthProvider),
    firestore: ref.read(firestoreProvider),
    localNotifications: ref.read(localNotificationsPluginProvider),
    chatPresence: ref.read(chatPresenceServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.read(firebaseAuthProvider).authStateChanges(),
);

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final auth = ref.watch(authStateProvider).value;
  if (auth == null) return const Stream.empty();
  return ref.read(firestoreServiceProvider).profileStream(auth.uid);
});

final discoverProfilesProvider = FutureProvider.autoDispose<List<UserProfile>>((
  ref,
) async {
  final auth = ref.watch(authStateProvider).value;
  if (auth == null) return [];
  return ref.read(firestoreServiceProvider).fetchDiscoverableProfiles(auth.uid);
});

final matchesProvider = StreamProvider.autoDispose<List<MatchItem>>((ref) {
  final auth = ref.watch(authStateProvider).value;
  if (auth == null) return const Stream.empty();
  return ref.read(firestoreServiceProvider).matchesStream(auth.uid);
});

final incomingLikesProvider = StreamProvider.autoDispose<List<LikeItem>>((ref) {
  final auth = ref.watch(authStateProvider).value;
  if (auth == null) return const Stream.empty();
  return ref.read(firestoreServiceProvider).incomingLikesStream(auth.uid);
});

final userSettingsProvider = StreamProvider.autoDispose<UserSettings>((ref) {
  final auth = ref.watch(authStateProvider).value;
  if (auth == null) {
    return Stream.value(
      const UserSettings(
        pushNotifications: true,
        messageNotifications: true,
        matchNotifications: true,
        likeNotifications: true,
        messageReadReceipts: true,
        showAge: true,
        showDistance: true,
        discoverable: true,
        themeMode: UserSettings.themeLight,
        accentColorValue: UserSettings.defaultAccentColorValue,
      ),
    );
  }
  return ref.read(firestoreServiceProvider).settingsStream(auth.uid);
});

final onboardingSeenProvider = StateProvider<bool>((ref) => false);
final delhiAccessGrantedProvider = StateProvider<bool>((ref) => false);
