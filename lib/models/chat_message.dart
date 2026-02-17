import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
    required this.readBy,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final Set<String> readBy;

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final readBy = (data['readBy'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toSet();
    return ChatMessage(
      id: doc.id,
      senderId: (data['senderId'] ?? '') as String,
      text: (data['text'] ?? '') as String,
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readBy: readBy,
    );
  }

  bool isReadBy(String uid) => readBy.contains(uid);
}
