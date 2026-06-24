import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'ludo_logic.dart';
import 'ludo_game.dart';

class BoardComponent extends PositionComponent with HasGameRef<LudoGame> {
  static const int gridSize = 15;
  late double tileSize;
  late double boardSize;

  // Maps shared track index (0–51) → board centre pixel
  final Map<int, Vector2> sharedTilePositions = {};

  // Maps colour → { home-column step (0–5) → board centre pixel }
  final Map<PlayerColor, Map<int, Vector2>> homeColumnPositions = {};

  // Maps colour → list of 4 home-base centre pixels (where pawns wait)
  final Map<PlayerColor, List<Vector2>> homePawnPositions = {};

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    boardSize = gameRef.size.x;
    tileSize  = boardSize / gridSize;
    size      = Vector2.all(boardSize);
    _computeTilePositions();
  }

  // -------------------------------------------------------
  // Position computation
  // -------------------------------------------------------

  void _computeTilePositions() {
    final path = _buildOuterPath();
    for (int i = 0; i < path.length; i++) {
      final cell = path[i];
      // FIX (issue 1): use tileCentre() everywhere so every shared-track
      // position is the pixel centre of its cell, not the top-left corner.
      sharedTilePositions[i] = _tileCentre(cell[0], cell[1]);
    }
    _buildHomeColumns();
    _buildHomeAreas();
  }

  /// Returns the pixel centre of the tile at (row, col).
  Vector2 _tileCentre(int row, int col) {
    return Vector2(
      col * tileSize + tileSize / 2,
      row * tileSize + tileSize / 2,
    );
  }

  // -------------------------------------------------------
  // Shared outer path (52 tiles, clockwise)
  //
  // FIX (issue 2): the original path started at [6,1] (mid-left),
  // making index 0 the wrong square for every colour's entry point.
  //
  // Standard Ludo layout on a 15×15 grid:
  //   • Red   enters at row 8, col 1  (left side, going down)  → index 0
  //   • Green enters at row 14, col 8 (bottom edge, going right)→ index 13
  //   • Yellow enters at row 6, col 13 (right side, going up)  → index 26
  //   • Blue  enters at row 0, col 6  (top edge, going left)   → index 39
  //
  // The path is walked clockwise from red's entry square.
  // -------------------------------------------------------
  List<List<int>> _buildOuterPath() {
    return const [
      // --- Red entry & left side going DOWN (col 1, rows 8→13) ---
      [8,1],  // index 0  ← red entry / safe square
      [9,1],[10,1],[11,1],[12,1],[13,1],

      // --- Bottom-left corner going RIGHT (row 13, cols 2→5) ---
      [13,2],[13,3],[13,4],[13,5],

      // --- Bottom excursion (row 14, cols 6→8) ---
      [14,6],[14,7],[14,8],  // index 13 ← green entry

      // --- Bottom-right corner going RIGHT (row 13, cols 9→13) ---
      [13,9],[13,10],[13,11],[13,12],[13,13],

      // --- Right side going UP (col 13, rows 12→6) ---
      [12,13],[11,13],[10,13],[9,13],[8,13],[7,13],[6,13],

      // --- Right excursion (col 14, rows 6→8) ---
      [6,14],[7,14],[8,14],  // index 26 ← yellow entry

      // --- Top-right corner going LEFT (row 1, cols 13→9) ---
      [1,13],[1,12],[1,11],[1,10],[1,9],

      // --- Top excursion (row 0, cols 8→6) ---
      [0,8],[0,7],[0,6],  // index 39 ← blue entry

      // --- Top-left corner going LEFT (row 1, cols 5→1) ---
      [1,5],[1,4],[1,3],[1,2],[1,1],

      // --- Left side going DOWN (col 1, rows 2→7) ---
      [2,1],[3,1],[4,1],[5,1],[6,1],[7,1],
      // index 51 is [7,1], one step above red's entry — correct
    ];
  }

  // -------------------------------------------------------
  // Home columns (the coloured straight to the centre)
  // Each colour has 6 steps (logical positions 52–57).
  // Step 0 is the first tile entering from the shared track;
  // step 5 leads into the centre finish triangle.
  // -------------------------------------------------------
  void _buildHomeColumns() {
    // Red: enters from left (col 1, row 8), column goes RIGHT
    homeColumnPositions[PlayerColor.red] = {
      for (int i = 0; i < 6; i++)
        i: _tileCentre(8, 2 + i),   // row 8, cols 2→7
    };

    // Green: enters from bottom (row 14, col 8), column goes UP
    homeColumnPositions[PlayerColor.green] = {
      for (int i = 0; i < 6; i++)
        i: _tileCentre(13 - i, 8),  // col 8, rows 13→8
    };

    // Yellow: enters from right (col 13, row 6), column goes LEFT
    homeColumnPositions[PlayerColor.yellow] = {
      for (int i = 0; i < 6; i++)
        i: _tileCentre(6, 12 - i),  // row 6, cols 12→7
    };

    // Blue: enters from top (row 1, col 6), column goes DOWN
    homeColumnPositions[PlayerColor.blue] = {
      for (int i = 0; i < 6; i++)
        i: _tileCentre(2 + i, 6),   // col 6, rows 2→7
    };
  }

  // -------------------------------------------------------
  // Home areas (the coloured quadrants where pawns start)
  // 4 pawns arranged in a 2×2 grid inside each quadrant.
  // FIX (issue 1): use _tileCentre() so pawns sit in cell centres.
  // -------------------------------------------------------
  void _buildHomeAreas() {
    // Red: top-left quadrant (rows 0–5, cols 0–5)
    homePawnPositions[PlayerColor.red] = [
      _tileCentre(2, 2), _tileCentre(2, 4),
      _tileCentre(4, 2), _tileCentre(4, 4),
    ];

    // Green: top-right quadrant (rows 0–5, cols 9–14)
    homePawnPositions[PlayerColor.green] = [
      _tileCentre(2, 10), _tileCentre(2, 12),
      _tileCentre(4, 10), _tileCentre(4, 12),
    ];

    // Yellow: bottom-right quadrant (rows 9–14, cols 9–14)
    homePawnPositions[PlayerColor.yellow] = [
      _tileCentre(10, 10), _tileCentre(10, 12),
      _tileCentre(12, 10), _tileCentre(12, 12),
    ];

    // Blue: bottom-left quadrant (rows 9–14, cols 0–5)
    homePawnPositions[PlayerColor.blue] = [
      _tileCentre(10, 2), _tileCentre(10, 4),
      _tileCentre(12, 2), _tileCentre(12, 4),
    ];
  }

  // -------------------------------------------------------
  // Public API used by PawnComponent
  // -------------------------------------------------------

  /// Returns the pixel centre position for a pawn given its
  /// logical state. PawnComponent subtracts radius to place
  /// the circle centred on this point.
  Vector2 positionForPawn(PlayerColor color, int pawnIndex, int logicalPos) {
    // In home base
    if (logicalPos == -1) {
      return homePawnPositions[color]![pawnIndex];
    }

    // In home column (steps 0–5 mapped to logical 52–56)
    if (logicalPos >= LudoLogic.homeColumnStart &&
        logicalPos < LudoLogic.finishedPosition) {
      final step = logicalPos - LudoLogic.homeColumnStart;
      return homeColumnPositions[color]![step]!;
    }

    // Finished — centre of the board
    if (logicalPos == LudoLogic.finishedPosition) {
      return Vector2(boardSize / 2, boardSize / 2);
    }

    // On the shared track
    final sharedIdx = LudoLogic.sharedTile(color, logicalPos);
    if (sharedIdx == null) {
      // Fallback: shouldn't happen, but return centre rather than crash
      return Vector2(boardSize / 2, boardSize / 2);
    }
    return sharedTilePositions[sharedIdx]!;
  }

  // -------------------------------------------------------
  // Rendering
  // -------------------------------------------------------

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _drawBoard(canvas);
  }

  void _drawBoard(Canvas canvas) {
    final paint = Paint();

    // White background
    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, boardSize, boardSize), paint);

    // Coloured home quadrants (6×6 each)
    _drawQuadrant(canvas, 0,  0,  const Color(0xFFFFCDD2)); // Red   TL
    _drawQuadrant(canvas, 0,  9,  const Color(0xFFC8E6C9)); // Green TR
    _drawQuadrant(canvas, 9,  9,  const Color(0xFFFFF9C4)); // Yellow BR
    _drawQuadrant(canvas, 9,  0,  const Color(0xFFBBDEFB)); // Blue  BL

    // Inner home circles
    _drawHomeCircle(canvas, 0, 0,  const Color(0xFFE53935)); // Red
    _drawHomeCircle(canvas, 0, 9,  const Color(0xFF43A047)); // Green
    _drawHomeCircle(canvas, 9, 9,  const Color(0xFFFDD835)); // Yellow
    _drawHomeCircle(canvas, 9, 0,  const Color(0xFF1E88E5)); // Blue

    // Centre finish triangles
    _drawCenterTriangles(canvas);

    // Grid lines
    paint
      ..color       = const Color(0xFFE0E0E0)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (int i = 0; i <= gridSize; i++) {
      canvas.drawLine(
          Offset(i * tileSize, 0), Offset(i * tileSize, boardSize), paint);
      canvas.drawLine(
          Offset(0, i * tileSize), Offset(boardSize, i * tileSize), paint);
    }

    // Board border
    paint
      ..color       = const Color(0xFF9E9E9E)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(Rect.fromLTWH(0, 0, boardSize, boardSize), paint);

    // Coloured home columns
    _drawHomeColumns(canvas);

    // Safe-tile stars
    _drawSafeTileStars(canvas);
  }

  void _drawQuadrant(Canvas canvas, int row, int col, Color color) {
    final paint = Paint()..color = color;
    canvas.drawRect(
      Rect.fromLTWH(col * tileSize, row * tileSize, tileSize * 6, tileSize * 6),
      paint,
    );
  }

  void _drawHomeCircle(Canvas canvas, int row, int col, Color color) {
    final center = Offset((col + 3) * tileSize, (row + 3) * tileSize);

    // Coloured circle
    canvas.drawCircle(center, tileSize * 2,   Paint()..color = color);
    // White inner
    canvas.drawCircle(center, tileSize * 1.2, Paint()..color = Colors.white);
  }

  void _drawCenterTriangles(Canvas canvas) {
    final cx = boardSize / 2;
    final cy = boardSize / 2;
    final t  = tileSize * 3;

    final colors = [
      const Color(0xFFE53935), // Red    (top)
      const Color(0xFF43A047), // Green  (right)
      const Color(0xFFFDD835), // Yellow (bottom)
      const Color(0xFF1E88E5), // Blue   (left)
    ];

    final triangles = [
      [Offset(cx, cy), Offset(cx - t, cy - t), Offset(cx + t, cy - t)],
      [Offset(cx, cy), Offset(cx + t, cy - t), Offset(cx + t, cy + t)],
      [Offset(cx, cy), Offset(cx + t, cy + t), Offset(cx - t, cy + t)],
      [Offset(cx, cy), Offset(cx - t, cy + t), Offset(cx - t, cy - t)],
    ];

    for (int i = 0; i < 4; i++) {
      final path = Path()
        ..moveTo(triangles[i][0].dx, triangles[i][0].dy)
        ..lineTo(triangles[i][1].dx, triangles[i][1].dy)
        ..lineTo(triangles[i][2].dx, triangles[i][2].dy)
        ..close();
      canvas.drawPath(path, Paint()..color = colors[i]);
    }

    // White centre circle
    canvas.drawCircle(
        Offset(cx, cy), tileSize * 0.8, Paint()..color = Colors.white);
  }

  void _drawHomeColumns(Canvas canvas) {
    final colors = {
      PlayerColor.red:    const Color(0xFFE53935),
      PlayerColor.green:  const Color(0xFF43A047),
      PlayerColor.yellow: const Color(0xFFFDD835),
      PlayerColor.blue:   const Color(0xFF1E88E5),
    };

    for (final entry in homeColumnPositions.entries) {
      final paint = Paint()
        ..color = colors[entry.key]!.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;

      for (final pos in entry.value.values) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(pos.x, pos.y),
            width:  tileSize * 0.9,
            height: tileSize * 0.9,
          ),
          paint,
        );
      }
    }
  }

  /// Draw a small star on each safe tile so players can see them.
  void _drawSafeTileStars(Canvas canvas) {
    const safeIndices = LudoLogic.safeTiles;
    final paint = Paint()..color = const Color(0x55000000);

    for (final idx in safeIndices) {
      final pos = sharedTilePositions[idx];
      if (pos == null) continue;
      final tp = TextPainter(
        text: const TextSpan(text: '★', style: TextStyle(fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(pos.x - tp.width / 2, pos.y - tp.height / 2),
      );
    }
  }
}
