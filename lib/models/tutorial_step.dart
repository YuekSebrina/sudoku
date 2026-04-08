import 'technique.dart';

/// A single tutorial lesson for a technique, containing a board example and
/// a demonstration of the technique in action.
class TutorialStep {
  final TechniqueType type;
  final String title;
  final String subtitle;
  final String description;

  /// 9x9 board values (0 = empty).
  final List<List<int>> boardValues;

  /// Pre-computed candidates for each cell.
  /// Outer list is rows, inner list is cols, each entry is the set of candidates.
  final List<List<Set<int>>> boardCandidates;

  /// The technique result that should be demonstrated on this board.
  final TechniqueResult demonstration;

  const TutorialStep({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.boardValues,
    required this.boardCandidates,
    required this.demonstration,
  });
}
