import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';

import '../config/fcm_http_v1_config.dart';

class FcmHttpV1Service {
  FcmHttpV1Service(this._firestore);

  final FirebaseFirestore _firestore;
  AutoRefreshingAuthClient? _authClient;
  Map<String, dynamic>? _serviceAccount;

  static const _scope = 'https://www.googleapis.com/auth/firebase.messaging';

  Future<void> sendLikeNotification({
    required String senderUid,
    required String recipientUid,
  }) {
    return _sendByType(
      type: _NotificationType.like,
      senderUid: senderUid,
      recipientUid: recipientUid,
    );
  }

  Future<void> sendMatchNotification({
    required String senderUid,
    required String recipientUid,
    required String matchId,
  }) {
    return _sendByType(
      type: _NotificationType.match,
      senderUid: senderUid,
      recipientUid: recipientUid,
      matchId: matchId,
    );
  }

  Future<void> sendChatNotification({
    required String senderUid,
    required String recipientUid,
    required String matchId,
    required String messageText,
  }) {
    return _sendByType(
      type: _NotificationType.chat,
      senderUid: senderUid,
      recipientUid: recipientUid,
      matchId: matchId,
      messageText: messageText,
    );
  }

  Future<void> _sendByType({
    required _NotificationType type,
    required String senderUid,
    required String recipientUid,
    String? matchId,
    String? messageText,
  }) async {
    if (!kEnableUnsafeClientSideFcm) return;
    if (senderUid.isEmpty ||
        recipientUid.isEmpty ||
        senderUid == recipientUid) {
      return;
    }

    try {
      final authClient = await _getAuthClient();
      final serviceJson = await _loadServiceAccount();
      final projectId = (serviceJson['project_id'] as String?)?.trim() ?? '';
      if (projectId.isEmpty) return;
      final appProjectId = Firebase.app().options.projectId;
      if (projectId != appProjectId) {
        if (kDebugMode) {
          debugPrint(
            'FCM HTTP v1 disabled: service-account project_id '
            '"$projectId" does not match app project "$appProjectId".',
          );
        }
        return;
      }

      final recipientDoc = await _firestore
          .collection('users')
          .doc(recipientUid)
          .get();
      final recipientData = recipientDoc.data() ?? <String, dynamic>{};
      if (!_isEnabled(recipientData['settings'], type)) return;

      final tokens = List<String>.from(recipientData['fcmTokens'] ?? const [])
          .map((token) => token.trim())
          .where((token) => token.isNotEmpty)
          .toList();
      if (tokens.isEmpty) return;

      final senderDoc = await _firestore
          .collection('users')
          .doc(senderUid)
          .get();
      final senderName =
          (senderDoc.data()?['displayName'] as String?)?.trim().isNotEmpty ==
              true
          ? (senderDoc.data()?['displayName'] as String).trim()
          : 'Someone';

      final endpoint = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
      );
      final invalidTokens = <String>[];

      for (final token in tokens) {
        final payload = _buildPayload(
          type: type,
          token: token,
          senderName: senderName,
          senderUid: senderUid,
          matchId: matchId,
          messageText: messageText,
        );

        final response = await authClient.post(
          endpoint,
          headers: const {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode(payload),
        );

        if (response.statusCode >= 200 && response.statusCode < 300) continue;
        if (kDebugMode) {
          debugPrint(
            'FCM HTTP v1 send failed '
            '[${response.statusCode}] ${response.body}',
          );
        }
        if (_isInvalidTokenResponse(response.body)) {
          invalidTokens.add(token);
        }
      }

      if (invalidTokens.isNotEmpty) {
        await _firestore.collection('users').doc(recipientUid).set({
          'fcmTokens': FieldValue.arrayRemove(invalidTokens),
        }, SetOptions(merge: true));
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Client-side FCM send failed: $error');
      }
    }
  }

  Future<AutoRefreshingAuthClient> _getAuthClient() async {
    final existing = _authClient;
    if (existing != null) return existing;

    final parsed = await _loadServiceAccount();
    final credentials = ServiceAccountCredentials.fromJson(parsed);
    final client = await clientViaServiceAccount(credentials, const [_scope]);
    _authClient = client;
    return client;
  }

  Future<Map<String, dynamic>> _loadServiceAccount() async {
    final cached = _serviceAccount;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(kFcmServiceAccountAssetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Service account JSON must be an object.');
    }
    _serviceAccount = decoded;
    return decoded;
  }

  bool _isEnabled(dynamic rawSettings, _NotificationType type) {
    final settings = rawSettings is Map
        ? rawSettings
        : const <String, dynamic>{};
    if (settings['pushNotifications'] == false) return false;
    switch (type) {
      case _NotificationType.chat:
        return settings['messageNotifications'] != false;
      case _NotificationType.match:
        return settings['matchNotifications'] != false;
      case _NotificationType.like:
        return settings['likeNotifications'] != false;
    }
  }

  Map<String, dynamic> _buildPayload({
    required _NotificationType type,
    required String token,
    required String senderName,
    required String senderUid,
    String? matchId,
    String? messageText,
  }) {
    final data = <String, String>{
      'type': type.value,
      'otherUserId': senderUid,
      if (matchId != null && matchId.isNotEmpty) 'matchId': matchId,
    };

    late final String title;
    late final String body;

    switch (type) {
      case _NotificationType.chat:
        final trimmed = (messageText ?? '').trim();
        title = senderName;
        if (trimmed.isEmpty) {
          body = 'New message';
        } else {
          body = trimmed.length > 120
              ? '${trimmed.substring(0, 117)}...'
              : trimmed;
        }
        break;
      case _NotificationType.match:
        title = "It's a match!";
        body = 'You matched with $senderName.';
        break;
      case _NotificationType.like:
        title = 'New like';
        body = '$senderName liked your profile.';
        break;
    }

    return {
      'message': {
        'token': token,
        'notification': {'title': title, 'body': body},
        'data': data,
        'android': {
          'priority': 'HIGH',
          'notification': {'channel_id': 'pulse_alerts', 'sound': 'default'},
        },
        'apns': {
          'headers': {'apns-priority': '10'},
          'payload': {
            'aps': {'sound': 'default'},
          },
        },
      },
    };
  }

  bool _isInvalidTokenResponse(String body) {
    final lower = body.toLowerCase();
    return lower.contains('unregistered') ||
        lower.contains('invalid registration token') ||
        lower.contains('not a valid fcm registration token');
  }

  void dispose() {
    _authClient?.close();
  }
}

enum _NotificationType {
  chat('chat'),
  match('match'),
  like('like');

  const _NotificationType(this.value);
  final String value;
}
