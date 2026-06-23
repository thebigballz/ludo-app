import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'ludo_logic.dart';
import 'ludo_game.dart';

class BoardComponent extends PositionComponent with HasGameRef<LudoGame> {
  static const int gridSize = 15;
  late double tileSize;
  late double boardSize;

  final Map<int, Vector2> sharedTilePositions = {};
  final Map<PlayerColor, Map<int, Vector2>> homeColumnPositions = {};
  final Map<PlayerColor, List<Vector2>> homePawnPositions = {};

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    boardSize = gameRef.size.x;
    tileSize  = boardSize / gridSize;
    size      = Vector2.all(boardSize);
    _computeTilePositions();
  }

  void _computeTilePositions() {
    final path = _buildOuterPath();
    for (int i = 0; i < path.length; i++) {
      final cell = path[i];
      sharedTilePositions[i] = Vector2(
        cell[1] * tileSize + tileSize / 2,
        cell[0] * tileSize + tileSize / 2,
      );
    }
    _buildHomeColumns();
    _buildHomeAreas();
  }

  // Perfect 52-tile clockwise path on 15x15 grid
  List<List<int>> _buildOuterPath() {
    return const [
      // Red entry going down (col 1, rows 6-13)
      [6,1],[7,1],[8,1],[9,1],[10,1],[11,1],[12,1],[13,1],
      // Bottom-left going right (row 13, cols 2-5)
      [13,2],[13,3],[13,4],[13,5],
      // Bottom excursion (row 14)
      [14,6],[14,7],[14,8],
      // Bottom-right going right (row 13, cols 9-13)
      [13,9],[13,10],[13,11],[13,12],[13,13],
      // Right side going up (col 13, rows 12-6)
      [12,13],[11,13],[10,13],[9,13],[8,13],[7,13],[6,13],
      // Right excursion (col 14)
      [6,14],[7,14],[8,14],
      // Continue right side up (col 13, rows 5-1)
      [5,13],[4,13],[3,13],[2,13],[1,13],
      // Top going left (row 1, cols 12-8)
      [1,12],[1,11],[1,10],[1,9],[1,8],
      // Top excursion (row 0)
      [0,8],[0,7],[0,6],
      // Top-left going left (row 1, cols 5-1)
      [1,5],[1,4],[1,3],[1,2],[1,1],
      // Left side going down (col 1, rows 2-5)
      [2,1],[3,1],[4,1],[5,1],
    ];
  }

  void _buildHomeColumns() {
    // Each color home column: 6 tiles leading to center (row/col 7)
    homeColumnPositions[PlayerColor.red] = {
      for (int i = 0; i < 6; i++)
        i: Vector2(tileSize * 7.5, tileSize * (8.5 + i)),
    };
    homeColumnPositions[PlayerColor.green] = {
      for (int i = 0; i < 6; i++)
        i: Vector2(tileSize * (6.5 - i), tileSize * 7.5),
    };
    homeColumnPositions[PlayerColor.yellow] = {
      for (int i = 0; i < 6; i++)
        i: Vector2(tileSize * 7.5, tileSize * (6.5 - i)),
    };
    homeColumnPositions[PlayerColor.blue] = {
      for (int i = 0; i < 6; i++)
        i: Vector2(tileSize * (8.5 + i), tileSize * 7.5),
    };
  }

  void _buildHomeAreas() {
    // 4 pawns in 2x2 grid inside each color quadrant
    homePawnPositions[PlayerColor.red] = [
      Vector2(tileSize * 2,    tileSize * 2),
      Vector2(tileSize * 3.5,  tileSize * 2),
      Vector2(tileSize * 2,    tileSize * 3.5),
      Vector2(tileSize * 3.5,  tileSize * 3.5),
    ];
    homePawnPositions[PlayerColor.green] = [
      Vector2(tileSize * 11,   tileSize * 2),
      Vector2(tileSize * 12.5, tileSize * 2),
      Vector2(tileSize * 11,   tileSize * 3.5),
      Vector2(tileSize * 12.5, tileSize * 3.5),
    ];
    homePawnPositions[PlayerColor.yellow] = [
      Vector2(tileSize * 11,   tileSize * 11),
      Vector2(tileSize * 12.5, tileSize * 11),
      Vector2(tileSize * 11,   tileSize * 12.5),
      Vector2(tileSize * 12.5, tileSize * 12.5),
    ];
    homePawnPositions[PlayerColor.blue] = [
      Vector2(tileSize * 2,    tileSize * 11),
      Vector2(tileSize * 3.5,  tileSize * 11),
      Vector2(tileSize * 2,    tileSize * 12.5),
      Vector2(tileSize * 3.5,  tileSize * 12.5),
    ];
  }

  Vector2 positionForPawn(PlayerColor color, int pawnIndex, int logicalPos) {
    if (logicalPos == -1) {
      return homePawnPositions[color]![pawnIndex];
    }
    if (logicalPos >= LudoLogic.homeColumnStart &&
        logicalPos < LudoLogic.finishedPosition) {
      final step = logicalPos - LudoLogic.homeColumnStart;
      return homeColumnPositions[color]![step]!;
    }
    if (logicalPos == LudoLogic.finishedPosition) {
      return Vector2(boardSize / 2, boardSize / 2);
    }
    final sharedPos = LudoLogic.sharedTile(color, logicalPos)!;
    return sharedTilePositions[sharedPos]!;
  }

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

    // Color quadrants (6x6 home areas)
    _drawQuadrant(canvas, 0,  0,  const Color(0xFFFFCDD2)); // Red TL
    _drawQuadrant(canvas, 0,  9,  const Color(0xFFC8E6C9)); // Green TR
    _drawQuadrant(canvas, 9,  9,  const Color(0xFFFFF9C4)); // Yellow BR
    _drawQuadrant(canvas, 9,  0,  const Color(0xFFBBDEFB)); // Blue BL

    // Inner home circles
    _drawHomeCircle(canvas, 0,  0,  const Color(0xFFE53935)); // Red
    _drawHomeCircle(canvas, 0,  9,  const Color(0xFF43A047)); // Green
    _drawHomeCircle(canvas, 9,  9,  const Color(0xFFFDD835)); // Yellow
    _drawHomeCircle(canvas, 9,  0,  const Color(0xFF1E88E5)); // Blue

    // Center triangles
    _drawCenterTriangles(canvas);

    // Grid lines (light)
    paint
      ..color       = const Color(0xFFE0E0E0)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (int i = 0; i <= gridSize; i++) {
      canvas.drawLine(Offset(i * tileSize, 0),
          Offset(i * tileSize, boardSize), paint);
      canvas.drawLine(Offset(0, i * tileSize),
          Offset(boardSize, i * tileSize), paint);
    }

    // Board border
    paint
      ..color       = const Color(0xFF9E9E9E)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(Rect.fromLTWH(0, 0, boardSize, boardSize), paint);

    // Home columns (colored paths to center)
    _drawHomeColumns(canvas);
  }

  void _drawQuadrant(Canvas canvas, int row, int col, Color color) {
    final paint = Paint()..color = color;
    canvas.drawRect(
      Rect.fromLTWH(
        col * tileSize,
        row * tileSize,
        tileSize * 6,
        tileSize * 6,
      ),
      paint,
    );
  }

  void _drawHomeCircle(Canvas canvas, int row, int col, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final center = Offset(
      (col + 3) * tileSize,
      (row + 3) * tileSize,
    );
    canvas.drawCircle(center, tileSize * 2, paint);

    // White inner circle
    paint.color = Colors.white;
    canvas.drawCircle(center, tileSize * 1.2, paint);
  }

  void _drawCenterTriangles(Canvas canvas) {
    final center = boardSize / 2;
    final t      = tileSize * 3;
    final paint  = Paint()..style = PaintingStyle.fill;

    // Red (top)
    paint.color = const Color(0xFFE53935);
    canvas.drawPath(
      Path()
        ..moveTo(center, center)
        ..lineTo(center - t, center - t)
        ..lineTo(center + t, center - t)
        ..close(),
      paint,
    );

    // Green (right)
    paint.color = const Color(0xFF43A047);
    canvas.drawPath(
      Path()
        ..moveTo(center, center)
        ..lineTo(center + t, center - t)
        ..lineTo(center + t, center + t)
        ..close(),
      paint,
    );

    // Yellow (bottom)
    paint.color = const Color(0xFFFDD835);
    canvas.drawPath(
      Path()
        ..moveTo(center, center)
        ..lineTo(center + t, center + t)
        ..lineTo(center - t, center + t)
        ..close(),
      paint,
    );

    // Blue (left)
    paint.color = const Color(0xFF1E88E5);
    canvas.drawPath(
      Path()
        ..moveTo(center, center)
        ..lineTo(center - t, center + t)
        ..lineTo(center - t, center - t)
        ..close(),
      paint,
    );

    // Center white hexagon
    final hexPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(center, center), tileSize * 0.8, hexPaint);
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
}