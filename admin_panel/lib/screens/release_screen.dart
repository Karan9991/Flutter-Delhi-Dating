import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

class ReleaseScreen extends ConsumerStatefulWidget {
  const ReleaseScreen({super.key});

  @override
  ConsumerState<ReleaseScreen> createState() => _ReleaseScreenState();
}

class _ReleaseScreenState extends ConsumerState<ReleaseScreen> {
  final _minBuildController = TextEditingController();
  final _latestVersionController = TextEditingController();
  final _storeUrlController = TextEditingController();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  bool _forceUpdate = false;
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _minBuildController.dispose();
    _latestVersionController.dispose();
    _storeUrlController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _setInitial(Map<String, dynamic>? data) {
    if (_initialized) return;
    _minBuildController.text =
        ((data?['minBuildNumber'] ?? 0) as num).toInt().toString();
    _latestVersionController.text =
        (data?['latestVersion'] ?? '').toString();
    _storeUrlController.text = (data?['storeUrl'] ??
            'https://play.google.com/store/apps/details?id=com.delhi.dating')
        .toString();
    _titleController.text = (data?['title'] ?? 'Update required').toString();
    _messageController.text = (data?['message'] ??
            'Please update Delhi Dating to continue.')
        .toString();
    _forceUpdate = data?['forceUpdate'] == true;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(firestoreProvider);
    final theme = Theme.of(context);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: db.collection('app_config').doc('release').snapshots(),
      builder: (context, snapshot) {
        _setInitial(snapshot.data?.data());

        if (snapshot.connectionState == ConnectionState.waiting &&
            !_initialized) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Force Update',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Users with a build number lower than the minimum will be blocked. '
              'You can also force everyone to update instantly.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Force update now'),
              subtitle: const Text('Blocks all users until they update.'),
              value: _forceUpdate,
              onChanged: (value) => setState(() => _forceUpdate = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _minBuildController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minimum build number',
                helperText: 'Use the +number from pubspec.yaml (e.g., 3)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _latestVersionController,
              decoration: const InputDecoration(
                labelText: 'Latest version name',
                helperText: 'Example: 3.0.0',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _storeUrlController,
              decoration: const InputDecoration(
                labelText: 'Play Store URL',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Update title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Update message'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 180,
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveConfig,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveConfig() async {
    setState(() => _saving = true);
    final db = ref.read(firestoreProvider);
    final minBuild = int.tryParse(_minBuildController.text.trim()) ?? 0;
    await db.collection('app_config').doc('release').set({
      'forceUpdate': _forceUpdate,
      'minBuildNumber': minBuild,
      'latestVersion': _latestVersionController.text.trim(),
      'storeUrl': _storeUrlController.text.trim(),
      'title': _titleController.text.trim().isEmpty
          ? 'Update required'
          : _titleController.text.trim(),
      'message': _messageController.text.trim().isEmpty
          ? 'Please update Delhi Dating to continue.'
          : _messageController.text.trim(),
    }, SetOptions(merge: true));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Release settings saved.')),
      );
      setState(() => _saving = false);
    }
  }
}
