import '../models/sudoku_board.dart';
import '../models/technique.dart';
import 'technique_finder.dart';

/// Service that provides smart hints during gameplay.
/// Finds the simplest applicable technique on the current board.
class HintService {
  /// Get a hint for the current board state.
  /// Returns a [TechniqueResult] describing the next step, or null if no
  /// technique could be found (would need brute-force).
  static TechniqueResult? getHint(SudokuBoard board) {
    final grid = board.toValues();
    final candidates = TechniqueFinder.computeAllCandidates(grid);
    return TechniqueFinder.findNext(grid, candidates);
  }

  /// Get a hint using provided candidates (e.g., user's notes).
  static TechniqueResult? getHintWithCandidates(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    return TechniqueFinder.findNext(grid, candidates);
  }
}
