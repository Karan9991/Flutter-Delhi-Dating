import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'chat_presence_service.dart';

class NotificationIntent {
  const NotificationIntent({
    required this.type,
    this.matchId,
    this.otherUserId,
  });

  final String type;
  final String? matchId;
  final String? otherUserId;

  static NotificationIntent? fromData(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    if (type == null || type.isEmpty) return null;

    return NotificationIntent(
      type: type,
      matchId: data['matchId']?.toString(),
      otherUserId: data['otherUserId']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      if (matchId != null && matchId!.isNotEmpty) 'matchId': matchId,
      if (otherUserId != null && otherUserId!.isNotEmpty)
        'otherUserId': otherUserId,
    };
  }
}

typedef NotificationTapHandler = void Function(NotificationIntent intent);

class NotificationService {
  NotificationService({
    required FirebaseMessaging messaging,
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required FlutterLocalNotificationsPlugin localNotifications,
    required ChatPresenceService chatPresence,
  }) : _messaging = messaging,
       _auth = auth,
       _firestore = firestore,
       _localNotifications = localNotifications,
       _chatPresence = chatPresence;

  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final ChatPresenceService _chatPresence;

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'pulse_alerts',
        'Delhi Dating Alerts',
        description: 'Notifications for likes, matches, and chat messages.',
        importance: Importance.high,
      );

  bool _initialized = false;
  String? _activeToken;
  String? _registeredUid;
  NotificationTapHandler? _tapHandler;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedMessageSubscription;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _configureLocalNotifications();
    await _requestPermission();
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    _authSubscription = _auth.authStateChanges().listen((user) {
      unawaited(_handleAuthStateChange(user));
    });
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
      unawaited(_handleTokenRefresh(token));
    });
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      unawaited(_showForegroundNotification(message));
    });
    _openedMessageSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleRemoteMessageTap,
    );

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleRemoteMessageTap(initialMessage);
    }

    await _handleAuthStateChange(_auth.currentUser);
  }

  void setTapHandler(NotificationTapHandler handler) {
    _tapHandler = handler;
  }

  Future<void> handlePushSettingChange({required bool enabled}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final token = _activeToken ?? await _messaging.getToken();
    _activeToken = token;
    if (token == null || token.isEmpty) return;

    if (enabled) {
      await _requestPermission();
      await _saveToken(uid: user.uid, token: token);
      return;
    }
    await _removeToken(uid: user.uid, token: token);
  }

  Future<void> _configureLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) {
            final intent = NotificationIntent.fromData(decoded);
            if (intent != null) _tapHandler?.call(intent);
          }
        } catch (_) {
          // Ignore malformed payload.
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);
  }

  Future<void> _requestPermission() async {
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } catch (_) {
      // Permission APIs are platform-dependent.
    }

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _handleAuthStateChange(User? user) async {
    if (user == null) {
      if (_registeredUid != null) {
        await _removeCurrentTokenForUid(_registeredUid!);
      }
      _registeredUid = null;
      return;
    }

    if (_registeredUid != null && _registeredUid != user.uid) {
      await _removeCurrentTokenForUid(_registeredUid!);
    }
    _registeredUid = user.uid;
    await _syncTokenForUser(user.uid);
  }

  Future<void> _handleTokenRefresh(String token) async {
    if (token.isEmpty) return;
    final previousToken = _activeToken;
    _activeToken = token;

    final user = _auth.currentUser;
    if (user == null) return;

    final pushEnabled = await _isPushEnabled(user.uid);
    if (!pushEnabled) {
      await _removeToken(uid: user.uid, token: token);
      return;
    }

    if (previousToken != null &&
        previousToken.isNotEmpty &&
        previousToken != token) {
      await _removeToken(uid: user.uid, token: previousToken);
    }
    await _saveToken(uid: user.uid, token: token);
  }

  Future<void> _syncTokenForUser(String uid) async {
    final token = _activeToken ?? await _messaging.getToken();
    _activeToken = token;
    if (token == null || token.isEmpty) return;

    final pushEnabled = await _isPushEnabled(uid);
    if (!pushEnabled) {
      await _removeToken(uid: uid, token: token);
      return;
    }
    await _saveToken(uid: uid, token: token);
  }

  Future<void> _removeCurrentTokenForUid(String uid) async {
    final token = _activeToken ?? await _messaging.getToken();
    _activeToken = token;
    if (token == null || token.isEmpty) return;
    await _removeToken(uid: uid, token: token);
  }

  Future<void> _saveToken({required String uid, required String token}) async {
    await _firestore.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  Future<void> _removeToken({
    required String uid,
    required String token,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayRemove([token]),
    }, SetOptions(merge: true));
  }

  Future<bool> _isPushEnabled(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final map = userDoc.data();
    final settings = map?['settings'] as Map<String, dynamic>?;
    return settings?['pushNotifications'] as bool? ?? true;
  }

  void _handleRemoteMessageTap(RemoteMessage message) {
    final intent = NotificationIntent.fromData(message.data);
    if (intent != null) _tapHandler?.call(intent);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final intent = NotificationIntent.fromData(message.data);
    if (intent == null) return;
    if (intent.type == 'chat' && _chatPresence.isViewingMatch(intent.matchId)) {
      return;
    }

    final title = message.notification?.title ?? _titleForType(intent.type);
    final body = message.notification?.body ?? _bodyForType(intent.type);
    if (title == null || body == null) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'pulse_alerts',
        'Delhi Dating Alerts',
        channelDescription: 'Notifications for likes, matches, and chat.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: jsonEncode(intent.toMap()),
    );
  }

  String? _titleForType(String type) {
    switch (type) {
      case 'chat':
        return 'New message';
      case 'match':
        return "It's a match!";
      case 'like':
        return 'New like';
      default:
        return null;
    }
  }

  String? _bodyForType(String type) {
    switch (type) {
      case 'chat':
        return 'Open the app to reply.';
      case 'match':
        return 'You matched with someone new.';
      case 'like':
        return 'Someone liked your profile.';
      default:
        return null;
    }
  }

  void dispose() {
    _authSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
    _foregroundSubscription?.cancel();
    _openedMessageSubscription?.cancel();
  }
}
