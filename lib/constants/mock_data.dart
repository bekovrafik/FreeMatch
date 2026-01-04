import '../models/user_profile.dart';
import '../models/card_item.dart';

// ignore: non_constant_identifier_names
final List<UserProfile> MOCK_PROFILES = [
  UserProfile(
    id: 'u1',
    name: 'Sarah',
    age: 24,
    bio: 'Adventure seeker | Coffee lover ☕️',
    imageUrls: ['https://images.unsplash.com/photo-1494790108377-be9c29b29330'],
    location: 'New York',
    profession: 'Designer',
    gender: 'WOMEN',
    distance: 5.0,
    interests: ['Travel', 'Art', 'Yoga'],
    lastActive: DateTime.now().millisecondsSinceEpoch,
    joinedDate: DateTime.now()
        .subtract(const Duration(days: 10))
        .millisecondsSinceEpoch,
    popularityScore: 80,
  ),
  UserProfile(
    id: 'u2',
    name: 'Jessica',
    age: 27,
    bio: 'Tech enthusiast & Gamer 🎮',
    imageUrls: ['https://images.unsplash.com/photo-1517841905240-472988babdf9'],
    location: 'Brooklyn',
    profession: 'Developer',
    gender: 'WOMEN',
    distance: 12.0,
    interests: ['Gaming', 'Coding', 'Sci-Fi'],
    lastActive: DateTime.now()
        .subtract(const Duration(hours: 2))
        .millisecondsSinceEpoch,
    joinedDate: DateTime.now()
        .subtract(const Duration(days: 1))
        .millisecondsSinceEpoch, // New User
    popularityScore: 65,
  ),
  UserProfile(
    id: 'u3',
    name: 'Emily',
    age: 22,
    bio: 'Nature lover 🌿',
    imageUrls: ['https://images.unsplash.com/photo-1524504388940-b1c1722653e1'],
    location: 'Queens',
    profession: 'Student',
    gender: 'WOMEN',
    distance: 8.0,
    interests: ['Hiking', 'Photography'],
    lastActive: DateTime.now()
        .subtract(const Duration(days: 8))
        .millisecondsSinceEpoch,
    joinedDate: DateTime.now()
        .subtract(const Duration(days: 20))
        .millisecondsSinceEpoch,
    popularityScore: 40,
  ),
  UserProfile(
    id: 'u4',
    name: 'Amanda',
    age: 26,
    bio: 'Foodie 🍕',
    imageUrls: ['https://images.unsplash.com/photo-1534528741775-53994a69daeb'],
    location: 'Manhattan',
    profession: 'Chef',
    gender: 'WOMEN',
    distance: 2.0,
    interests: ['Cooking', 'Music'],
    lastActive: DateTime.now().millisecondsSinceEpoch,
    joinedDate: DateTime.now()
        .subtract(const Duration(days: 5))
        .millisecondsSinceEpoch,
    hasLikedCurrentUser: true, // Priority
    popularityScore: 90,
  ),
];

// ignore: non_constant_identifier_names
final List<AdContent> MOCK_ADS = [
  AdContent(
    id: 'ad1',
    title: 'Premium Dating',
    ctaText: 'Upgrade Now',
    imageUrl: 'https://images.unsplash.com/photo-1560250097-0b93528c311a',
    linkUrl: 'https://example.com',
    description: 'Get unlimited swipes and see who likes you!',
  ),
];
