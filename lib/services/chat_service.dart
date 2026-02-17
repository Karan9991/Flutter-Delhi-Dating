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

    final matchDoc = await _db.collection('matches').doc(matchId).get();
    final userIds = List<String>.from(matchDoc.data()?['userIds'] ?? const []);
    final recipientUid = userIds.firstWhere(
      (uid) => uid != senderId,
      orElse: () => '',
    );
    if (recipientUid.isEmpty) return;

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
}
