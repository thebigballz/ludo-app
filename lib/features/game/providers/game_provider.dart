import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/game_room_model.dart';
import '../data/repositories/game_repository.dart';
import '../engine/ludo_logic.dart';
import '../../auth/providers/auth_provider.dart';

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepository();
});

// Stream providers for real-time Firebase data
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

// -------------------------------------------------------
// Game action state
// -------------------------------------------------------

class GameActionState {
  final bool isRolling;
  final bool isMoving;
  final int? lastRoll;
  final List<int> rollHistory;
  final String? error;

  const GameActionState({
    this.isRolling   = false,
    this.isMoving    = false,
    this.lastRoll,
    this.rollHistory = const [],
    this.error,
  });

  GameActionState copyWith({
    bool? isRolling,
    bool? isMoving,
    int? lastRoll,
    List<int>? rollHistory,
    String? error,
  }) {
    return GameActionState(
      isRolling:   isRolling   ?? this.isRolling,
      isMoving:    isMoving    ?? this.isMoving,
      lastRoll:    lastRoll    ?? this.lastRoll,
      rollHistory: rollHistory ?? this.rollHistory,
      error:       error,
    );
  }
}

// -------------------------------------------------------
// Game notifier
// -------------------------------------------------------

class GameNotifier extends StateNotifier<GameActionState> {
  final GameRepository _repository;
  final int _userId;
  final String _roomId;

  GameNotifier(this._repository, this._userId, this._roomId)
      : super(const GameActionState());

  Future<void> rollDice(List<LudoPlayer> players) async {
    if (state.isRolling) return;

    state = state.copyWith(isRolling: true);

    final roll = Random().nextInt(6) + 1;
    await _repository.setDiceRoll(_roomId, roll);

    final currentPlayer =
        players.firstWhere((p) => p.userId == _userId);
    final validMoves = LudoLogic.validMoves(currentPlayer, roll);

    if (validMoves.isEmpty) {
      final currentIndex =
          players.indexWhere((p) => p.userId == _userId);
      final nextIndex = LudoLogic.nextPlayerIndex(
        currentIndex,
        players.length,
        false,
      );
      await _repository.advanceTurn(_roomId, players[nextIndex].userId);
    }

    state = state.copyWith(isRolling: false, lastRoll: roll);
  }

  Future<void> skipTurn(List<LudoPlayer> players) async {
    if (state.isMoving || state.isRolling) return;

    final currentIndex =
        players.indexWhere((p) => p.userId == _userId);
    if (currentIndex < 0) return;

    final nextIndex = LudoLogic.nextPlayerIndex(
      currentIndex,
      players.length,
      false,
    );
    await _repository.advanceTurn(_roomId, players[nextIndex].userId);
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

    // Update Firebase pawn position
    await _repository.movePawn(
      _roomId,
      _userId,
      pawnToMove.id,
      pawnToMove.position,
    );

    // Update captured pawns
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

    // Record the move
    await _repository.recordMove(
      _roomId,
      _userId,
      diceRoll,
      pawnToMove.id,
      from,
      pawnToMove.position,
    );

    // Check for winner
    final winner = LudoLogic.checkWinner(allPlayers);
    if (winner != null) {
      await _repository.setWinner(_roomId, winner.userId);
      state = state.copyWith(isMoving: false);
      return;
    }

    // Extra turn on 6 or capture
    final extraTurn = LudoLogic.getsExtraTurn(diceRoll, captured);
    final currentIndex =
    allPlayers.indexWhere((p) => p.userId == _userId);
    final nextIndex = LudoLogic.nextPlayerIndex(
      currentIndex,
      allPlayers.length,
      extraTurn,
    );

    await _repository.advanceTurn(_roomId, allPlayers[nextIndex].userId);

    state = state.copyWith(
      isMoving:    false,
      rollHistory: extraTurn ? state.rollHistory : [],
    );
  }

  // Presence
  Future<void> setConnected(bool connected) async {
    await _repository.setPlayerConnected(_roomId, _userId, connected);
  }
}

// -------------------------------------------------------
// Provider
// -------------------------------------------------------

final gameProvider = StateNotifierProvider
    .family<GameNotifier, GameActionState, String>(
      (ref, String roomId) {
    final repo   = ref.watch(gameRepositoryProvider);
    final userId = ref.watch(authProvider).user?.id ?? 0;
    return GameNotifier(repo, userId, roomId);
  },
);