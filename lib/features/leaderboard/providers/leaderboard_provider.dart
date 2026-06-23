import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/leaderboard_model.dart';
import '../data/repositories/leaderboard_repository.dart';
import '../../../core/errors/exceptions.dart';

final leaderboardRepositoryProvider =
Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository();
});

class LeaderboardState {
  final List<LeaderboardEntry> players;
  final bool isLoading;
  final String? error;

  const LeaderboardState({
    this.players  = const [],
    this.isLoading = false,
    this.error,
  });

  LeaderboardState copyWith({
    List<LeaderboardEntry>? players,
    bool? isLoading,
    String? error,
  }) {
    return LeaderboardState(
      players:   players   ?? this.players,
      isLoading: isLoading ?? this.isLoading,
      error:     error,
    );
  }
}

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final LeaderboardRepository _repository;

  LeaderboardNotifier(this._repository) : super(const LeaderboardState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final players = await _repository.getLeaderboard();
      state = state.copyWith(players: players, isLoading: false);
    } on NetworkException {
      state = state.copyWith(
        isLoading: false,
        error:     'No internet connection.',
      );
    } on ServerException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Something went wrong.');
    }
  }
}

final leaderboardProvider =
StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  return LeaderboardNotifier(ref.read(leaderboardRepositoryProvider));
});