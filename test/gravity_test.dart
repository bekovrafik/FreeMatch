import 'package:flutter_test/flutter_test.dart';
import 'package:freematch/models/user_profile.dart';
import 'package:freematch/services/gravity_service.dart';

void main() {
  group('GravityService Logic Tests', () {
    final service = GravityService();

    test('New User (< 48h) gets 1.5x Multiplier', () {
      final now = DateTime.now();

      final oldUser = UserProfile(
        id: 'old',
        name: 'Old',
        age: 25,
        bio: '',
        imageUrls: [],
        location: '',
        profession: '',
        gender: 'MEN',
        distance: 10,
        interests: [],
        lastActive: now.millisecondsSinceEpoch,
        joinedDate: now
            .subtract(const Duration(days: 10))
            .millisecondsSinceEpoch,
        popularityScore: 50,
      );

      final newUser = UserProfile(
        id: 'new',
        name: 'New',
        age: 25,
        bio: '',
        imageUrls: [],
        location: '',
        profession: '',
        gender: 'MEN',
        distance: 10,
        interests: [],
        lastActive: now.millisecondsSinceEpoch,
        joinedDate: now
            .subtract(const Duration(hours: 10))
            .millisecondsSinceEpoch, // < 48h
        popularityScore: 50,
      );

      final oldScore = service.calculateGravityScore(oldUser);
      final newScore = service.calculateGravityScore(newUser);

      // Base score for both should be roughly same before multiplier:
      // Recency (Active now) = 1.0 * 0.5 = 0.5
      // Proximity (10km/100km) = 0.9 * 0.3 = 0.27
      // Popularty (50/100) = 0.5 * 0.2 = 0.1
      // Total Base ~ 0.87

      // New user should be ~ 0.87 * 1.5 = 1.305

      expect(newScore, greaterThan(oldScore));
      expect(newScore, closeTo(oldScore * 1.5, 0.001));
    });

    test('User active 7+ days ago has Recency Score of 0', () {
      final recencyUser = UserProfile(
        id: 'recency',
        name: 'Rec',
        age: 25,
        bio: '',
        imageUrls: [],
        location: '',
        profession: '',
        gender: 'MEN',
        distance: 0,
        interests: [],
        lastActive: DateTime.now()
            .subtract(const Duration(days: 8))
            .millisecondsSinceEpoch, // > 7 days
        joinedDate: DateTime.now()
            .subtract(const Duration(days: 20))
            .millisecondsSinceEpoch,
        popularityScore: 0,
      );

      final score = service.calculateGravityScore(recencyUser);
      // Recency 0
      // Proximity (0 dist) = 1.0 * 0.3 = 0.3
      // Popularity 0
      // Total = 0.3
      expect(score, closeTo(0.3, 0.001));
    });

    test('Has Liked Current User gives massive boost', () {
      final normalUser = UserProfile(
        id: 'n',
        name: 'N',
        age: 25,
        bio: '',
        imageUrls: [],
        location: '',
        profession: '',
        gender: 'MEN',
        distance: 10,
        interests: [],
        lastActive: DateTime.now().millisecondsSinceEpoch,
        joinedDate: DateTime.now()
            .subtract(const Duration(days: 10))
            .millisecondsSinceEpoch,
        popularityScore: 50,
      );

      final likedUser = UserProfile(
        id: 'l',
        name: 'L',
        age: 25,
        bio: '',
        imageUrls: [],
        location: '',
        profession: '',
        gender: 'MEN',
        distance: 10,
        interests: [],
        lastActive: DateTime.now().millisecondsSinceEpoch,
        joinedDate: DateTime.now()
            .subtract(const Duration(days: 10))
            .millisecondsSinceEpoch,
        popularityScore: 50,
        hasLikedCurrentUser: true,
      );

      final nScore = service.calculateGravityScore(normalUser);
      final lScore = service.calculateGravityScore(likedUser);

      expect(lScore, greaterThan(nScore + 900)); // Check for +1000 boost
    });
  });
}
