import 'discovery_preferences.dart';

class UserProfile {
  final String id;
  final String name;
  final int age;
  final String bio;
  final List<String> imageUrls;
  final String location;
  final String profession;
  final String gender; // 'MEN' | 'WOMEN'
  final double distance; // in km
  final List<String> interests;
  final String? voiceIntro;
  final String? voiceIntroTitle;
  final int? dob; // Timestamp in milliseconds
  final bool isVerified;

  // New Personal Details
  final String? status; // Single, Available, Seeing Someone
  final String? orientation; // Straight, Gay, Bisexual
  final String? drinks; // Never, Sometimes, Socially, Often
  final String? height; // e.g. "175 cm" or "5'9""
  final String? religion;
  final String? sign; // Zodiac
  final String? smokes; // Yes, No, Sometimes
  final List<String>? speaks; // Languages
  final String? bodyType;
  final String? lookingFor;

  // Algorithm Fields
  final int lastActive; // Timestamp
  final int joinedDate; // Timestamp
  final bool hasLikedCurrentUser;
  final int popularityScore; // 0-100
  final bool isSuperLike; // Contextual: Did this user super like me?

  UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.bio,
    required this.imageUrls,
    required this.location,
    required this.profession,
    required this.gender,
    required this.distance,
    required this.interests,
    this.voiceIntro,
    this.voiceIntroTitle,
    this.dob,
    this.isVerified = false,
    this.status,
    this.orientation,
    this.drinks,
    this.height,
    this.religion,
    this.sign,
    this.smokes,
    this.speaks,
    this.bodyType,
    this.lookingFor,
    required this.lastActive,
    required this.joinedDate,
    this.hasLikedCurrentUser = false,
    this.isSuperLike = false,
    this.popularityScore = 50,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      age: (json['age'] as num?)?.toInt() ?? 18,
      bio: json['bio'] ?? '',
      imageUrls:
          (json['imageUrls'] as List?)?.map((e) => e.toString()).toList() ?? [],
      location: json['location'] ?? 'Unknown',
      profession: json['profession'] ?? '',
      gender: json['gender'] ?? 'WOMEN',
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      interests:
          (json['interests'] as List?)?.map((e) => e.toString()).toList() ?? [],
      voiceIntro: json['voiceIntro'],
      voiceIntroTitle: json['voiceIntroTitle'],
      dob: (json['dob'] as num?)?.toInt(),
      isVerified: json['isVerified'] ?? false,
      status: json['status'],
      orientation: json['orientation'],
      drinks: json['drinks'],
      height: json['height'],
      religion: json['religion'],
      sign: json['sign'],
      smokes: json['smokes'],
      speaks: (json['speaks'] as List?)?.map((e) => e.toString()).toList(),
      bodyType: json['bodyType'],
      lookingFor: json['lookingFor'],
      lastActive:
          (json['lastActive'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      joinedDate:
          (json['joinedDate'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      hasLikedCurrentUser: json['hasLikedCurrentUser'] ?? false,
      // isSuperLike is not usually in the user doc, defaults to false
      popularityScore: (json['popularityScore'] as num?)?.toInt() ?? 50,
    );
  }

  UserProfile copyWith({
    String? id,
    String? name,
    int? age,
    String? bio,
    List<String>? imageUrls,
    String? location,
    String? profession,
    String? gender,
    double? distance,
    List<String>? interests,
    String? voiceIntro,
    String? voiceIntroTitle,
    int? dob,
    bool? isVerified,
    int? lastActive,
    int? joinedDate,
    bool? hasLikedCurrentUser,
    bool? isSuperLike,
    int? popular,
    String? status,
    String? orientation,
    String? drinks,
    String? height,
    String? religion,
    String? sign,
    String? smokes,
    List<String>? speaks,
    String? bodyType,
    String? lookingFor,
    int? popularityScore,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      imageUrls: imageUrls ?? this.imageUrls,
      location: location ?? this.location,
      profession: profession ?? this.profession,
      gender: gender ?? this.gender,
      distance: distance ?? this.distance,
      interests: interests ?? this.interests,
      voiceIntro: voiceIntro ?? this.voiceIntro,
      voiceIntroTitle: voiceIntroTitle ?? this.voiceIntroTitle,
      dob: dob ?? this.dob,
      isVerified: isVerified ?? this.isVerified,
      status: status ?? this.status,
      orientation: orientation ?? this.orientation,
      drinks: drinks ?? this.drinks,
      height: height ?? this.height,
      religion: religion ?? this.religion,
      sign: sign ?? this.sign,
      smokes: smokes ?? this.smokes,
      speaks: speaks ?? this.speaks,
      bodyType: bodyType ?? this.bodyType,
      lookingFor: lookingFor ?? this.lookingFor,
      lastActive: lastActive ?? this.lastActive,
      joinedDate: joinedDate ?? this.joinedDate,
      hasLikedCurrentUser: hasLikedCurrentUser ?? this.hasLikedCurrentUser,
      isSuperLike: isSuperLike ?? this.isSuperLike,
      popularityScore: popularityScore ?? this.popularityScore,
    );
  }

  // Helper: Map to DiscoveryPreferences
  DiscoveryPreferences toDiscoveryPreferences([
    DiscoveryPreferences? existing,
  ]) {
    return DiscoveryPreferences(
      ageRange: existing?.ageRange ?? const [18, 35],
      distance: distance > 0 ? distance : (existing?.distance ?? 50),
      gender: lookingFor != null && lookingFor!.isNotEmpty
          ? (lookingFor == 'MEN' || lookingFor == 'WOMEN'
                ? lookingFor!
                : 'EVERYONE')
          : (existing?.gender ?? 'EVERYONE'),
      location: location,
      interests: interests,
      lookingFor: lookingFor != null
          ? [lookingFor!]
          : (existing?.lookingFor ?? []),
    );
  }

  // Helper: Create Profile from Preferences (Partial Update)
  UserProfile copyWithPreferences(DiscoveryPreferences prefs) {
    return copyWith(
      distance: prefs.distance,
      location: prefs.location,
      interests: prefs.interests,
      // We map 'gender' preference to 'lookingFor' field in profile/firestore for query usage
      lookingFor: prefs.gender,
    );
  }
}
