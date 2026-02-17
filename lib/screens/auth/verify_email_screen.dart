import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _checking = false;
  bool _sending = false;
  String? _message;
  String? _error;

  Future<void> _checkVerification() async {
    setState(() {
      _checking = true;
      _error = null;
      _message = null;
    });

    try {
      await ref.read(authServiceProvider).reloadCurrentUser();
      final user = ref.read(authStateProvider).value;
      if (user != null && user.emailVerified) {
        if (!mounted) return;
        context.go('/');
        return;
      }
      setState(() {
        _error = 'Email not verified yet. Open your inbox and click the link.';
      });
    } catch (_) {
      setState(() {
        _error = 'Unable to check verification status. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _checking = false;
        });
      }
    }
  }

  Future<void> _resendVerification() async {
    setState(() {
      _sending = true;
      _error = null;
      _message = null;
    });
    try {
      await ref
          .read(authServiceProvider)
          .resendEmailVerificationForCurrentUser();
      setState(() {
        _message = 'Verification email sent again.';
      });
    } catch (_) {
      setState(() {
        _error = 'Unable to resend email now. Try again in a moment.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).value;
    final email = user?.email ?? 'your email';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.14),
                    theme.scaffoldBackgroundColor,
                    theme.scaffoldBackgroundColor,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.24,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Check your inbox',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'We sent a verification link to $email. '
                          'You need to verify before signing in.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.76,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (_message != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              _message!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF1E9F5B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              _error!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _checking ? null : _checkVerification,
                            child: _checking
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('I have verified'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _sending ? null : _resendVerification,
                            child: _sending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Resend verification email'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: _signOut,
                            child: const Text('Use another account'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
