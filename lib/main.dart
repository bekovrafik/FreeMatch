import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'providers/user_provider.dart';
import 'screens/profile_setup_screen.dart';

// Background Message Handler (Must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const ProviderScope(child: FreeMatchApp()));
}

class FreeMatchApp extends ConsumerStatefulWidget {
  const FreeMatchApp({super.key});

  @override
  ConsumerState<FreeMatchApp> createState() => _FreeMatchAppState();
}

class _FreeMatchAppState extends ConsumerState<FreeMatchApp> {
  @override
  void initState() {
    super.initState();
    // Initialize Notifications
    ref.read(notificationServiceProvider).initialize();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'FreeMatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF020617), // Slate-950
        colorScheme: const ColorScheme.dark(
          primary: Colors.amber, // Amber-500
          surface: Color(0xFF0F172A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF020617),
          elevation: 0,
        ),
      ),
      home: _getHome(authState),
    );
  }

  Widget _getHome(AsyncValue<User?> authState) {
    return authState.when(
      data: (user) {
        if (user != null) {
          // Initialize Notifications for User (Save Token & Subscribe)
          ref.read(notificationServiceProvider).saveToken(user.uid);
          ref.read(notificationServiceProvider).subscribeToTopic('daily_rewards');

          // Check if profile exists and is complete
          final profileAsync = ref.watch(currentUserProfileProvider);

          return profileAsync.when(
            data: (profile) {
              if (profile == null) {
                // User exists in Auth but not in Firestore -> Setup
                return const ProfileSetupScreen();
              }
              // Check completion (basic check: name is not empty/Unknown)
              if (profile.name == 'Unknown' || profile.name.isEmpty) {
                return const ProfileSetupScreen();
              }
              return const HomeScreen();
            },
            loading: () => const SplashScreen(),
            error: (e, s) => Scaffold(
              body: Center(child: Text('Error loading profile: $e')),
            ),
          );
        }
        return const OnboardingWrapper();
      },
      loading: () => const SplashScreen(),
      error: (e, stack) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

class OnboardingWrapper extends StatefulWidget {
  const OnboardingWrapper({super.key});

  @override
  State<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<OnboardingWrapper> {
  // Simple in-memory state for demo. Ideally use SharedPreferences.
  bool _started = false;
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      return WelcomeScreen(onStart: () => setState(() => _started = true));
    }
    if (!_completed) {
      return OnboardingScreen(
        onComplete: () => setState(() => _completed = true),
      );
    }
    return const AuthScreen();
  }
}
