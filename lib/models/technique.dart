/// Difficulty category for techniques.
enum TechniqueCategory {
  beginner('初级', '🟢', 0),
  intermediate('中级', '🔵', 1),
  advanced('高级', '🟠', 2),
  expert('进阶', '🔴', 3),
  chains('链', '⛓️', 4);

  final String label;
  final String icon;
  final int order;
  const TechniqueCategory(this.label, this.icon, this.order);
}

/// All 30 solving techniques, ordered by difficulty.
enum TechniqueType {
  // --- Beginner (初级) ---
  boxHiddenSingle(
    nameZh: '宫唯一数',
    nameEn: 'Box Hidden Single',
    category: TechniqueCategory.beginner,
    weight: 1,
  ),
  rowHiddenSingle(
    nameZh: '行唯一数',
    nameEn: 'Row Hidden Single',
    category: TechniqueCategory.beginner,
    weight: 2,
  ),
  colHiddenSingle(
    nameZh: '列唯一数',
    nameEn: 'Column Hidden Single',
    category: TechniqueCategory.beginner,
    weight: 3,
  ),
  boxElimination(
    nameZh: '宫摒除法',
    nameEn: 'Box Elimination',
    category: TechniqueCategory.beginner,
    weight: 4,
  ),
  rowElimination(
    nameZh: '行摒除法',
    nameEn: 'Row Elimination',
    category: TechniqueCategory.beginner,
    weight: 5,
  ),
  colElimination(
    nameZh: '列摒除法',
    nameEn: 'Column Elimination',
    category: TechniqueCategory.beginner,
    weight: 6,
  ),

  // --- Intermediate (中级) ---
  nakedSingle(
    nameZh: '唯一余数',
    nameEn: 'Naked Single',
    category: TechniqueCategory.intermediate,
    weight: 10,
  ),
  explicitBoxLineReduction(
    nameZh: '宫对行列区块摒除法（显性）',
    nameEn: 'Explicit Pointing',
    category: TechniqueCategory.intermediate,
    weight: 11,
  ),
  nakedPair(
    nameZh: '直观2数对',
    nameEn: 'Naked Pair',
    category: TechniqueCategory.intermediate,
    weight: 12,
  ),
  hiddenBoxLineReduction(
    nameZh: '宫对行列区块摒除法（隐性）',
    nameEn: 'Hidden Pointing',
    category: TechniqueCategory.intermediate,
    weight: 13,
  ),
  lineBoxClaiming(
    nameZh: '行列对宫区块摒除法（隐性）',
    nameEn: 'Claiming / Box-Line Reduction',
    category: TechniqueCategory.intermediate,
    weight: 14,
  ),

  // --- Advanced (高级) ---
  nakedTriple(
    nameZh: '直观3数对',
    nameEn: 'Naked Triple',
    category: TechniqueCategory.advanced,
    weight: 20,
  ),
  xWing(
    nameZh: 'X-Wing',
    nameEn: 'X-Wing',
    category: TechniqueCategory.advanced,
    weight: 21,
  ),
  hiddenPair(
    nameZh: '隐性2数对',
    nameEn: 'Hidden Pair',
    category: TechniqueCategory.advanced,
    weight: 22,
  ),
  explicitNakedTriple(
    nameZh: '显性3数对',
    nameEn: 'Explicit Naked Triple',
    category: TechniqueCategory.advanced,
    weight: 23,
  ),
  hiddenTriple(
    nameZh: '隐性3数对',
    nameEn: 'Hidden Triple',
    category: TechniqueCategory.advanced,
    weight: 24,
  ),
  swordfish(
    nameZh: 'Swordfish / 剑鱼',
    nameEn: 'Swordfish',
    category: TechniqueCategory.advanced,
    weight: 25,
  ),
  skyscraper(
    nameZh: 'Skyscraper / 摩天楼',
    nameEn: 'Skyscraper',
    category: TechniqueCategory.advanced,
    weight: 26,
  ),
  xyWing(
    nameZh: 'XY-Wing / XY翼',
    nameEn: 'XY-Wing',
    category: TechniqueCategory.advanced,
    weight: 27,
  ),
  strongLinks2(
    nameZh: 'Strong Links / 强链2数组',
    nameEn: 'Strong Links (2)',
    category: TechniqueCategory.advanced,
    weight: 28,
  ),
  xyzWing(
    nameZh: 'XYZ-Wing / XYZ翼',
    nameEn: 'XYZ-Wing',
    category: TechniqueCategory.advanced,
    weight: 29,
  ),

  // --- Expert (进阶) ---
  strongLinks3(
    nameZh: 'Strong Links / 强链3数组',
    nameEn: 'Strong Links (3)',
    category: TechniqueCategory.expert,
    weight: 30,
  ),
  bug1(
    nameZh: 'BUG1 / 二向值坟墓1',
    nameEn: 'BUG Type 1',
    category: TechniqueCategory.expert,
    weight: 31,
  ),
  bug2(
    nameZh: 'BUG2 / 二向值坟墓2',
    nameEn: 'BUG Type 2',
    category: TechniqueCategory.expert,
    weight: 32,
  ),
  vwxyzWing(
    nameZh: 'VWXYZ-Wing',
    nameEn: 'VWXYZ-Wing',
    category: TechniqueCategory.expert,
    weight: 33,
  ),
  uvwxyzWing(
    nameZh: 'UVWXYZ-Wing',
    nameEn: 'UVWXYZ-Wing',
    category: TechniqueCategory.expert,
    weight: 34,
  ),

  // --- Chains (链) ---
  biDirectionalXCycle(
    nameZh: '双向X链',
    nameEn: 'Bidirectional X-Cycle',
    category: TechniqueCategory.chains,
    weight: 40,
  ),
  biDirectionalCycle(
    nameZh: '双向链',
    nameEn: 'Bidirectional Cycle',
    category: TechniqueCategory.chains,
    weight: 41,
  ),
  cellForcingChain(
    nameZh: '单元格强制链组',
    nameEn: 'Cell Forcing Chains',
    category: TechniqueCategory.chains,
    weight: 42,
  ),
  regionForcingChain(
    nameZh: '区域强制链组',
    nameEn: 'Region Forcing Chains',
    category: TechniqueCategory.chains,
    weight: 43,
  );

  final String nameZh;
  final String nameEn;
  final TechniqueCategory category;
  final int weight;

  const TechniqueType({
    required this.nameZh,
    required this.nameEn,
    required this.category,
    required this.weight,
  });
}

/// A position on the 9x9 board.
class CellPosition {
  final int row;
  final int col;
  const CellPosition(this.row, this.col);

  int get boxIndex => (row ~/ 3) * 3 + (col ~/ 3);
  int get boxRow => (row ~/ 3) * 3;
  int get boxCol => (col ~/ 3) * 3;

  @override
  bool operator ==(Object other) =>
      other is CellPosition && other.row == row && other.col == col;

  @override
  int get hashCode => row * 9 + col;

  @override
  String toString() => '($row,$col)';
}

/// A line/arrow drawn between two cells for visualization.
/// When [digit] > 0, the line connects the specific candidate digit
/// positions within the cells (not cell centers).
class HighlightLine {
  final CellPosition from;
  final CellPosition to;
  final HighlightLineStyle style;

  /// The candidate digit this line connects. 0 = use cell center.
  final int digit;

  const HighlightLine(this.from, this.to, {this.style = HighlightLineStyle.solid, this.digit = 0});
}

enum HighlightLineStyle { solid, dashed, arrow }

/// The result of detecting a technique application on the board.
class TechniqueResult {
  /// Which technique was found.
  final TechniqueType type;

  /// Human-readable description of this specific finding.
  final String description;

  /// Cells that are the primary focus (e.g., the cell to fill).
  final List<CellPosition> highlightCells;

  /// Secondary cells involved (e.g., cells in the same row/col/box that cause elimination).
  final List<CellPosition> relatedCells;

  /// Candidates to remove: cell → set of digits to eliminate.
  final Map<CellPosition, Set<int>> eliminateCandidates;

  /// Digits to place: cell → digit.
  final Map<CellPosition, int> placements;

  /// Visual lines/arrows to draw.
  final List<HighlightLine> lines;

  /// The main digit involved (0 if not applicable).
  final int targetNumber;

  const TechniqueResult({
    required this.type,
    required this.description,
    this.highlightCells = const [],
    this.relatedCells = const [],
    this.eliminateCandidates = const {},
    this.placements = const {},
    this.lines = const [],
    this.targetNumber = 0,
  });
}
