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
                      onTap: () => _showUserDetails(doc),
                      leading: SizedBox(
                        width: 40,
                        height: 40,
                        child: ClipOval(
                          child: photoUrls.isNotEmpty
                              ? Image.network(
                                  photoUrls.first,
                                  fit: BoxFit.cover,
                                  webHtmlElementStrategy:
                                      WebHtmlElementStrategy.prefer,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: theme.colorScheme.surfaceVariant,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.person_outline,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: theme.colorScheme.surfaceVariant,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.person_outline),
                                ),
                        ),
                      ),
                      title: Text(name),
                      subtitle: Text('UID: ${doc.id} • Age: $age'),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          if (isBanned)
                            const Chip(label: Text('BANNED')),
                          TextButton(
                            onPressed: () => _showUserDetails(doc),
                            child: const Text('View'),
                          ),
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

  Future<void> _showUserDetails(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final theme = Theme.of(context);
    final photoUrls = List<String>.from(data['photoUrls'] ?? const []);
    final interests = List<String>.from(data['interests'] ?? const []);
    final createdAt = data['createdAt']?.toString() ?? '—';
    final lastActive = data['lastActive']?.toString() ?? '—';

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['displayName']?.toString().isNotEmpty == true
            ? data['displayName'].toString()
            : 'User profile'),
        content: SizedBox(
          width: 640,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (photoUrls.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: photoUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final url = photoUrls[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            url,
                            width: 160,
                            height: 200,
                            fit: BoxFit.cover,
                            webHtmlElementStrategy:
                                WebHtmlElementStrategy.prefer,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 160,
                                height: 200,
                                color: theme.colorScheme.surfaceVariant,
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image_outlined),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    height: 160,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('No photos uploaded'),
                  ),
                const SizedBox(height: 16),
                _detailRow('UID', doc.id),
                _detailRow('Age', (data['age'] ?? '—').toString()),
                _detailRow('Gender', (data['gender'] ?? '—').toString()),
                _detailRow('Looking for', (data['lookingFor'] ?? '—').toString()),
                _detailRow('Pronouns', (data['pronouns'] ?? '—').toString()),
                _detailRow('Job title', (data['jobTitle'] ?? '—').toString()),
                _detailRow('Company', (data['company'] ?? '—').toString()),
                _detailRow('Education', (data['education'] ?? '—').toString()),
                _detailRow('Height (cm)', (data['heightCm'] ?? '—').toString()),
                _detailRow('Created', createdAt),
                _detailRow('Last active', lastActive),
                const SizedBox(height: 12),
                Text('Bio', style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(
                  (data['bio'] ?? '—').toString(),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text('Interests', style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                if (interests.isEmpty)
                  const Text('—')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: interests
                        .map((interest) => Chip(label: Text(interest)))
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
