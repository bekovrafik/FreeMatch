import '../models/user_profile.dart';

class GravityService {
  static const int sevenDaysMs = 7 * 24 * 60 * 60 * 1000;
  static const int fortyEightHoursMs = 48 * 60 * 60 * 1000;

  /// Calculates a "Gravity Score" to sort profiles based on quality and relevance.
  /// Formula: (Recency * 0.5) + (Proximity * 0.3) + (Popularity * 0.2) + Bonuses
  double calculateGravityScore(
    UserProfile profile, {
    double maxRadius = 100.0,
    String? userLocation,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Recency Score (0.0 to 1.0)
    // 1.0 = Active Now, 0.0 = Active 7 days ago
    final msSinceActive = now - profile.lastActive;
    final recencyScore = (1.0 - (msSinceActive / sevenDaysMs)).clamp(0.0, 1.0);

    // 2. Proximity Score (0.0 to 1.0)
    // 1.0 = 0km away, 0.0 = Max distance (filters.distance)
    final proximityScore = (1.0 - (profile.distance / maxRadius)).clamp(
      0.0,
      1.0,
    );

    // 3. Popularity Score (0.0 to 1.0)
    final popScore = profile.popularityScore / 100.0;

    // Base Gravity Calculation
    double gravity =
        (recencyScore * 0.5) + (proximityScore * 0.3) + (popScore * 0.2);

    // --- Multipliers & Bonuses ---

    // Priority 1: Instant Match (User already likes current user)
    if (profile.hasLikedCurrentUser) {
      gravity += 1000.0; // Massive boost
    }

    // Priority 2: New User Boost (Joined < 48 hours ago)
    // Prompt specification: "NewUserMultiplier (1.5x) for profiles created < 48 hours ago"
    // The previous code added a flat 500 bonus. The prompt asks for 1.5x Multiplier.
    // BUT the prompt implies ranking priority. Multiplier on base score is subtle compared to flat priority.
    // However, I will strictly follow "NewUserMultiplier (1.5x)" instruction on the base gravity.
    // Wait, prompt also says "Flashness Priority... New User Boost where users < 20 swipes... "
    // The prompt explicitly says: "Add a NewUserMultiplier (1.5x) for profiles created < 48 hours ago" in the "Logic Refactor" section.

    final isNew = (now - profile.joinedDate) < fortyEightHoursMs;
    if (isNew) {
      gravity *= 1.5;
    }

    // Recover priority for new users if the multiplier isn't enough to beat old inactive users?
    // Base gravity max is ~1.0. 1.5x makes it 1.5.
    // A flat bonus ensuring visibility is usually better for "Boost", but I will stick to multiplier as requested.

    // Priority 3: City Match
    if (userLocation != null &&
        profile.location.toLowerCase().contains(userLocation.toLowerCase())) {
      gravity += 0.5; // Significant boost relative to base score
    }

    return gravity;
  }

  /// Sorts a list of profiles based on Gravity Score.
  List<UserProfile> sortProfiles(
    List<UserProfile> profiles, {
    double maxRadius = 100.0,
    String? userLocation,
  }) {
    // We map to an object to hold the score to avoid recalculating it multiple times
    final scored = profiles
        .map(
          (p) => (
            profile: p,
            score: calculateGravityScore(
              p,
              maxRadius: maxRadius,
              userLocation: userLocation,
            ),
          ),
        )
        .toList();

    scored.sort((a, b) => b.score.compareTo(a.score)); // Descending

    return scored.map((item) => item.profile).toList();
  }
}
