import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({
    super.key,
    required this.title,
    required this.message,
    required this.storeUrl,
    required this.currentVersion,
    required this.latestVersion,
  });

  final String title;
  final String message;
  final String storeUrl;
  final String currentVersion;
  final String latestVersion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      Icons.system_update_alt_rounded,
                      size: 44,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Current version: $currentVersion',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (latestVersion.isNotEmpty)
                    Text(
                      'Latest version: $latestVersion',
                      style: theme.textTheme.bodySmall,
                    ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _openStore(context),
                    icon: const Icon(Icons.shop_rounded),
                    label: const Text('Update on Play Store'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openStore(BuildContext context) async {
    final uri = Uri.parse(storeUrl);
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the Play Store.')),
      );
    }
  }
}
