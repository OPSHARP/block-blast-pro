// Piece tray containing 3 block slots with drag handlers and physics badges

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../domain/models/block_model.dart';
import '../../domain/models/block_weight.dart';
import '../../domain/models/special_block_type.dart';
import '../../core/theme/game_theme.dart';
import 'piece_widget.dart';

class PieceTrayWidget extends StatelessWidget {
  final List<BlockModel?> pieces;
  final GameTheme theme;
  final int? draggingIndex;
  final Function(int index, Offset globalPos, bool isDirectCursor) onDragStart;
  final Function(Offset globalPos, bool isDirectCursor) onDragUpdate;
  final VoidCallback onDragEnd;
  final Function(int slotIndex)? onRotatePiece;

  const PieceTrayWidget({
    super.key,
    required this.pieces,
    required this.theme,
    required this.draggingIndex,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    this.onRotatePiece,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.boardBackground.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.boardBorder.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (int i = 0; i < 3; i++)
            Expanded(
              child: _buildSlot(context, i),
            ),
        ],
      ),
    );
  }

  Widget _buildSlot(BuildContext context, int slotIndex) {
    if (slotIndex >= pieces.length) return const SizedBox.shrink();
    final piece = pieces[slotIndex];

    if (piece == null) {
      return Center(
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.cellEmpty.withValues(alpha: 0.15),
          ),
        ),
      );
    }

    final isBeingDragged = draggingIndex == slotIndex;

    return Stack(
      alignment: Alignment.center,
      children: [
        Listener(
          onPointerDown: (event) {
            final isDirect = event.kind == PointerDeviceKind.mouse ||
                event.kind == PointerDeviceKind.trackpad;
            onDragStart(slotIndex, event.position, isDirect);
          },
          onPointerMove: (event) {
            final isDirect = event.kind == PointerDeviceKind.mouse ||
                event.kind == PointerDeviceKind.trackpad;
            onDragUpdate(event.position, isDirect);
          },
          onPointerUp: (_) {
            onDragEnd();
          },
          onPointerCancel: (_) {
            onDragEnd();
          },
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: isBeingDragged ? 0.25 : 1.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: PieceWidget(
                        block: piece,
                        cellSize: 24.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                _buildBadge(piece),
              ],
            ),
          ),
        ),
        if (!isBeingDragged && onRotatePiece != null)
          Positioned(
            top: 2,
            right: 4,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onRotatePiece!(slotIndex),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.accent.withValues(alpha: 0.6),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.rotate_right,
                  size: 13,
                  color: theme.accent,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBadge(BlockModel piece) {
    String label = '';
    Color badgeColor = Colors.transparent;

    if (piece.specialType != SpecialBlockType.none) {
      label = piece.specialType.displayName.split(' ').first.toUpperCase();
      badgeColor = theme.accent;
    } else if (piece.weightClass != BlockWeightClass.normal) {
      label = piece.weightClass.name.toUpperCase();
      badgeColor = piece.weightClass == BlockWeightClass.ultra
          ? const Color(0xFFEF4444)
          : piece.weightClass == BlockWeightClass.heavy
              ? const Color(0xFFF59E0B)
              : const Color(0xFF06B6D4);
    }

    if (label.isEmpty) {
      return const SizedBox(height: 12);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          color: badgeColor,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
