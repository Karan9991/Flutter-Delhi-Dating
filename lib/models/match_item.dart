import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_profile.dart';

class MatchItem {
  MatchItem({
    required this.matchId,
    required this.otherUser,
    this.lastMessage,
    this.lastMessageAt,
  });

  final String matchId;
  final UserProfile otherUser;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  static DateTime? toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }
}
