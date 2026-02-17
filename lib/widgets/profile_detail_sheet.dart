import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/user_profile.dart';

class ProfileDetailSheet extends StatelessWidget {
  const ProfileDetailSheet({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 360,
                child: PageView.builder(
                  itemCount: profile.photoUrls.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: CachedNetworkImage(
                        imageUrl: profile.photoUrls[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
                      if ((profile.company ?? '').isNotEmpty) profile.company!,
                      if ((profile.education ?? '').isNotEmpty)
                        profile.education!,
                    ].join(' • '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.68),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(profile.bio, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: profile.interests
                    .map((interest) => Chip(label: Text(interest)))
                    .toList(),
              ),
              const SizedBox(height: 20),
              _InfoRow(label: 'Location', value: profile.location),
              _InfoRow(label: 'Gender', value: profile.gender),
              _InfoRow(label: 'Looking for', value: profile.lookingFor),
              if (profile.heightCm != null)
                _InfoRow(label: 'Height', value: '${profile.heightCm} cm'),
            ],
          ),
        );
      },
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
