import { MOCK_ADS, MOCK_PROFILES } from '../constants';
import { AdContent, CardItem, CardType, UserProfile } from '../types';

interface FeedFilters {
  gender: 'MEN' | 'WOMEN' | 'EVERYONE';
  distance: number;
  ageRange: [number, number];
  location?: string;
  interests?: string[];
}

// State to hold the filtered list of profiles
let activeProfiles: UserProfile[] = [...MOCK_PROFILES];

const SEVEN_DAYS_MS = 7 * 24 * 60 * 60 * 1000;
const FORTY_EIGHT_HOURS_MS = 48 * 60 * 60 * 1000;

/**
 * Advanced Ranking Algorithm
 * Calculates a "Gravity Score" to sort profiles based on quality and relevance.
 * Formula: (Recency * 0.5) + (Proximity * 0.3) + (Popularity * 0.2) + Bonuses
 */
const calculateGravityScore = (profile: UserProfile, filters: FeedFilters): number => {
  const now = Date.now();

  // 1. Recency Score (0.0 to 1.0)
  // 1.0 = Active Now, 0.0 = Active 7 days ago
  const msSinceActive = now - profile.lastActive;
  const recencyScore = Math.max(0, 1 - (msSinceActive / SEVEN_DAYS_MS));

  // 2. Proximity Score (0.0 to 1.0)
  // 1.0 = 0km away, 0.0 = Max distance (filters.distance)
  // Prevent division by zero if filter distance is very small
  const maxDist = filters.distance || 100; 
  const proximityScore = Math.max(0, 1 - (profile.distance / maxDist));

  // 3. Popularity Score (0.0 to 1.0)
  const popScore = (profile.popularityScore || 0) / 100;

  // Base Gravity Calculation
  let gravity = (recencyScore * 0.5) + (proximityScore * 0.3) + (popScore * 0.2);

  // --- Multipliers & Bonuses ---

  // Priority 1: Instant Match (User already likes current user)
  if (profile.hasLikedCurrentUser) {
      gravity += 1000; // Massive boost to ensure they appear first
  }

  // Priority 2: New User Boost (Joined < 48 hours ago)
  const isNew = (now - profile.joinedDate) < FORTY_EIGHT_HOURS_MS;
  if (isNew) {
      gravity += 500; // Significant boost
  }

  // Priority 3: City Match (Exact String Match)
  // Assuming 'filters.location' is the current user's location
  if (filters.location && profile.location.toLowerCase().includes(filters.location.toLowerCase())) {
      gravity += 50; // City priority
  }

  return gravity;
};

/**
 * Updates the active profile pool based on the "Search & Rank" algorithm.
 * Steps: Filter -> Exclude -> Score -> Sort
 */
export const setFeedFilters = (filters: FeedFilters, blockedIds: string[] = [], swipedIds: string[] = []) => {
  const now = Date.now();

  // Step 1: Filter & Exclude (Hard Filters)
  const candidates = MOCK_PROFILES.filter(p => {
    // 1. Safety Filter (Blocklist & Already Swiped)
    if (blockedIds.includes(p.id)) return false;
    if (swipedIds.includes(p.id)) return false;

    // 2. Gender Filter
    if (filters.gender !== 'EVERYONE' && p.gender !== filters.gender) return false;

    // 3. Distance Filter (Hard Radius)
    if (p.distance > filters.distance) return false;

    // 4. Age Filter
    if (p.age < filters.ageRange[0] || p.age > filters.ageRange[1]) return false;

    // 5. Active Status Filter (Must be active in last 7 days)
    // Exception: If they are a brand new user (joined < 48h), show them even if 'lastActive' logic is weird (edge case safety)
    const isNew = (now - p.joinedDate) < FORTY_EIGHT_HOURS_MS;
    if (!isNew && (now - p.lastActive) > SEVEN_DAYS_MS) {
        return false; // Ghost profile
    }

    // 6. Interest Filter (Optional strict filtering, or just rank lower? Implementation: Strict filter if set)
    if (filters.interests && filters.interests.length > 0) {
        if (!p.interests) return false;
        const hasInterest = p.interests.some(interest => filters.interests!.includes(interest));
        if (!hasInterest) return false;
    }

    return true;
  });

  // Step 2 & 3: Score & Sort
  // Map to object with score, then sort, then map back to profile
  const rankedProfiles = candidates.map(p => ({
      profile: p,
      score: calculateGravityScore(p, filters)
  }))
  .sort((a, b) => b.score - a.score) // Descending sort (Highest score first)
  .map(item => item.profile);

  // Step 4: Batching (Handled by slicing/getCardAtIndex implicitly via array access)
  activeProfiles = rankedProfiles;

  console.log(`Algo Run: ${candidates.length} candidates. Top profile: ${activeProfiles[0]?.name || 'None'}`);
};

/**
 * FSA Rule: Profile - Profile - Profile - Ad (P-P-P-A)
 * 3 Profiles then 1 Ad.
 * Loop infinitely.
 */
export const getCardAtIndex = (index: number): CardItem => {
  // Check if we ran out of profiles
  if (activeProfiles.length === 0) {
     return {
         type: CardType.EMPTY,
         data: {} as any, // Dummy data
         uniqueId: `empty-${index}`
     };
  }

  const patternLength = 4;
  const positionInPattern = index % patternLength; // 0, 1, 2, 3

  // Indices 0, 1, 2 are Profiles. Index 3 is Ad.
  if (positionInPattern < 3) {
    // It's a Profile
    // We need to calculate which profile to show based on the ACTIVE pool.
    const cycleIndex = Math.floor(index / patternLength);
    // Use activeProfiles instead of MOCK_PROFILES
    const profileIndex = (cycleIndex * 3 + positionInPattern) % activeProfiles.length;
    
    const profile = activeProfiles[profileIndex];

    return {
      type: CardType.PROFILE,
      data: profile,
      uniqueId: `profile-${index}-${profile.id}`
    };
  } else {
    // It's an Ad
    // Each cycle consumes 1 ad.
    const cycleIndex = Math.floor(index / patternLength);
    const adIndex = cycleIndex % MOCK_ADS.length;

    return {
      type: CardType.AD,
      data: MOCK_ADS[adIndex],
      uniqueId: `ad-${index}-${MOCK_ADS[adIndex].id}`
    };
  }
};

/**
 * Unit Test Simulation for the FSA Logic
 * Verifies that 4th, 8th, 12th cards are Ads.
 * (Indices 3, 7, 11)
 */
export const testFSALogic = (): boolean => {
  console.group('🧪 Running FSA Unit Test');
  
  const testIndices = [3, 7, 11]; // 4th, 8th, 12th cards
  let allPass = true;

  testIndices.forEach(idx => {
    // Only run test if we have profiles, otherwise it returns EMPTY
    if (activeProfiles.length > 0) {
        const card = getCardAtIndex(idx);
        const isAd = card.type === CardType.AD;
        console.log(`Index ${idx} (Card ${idx + 1}): ${card.type} - ${isAd ? '✅ PASS' : '❌ FAIL'}`);
        if (!isAd) allPass = false;
    }
  });

  // Verify a profile index
  if (activeProfiles.length > 0) {
      const profileCard = getCardAtIndex(0);
      const isProfile = profileCard.type === CardType.PROFILE;
      console.log(`Index 0 (Card 1): ${profileCard.type} - ${isProfile ? '✅ PASS' : '❌ FAIL'}`);
      if (!isProfile) allPass = false;
  }

  console.log(allPass ? '🎉 All FSA Tests Passed!' : '💥 Some FSA Tests Failed');
  console.groupEnd();
  return allPass;
};