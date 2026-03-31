import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/user_settings.dart';
import 'providers.dart';
import 'router_refresh.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/auth/delhi_access_gate_screen.dart';
import 'screens/home/chat_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/intro_screen.dart';
import 'screens/onboarding/profile_setup_screen.dart';
import 'screens/system/banned_screen.dart';
import 'screens/system/maintenance_screen.dart';
import 'screens/system/update_required_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

class DatingApp extends ConsumerStatefulWidget {
  const DatingApp({super.key});

  @override
  ConsumerState<DatingApp> createState() => _DatingAppState();
}

class _DatingAppState extends ConsumerState<DatingApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/',
      refreshListenable: GoRouterRefreshStream.multiple([
        ref.read(authStateProvider.stream),
        ref.read(userProfileProvider.stream),
      ]),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            final tabValue = int.tryParse(
              state.uri.queryParameters['tab'] ?? '',
            );
            final initialTab =
                tabValue != null && tabValue >= 0 && tabValue <= 3
                ? tabValue
                : 0;
            return HomeScreen(initialIndex: initialTab);
          },
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/intro',
          builder: (context, state) => const IntroScreen(),
        ),
        GoRoute(
          path: '/delhi-access',
          builder: (context, state) => const DelhiAccessGateScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => ForgotPasswordScreen(
            initialEmail: state.extra is String ? state.extra as String : null,
          ),
        ),
        GoRoute(
          path: '/verify-email',
          builder: (context, state) => const VerifyEmailScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const ProfileSetupScreen(),
        ),
        GoRoute(
          path: '/chat/:matchId',
          builder: (context, state) {
            final matchId = state.pathParameters['matchId'] ?? '';
            final otherId = state.extra is String ? state.extra as String : '';
            return ChatScreen(matchId: matchId, otherUserId: otherId);
          },
        ),
      ],
      redirect: (context, state) {
        final authState = ref.read(authStateProvider);
        final isLoading = authState.isLoading;
        if (isLoading) return null;

        final user = authState.asData?.value;
        final isAuthRoute =
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/register' ||
            state.matchedLocation == '/forgot-password';
        final isIntroRoute = state.matchedLocation == '/intro';
        final isDelhiAccessRoute = state.matchedLocation == '/delhi-access';
        final isVerifyRoute = state.matchedLocation == '/verify-email';
        final isOnboardingRoute = state.matchedLocation == '/onboarding';
        final hasSeenIntro = ref.read(onboardingSeenProvider);
        final hasDelhiAccess = ref.read(delhiAccessGrantedProvider);

        if (!hasSeenIntro && user == null) {
          return isIntroRoute ? null : '/intro';
        }
        if (isIntroRoute && user != null) return '/';
        if (isIntroRoute && user == null) {
          return hasDelhiAccess ? '/login' : '/delhi-access';
        }

        if (user == null) {
          if (!hasDelhiAccess) {
            return isDelhiAccessRoute ? null : '/delhi-access';
          }
          if (isDelhiAccessRoute) return '/login';
          return isAuthRoute ? null : '/login';
        }

        if (_needsEmailVerification(user)) {
          return isVerifyRoute ? null : '/verify-email';
        }

        final profileState = ref.read(userProfileProvider);
        final profile = profileState.asData?.value;
        final needsProfile =
            !profileState.isLoading &&
            (profile == null || !profile.isComplete);
        if (needsProfile) {
          return isOnboardingRoute ? null : '/onboarding';
        }

        if (isVerifyRoute || isAuthRoute || isDelhiAccessRoute) return '/';
        return null;
      },
    );

    try {
      final notificationService = ref.read(notificationServiceProvider);
      notificationService.setTapHandler(_handleNotificationTap);
      unawaited(notificationService.initialize());
    } catch (_) {
      // Allows widget tests that do not bootstrap Firebase.
    }

    ref.read(adServiceProvider).start();
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(featureFlagsProvider, (previous, next) {
      final flags = next.asData?.value;
      if (flags == null) return;
      ref.read(adServiceProvider).setAdsEnabled(flags.adsEnabled);
    });

    final settings = ref
        .watch(userSettingsProvider)
        .maybeWhen(
          data: (value) => value,
          orElse: () => const UserSettings(
            pushNotifications: true,
            messageNotifications: true,
            matchNotifications: true,
            likeNotifications: true,
            messageReadReceipts: true,
            showAge: true,
            showDistance: true,
            discoverable: true,
            themeMode: UserSettings.themeLight,
            accentColorValue: UserSettings.defaultAccentColorValue,
          ),
        );
    final themeMode = settings.themeMode == UserSettings.themeDark
        ? ThemeMode.dark
        : ThemeMode.light;
    final accentColor = Color(settings.accentColorValue);
    final featureFlags = ref
        .watch(featureFlagsProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final releaseConfig = ref
        .watch(releaseConfigProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final appVersion = ref
        .watch(appVersionProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final profile = ref
        .watch(userProfileProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);

    final updateRequired = releaseConfig != null &&
        appVersion != null &&
        releaseConfig.requiresUpdate(appVersion.buildNumber);

    if (updateRequired) {
      final versionLabel = appVersion.version.isNotEmpty
          ? '${appVersion.version} (${appVersion.buildNumber})'
          : appVersion.buildNumber.toString();
      return MaterialApp(
        title: 'Delhi Dating',
        theme: AppTheme.lightTheme(accent: accentColor),
        darkTheme: AppTheme.darkTheme(accent: accentColor),
        themeMode: themeMode,
        home: UpdateRequiredScreen(
          title: releaseConfig.title,
          message: releaseConfig.message,
          storeUrl: releaseConfig.storeUrl,
          currentVersion: versionLabel,
          latestVersion: releaseConfig.latestVersion,
        ),
        debugShowCheckedModeBanner: false,
      );
    }

    if (featureFlags?.maintenanceEnabled == true) {
      return MaterialApp(
        title: 'Delhi Dating',
        theme: AppTheme.lightTheme(accent: accentColor),
        darkTheme: AppTheme.darkTheme(accent: accentColor),
        themeMode: themeMode,
        home: const MaintenanceScreen(),
        debugShowCheckedModeBanner: false,
      );
    }

    if (profile?.isBanned == true) {
      return MaterialApp(
        title: 'Delhi Dating',
        theme: AppTheme.lightTheme(accent: accentColor),
        darkTheme: AppTheme.darkTheme(accent: accentColor),
        themeMode: themeMode,
        home: BannedScreen(reason: profile?.banReason),
        debugShowCheckedModeBanner: false,
      );
    }

    return MaterialApp.router(
      title: 'Delhi Dating',
      theme: AppTheme.lightTheme(accent: accentColor),
      darkTheme: AppTheme.darkTheme(accent: accentColor),
      themeMode: themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }

  bool _needsEmailVerification(User user) {
    final hasPasswordProvider = user.providerData.any(
      (provider) => provider.providerId == EmailAuthProvider.PROVIDER_ID,
    );
    if (!hasPasswordProvider) {
      return false;
    }
    return !user.emailVerified;
  }

  void _handleNotificationTap(NotificationIntent intent) {
    if (!mounted) return;

    switch (intent.type) {
      case 'chat':
        final matchId = intent.matchId;
        if (matchId == null || matchId.isEmpty) return;
        _router.push('/chat/$matchId', extra: intent.otherUserId ?? '');
        break;
      case 'like':
      case 'match':
        _router.go('/?tab=1');
        break;
      default:
        _router.go('/');
        break;
    }
  }
}
