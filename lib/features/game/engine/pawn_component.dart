import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'ludo_logic.dart';
import 'board_component.dart';

class PawnComponent extends CircleComponent with TapCallbacks {
  final Pawn pawn;
  final VoidCallback onTapped;
  final BoardComponent boardComponent;

  bool _isHighlighted = false;
  int  _pawnIndex     = 0;

  PawnComponent({
    required this.pawn,
    required this.onTapped,
    required this.boardComponent,
  }) : super(radius: 0);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    priority = 10;
    radius = boardComponent.tileSize * 0.38;
    _pawnIndex = int.parse(pawn.id.replaceAll('p', '')) - 1;
    refreshPosition();
  }

  void refreshPosition() {
    final pos = boardComponent.positionForPawn(
      pawn.color,
      _pawnIndex,
      pawn.position,
    );
    position = pos - Vector2.all(radius);
  }

  void setHighlighted(bool highlighted) {
    _isHighlighted = highlighted;
  }

  Color get _pawnColor {
    switch (pawn.color) {
      case PlayerColor.red:    return const Color(0xFFE53935);
      case PlayerColor.green:  return const Color(0xFF43A047);
      case PlayerColor.yellow: return const Color(0xFFFDD835);
      case PlayerColor.blue:   return const Color(0xFF1E88E5);
    }
  }

  @override
  void render(Canvas canvas) {
    // Shadow
    final shadowPaint = Paint()
      ..color  = Colors.black26
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(
      Offset(radius + 2, radius + 2),
      radius,
      shadowPaint,
    );

    // Body
    final bodyPaint = Paint()..color = _pawnColor;
    canvas.drawCircle(Offset(radius, radius), radius, bodyPaint);

    // Highlight ring
    if (_isHighlighted) {
      final ringPaint = Paint()
        ..color       = Colors.white
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(Offset(radius, radius), radius - 1, ringPaint);

      // Pulse indicator
      final pulsePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.4);
      canvas.drawCircle(Offset(radius, radius), radius * 1.3, pulsePaint);
    }

    // White inner circle (classic Ludo pawn look)
    final innerPaint = Paint()..color = Colors.white.withValues(alpha: 0.4);
    canvas.drawCircle(Offset(radius, radius), radius * 0.45, innerPaint);
  }

  @override
  void onTapDown(TapDownEvent event) {
    event.handled = true;
    onTapped();
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    // Expand hit area so home-base pawns are easier to tap.
    return point.distanceTo(Vector2(radius, radius)) <= radius * 1.4;
  }
}