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

  /// Requests a server-generated dice result.
  ///
  /// The client no longer calls Random() or writes dice_roll directly.
  /// The Firebase Cloud Function is responsible for generating and publishing
  /// the authoritative result.
  Future<void> rollDice(List<LudoPlayer> players) async {
    if (state.isRolling) return;

    state = state.copyWith(isRolling: true);
    try {
      await _repository.requestDiceRoll(_roomId);
    } catch (e) {
      state = state.copyWith(
        isRolling: false,
        error: 'Unable to request dice roll.',
      );
      rethrow;
    }
  }

  Future<void> _doSkipTurn(List<LudoPlayer> players) async {
    final currentIndex = players.indexWhere((p) => p.userId == _userId);
    if (currentIndex < 0) return;

    final nextIndex = LudoLogic.nextPlayerIndex(
      currentIndex,
      players.length,
      false,
    );

    await _repository.advanceTurn(_roomId, players[nextIndex].userId);
    await _repository.clearDiceRoll(_roomId);
  }

  Future<void> skipTurnIfNeeded(List<LudoPlayer> players) async {
    if (state.isSkipping || state.isRolling || state.isMoving) return;

    state = state.copyWith(isSkipping: true);
    try {
      await _doSkipTurn(players);
    } finally {
      state = state.copyWith(isSkipping: false);
    }
  }

  Future<void> movePawn(
      Pawn pawn,
      int diceRoll,
      List<LudoPlayer> allPlayers,
      ) async {
    if (state.isMoving) return;

    state = state.copyWith(isMoving: true);

    final currentPlayer =
    allPlayers.firstWhere((p) => p.userId == _userId);
    final pawnToMove =
    currentPlayer.pawns.firstWhere((p) => p.id == pawn.id);
    final from = pawnToMove.position;

    final captured = LudoLogic.applyMove(
      currentPlayer,
      pawnToMove,
      diceRoll,
      allPlayers,
    );

    await _repository.movePawn(
      _roomId,
      _userId,
      pawnToMove.id,
      pawnToMove.position,
    );

    for (final capturedPawn in captured) {
      final owner = allPlayers.firstWhere(
            (p) => p.pawns.any(
              (cp) =>
          cp.id == capturedPawn.id && cp.color == capturedPawn.color,
        ),
      );
      await _repository.movePawn(
        _roomId,
        owner.userId,
        capturedPawn.id,
        -1,
      );
    }

    // Move history is now server-owned. This call remains here temporarily
    // for the Phase 2 transition, but the current Firebase rules reject it.

    final winner = LudoLogic.checkWinner(allPlayers);
    if (winner != null) {
      // Winner publication will also become server-authoritative in Phase 2.
      state = state.copyWith(isMoving: false);
      return;
    }

    final extraTurn = LudoLogic.getsExtraTurn(diceRoll, captured);
    final currentIndex =
    allPlayers.indexWhere((p) => p.userId == _userId);
    final nextIndex = LudoLogic.nextPlayerIndex(
      currentIndex,
      allPlayers.length,
      extraTurn,
    );

    await _repository.advanceTurn(_roomId, allPlayers[nextIndex].userId);
    await _repository.clearDiceRoll(_roomId);

    state = state.copyWith(
      isMoving: false,
      rollHistory: extraTurn ? state.rollHistory : [],
    );
  }

  Future<void> setConnected(bool connected) async {
    await _repository.setPlayerConnected(_roomId, _userId, connected);
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
