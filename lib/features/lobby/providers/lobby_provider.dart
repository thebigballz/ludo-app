import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/game_model.dart';
import '../data/repositories/lobby_repository.dart';
import '../../../core/errors/exceptions.dart';

final lobbyRepositoryProvider = Provider<LobbyRepository>((ref) {
  return LobbyRepository();
});

// State
class LobbyState {
  final List<GameModel> tables;
  final bool isLoading;
  final bool isJoining;
  final String? error;
  final double? selectedStake;

  const LobbyState({
    this.tables       = const [],
    this.isLoading    = false,
    this.isJoining    = false,
    this.error,
    this.selectedStake,
  });

  LobbyState copyWith({
    List<GameModel>? tables,
    bool? isLoading,
    bool? isJoining,
    String? error,
    double? selectedStake,
  }) {
    return LobbyState(
      tables:        tables        ?? this.tables,
      isLoading:     isLoading     ?? this.isLoading,
      isJoining:     isJoining     ?? this.isJoining,
      error:         error,
      selectedStake: selectedStake ?? this.selectedStake,
    );
  }
}

// Notifier
class LobbyNotifier extends StateNotifier<LobbyState> {
  final LobbyRepository _repository;

  LobbyNotifier(this._repository) : super(const LobbyState()) {
    loadTables();
  }

  Future<void> loadTables({double? stakeAmount}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final tables = await _repository.getTables(stakeAmount: stakeAmount);
      state = state.copyWith(tables: tables, isLoading: false);
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

  void filterByStake(double? stakeAmount) {
    state = state.copyWith(selectedStake: stakeAmount);
    loadTables(stakeAmount: stakeAmount);
  }

  Future<GameModel?> joinTable(int gameId) async {
    state = state.copyWith(isJoining: true, error: null);

    try {
      final game = await _repository.joinTable(gameId);
      state = state.copyWith(isJoining: false);
      return game;
    } on ServerException catch (e) {
      state = state.copyWith(isJoining: false, error: e.message);
      return null;
    } on NetworkException {
      state = state.copyWith(
        isJoining: false,
        error:     'No internet connection.',
      );
      return null;
    } catch (e) {
      state = state.copyWith(isJoining: false, error: 'Something went wrong.');
      return null;
    }
  }

  Future<bool> leaveTable(int gameId) async {
    try {
      await _repository.leaveTable(gameId);
      await loadTables();
      return true;
    } on ServerException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Something went wrong.');
      return false;
    }
  }
}

final lobbyProvider = StateNotifierProvider<LobbyNotifier, LobbyState>((ref) {
  return LobbyNotifier(ref.read(lobbyRepositoryProvider));
});