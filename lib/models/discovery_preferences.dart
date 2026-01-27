class DiscoveryPreferences {
  final List<double> ageRange; // [min, max]
  final double distance;
  final String gender; // 'MEN', 'WOMEN', 'EVERYONE'
  final String location;
  final List<String> interests;
  final List<String> lookingFor;

  const DiscoveryPreferences({
    this.ageRange = const [18, 35],
    this.distance = 50,
    this.gender = 'EVERYONE',
    this.location = '',
    this.interests = const [],
    this.lookingFor = const [],
  });

  DiscoveryPreferences copyWith({
    List<double>? ageRange,
    double? distance,
    String? gender,
    String? location,
    List<String>? interests,
    List<String>? lookingFor,
  }) {
    return DiscoveryPreferences(
      ageRange: ageRange ?? this.ageRange,
      distance: distance ?? this.distance,
      gender: gender ?? this.gender,
      location: location ?? this.location,
      interests: interests ?? this.interests,
      lookingFor: lookingFor ?? this.lookingFor,
    );
  }
}
