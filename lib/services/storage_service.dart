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

  Future<void> deleteUserProfileImages(String uid) async {
    final userFolderRef = _storage.ref('profile_images/$uid');
    await _deleteFolder(userFolderRef);
  }

  Future<void> _deleteFolder(Reference folderRef) async {
    ListResult result;
    try {
      result = await folderRef.listAll();
    } on FirebaseException catch (error) {
      if (error.code == 'object-not-found') return;
      rethrow;
    }

    for (final prefix in result.prefixes) {
      await _deleteFolder(prefix);
    }

    for (final item in result.items) {
      try {
        await item.delete();
      } on FirebaseException catch (error) {
        if (error.code != 'object-not-found') rethrow;
      }
    }
  }
}
