import 'package:cloud_firestore/cloud_firestore.dart';

import 'fcm_http_v1_service.dart';

class MatchingService {
  MatchingService(this._db, this._fcmService);

  final FirebaseFirestore _db;
  final FcmHttpV1Service _fcmService;

  Future<void> likeUser({
    required String currentUid,
    required String otherUid,
  }) async {
    final likedRef = _db
        .collection('swipes')
        .doc(currentUid)
        .collection('liked')
        .doc(otherUid);

    await likedRef.set({'createdAt': FieldValue.serverTimestamp()});

    final likedByRef = _db
        .collection('swipes')
        .doc(otherUid)
        .collection('likedBy')
        .doc(currentUid);
    await likedByRef.set({'createdAt': FieldValue.serverTimestamp()});

    final otherLikeRef = _db
        .collection('swipes')
        .doc(otherUid)
        .collection('liked')
        .doc(currentUid);
    final currentLikedByRef = _db
        .collection('swipes')
        .doc(currentUid)
        .collection('likedBy')
        .doc(otherUid);

    final matched = await _db.runTransaction<bool>((transaction) async {
      final otherLikeSnap = await transaction.get(otherLikeRef);
      if (!otherLikeSnap.exists) return false;

      final matchId = _matchIdFor(currentUid, otherUid);
      final matchRef = _db.collection('matches').doc(matchId);
      final matchSnap = await transaction.get(matchRef);
      if (matchSnap.exists) {
        transaction.set(matchRef, {
          'isMatch': true,
          'matchedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        transaction.set(matchRef, {
          'userIds': [currentUid, otherUid],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': null,
          'lastMessageAt': null,
          'isMatch': true,
          'matchedAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.delete(likedByRef);
      transaction.delete(currentLikedByRef);
      return true;
    });

    if (matched) {
      await _fcmService.sendMatchNotification(
        senderUid: currentUid,
        recipientUid: otherUid,
        matchId: _matchIdFor(currentUid, otherUid),
      );
      return;
    }

    await _fcmService.sendLikeNotification(
      senderUid: currentUid,
      recipientUid: otherUid,
    );
  }

  Future<void> passUser({
    required String currentUid,
    required String otherUid,
  }) async {
    final passedRef = _db
        .collection('swipes')
        .doc(currentUid)
        .collection('passed')
        .doc(otherUid);
    final likedByRef = _db
        .collection('swipes')
        .doc(currentUid)
        .collection('likedBy')
        .doc(otherUid);

    await passedRef.set({'createdAt': FieldValue.serverTimestamp()});
    await likedByRef.delete();
  }

  String _matchIdFor(String uidA, String uidB) {
    final ordered = [uidA, uidB]..sort();
    return ordered.join('_');
  }
}
