enum CardType { profile, ad, empty }

class CardItem {
  final CardType type;
  final dynamic data; // UserProfile or AdContent
  final String uniqueId;

  CardItem({required this.type, required this.data, required this.uniqueId});
}

class AdContent {
  final String id;
  final String title;
  final String ctaText;
  final String imageUrl;
  final String linkUrl;
  final String description;

  AdContent({
    required this.id,
    required this.title,
    required this.ctaText,
    required this.imageUrl,
    required this.linkUrl,
    required this.description,
  });
}
