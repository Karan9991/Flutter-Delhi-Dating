import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(firestoreProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Matches',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: db
                .collection('matches')
                .orderBy('createdAt', descending: true)
                .limit(200)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text('No matches found.'));
              }

              final matches = snapshot.data!.docs;
              if (matches.isEmpty) {
                return const Center(child: Text('No matches found.'));
              }

              return ListView.separated(
                itemCount: matches.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = matches[index];
                  final data = doc.data();
                  final userIds = List<String>.from(data['userIds'] ?? const []);
                  final lastMessage = (data['lastMessage'] ?? '') as String;
                  final createdAt = data['createdAt'] is Timestamp
                      ? (data['createdAt'] as Timestamp).toDate()
                      : null;
                  final isMatch = data['isMatch'] == true;

                  return Card(
                    child: ListTile(
                      title: Text('Match ${doc.id}'),
                      subtitle: Text(
                        'Users: ${userIds.join(', ')}\n'
                        'Last message: ${lastMessage.isEmpty ? '—' : lastMessage}',
                      ),
                      isThreeLine: true,
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          if (createdAt != null)
                            Text(
                              DateFormat('MMM d').format(createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          if (isMatch)
                            const Chip(label: Text('Matched')),
                          TextButton(
                            onPressed: () => _showMessages(context, doc.reference),
                            child: const Text('Messages'),
                          ),
                          TextButton(
                            onPressed: () => _confirmDelete(context, doc.reference),
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

  Future<void> _showMessages(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> matchRef,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recent messages'),
        content: SizedBox(
          width: 520,
          height: 420,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: matchRef
                .collection('messages')
                .orderBy('sentAt', descending: true)
                .limit(30)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text('No messages yet.'));
              }
              final messages = snapshot.data!.docs;
              if (messages.isEmpty) {
                return const Center(child: Text('No messages yet.'));
              }
              return ListView.separated(
                itemCount: messages.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final data = messages[index].data();
                  final text = (data['text'] ?? '').toString();
                  final sender = data['senderId'] ?? '-';
                  final sentAt = data['sentAt'] is Timestamp
                      ? (data['sentAt'] as Timestamp).toDate()
                      : null;
                  final time = sentAt == null
                      ? ''
                      : DateFormat('MMM d, h:mm a').format(sentAt);
                  return ListTile(
                    dense: true,
                    title: Text(text.isEmpty ? '(image or empty message)' : text),
                    subtitle: Text('From: $sender  $time'),
                  );
                },
              );
            },
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

  Future<void> _confirmDelete(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> matchRef,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete match?'),
        content: const Text('This deletes the match document only.'),
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
      await matchRef.delete();
    }
  }
}
