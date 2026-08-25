import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/game_room_model.dart';
import '../data/repositories/game_repository.dart';
import '../engine/ludo_logic.dart';
import '../../auth/providers/auth_provider.dart';

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepository();
});

final gameRoomStreamProvider = StreamProvider.family<GameRoomModel?, String>(
      (ref, String roomId) {
    final repo = ref.watch(gameRepositoryProvider);
    return repo.watchRoom(roomId);
  },
);

final gameStateStreamProvider =
StreamProvider.family<GameRoomState?, String>(
      (ref, String roomId) {
    final repo = ref.watch(gameRepositoryProvider);
    return repo.watchState(roomId);
  },
);

final gamePawnsStreamProvider =
StreamProvider.family<Map<String, PawnPositions>, String>(
      (ref, String roomId) {
    final repo = ref.watch(gameRepositoryProvider);
    return repo.watchPawns(roomId);
  },
);

class GameActionState {
  final bool isRolling;
  final bool isMoving;
  final bool isSkipping;
  final int? lastRoll;
  final List<int> rollHistory;
  final String? error;

  const GameActionState({
    this.isRolling = false,
    this.isMoving = false,
    this.isSkipping = false,
    this.lastRoll,
    this.rollHistory = const [],
    this.error,
  });

  GameActionState copyWith({
    bool? isRolling,
    bool? isMoving,
    bool? isSkipping,
    int? lastRoll,
    List<int>? rollHistory,
    String? error,
  }) {
    return GameActionState(
      isRolling: isRolling ?? this.isRolling,
      isMoving: isMoving ?? this.isMoving,
      isSkipping: isSkipping ?? this.isSkipping,
      lastRoll: lastRoll ?? this.lastRoll,
      rollHistory: rollHistory ?? this.rollHistory,
      error: error,
    );
  }
}

class GameNotifier extends StateNotifier<GameActionState> {
  final GameRepository _repository;
  final int _userId;
  final String _roomId;

  GameNotifier(this._repository, this._userId, this._roomId)
      : super(const GameActionState());

  Future<int?> _gameId() => _repository.getGameId(_roomId);

  Future<void> rollDice(List<LudoPlayer> players) async {
    if (state.isRolling || state.isSkipping || state.isMoving) return;

    state = state.copyWith(isRolling: true, error: null);

    try {
      final gameId = await _gameId();
      if (gameId == null) {
        throw StateError('Game ID is unavailable.');
      }

      final roll = await _repository.requestDiceRoll(gameId);
      state = state.copyWith(
        isRolling: false,
        lastRoll: roll,
      );
    } catch (e) {
      state = state.copyWith(
        isRolling: false,
        error: _messageFromError(e),
      );
    }
  }

  Future<void> skipTurnIfNeeded(List<LudoPlayer> players) async {
    if (state.isSkipping || state.isRolling || state.isMoving) return;

    state = state.copyWith(isSkipping: true, error: null);
    try {
      final gameId = await _gameId();
      if (gameId == null) {
        throw StateError('Game ID is unavailable.');
      }
      await _repository.skipTurn(gameId);
    } catch (e) {
      state = state.copyWith(error: _messageFromError(e));
    } finally {
      state = state.copyWith(isSkipping: false);
    }
  }

  Future<void> movePawn(
      Pawn pawn,
      int diceRoll,
      List<LudoPlayer> allPlayers,
      ) async {
    if (state.isMoving || state.isRolling || state.isSkipping) return;

    state = state.copyWith(isMoving: true, error: null);
    try {
      final gameId = await _gameId();
      if (gameId == null) {
        throw StateError('Game ID is unavailable.');
      }

      final pawnIndex = int.parse(pawn.id.replaceFirst('p', '')) - 1;
      await _repository.movePawn(gameId, pawnIndex);
    } catch (e) {
      state = state.copyWith(error: _messageFromError(e));
    } finally {
      state = state.copyWith(isMoving: false);
    }
  }

  Future<void> setConnected(bool connected) async {
    await _repository.setPlayerConnected(_roomId, _userId, connected);
  }

  String _messageFromError(Object error) {
    final message = error.toString();
    return message.startsWith('DioException')
        ? 'The server rejected the action. Please try again.'
        : message;
  }
}

final gameProvider = StateNotifierProvider
    .family<GameNotifier, GameActionState, String>(
      (ref, String roomId) {
    final repo = ref.watch(gameRepositoryProvider);
    final userId = ref.watch(authProvider).user?.id ?? 0;
    return GameNotifier(repo, userId, roomId);
  },
);
