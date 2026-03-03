import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';
import 'fcm_http_v1_service.dart';

class ChatService {
  ChatService(this._db, this._fcmService);

  final FirebaseFirestore _db;
  final FcmHttpV1Service _fcmService;

  static String conversationIdForUsers(String uidA, String uidB) {
    final ordered = [uidA, uidB]..sort();
    return ordered.join('_');
  }

  Future<String?> resolveOtherUserId({
    required String matchId,
    required String currentUid,
  }) async {
    final matchDoc = await _db.collection('matches').doc(matchId).get();
    if (!matchDoc.exists) return null;
    final userIds = List<String>.from(matchDoc.data()?['userIds'] ?? const []);
    if (!userIds.contains(currentUid)) return null;
    return userIds.firstWhere((uid) => uid != currentUid, orElse: () => '');
  }

  Stream<List<ChatMessage>> messagesStream(String matchId) {
    return _db
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ChatMessage.fromDoc(doc)).toList(),
        );
  }

  Future<void> sendMessage({
    required String matchId,
    required String senderId,
    required String text,
  }) async {
    final normalized = text.trim();
    if (normalized.isEmpty) return;
    final matchDoc = await _db.collection('matches').doc(matchId).get();
    if (!matchDoc.exists) {
      throw StateError('Conversation is no longer available.');
    }
    final userIds = List<String>.from(matchDoc.data()?['userIds'] ?? const []);
    if (!userIds.contains(senderId)) {
      throw StateError('You are not a participant in this conversation.');
    }
    final recipientUid = userIds.firstWhere(
      (uid) => uid != senderId,
      orElse: () => '',
    );
    if (recipientUid.isEmpty) {
      throw StateError('Could not find the other participant.');
    }
    final blocked = await _isBlockedBetween(
      blockerUid: senderId,
      blockedUid: recipientUid,
    );
    final blockedByOther = await _isBlockedBetween(
      blockerUid: recipientUid,
      blockedUid: senderId,
    );
    if (blocked || blockedByOther) {
      throw StateError('Messaging is unavailable for this chat.');
    }

    final messageRef = _db
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .doc();
    await messageRef.set({
      'senderId': senderId,
      'text': normalized,
      'sentAt': FieldValue.serverTimestamp(),
      'readBy': [senderId],
    });

    await _db.collection('matches').doc(matchId).set({
      'lastMessage': normalized,
      'lastMessageAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _fcmService.sendChatNotification(
      senderUid: senderId,
      recipientUid: recipientUid,
      matchId: matchId,
      messageText: normalized,
    );
  }

  Future<String> createOrGetConversation({
    required String currentUid,
    required String otherUid,
  }) async {
    if (currentUid == otherUid) {
      throw StateError('Invalid conversation participants.');
    }
    final blocked = await _isBlockedBetween(
      blockerUid: currentUid,
      blockedUid: otherUid,
    );
    final blockedByOther = await _isBlockedBetween(
      blockerUid: otherUid,
      blockedUid: currentUid,
    );
    if (blocked || blockedByOther) {
      throw StateError('This user is unavailable for chat.');
    }

    final conversationId = conversationIdForUsers(currentUid, otherUid);
    final ref = _db.collection('matches').doc(conversationId);
    final snapshot = await ref.get();

    if (!snapshot.exists) {
      await ref.set({
        'userIds': [currentUid, otherUid],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
        'lastMessageAt': null,
        'isMatch': false,
      });
    }

    return conversationId;
  }

  Future<void> reportUser({
    required String reporterUid,
    required String reportedUid,
    required String matchId,
    required String reason,
    String? details,
  }) async {
    final normalizedReason = reason.trim();
    final normalizedDetails = details?.trim() ?? '';
    await _db.collection('reports').add({
      'source': 'chat',
      'matchId': matchId,
      'reporterUid': reporterUid,
      'reportedUid': reportedUid,
      'reason': normalizedReason.isEmpty ? 'Other' : normalizedReason,
      if (normalizedDetails.isNotEmpty) 'details': normalizedDetails,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> blockUser({
    required String blockerUid,
    required String blockedUid,
    required String matchId,
    String reason = 'User blocked from chat',
  }) async {
    final batch = _db.batch();
    final blockedAt = FieldValue.serverTimestamp();

    batch.set(
      _db
          .collection('users')
          .doc(blockerUid)
          .collection('blocks')
          .doc(blockedUid),
      {
        'blockerUid': blockerUid,
        'blockedUid': blockedUid,
        'matchId': matchId,
        'reason': reason,
        'source': 'chat',
        'blockedAt': blockedAt,
      },
      SetOptions(merge: true),
    );

    batch.set(
      _db
          .collection('swipes')
          .doc(blockerUid)
          .collection('passed')
          .doc(blockedUid),
      {'createdAt': blockedAt, 'blocked': true},
      SetOptions(merge: true),
    );
    batch.delete(
      _db
          .collection('swipes')
          .doc(blockerUid)
          .collection('liked')
          .doc(blockedUid),
    );
    batch.delete(
      _db
          .collection('swipes')
          .doc(blockerUid)
          .collection('likedBy')
          .doc(blockedUid),
    );

    await batch.commit();
    await unmatch(matchId);
  }

  Future<void> deleteChat(String matchId) async {
    final messagesRef = _db
        .collection('matches')
        .doc(matchId)
        .collection('messages');

    while (true) {
      final snapshot = await messagesRef.limit(200).get();
      if (snapshot.docs.isEmpty) break;

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    await _db.collection('matches').doc(matchId).set({
      'lastMessage': null,
      'lastMessageAt': null,
    }, SetOptions(merge: true));
  }

  Future<void> unmatch(String matchId) async {
    await deleteChat(matchId);
    await _db.collection('matches').doc(matchId).delete();
  }

  Future<void> markMessagesRead({
    required String matchId,
    required String readerUid,
  }) async {
    final snapshot = await _db
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .limit(120)
        .get();

    final batch = _db.batch();
    var updated = false;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final senderId = (data['senderId'] ?? '') as String;
      if (senderId == readerUid) continue;
      final readBy = (data['readBy'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toSet();
      if (readBy.contains(readerUid)) continue;
      batch.update(doc.reference, {
        'readBy': FieldValue.arrayUnion([readerUid]),
      });
      updated = true;
    }

    if (updated) {
      await batch.commit();
    }
  }

  Future<bool> _isBlockedBetween({
    required String blockerUid,
    required String blockedUid,
  }) async {
    final doc = await _db
        .collection('users')
        .doc(blockerUid)
        .collection('blocks')
        .doc(blockedUid)
        .get();
    return doc.exists;
  }
}
