import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  static const String keyLastLogin = 'fm_last_login';
  static const String keyStreak = 'fm_streak';
  static const String keyClaimedToday = 'fm_claimed_today';

  Future<Map<String, dynamic>> checkDailyStreak() async {
    final prefs = await SharedPreferences.getInstance();

    final lastLogin = prefs.getString(keyLastLogin) ?? '';
    final storedStreak = prefs.getInt(keyStreak) ?? 1;
    final lastClaimed = prefs.getString(keyClaimedToday) ?? '';

    // Normalize dates to YYYY-MM-DD to avoid time issues
    final now = DateTime.now();
    final today = "${now.year}-${now.month}-${now.day}";

    final yesterdayDate = now.subtract(const Duration(days: 1));
    final yesterday =
        "${yesterdayDate.year}-${yesterdayDate.month}-${yesterdayDate.day}";

    int currentStreak = storedStreak;
    bool showReward = false;
    bool hasClaimedToday = false;

    if (lastLogin == today) {
      // Already logged in today
      hasClaimedToday = (lastClaimed == today);
      // If not claimed today, show reward
      if (!hasClaimedToday) {
        showReward = true;
      }
    } else {
      // Validating streak
      if (lastLogin == yesterday) {
        // Consecutive day
        currentStreak = storedStreak + 1;
      } else {
        // Streak broken (unless first login)
        // If lastLogin is empty, it's first login. keep streak 1.
        if (lastLogin.isNotEmpty) {
          currentStreak = 1;
        }
      }
      showReward = true;
    }

    if (currentStreak != storedStreak) {
      await prefs.setInt(keyStreak, currentStreak);
    }

    // Always update last login
    if (lastLogin != today) {
      await prefs.setString(keyLastLogin, today);
    }

    return {'streak': currentStreak, 'showReward': showReward};
  }

  Future<void> claimReward() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = "${now.year}-${now.month}-${now.day}";
    await prefs.setString(keyClaimedToday, today);
  }

  Future<void> resetClaimStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyClaimedToday);
  }
}
