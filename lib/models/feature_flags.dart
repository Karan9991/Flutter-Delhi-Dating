import 'package:cloud_firestore/cloud_firestore.dart';

class FeatureFlags {
  const FeatureFlags({
    required this.adsEnabled,
    required this.discoverEnabled,
    required this.swipeEnabled,
    required this.maintenanceEnabled,
  });

  final bool adsEnabled;
  final bool discoverEnabled;
  final bool swipeEnabled;
  final bool maintenanceEnabled;

  static const FeatureFlags defaults = FeatureFlags(
    adsEnabled: true,
    discoverEnabled: true,
    swipeEnabled: true,
    maintenanceEnabled: false,
  );

  factory FeatureFlags.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return FeatureFlags(
      adsEnabled: _asBool(data['adsEnabled'], defaults.adsEnabled),
      discoverEnabled: _asBool(data['discoverEnabled'], defaults.discoverEnabled),
      swipeEnabled: _asBool(data['swipeEnabled'], defaults.swipeEnabled),
      maintenanceEnabled:
          _asBool(data['maintenanceEnabled'], defaults.maintenanceEnabled),
    );
  }

  static bool _asBool(dynamic value, bool fallback) {
    if (value is bool) return value;
    if (value is num) return value.toInt() != 0;
    return fallback;
  }
}
