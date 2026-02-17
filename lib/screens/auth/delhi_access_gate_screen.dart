import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';
import '../../services/delhi_access_service.dart';

class DelhiAccessGateScreen extends ConsumerStatefulWidget {
  const DelhiAccessGateScreen({super.key});

  @override
  ConsumerState<DelhiAccessGateScreen> createState() =>
      _DelhiAccessGateScreenState();
}

class _DelhiAccessGateScreenState extends ConsumerState<DelhiAccessGateScreen> {
  DelhiAccessResult _result = const DelhiAccessResult(
    status: DelhiAccessStatus.initial,
    message: 'Checking your location for Delhi access.',
  );
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _runCheck();
  }

  Future<void> _runCheck() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _result = const DelhiAccessResult(
        status: DelhiAccessStatus.checking,
        message: 'Checking your location for Delhi access.',
      );
    });

    final result = await ref
        .read(delhiAccessServiceProvider)
        .verifyDelhiAccess();
    if (!mounted) return;

    ref.read(delhiAccessGrantedProvider.notifier).state = result.isAllowed;
    setState(() {
      _checking = false;
      _result = result;
    });
  }

  Future<void> _openAppSettings() async {
    await ref.read(delhiAccessServiceProvider).openAppSettings();
  }

  Future<void> _openLocationSettings() async {
    await ref.read(delhiAccessServiceProvider).openLocationSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAllowed = _result.status == DelhiAccessStatus.allowed;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatusIcon(status: _result.status),
                      const SizedBox(height: 16),
                      Text(
                        'Delhi Dating',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _headlineFor(_result.status),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(_result.message, style: theme.textTheme.bodyMedium),
                      if (_result.distanceKm != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Current distance from central Delhi: ${_result.distanceKm!.toStringAsFixed(1)} km',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.74,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      if (_checking)
                        const Center(child: CircularProgressIndicator()),
                      if (!_checking && isAllowed) ...[
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => context.go('/login'),
                            child: const Text('Continue to sign in'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => context.go('/register'),
                            child: const Text('Create account'),
                          ),
                        ),
                      ],
                      if (!_checking && !isAllowed) ...[
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _runCheck,
                            child: const Text('Try again'),
                          ),
                        ),
                        if (_result.status ==
                            DelhiAccessStatus.permissionDeniedForever) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _openAppSettings,
                              child: const Text('Open app settings'),
                            ),
                          ),
                        ],
                        if (_result.status ==
                            DelhiAccessStatus.locationServicesDisabled) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _openLocationSettings,
                              child: const Text('Open location settings'),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _headlineFor(DelhiAccessStatus status) {
    switch (status) {
      case DelhiAccessStatus.allowed:
        return 'You are eligible to use this app.';
      case DelhiAccessStatus.outsideDelhi:
        return 'This app is available only in Delhi.';
      case DelhiAccessStatus.permissionDenied:
      case DelhiAccessStatus.permissionDeniedForever:
        return 'Location permission is required.';
      case DelhiAccessStatus.locationServicesDisabled:
        return 'Turn on location services.';
      case DelhiAccessStatus.error:
        return 'Location check failed.';
      case DelhiAccessStatus.initial:
      case DelhiAccessStatus.checking:
        return 'Verifying your location.';
    }
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final DelhiAccessStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAllowed = status == DelhiAccessStatus.allowed;
    final isBlocked = status == DelhiAccessStatus.outsideDelhi;
    final isChecking =
        status == DelhiAccessStatus.initial ||
        status == DelhiAccessStatus.checking;

    final Color color = isAllowed
        ? const Color(0xFF1E9F5B)
        : isBlocked
        ? colorScheme.error
        : colorScheme.primary;
    final IconData icon = isAllowed
        ? Icons.verified_rounded
        : isBlocked
        ? Icons.location_off_rounded
        : isChecking
        ? Icons.location_searching_rounded
        : Icons.location_on_rounded;

    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 34),
    );
  }
}
