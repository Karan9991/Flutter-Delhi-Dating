import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(firestoreProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Users',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search by name or UID',
          ),
          onChanged: (value) => setState(() => _query = value.trim()),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: db
                .collection('users')
                .orderBy('createdAt', descending: true)
                .limit(100)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text('No users found.'));
              }

              final docs = snapshot.data!.docs;
              final filtered = docs.where((doc) {
                if (_query.isEmpty) return true;
                final data = doc.data();
                final name = (data['displayName'] ?? '').toString().toLowerCase();
                final uid = doc.id.toLowerCase();
                return name.contains(_query.toLowerCase()) || uid.contains(_query.toLowerCase());
              }).toList();

              if (filtered.isEmpty) {
                return const Center(child: Text('No matching users.'));
              }

              return ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = filtered[index];
                  final data = doc.data();
                  final name = (data['displayName'] ?? 'Unknown') as String;
                  final photoUrls = List<String>.from(data['photoUrls'] ?? const []);
                  final age = data['age'] ?? '-';
                  final isBanned = data['isBanned'] == true;

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            photoUrls.isNotEmpty ? NetworkImage(photoUrls.first) : null,
                        child: photoUrls.isEmpty ? const Icon(Icons.person_outline) : null,
                      ),
                      title: Text(name),
                      subtitle: Text('UID: ${doc.id} • Age: $age'),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          if (isBanned)
                            const Chip(label: Text('BANNED')),
                          TextButton(
                            onPressed: () => _toggleBan(doc.reference, isBanned),
                            child: Text(isBanned ? 'Unban' : 'Ban'),
                          ),
                          TextButton(
                            onPressed: () => _confirmDelete(doc.reference),
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _toggleBan(DocumentReference<Map<String, dynamic>> refDoc, bool isBanned) async {
    if (isBanned) {
      await refDoc.update({
        'isBanned': false,
        'bannedAt': FieldValue.delete(),
        'banReason': FieldValue.delete(),
      });
      return;
    }

    final reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ban user'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ban'),
          ),
        ],
      ),
    );

    if (result != true) return;
    await refDoc.update({
      'isBanned': true,
      'bannedAt': FieldValue.serverTimestamp(),
      if (reasonController.text.trim().isNotEmpty)
        'banReason': reasonController.text.trim(),
    });
  }

  Future<void> _confirmDelete(DocumentReference<Map<String, dynamic>> refDoc) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete user profile?'),
        content: const Text(
          'This deletes the user profile document only. Auth and storage data remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      await refDoc.delete();
    }
  }
}
