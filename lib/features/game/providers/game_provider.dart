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
  // FIX: new flag — prevents the listener from calling skipTurn
  // while a skip write is already in-flight to Firebase.
  final bool isSkipping;
  final int? lastRoll;
  final List<int> rollHistory;
  final String? error;

  const GameActionState({
    this.isRolling   = false,
    this.isMoving    = false,
    this.isSkipping  = false,
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
      isRolling:   isRolling   ?? this.isRolling,
      isMoving:    isMoving    ?? this.isMoving,
      isSkipping:  isSkipping  ?? this.isSkipping,
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
      // FIX: when this player has no valid moves, skip immediately
      // from rollDice rather than relying on the listener.
      // This avoids the round-trip through Firebase that triggers
      // the other device's listener before this one has settled.
      await _doSkipTurn(players);
    }

    state = state.copyWith(isRolling: false, lastRoll: roll);
  }

  // FIX: renamed internal helper — only callable from within the notifier.
  // External callers (the listener in game_screen.dart) use skipTurnIfNeeded.
  Future<void> _doSkipTurn(List<LudoPlayer> players) async {
    final currentIndex =
    players.indexWhere((p) => p.userId == _userId);
    if (currentIndex < 0) return;

    final nextIndex = LudoLogic.nextPlayerIndex(
      currentIndex,
      players.length,
      false,
    );

    await _repository.advanceTurn(_roomId, players[nextIndex].userId);

    // FIX: clear dice_roll immediately after advancing so the next
    // device's listener sees phase='rolling' with no dice_roll value,
    // and therefore never enters the "no valid moves → skip" branch.
    await _repository.clearDiceRoll(_roomId);
  }

  /// Called by the game_screen listener. The guard ensures that even
  /// if Firebase fires multiple snapshots in quick succession, only one
  /// skip write goes through.
  Future<void> skipTurnIfNeeded(List<LudoPlayer> players) async {
    // FIX: bail out if we are already handling a skip, rolling, or moving.
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

    await _repository.recordMove(
      _roomId,
      _userId,
      diceRoll,
      pawnToMove.id,
      from,
      pawnToMove.position,
    );

    final winner = LudoLogic.checkWinner(allPlayers);
    if (winner != null) {
      await _repository.setWinner(_roomId, winner.userId);
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

    // FIX: clear dice_roll after every move so the next player's device
    // starts with a clean state and the listener never sees a stale roll.
    await _repository.clearDiceRoll(_roomId);

    state = state.copyWith(
      isMoving:    false,
      rollHistory: extraTurn ? state.rollHistory : [],
    );
  }

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
