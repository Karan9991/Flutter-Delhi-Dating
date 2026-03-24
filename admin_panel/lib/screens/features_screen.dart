import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

class FeaturesScreen extends ConsumerWidget {
  const FeaturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(firestoreProvider);
    final theme = Theme.of(context);

    final featuresRef = db.collection('app_config').doc('features');
    final accessRef = db.collection('app_config').doc('access');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feature toggles',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: accessRef.snapshots(),
                    builder: (context, snapshot) {
                      final data = snapshot.data?.data() ?? {};
                      final locationValue = data['location'];
                      final isDelhiOnly = locationValue is num
                          ? locationValue.toInt() != 0
                          : (locationValue is bool ? locationValue : true);

                      return SwitchListTile(
                        value: isDelhiOnly,
                        title: const Text('Delhi-only location gate'),
                        subtitle: const Text(
                          'When off, users outside Delhi can access the app.',
                        ),
                        onChanged: (value) async {
                          await accessRef.set({'location': value ? 1 : 0}, SetOptions(merge: true));
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: featuresRef.snapshots(),
                    builder: (context, snapshot) {
                      final data = snapshot.data?.data() ?? {};
                      final adsEnabled = _asBool(data['adsEnabled'], true);
                      final discoverEnabled = _asBool(data['discoverEnabled'], true);
                      final swipeEnabled = _asBool(data['swipeEnabled'], true);
                      final maintenanceEnabled = _asBool(data['maintenanceEnabled'], false);

                      return Column(
                        children: [
                          SwitchListTile(
                            value: adsEnabled,
                            title: const Text('Ads enabled'),
                            subtitle: const Text('Controls banner, interstitial, and app-open ads.'),
                            onChanged: (value) => _update(featuresRef, {'adsEnabled': value}),
                          ),
                          SwitchListTile(
                            value: discoverEnabled,
                            title: const Text('Discover enabled'),
                            subtitle: const Text('Controls the Discover tab availability.'),
                            onChanged: (value) => _update(featuresRef, {'discoverEnabled': value}),
                          ),
                          SwitchListTile(
                            value: swipeEnabled,
                            title: const Text('Swipe enabled'),
                            subtitle: const Text('Controls swipe gestures and like/pass actions.'),
                            onChanged: (value) => _update(featuresRef, {'swipeEnabled': value}),
                          ),
                          SwitchListTile(
                            value: maintenanceEnabled,
                            title: const Text('Maintenance mode'),
                            subtitle: const Text('Shows a maintenance screen to all users.'),
                            onChanged: (value) => _update(featuresRef, {'maintenanceEnabled': value}),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static bool _asBool(dynamic value, bool fallback) {
    if (value is bool) return value;
    if (value is num) return value.toInt() != 0;
    return fallback;
  }

  Future<void> _update(
    DocumentReference<Map<String, dynamic>> refDoc,
    Map<String, dynamic> data,
  ) {
    return refDoc.set(data, SetOptions(merge: true));
  }
}
