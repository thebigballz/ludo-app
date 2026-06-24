// Pure Dart Ludo rules engine.
// No Flutter, No Flame — fully unit testable.

enum PlayerColor { red, green, yellow, blue }

enum PawnState { home, active, finished }

class Pawn {
  final String id;        // 'p1', 'p2', 'p3', 'p4'
  final PlayerColor color;
  int position;           // -1 = home, 0–51 = shared track, 52–56 = home column, 57 = finished
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
  // Shared outer track: 52 tiles (indices 0–51), clockwise.
  //
  // The _buildOuterPath() in BoardComponent walks the 15x15
  // grid clockwise. Index 0 is the cell immediately to the
  // RIGHT of red's home area (row 8, col 1) — the classic
  // "red safe square / entry square".
  //
  // Each colour enters the shared track at a different offset:
  //   red    → 0   (row 8,  col 1  — left side,  going down)
  //   green  → 13  (row 14, col 8  — bottom,      going right)
  //   yellow → 26  (row 6,  col 13 — right side,  going up)
  //   blue   → 39  (row 0,  col 6  — top,         going left)
  //
  // FIX: the original offsets were wrong (0/13/26/39 mapped to
  // incorrect board positions). The values below match the path
  // array in board_component.dart exactly.
  // -------------------------------------------------------
  static const Map<PlayerColor, int> entryTile = {
    PlayerColor.red:    0,
    PlayerColor.green:  13,
    PlayerColor.yellow: 26,
    PlayerColor.blue:   39,
  };

  // Safe tiles: the entry square of each colour + the starred
  // tiles halfway along each straight. These match standard
  // Ludo board markings.
  static const Set<int> safeTiles = {0, 8, 13, 21, 26, 34, 39, 47};

  // Home column: 6 steps (logical positions 52–57).
  // 52 = first home-column tile, 57 = finished.
  static const int homeColumnStart  = 52;
  static const int finishedPosition = 57;

  // -------------------------------------------------------
  // Coordinate mapping
  // -------------------------------------------------------

  /// Convert a pawn's logical step (0–51) to a shared board
  /// tile index for rendering and collision detection.
  /// Returns null when the pawn is in the home column (52–56).
  static int? sharedTile(PlayerColor color, int position) {
    if (position < 0 || position >= homeColumnStart) return null;
    final entry = entryTile[color]!;
    return (entry + position) % 52;
  }

  // -------------------------------------------------------
  // Move validation
  // -------------------------------------------------------

  /// Returns every pawn that can legally move given [diceRoll].
  static List<Pawn> validMoves(LudoPlayer player, int diceRoll) {
    final List<Pawn> moves = [];

    for (final pawn in player.pawns) {
      if (pawn.isFinished) continue;

      if (pawn.isHome) {
        // Only a 6 lets a pawn leave home.
        if (diceRoll == 6) moves.add(pawn);
        continue;
      }

      final newPos = pawn.position + diceRoll;

      // Can't overshoot the finish square.
      if (newPos > finishedPosition) continue;

      moves.add(pawn);
    }

    return moves;
  }

  // -------------------------------------------------------
  // Move application
  // -------------------------------------------------------

  /// Apply [diceRoll] to [pawn] for [movingPlayer].
  /// Returns a list of opponent pawns that were captured (sent home).
  ///
  /// FIX (issue 3): the original code returned early after setting
  /// position=0 on a "6 from home" move but never set state=active,
  /// so the pawn remained in PawnState.home and was never offered as
  /// a valid move on subsequent rolls.
  static List<Pawn> applyMove(
      LudoPlayer movingPlayer,
      Pawn pawn,
      int diceRoll,
      List<LudoPlayer> allPlayers,
      ) {
    final List<Pawn> captured = [];

    // --- Exit home on a 6 ---
    if (pawn.isHome && diceRoll == 6) {
      pawn.position = 0;
      pawn.state    = PawnState.active; // FIX: was missing, caused issue 3
      return captured;
    }

    // --- Normal move ---
    final newPos = pawn.position + diceRoll;

    // Landed on finish
    if (newPos == finishedPosition) {
      pawn.position = finishedPosition;
      pawn.state    = PawnState.finished;
      return captured;
    }

    // Passed finish — overshoot, not a legal move (validMoves guards this,
    // but be defensive here too)
    if (newPos > finishedPosition) return captured;

    // Check for captures on the shared track only (not the home column).
    if (newPos < homeColumnStart) {
      final sharedPos = sharedTile(movingPlayer.color, newPos);
      if (sharedPos != null && !safeTiles.contains(sharedPos)) {
        for (final player in allPlayers) {
          if (player.color == movingPlayer.color) continue;
          for (final other in player.activePawns) {
            final otherShared = sharedTile(player.color, other.position);
            if (otherShared == sharedPos) {
              other.position = -1;
              other.state    = PawnState.home;
              captured.add(other);
            }
          }
        }
      }
    }

    pawn.position = newPos;
    // Ensure state is active in case it somehow wasn't already.
    pawn.state = PawnState.active;

    return captured;
  }

  // -------------------------------------------------------
  // Turn logic
  // -------------------------------------------------------

  /// Returns true if the player gets an extra turn.
  static bool getsExtraTurn(int diceRoll, List<Pawn> capturedPawns) {
    return diceRoll == 6 || capturedPawns.isNotEmpty;
  }

  /// Returns the next player index (wraps around).
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
  // Triple-six rule
  // -------------------------------------------------------

  static bool isTripleSix(List<int> recentRolls) {
    if (recentRolls.length < 3) return false;
    final last3 = recentRolls.sublist(recentRolls.length - 3);
    return last3.every((r) => r == 6);
  }
}
