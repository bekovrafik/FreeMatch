import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freematch/main.dart';
import 'package:freematch/services/notification_service.dart';
import 'package:freematch/services/admob_service.dart';

// Simple Mocks
class MockNotificationService extends Fake implements NotificationService {
  @override
  Future<void> initialize() async {}
}

class MockAppOpenAdManager extends Fake implements AppOpenAdManager {
  @override
  Future<void> loadAd() async {}

  @override
  void showAdIfAvailable() {}
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app with mocked services
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationServiceProvider.overrideWithValue(
            MockNotificationService(),
          ),
          appOpenAdManagerProvider.overrideWithValue(MockAppOpenAdManager()),
        ],
        child: const FreeMatchApp(),
      ),
    );

    // Trigger a frame
    await tester.pump();

    // Verify that the app launches (MaterialApp exists)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
