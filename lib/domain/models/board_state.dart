// Authoritative Board State for Block Blast Pro

import 'cell_model.dart';
import '../../core/constants/game_constants.dart';

class BoardState {
  final int gridSize;
  final List<List<CellModel>> cells;

  BoardState({
    this.gridSize = GameConstants.defaultGridSize,
    List<List<CellModel>>? cells,
  }) : cells = cells ??
            List.generate(
              gridSize,
              (y) => List.generate(
                gridSize,
                (x) => CellModel(x: x, y: y),
              ),
            );

  bool isValidCoord(int x, int y) {
    return x >= 0 && x < gridSize && y >= 0 && y < gridSize;
  }

  CellModel getCell(int x, int y) {
    if (!isValidCoord(x, y)) {
      throw RangeError('Coordinate ($x, $y) out of board bounds ($gridSize x $gridSize)');
    }
    return cells[y][x];
  }

  bool isOccupied(int x, int y) {
    if (!isValidCoord(x, y)) return true; // Bounds count as occupied/blocked
    return cells[y][x].isOccupied;
  }

  int get occupiedCount {
    int count = 0;
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (cells[y][x].isOccupied) count++;
      }
    }
    return count;
  }

  double get density => occupiedCount / (gridSize * gridSize);

  BoardState copyWith({
    int? gridSize,
    List<List<CellModel>>? cells,
  }) {
    return BoardState(
      gridSize: gridSize ?? this.gridSize,
      cells: cells ??
          this.cells
              .map((row) => row.map((cell) => cell.copyWith()).toList())
              .toList(),
    );
  }

  BoardState withCellUpdated(CellModel newCell) {
    final newCells = cells
        .map((row) => row.map((cell) => cell.copyWith()).toList())
        .toList();
    newCells[newCell.y][newCell.x] = newCell;
    return BoardState(gridSize: gridSize, cells: newCells);
  }

  Map<String, dynamic> toMap() {
    return {
      'gridSize': gridSize,
      'cells': cells.map((row) => row.map((c) => c.toMap()).toList()).toList(),
    };
  }

  factory BoardState.fromMap(Map<String, dynamic> map) {
    final size = map['gridSize'] as int? ?? GameConstants.defaultGridSize;
    final rawCells = map['cells'] as List<dynamic>?;
    if (rawCells == null) {
      return BoardState(gridSize: size);
    }
    final parsedCells = rawCells.map((row) {
      return (row as List<dynamic>).map((cellMap) {
        return CellModel.fromMap(cellMap as Map<String, dynamic>);
      }).toList();
    }).toList();
    return BoardState(gridSize: size, cells: parsedCells);
  }
}
