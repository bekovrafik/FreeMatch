import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // For runZonedGuarded
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Localization
import 'package:shared_preferences/shared_preferences.dart'; // Persistence

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'theme/app_theme.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/local_db_service.dart';
import 'services/admob_service.dart';
import 'providers/user_provider.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/chat_detail_screen.dart';

// Background Message Handler (Must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // 1. Zoned Errors (Global Crash Reporting)
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

      // 2. Global Error Hook
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint("UI ERROR: ${details.exception}");
        // TODO: Send to Crashlytics
      };

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await MobileAds.instance.initialize();
      await LocalDBService().init();

      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // 3. Load Persistent State (Onboarding)
      final prefs = await SharedPreferences.getInstance();
      final bool onboardingCompleted =
          prefs.getBool('onboarding_completed') ?? false;

      runApp(
        ProviderScope(
          child: FreeMatchApp(startOnboarding: !onboardingCompleted),
        ),
      );
    },
    (error, stack) {
      debugPrint("ASYNC ERROR: $error");
      // TODO: Send to Crashlytics
    },
  );
}

class FreeMatchApp extends ConsumerStatefulWidget {
  final bool startOnboarding;
  const FreeMatchApp({super.key, this.startOnboarding = true});

  @override
  ConsumerState<FreeMatchApp> createState() => _FreeMatchAppState();
}

class _FreeMatchAppState extends ConsumerState<FreeMatchApp>
    with WidgetsBindingObserver {
  late AppOpenAdManager _appOpenAdManager;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.read(notificationServiceProvider).initialize();

    // Initialize App Open Ad Manager
    _appOpenAdManager = ref.read(appOpenAdManagerProvider);
    _appOpenAdManager.loadAd(showImmediately: true);

    // Deep Linking Setup
    ref
        .read(notificationServiceProvider)
        .setupInteractedMessage(_handleMessage);
  }

  // Removed _setupInteractedMessage as it is now in NotificationService

  void _handleMessage(RemoteMessage message) {
    if (message.data['type'] == 'chat') {
      final chatId = message.data['chatId'];
      final userId = message.data['senderId']; // The other user
      final userName = message.data['senderName'] ?? 'Unknown';

      // We might not have the image URL in the payload, defaulting or fetching placeholder
      // For a robust app, we'd fetch the user profile here using userId.
      // MVP: Open chat, image might be missing until real fetch.
      // Attempt to extract image if sent:
      final userImage = message.data['senderImage'] ?? '';

      if (chatId != null && userId != null) {
        // Use the global key to navigate
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              match: {
                'id': userId,
                'chatId': chatId,
                'name': userName,
                'image': userImage,
              },
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _isPaused = true;
    }
    if (state == AppLifecycleState.resumed && _isPaused) {
      _isPaused = false;
      _appOpenAdManager.showAdIfAvailable();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'FreeMatch',
      navigatorKey: navigatorKey, // Added Global Key
      debugShowCheckedModeBanner: false,

      // 4. Localization
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        // Add more locales here
      ],

      theme: AppTheme.darkTheme,
      home: _getHome(authState),
    );
  }

  Widget _getHome(AsyncValue<User?> authState) {
    return authState.when(
      data: (user) {
        if (user != null) {
          // User is logged in
          ref.read(notificationServiceProvider).saveToken(user.uid);
          ref
              .read(notificationServiceProvider)
              .subscribeToTopic('daily_rewards');

          final profileAsync = ref.watch(currentUserProfileProvider);
          return profileAsync.when(
            data: (profile) {
              if (profile == null ||
                  profile.name == 'Unknown' ||
                  profile.name.isEmpty) {
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

        // User not logged in -> Wrapper decides (Welcome vs Auth)
        // Actually, we passed 'startOnboarding' to App, but Wrapper manages state.
        // Let's pass the persistent state down.
        return OnboardingWrapper(initiallyCompleted: !widget.startOnboarding);
      },
      loading: () => const SplashScreen(),
      error: (e, stack) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

class OnboardingWrapper extends StatefulWidget {
  final bool initiallyCompleted;
  const OnboardingWrapper({super.key, required this.initiallyCompleted});

  @override
  State<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<OnboardingWrapper> {
  late bool _completed;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _completed = widget.initiallyCompleted;
    // If already completed in previous session, we might want to go straight to Auth.
    // Logic:
    // If !completed -> Show Welcome -> Onboarding -> Auth
    // If completed -> Show Auth
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    setState(() => _completed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) {
      return const AuthScreen();
    }

    if (!_started) {
      return WelcomeScreen(onStart: () => setState(() => _started = true));
    }

    return OnboardingScreen(onComplete: _completeOnboarding);
  }
}
