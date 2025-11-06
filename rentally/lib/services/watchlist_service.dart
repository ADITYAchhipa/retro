import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WatchlistState {
  final Set<String> watchedIds;
  final bool isLoading;
  final String? error;

  const WatchlistState({
    this.watchedIds = const {},
    this.isLoading = false,
    this.error,
  });

  WatchlistState copyWith({
    Set<String>? watchedIds,
    bool? isLoading,
    String? error,
  }) => WatchlistState(
        watchedIds: watchedIds ?? this.watchedIds,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  bool isWatched(String id) => watchedIds.contains(id);
}

class WatchlistService extends StateNotifier<WatchlistState> {
  WatchlistService() : super(const WatchlistState()) {
    _load();
  }

  static const String _prefsKey = 'watched_listing_ids';

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_prefsKey) ?? <String>[];
      state = state.copyWith(watchedIds: ids.toSet(), isLoading: false);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load watchlist: $e', isLoading: false);
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, state.watchedIds.toList());
    } catch (e) {
      state = state.copyWith(error: 'Failed to save watchlist: $e');
    }
  }

  Future<void> toggle(String id) async {
    final ids = Set<String>.from(state.watchedIds);
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
    }
    state = state.copyWith(watchedIds: ids);
    await _save();
  }

  Future<void> add(String id) async {
    if (!state.watchedIds.contains(id)) {
      final ids = Set<String>.from(state.watchedIds)..add(id);
      state = state.copyWith(watchedIds: ids);
      await _save();
    }
  }

  Future<void> remove(String id) async {
    if (state.watchedIds.contains(id)) {
      final ids = Set<String>.from(state.watchedIds)..remove(id);
      state = state.copyWith(watchedIds: ids);
      await _save();
    }
  }
}

final watchlistProvider = StateNotifierProvider<WatchlistService, WatchlistState>((ref) {
  return WatchlistService();
});
