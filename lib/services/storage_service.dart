import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  StorageService(this._storage);

  final FirebaseStorage _storage;
  final Uuid _uuid = const Uuid();

  Future<String> uploadProfileImage({
    required String uid,
    required File file,
  }) async {
    final fileId = _uuid.v4();
    final ref = _storage.ref('profile_images/$uid/$fileId.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
