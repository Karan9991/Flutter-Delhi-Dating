import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/like_item.dart';
import '../models/match_item.dart';
import '../models/user_profile.dart';
import '../models/user_settings.dart';

class FirestoreService {
  FirestoreService(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _matches =>
      _db.collection('matches');
  CollectionReference<Map<String, dynamic>> get _swipes =>
      _db.collection('swipes');

  Stream<UserProfile?> profileStream(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromDoc(doc);
    });
  }

  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromDoc(doc);
  }

  Future<void> saveProfile(UserProfile profile) {
    return _users.doc(profile.id).set(profile.toMap(), SetOptions(merge: true));
  }

  Future<void> updateLastActive(String uid) {
    return _users.doc(uid).set({
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<UserProfile>> fetchDiscoverableProfiles(String uid) async {
    final userSnapshot = await _users.limit(50).get();
    final likedSnapshot = await _swipes.doc(uid).collection('liked').get();
    final passedSnapshot = await _swipes.doc(uid).collection('passed').get();

    final excluded = <String>{uid};
    for (final doc in likedSnapshot.docs) {
      excluded.add(doc.id);
    }
    for (final doc in passedSnapshot.docs) {
      excluded.add(doc.id);
    }

    return userSnapshot.docs
        .where((doc) => !excluded.contains(doc.id))
        .where((doc) {
          final data = doc.data();
          final settings = data['settings'] as Map<String, dynamic>?;
          final discoverable = settings?['discoverable'] as bool? ?? true;
          return discoverable;
        })
        .map(UserProfile.fromDoc)
        .where(
          (profile) =>
              profile.photoUrls.isNotEmpty &&
              profile.displayName.isNotEmpty &&
              profile.age >= 18,
        )
        .toList();
  }

  Stream<List<MatchItem>> matchesStream(String uid) {
    return _matches.where('userIds', arrayContains: uid).snapshots().asyncMap((
      snapshot,
    ) async {
      final futures = snapshot.docs.map((doc) async {
        final data = doc.data();
        final userIds = List<String>.from(data['userIds'] ?? const []);
        final otherId = userIds.firstWhere((id) => id != uid, orElse: () => '');
        if (otherId.isEmpty) return null;
        final otherDoc = await _users.doc(otherId).get();
        if (!otherDoc.exists) return null;
        return MatchItem(
          matchId: doc.id,
          otherUser: UserProfile.fromDoc(otherDoc),
          lastMessage: data['lastMessage'] as String?,
          lastMessageAt: MatchItem.toDateTime(data['lastMessageAt']),
        );
      });

      final resolved = await Future.wait(futures);
      final items = resolved.whereType<MatchItem>().toList();
      items.sort((a, b) {
        final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return items;
    });
  }

  Stream<List<LikeItem>> incomingLikesStream(String uid) {
    return _swipes
        .doc(uid)
        .collection('likedBy')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final futures = snapshot.docs.map((doc) async {
            final profileDoc = await _users.doc(doc.id).get();
            if (!profileDoc.exists) return null;
            final profile = UserProfile.fromDoc(profileDoc);
            if (profile.displayName.isEmpty) return null;
            return LikeItem(
              user: profile,
              likedAt: LikeItem.toDateTime(doc.data()['createdAt']),
            );
          });

          final resolved = await Future.wait(futures);
          return resolved.whereType<LikeItem>().toList();
        });
  }

  Stream<UserSettings> settingsStream(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      final data = doc.data();
      return UserSettings.fromMap(data?['settings'] as Map<String, dynamic>?);
    });
  }

  Future<void> updateSettings(String uid, UserSettings settings) {
    return _users.doc(uid).set({
      'settings': settings.toMap(),
    }, SetOptions(merge: true));
  }
}
