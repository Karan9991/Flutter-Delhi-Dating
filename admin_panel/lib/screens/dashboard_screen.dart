import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<_DashboardCounts> _loadCounts(FirebaseFirestore db) async {
    final users = await db.collection('users').count().get();
    final matches = await db.collection('matches').count().get();
    final reports = await db.collection('reports').count().get();
    final messages = await db.collectionGroup('messages').count().get();
    return _DashboardCounts(
      users: users.count ?? 0,
      matches: matches.count ?? 0,
      reports: reports.count ?? 0,
      messages: messages.count ?? 0,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(firestoreProvider);
    final theme = Theme.of(context);

    return FutureBuilder<_DashboardCounts>(
      future: _loadCounts(db),
      builder: (context, snapshot) {
        final data = snapshot.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat('EEEE, MMM d, yyyy').format(DateTime.now()),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _StatCard(
                    title: 'Total users',
                    value: data?.users ?? 0,
                    icon: Icons.people_outline,
                  ),
                  _StatCard(
                    title: 'Matches',
                    value: data?.matches ?? 0,
                    icon: Icons.favorite_border,
                  ),
                  _StatCard(
                    title: 'Reports',
                    value: data?.reports ?? 0,
                    icon: Icons.report_gmailerrorred_outlined,
                  ),
                  _StatCard(
                    title: 'Messages',
                    value: data?.messages ?? 0,
                    icon: Icons.chat_bubble_outline,
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value.toString(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardCounts {
  const _DashboardCounts({
    required this.users,
    required this.matches,
    required this.reports,
    required this.messages,
  });

  final int users;
  final int matches;
  final int reports;
  final int messages;
}
