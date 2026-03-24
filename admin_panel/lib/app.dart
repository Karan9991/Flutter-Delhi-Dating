import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/admin_allowlist.dart';
import 'providers.dart';
import 'screens/admin_home.dart';
import 'screens/login_screen.dart';
import 'theme/admin_theme.dart';

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Delhi Dating Admin',
      theme: AdminTheme.light(),
      debugShowCheckedModeBanner: false,
      home: const AdminGate(),
    );
  }
}

class AdminGate extends ConsumerWidget {
  const AdminGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }
        if (!_isAllowed(user)) {
          return _UnauthorizedScreen(user: user);
        }
        return const AdminHome();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Auth error: $error')),
      ),
    );
  }

  bool _isAllowed(User user) {
    final email = user.email?.toLowerCase().trim();
    if (email == null || email.isEmpty) return false;
    return adminAllowlistEmails.contains(email);
  }
}

class _UnauthorizedScreen extends ConsumerWidget {
  const _UnauthorizedScreen({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 40),
                const SizedBox(height: 12),
                const Text(
                  'Access denied',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'The account ${user.email ?? ''} is not on the admin allowlist.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    await ref.read(firebaseAuthProvider).signOut();
                  },
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
