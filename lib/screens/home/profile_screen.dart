import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';
import '../../widgets/empty_state.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final profileState = ref.watch(userProfileProvider);
    final auth = ref.watch(authStateProvider).value;
    final matchesCount = ref
        .watch(matchesProvider)
        .maybeWhen(data: (matches) => matches.length, orElse: () => 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => context.push('/onboarding'),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: profileState.when(
        data: (profile) {
          if (profile == null) {
            return const EmptyState(
              title: 'Build your profile',
              subtitle: 'Add your details to start matching.',
              icon: Icons.person_outline,
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 260,
                  child: PageView.builder(
                    itemCount: profile.photoUrls.length,
                    itemBuilder: (context, index) => ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: CachedNetworkImage(
                        imageUrl: profile.photoUrls[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${profile.displayName}, ${profile.age}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (profile.pronouns?.isNotEmpty == true)
                      Chip(label: Text(profile.pronouns!)),
                  ],
                ),
                if ((profile.jobTitle ?? '').isNotEmpty ||
                    (profile.company ?? '').isNotEmpty ||
                    (profile.education ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      [
                        if ((profile.jobTitle ?? '').isNotEmpty)
                          profile.jobTitle!,
                        if ((profile.company ?? '').isNotEmpty)
                          profile.company!,
                        if ((profile.education ?? '').isNotEmpty)
                          profile.education!,
                      ].join(' • '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.68),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StatChip(label: 'Matches', value: matchesCount.toString()),
                    const SizedBox(width: 12),
                    _StatChip(
                      label: 'Photos',
                      value: profile.photoUrls.length.toString(),
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      label: 'Interests',
                      value: profile.interests.length.toString(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'About',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  profile.bio,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: profile.interests
                      .map((interest) => Chip(label: Text(interest)))
                      .toList(),
                ),
                const SizedBox(height: 20),
                _InfoRow(label: 'Gender', value: profile.gender),
                _InfoRow(label: 'Looking for', value: profile.lookingFor),
                _InfoRow(
                  label: 'Height',
                  value: profile.heightCm == null
                      ? '—'
                      : '${profile.heightCm} cm',
                ),
                if ((auth?.email ?? '').isNotEmpty)
                  _InfoRow(label: 'Email', value: auth!.email!),
              ],
            ),
          );
        },
        error: (error, stack) => const EmptyState(
          title: 'Profile unavailable',
          subtitle: 'Please try again later.',
          icon: Icons.error_outline,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.68),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.68),
            ),
          ),
        ],
      ),
    );
  }
}
