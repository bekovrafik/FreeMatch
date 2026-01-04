import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_item.dart';
import '../services/feed_service.dart';
import 'user_provider.dart';

final feedServiceProvider = Provider((ref) => FeedService(ref));

// Convert to AsyncNotifier to handle async initialization cleanly
final feedProvider = AsyncNotifierProvider<FeedNotifier, List<CardItem>>(
  FeedNotifier.new,
);

class FeedNotifier extends AsyncNotifier<List<CardItem>> {
  late FeedService _service;
  int _currentIndex = 0;

  @override
  Future<List<CardItem>> build() async {
    _service = ref.watch(feedServiceProvider);
    // Watch user settings to trigger refresh when filters change
    ref.watch(userProvider);

    await _service.initializeFeed();
    return _initialLoad();
  }

  List<CardItem> _initialLoad() {
    // Load first batch
    final List<CardItem> newCards = [];
    for (int i = 0; i < 5; i++) {
      newCards.add(_service.getCardAtIndex(_currentIndex + i));
    }
    return newCards;
  }

  // History for Rewind
  final List<int> _history = [];

  void popCard() {
    _history.add(_currentIndex); // Save current index before advancing
    _currentIndex++;

    final nextCard = _service.getCardAtIndex(_currentIndex + 4);

    // Efficient state update for AsyncValue
    state = AsyncValue.data([...(state.value?.skip(1) ?? []), nextCard]);
  }

  void rewind() {
    if (_history.isEmpty) return;

    final prevIndex = _history.removeLast();
    _currentIndex = prevIndex;

    // To visualy "rewind", we need to reconstruct the stack starting from the OLD index
    // This is expensive but necessary for the visual effect of "returning"
    state = AsyncValue.data(_initialLoad());
  }

  bool get canRewind => _history.isNotEmpty;

  int get currentIndex => _currentIndex;
}
