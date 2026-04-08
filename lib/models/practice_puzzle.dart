import 'technique.dart';

/// A practice puzzle for a specific technique.
class PracticePuzzle {
  /// 9x9 board values (0 = empty).
  final List<List<int>> puzzle;

  /// The complete solution.
  final List<List<int>> solution;

  /// Pre-computed candidates for the puzzle state.
  final List<List<Set<int>>> candidates;

  /// The expected technique application the user should find.
  final TechniqueResult expectedStep;

  const PracticePuzzle({
    required this.puzzle,
    required this.solution,
    required this.candidates,
    required this.expectedStep,
  });
}
