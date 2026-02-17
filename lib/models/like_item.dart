import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_profile.dart';

class LikeItem {
  const LikeItem({required this.user, this.likedAt});

  final UserProfile user;
  final DateTime? likedAt;

  static DateTime? toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }
}
