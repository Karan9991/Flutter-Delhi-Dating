import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(firestoreProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reports',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: db
                .collection('reports')
                .orderBy('createdAt', descending: true)
                .limit(200)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text('No reports found.'));
              }

              final reports = snapshot.data!.docs;
              if (reports.isEmpty) {
                return const Center(child: Text('No reports found.'));
              }

              return ListView.separated(
                itemCount: reports.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = reports[index];
                  final data = doc.data();
                  final status = (data['status'] ?? 'open') as String;
                  final createdAt = data['createdAt'] is Timestamp
                      ? (data['createdAt'] as Timestamp).toDate()
                      : null;
                  final formattedDate = createdAt == null
                      ? 'unknown'
                      : DateFormat('MMM d, yyyy – h:mm a').format(createdAt);

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Report • ${status.toUpperCase()}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                formattedDate,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Reason: ${data['reason'] ?? 'Unknown'}'),
                          if (data['details'] != null)
                            Text(
                              'Details: ${data['details']}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text('Reporter UID: ${data['reporterUid'] ?? '-'}'),
                          Text('Reported UID: ${data['reportedUid'] ?? '-'}'),
                          if (data['matchId'] != null)
                            Text('Match ID: ${data['matchId']}'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: status == 'open'
                                    ? () => _updateStatus(doc.reference, 'resolved')
                                    : null,
                                child: const Text('Mark resolved'),
                              ),
                              OutlinedButton(
                                onPressed: status == 'open'
                                    ? () => _updateStatus(doc.reference, 'dismissed')
                                    : null,
                                child: const Text('Dismiss'),
                              ),
                            ],
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

  Future<void> _updateStatus(
    DocumentReference<Map<String, dynamic>> refDoc,
    String status,
  ) {
    return refDoc.update({
      'status': status,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }
}
