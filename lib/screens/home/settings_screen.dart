import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_settings.dart';
import '../../providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const List<Color> _presetAccentColors = [
    Color(UserSettings.defaultAccentColorValue),
    Color(0xFFFF4D6D),
    Color(0xFFFF6B6B),
    Color(0xFFF97316),
    Color(0xFFEAB308),
    Color(0xFF22C55E),
    Color(0xFF14B8A6),
    Color(0xFF3B82F6),
    Color(0xFF6366F1),
    Color(0xFF9333EA),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(userSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsState.when(
        data: (settings) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionCard(
              title: 'Appearance',
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme mode',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment<String>(
                            value: UserSettings.themeLight,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode_outlined),
                          ),
                          ButtonSegment<String>(
                            value: UserSettings.themeDark,
                            label: Text('Dark'),
                            icon: Icon(Icons.dark_mode_outlined),
                          ),
                        ],
                        selected: {settings.themeMode},
                        onSelectionChanged: (selection) {
                          if (selection.isEmpty) return;
                          final mode = selection.first;
                          _updateSettings(
                            ref,
                            settings.copyWith(themeMode: mode),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'App color',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 10),
                      _buildAccentSelector(context, ref, settings),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Discovery',
              children: [
                _buildSwitchTile(
                  context,
                  title: 'Show age',
                  subtitle: 'Control whether your age is visible',
                  value: settings.showAge,
                  onChanged: (value) =>
                      _updateSettings(ref, settings.copyWith(showAge: value)),
                ),
                _buildSwitchTile(
                  context,
                  title: 'Show distance',
                  subtitle: 'Display distance on your profile',
                  value: settings.showDistance,
                  onChanged: (value) => _updateSettings(
                    ref,
                    settings.copyWith(showDistance: value),
                  ),
                ),
                _buildSwitchTile(
                  context,
                  title: 'Discoverable',
                  subtitle: 'Pause your profile from being shown',
                  value: settings.discoverable,
                  onChanged: (value) => _updateSettings(
                    ref,
                    settings.copyWith(discoverable: value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Notifications',
              children: [
                _buildSwitchTile(
                  context,
                  title: 'Push notifications',
                  subtitle: 'Get notified about important updates',
                  value: settings.pushNotifications,
                  onChanged: (value) =>
                      _onPushNotificationsChanged(ref, settings, value),
                ),
                _buildSwitchTile(
                  context,
                  title: 'Message alerts',
                  subtitle: 'Get notified when someone messages you',
                  value: settings.messageNotifications,
                  enabled: settings.pushNotifications,
                  onChanged: (value) => _updateSettings(
                    ref,
                    settings.copyWith(messageNotifications: value),
                  ),
                ),
                _buildSwitchTile(
                  context,
                  title: 'Match alerts',
                  subtitle: 'Get notified when you match',
                  value: settings.matchNotifications,
                  enabled: settings.pushNotifications,
                  onChanged: (value) => _updateSettings(
                    ref,
                    settings.copyWith(matchNotifications: value),
                  ),
                ),
                _buildSwitchTile(
                  context,
                  title: 'Like alerts',
                  subtitle: 'Get notified when someone likes you',
                  value: settings.likeNotifications,
                  enabled: settings.pushNotifications,
                  onChanged: (value) => _updateSettings(
                    ref,
                    settings.copyWith(likeNotifications: value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Chat',
              children: [
                _buildSwitchTile(
                  context,
                  title: 'Read receipts',
                  subtitle: 'Show when you have read messages',
                  value: settings.messageReadReceipts,
                  onChanged: (value) => _updateSettings(
                    ref,
                    settings.copyWith(messageReadReceipts: value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Safety Center',
              description:
                  'Keep conversations respectful and meet in public places for first dates.',
              onTap: () => _showInfoSheet(
                context,
                title: 'Safety Center',
                body:
                    'Delhi Dating encourages respectful connections. Share your plans with friends, meet in public, and trust your instincts.',
              ),
            ),
            _InfoCard(
              title: 'Privacy & Terms',
              description: 'Review how your data is stored and used.',
              onTap: () => _showInfoSheet(
                context,
                title: 'Privacy & Terms',
                body:
                    'Your data is stored securely in Firebase. Update this section with your official privacy policy and terms before publishing.',
              ),
            ),
            _InfoCard(
              title: 'Help & Support',
              description: 'Contact support or report a safety concern.',
              onTap: () => _showInfoSheet(
                context,
                title: 'Help & Support',
                body:
                    'Need help? Email support@yourapp.com or add your help center URL before publishing.',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => ref.read(authServiceProvider).signOut(),
              child: const Text('Sign out'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _confirmDelete(context, ref),
              child: const Text('Delete account'),
            ),
          ],
        ),
        error: (error, stack) =>
            const Center(child: Text('Settings unavailable')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _updateSettings(WidgetRef ref, UserSettings settings) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;
    await ref.read(firestoreServiceProvider).updateSettings(user.uid, settings);
  }

  Future<void> _onPushNotificationsChanged(
    WidgetRef ref,
    UserSettings currentSettings,
    bool enabled,
  ) async {
    final nextSettings = currentSettings.copyWith(pushNotifications: enabled);
    await _updateSettings(ref, nextSettings);
    await ref
        .read(notificationServiceProvider)
        .handlePushSettingChange(enabled: enabled);
  }

  Widget _buildAccentSelector(
    BuildContext context,
    WidgetRef ref,
    UserSettings settings,
  ) {
    final selectedColor = Color(settings.accentColorValue);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selectedColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selectedColor.withValues(alpha: 0.55)),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: selectedColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _hex(selectedColor),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _openCustomColorPicker(context, ref, settings),
                icon: const Icon(Icons.tune, size: 16),
                label: const Text('Custom'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _presetAccentColors.map((color) {
            final isSelected = color.toARGB32() == settings.accentColorValue;
            return GestureDetector(
              onTap: () => _updateSettings(
                ref,
                settings.copyWith(accentColorValue: color.toARGB32()),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? onSurface : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: isSelected ? 12 : 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 18,
                        color: _isLightColor(color)
                            ? Colors.black
                            : Colors.white,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _openCustomColorPicker(
    BuildContext context,
    WidgetRef ref,
    UserSettings settings,
  ) async {
    final initialColor = Color(settings.accentColorValue);
    final initialHsv = HSVColor.fromColor(initialColor);
    double hue = initialHsv.hue;
    double saturation = initialHsv.saturation;
    double value = initialHsv.value;

    final picked = await showDialog<Color>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final preview = HSVColor.fromAHSV(
              1,
              hue,
              saturation,
              value,
            ).toColor();

            return AlertDialog(
              title: const Text('Pick app color'),
              content: SizedBox(
                width: 330,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 52,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: preview,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _hex(preview),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 10),
                    _ColorSlider(
                      label: 'Hue',
                      value: hue,
                      max: 360,
                      onChanged: (v) => setDialogState(() => hue = v),
                    ),
                    _ColorSlider(
                      label: 'Saturation',
                      value: saturation,
                      max: 1,
                      onChanged: (v) => setDialogState(() => saturation = v),
                    ),
                    _ColorSlider(
                      label: 'Brightness',
                      value: value,
                      max: 1,
                      onChanged: (v) => setDialogState(() => value = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(preview),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked == null) return;
    await _updateSettings(
      ref,
      settings.copyWith(accentColorValue: picked.toARGB32()),
    );
  }

  String _hex(Color color) {
    final value = color.toARGB32() & 0x00FFFFFF;
    final hex = value.toRadixString(16).padLeft(6, '0').toUpperCase();
    return '#$hex';
  }

  bool _isLightColor(Color color) {
    return color.computeLuminance() > 0.58;
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeTrack = colorScheme.primary.withValues(
      alpha: isDark ? 0.6 : 0.35,
    );
    final inactiveTrack = isDark
        ? const Color(0xFF4E3F54)
        : const Color(0xFFF0E3F2);
    final inactiveThumb = isDark
        ? const Color(0xFFF9D9FF)
        : const Color(0xFFC067C0);

    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeThumbColor: colorScheme.primary,
      activeTrackColor: activeTrack,
      inactiveThumbColor: inactiveThumb,
      inactiveTrackColor: inactiveTrack,
    );
  }

  void _showInfoSheet(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This action is permanent. Your profile and matches will be removed.',
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

    if (confirm != true) return;

    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

    try {
      await ref
          .read(firestoreProvider)
          .collection('users')
          .doc(user.uid)
          .delete();
      await user.delete();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in again before deleting your account.'),
        ),
      );
    }
  }
}

class _ColorSlider extends StatelessWidget {
  const _ColorSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final display = max == 360
        ? value.round().toString()
        : (value * 100).round().toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const Spacer(),
            Text(display, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
        Slider(
          min: 0,
          max: max,
          value: value.clamp(0, max),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            ListTile(
              title: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
