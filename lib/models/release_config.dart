import 'package:cloud_firestore/cloud_firestore.dart';

class ReleaseConfig {
  const ReleaseConfig({
    required this.minBuildNumber,
    required this.forceUpdate,
    required this.latestVersion,
    required this.storeUrl,
    required this.title,
    required this.message,
  });

  final int minBuildNumber;
  final bool forceUpdate;
  final String latestVersion;
  final String storeUrl;
  final String title;
  final String message;

  factory ReleaseConfig.fallback() {
    return const ReleaseConfig(
      minBuildNumber: 0,
      forceUpdate: false,
      latestVersion: '',
      storeUrl: 'https://play.google.com/store/apps/details?id=com.delhi.dating',
      title: 'Update available',
      message:
          'A newer version of Delhi Dating is available. Please update to continue.',
    );
  }

  factory ReleaseConfig.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return ReleaseConfig.fallback();
    return ReleaseConfig(
      minBuildNumber: (data['minBuildNumber'] is num)
          ? (data['minBuildNumber'] as num).toInt()
          : 0,
      forceUpdate: data['forceUpdate'] == true,
      latestVersion: (data['latestVersion'] ?? '') as String,
      storeUrl: (data['storeUrl'] ??
              'https://play.google.com/store/apps/details?id=com.delhi.dating')
          as String,
      title: (data['title'] ?? 'Update required') as String,
      message: (data['message'] ??
              'Please update Delhi Dating to keep using the app.')
          as String,
    );
  }

  bool requiresUpdate(int buildNumber) {
    if (forceUpdate) return true;
    if (minBuildNumber <= 0) return false;
    return buildNumber < minBuildNumber;
  }
}
