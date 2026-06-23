//Pure Dart Ludo rules engine.
// No Flutter, No Flame — fully unit testable.

enum PlayerColor { red, green, yellow, blue }

enum PawnState { home, active, finished }

class Pawn {
  final String id;          // 'p1', 'p2', 'p3', 'p4'
  final PlayerColor color;
  int position;             // -1 = home, 0–56 = board, 57 = finished
  PawnState state;

  Pawn({
    required this.id,
    required this.color,
    this.position = -1,
    this.state    = PawnState.home,
  });

  bool get isHome     => state == PawnState.home;
  bool get isActive   => state == PawnState.active;
  bool get isFinished => state == PawnState.finished;
}

class LudoPlayer {
  final int userId;
  final PlayerColor color;
  final List<Pawn> pawns;

  LudoPlayer({
    required this.userId,
    required this.color,
  }) : pawns = List.generate(
    4,
        (i) => Pawn(id: 'p${i + 1}', color: color),
  );

  bool get hasWon => pawns.every((p) => p.isFinished);

  List<Pawn> get activePawns  => pawns.where((p) => p.isActive).toList();
  List<Pawn> get homePawns    => pawns.where((p) => p.isHome).toList();
}

class LudoLogic {
  // -------------------------------------------------------
  // Board path per color — 57 steps (0 = entry, 56 = last
  // before home, 57 = finished)
  // Each color has its own entry point on the shared track.
  // -------------------------------------------------------

  // Shared outer track: 52 tiles (0–51)
  // Each color enters at a different offset:
  static const Map<PlayerColor, int> entryTile = {
    PlayerColor.red:    0,
    PlayerColor.green:  13,
    PlayerColor.yellow: 26,
    PlayerColor.blue:   39,
  };

  // Safe tiles on the shared track (stars on a standard board)
  static const Set<int> safeTiles = {0, 8, 13, 21, 26, 34, 39, 47};

  // Home column length: 6 tiles (positions 52–57 in logical space)
  static const int homeColumnStart = 52;
  static const int finishedPosition = 57;

  /// Convert a pawn's logical step count (0–56) to a
  /// shared board tile index for collision detection.
  static int? sharedTile(PlayerColor color, int position) {
    if (position < 0 || position >= homeColumnStart) return null;
    final entry = entryTile[color]!;
    return (entry + position) % 52;
  }

  // -------------------------------------------------------
  // Move validation
  // -------------------------------------------------------

  /// Returns list of pawns that can legally move given a dice roll.
  static List<Pawn> validMoves(LudoPlayer player, int diceRoll) {
    final List<Pawn> moves = [];

    for (final pawn in player.pawns) {
      if (pawn.isFinished) continue;

      if (pawn.isHome) {
        // Can only exit home on a 6
        if (diceRoll == 6) moves.add(pawn);
        continue;
      }

      final newPos = pawn.position + diceRoll;

      // Can't overshoot finish
      if (newPos > finishedPosition) continue;

      moves.add(pawn);
    }

    return moves;
  }

  /// Returns true if a move results in a capture.
  static bool isCapture(
      LudoPlayer movingPlayer,
      Pawn movingPawn,
      int newPosition,
      List<LudoPlayer> allPlayers,
      ) {
    final sharedPos = sharedTile(movingPlayer.color, newPosition);
    if (sharedPos == null) return false;               // in home column
    if (safeTiles.contains(sharedPos)) return false;   // safe tile

    for (final player in allPlayers) {
      if (player.color == movingPlayer.color) continue;
      for (final pawn in player.activePawns) {
        final otherShared = sharedTile(player.color, pawn.position);
        if (otherShared == sharedPos) return true;
      }
    }
    return false;
  }

  /// Apply a move. Returns captured pawns (sent home) if any.
  static List<Pawn> applyMove(
      LudoPlayer movingPlayer,
      Pawn pawn,
      int diceRoll,
      List<LudoPlayer> allPlayers,
      ) {
    final List<Pawn> captured = [];

    if (pawn.isHome && diceRoll == 6) {
      pawn.position = 0;
      pawn.state    = PawnState.active;
      return captured;
    }

    final newPos = pawn.position + diceRoll;

    if (newPos == finishedPosition) {
      pawn.position = finishedPosition;
      pawn.state    = PawnState.finished;
      return captured;
    }

    // Check for captures before moving
    final sharedPos = sharedTile(movingPlayer.color, newPos);
    if (sharedPos != null && !safeTiles.contains(sharedPos)) {
      for (final player in allPlayers) {
        if (player.color == movingPlayer.color) continue;
        for (final other in player.activePawns) {
          final otherShared = sharedTile(player.color, other.position);
          if (otherShared == sharedPos) {
            // Send captured pawn home
            other.position = -1;
            other.state    = PawnState.home;
            captured.add(other);
          }
        }
      }
    }

    pawn.position = newPos;
    return captured;
  }

  // -------------------------------------------------------
  // Turn logic
  // -------------------------------------------------------

  /// Returns true if the player gets an extra turn.
  static bool getsExtraTurn(int diceRoll, List<Pawn> capturedPawns) {
    return diceRoll == 6 || capturedPawns.isNotEmpty;
  }

  /// Returns the next player index.
  static int nextPlayerIndex(
      int currentIndex,
      int playerCount,
      bool extraTurn,
      ) {
    if (extraTurn) return currentIndex;
    return (currentIndex + 1) % playerCount;
  }

  // -------------------------------------------------------
  // Win condition
  // -------------------------------------------------------

  static LudoPlayer? checkWinner(List<LudoPlayer> players) {
    for (final player in players) {
      if (player.hasWon) return player;
    }
    return null;
  }

  // -------------------------------------------------------
  // Dice
  // -------------------------------------------------------

  /// Triple 6 rule — if a player rolls three 6s in a row,
  /// their turn is forfeited and the last move is reversed.
  static bool isTripleSix(List<int> recentRolls) {
    if (recentRolls.length < 3) return false;
    final last3 = recentRolls.sublist(recentRolls.length - 3);
    return last3.every((r) => r == 6);
  }
}