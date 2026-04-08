import '../models/technique.dart';
import '../models/tutorial_step.dart';

/// All tutorial steps with example boards and demonstrations.
final List<TutorialStep> allTutorialSteps = [
  // ============================================================
  // BEGINNER: 初级
  // ============================================================

  // 1. 宫唯一数 (Box Hidden Single)
  TutorialStep(
    type: TechniqueType.boxHiddenSingle,
    title: '宫唯一数',
    subtitle: '在宫中找到某数字唯一可放置的位置',
    description: '''【原理】
在一个 3×3 宫格中，某个数字只有一个空格可以放置时，该数字就是那个空格的答案。

【如何使用】
1. 选择一个 3×3 宫格
2. 选择一个数字（如 5）
3. 检查该宫中 5 可能出现在哪些空格
4. 如果只有一个空格可以放 5，那它就是答案

【棋盘说明】
绿色高亮的格子是目标格——在该宫中，数字只能放在此处。
黄色标注的是同宫的其他格子。
点击"下一步"将填入该数字。

【适用场景】
最常用的初级技巧，适用于所有难度的题目。''',
    boardValues: [
      [5, 3, 0, 0, 7, 0, 0, 0, 0],
      [6, 0, 0, 1, 9, 5, 0, 0, 0],
      [0, 9, 8, 0, 0, 0, 0, 6, 0],
      [8, 0, 0, 0, 6, 0, 0, 0, 3],
      [4, 0, 0, 8, 0, 3, 0, 0, 1],
      [7, 0, 0, 0, 2, 0, 0, 0, 6],
      [0, 6, 0, 0, 0, 0, 2, 8, 0],
      [0, 0, 0, 4, 1, 9, 0, 0, 5],
      [0, 0, 0, 0, 8, 0, 0, 7, 9],
    ],
    boardCandidates: _emptyCandsPlaceholder(),
    demonstration: TechniqueResult(
      type: TechniqueType.boxHiddenSingle,
      description: '在第1行第1列宫中，数字 4 只能放在 R2C2，因此该格填入 4',
      highlightCells: [CellPosition(1, 1)],
      relatedCells: [
        CellPosition(0, 0), CellPosition(0, 1), CellPosition(0, 2),
        CellPosition(1, 0), CellPosition(1, 2),
        CellPosition(2, 0), CellPosition(2, 1), CellPosition(2, 2),
      ],
      placements: {CellPosition(1, 1): 4},
      targetNumber: 4,
    ),
  ),

  // 2. 行唯一数 (Row Hidden Single)
  TutorialStep(
    type: TechniqueType.rowHiddenSingle,
    title: '行唯一数',
    subtitle: '在行中找到某数字唯一可放置的位置',
    description: '''【原理】
在一行中，某个数字只有一个空格可以放置时，该数字就是那个空格的答案。

【如何使用】
1. 选择一行
2. 选择一个数字
3. 检查该行中该数字可能出现在哪些空格
4. 如果只有一个空格可以放，那它就是答案

【棋盘说明】
绿色高亮的格子是目标格——在该行中，数字只能放在此处。
黄色标注的是同行的其他格子。

【适用场景】
配合宫唯一数使用，是初级解题的基础技巧。''',
    boardValues: [
      [0, 0, 3, 0, 2, 0, 6, 0, 0],
      [9, 0, 0, 3, 0, 5, 0, 0, 1],
      [0, 0, 1, 8, 0, 6, 4, 0, 0],
      [0, 0, 8, 1, 0, 2, 9, 0, 0],
      [7, 0, 0, 0, 0, 0, 0, 0, 8],
      [0, 0, 6, 7, 0, 8, 2, 0, 0],
      [0, 0, 2, 6, 0, 9, 5, 0, 0],
      [8, 0, 0, 2, 0, 3, 0, 0, 9],
      [0, 0, 5, 0, 1, 0, 3, 0, 0],
    ],
    boardCandidates: _emptyCandsPlaceholder(),
    demonstration: TechniqueResult(
      type: TechniqueType.rowHiddenSingle,
      description: '在第5行中，数字 5 只能放在 R5C5，因此该格填入 5',
      highlightCells: [CellPosition(4, 4)],
      relatedCells: [
        CellPosition(4, 0), CellPosition(4, 1), CellPosition(4, 2),
        CellPosition(4, 3), CellPosition(4, 5),
        CellPosition(4, 6), CellPosition(4, 7), CellPosition(4, 8),
      ],
      placements: {CellPosition(4, 4): 5},
      targetNumber: 5,
    ),
  ),

  // 3. 列唯一数 (Column Hidden Single)
  TutorialStep(
    type: TechniqueType.colHiddenSingle,
    title: '列唯一数',
    subtitle: '在列中找到某数字唯一可放置的位置',
    description: '''【原理】
在一列中，某个数字只有一个空格可以放置时，该数字就是那个空格的答案。

【如何使用】
1. 选择一列
2. 选择一个数字
3. 检查该列中该数字可能出现在哪些空格
4. 如果只有一个空格可以放，那它就是答案

【棋盘说明】
绿色高亮的格子是目标格——在该列中，数字只能放在此处。

【适用场景】
与行唯一数类似，是初级解题的基础技巧。''',
    boardValues: [
      [0, 0, 0, 2, 6, 0, 7, 0, 1],
      [6, 8, 0, 0, 7, 0, 0, 9, 0],
      [1, 9, 0, 0, 0, 4, 5, 0, 0],
      [8, 2, 0, 1, 0, 0, 0, 4, 0],
      [0, 0, 4, 6, 0, 2, 9, 0, 0],
      [0, 5, 0, 0, 0, 3, 0, 2, 8],
      [0, 0, 9, 3, 0, 0, 0, 7, 4],
      [0, 4, 0, 0, 5, 0, 0, 3, 6],
      [7, 0, 3, 0, 1, 8, 0, 0, 0],
    ],
    boardCandidates: _emptyCandsPlaceholder(),
    demonstration: TechniqueResult(
      type: TechniqueType.colHiddenSingle,
      description: '在第6列中，数字 6 只能放在 R4C6，因此该格填入 6',
      highlightCells: [CellPosition(3, 5)],
      relatedCells: [
        CellPosition(0, 5), CellPosition(1, 5), CellPosition(2, 5),
        CellPosition(4, 5), CellPosition(5, 5),
        CellPosition(6, 5), CellPosition(7, 5), CellPosition(8, 5),
      ],
      placements: {CellPosition(3, 5): 6},
      targetNumber: 6,
    ),
  ),

  // 4. 宫摒除法 (Box Elimination / Pointing)
  TutorialStep(
    type: TechniqueType.boxElimination,
    title: '宫摒除法',
    subtitle: '宫内候选数对齐，排除行/列其他位置',
    description: '''【原理】
当某个数字在某宫中只出现在同一行或同一列时，该数字可以从该行/列的其他宫的格中排除。

【如何使用】
1. 在某宫中，检查某数字的候选位置
2. 如果所有候选位置都在同一行（或同一列）
3. 则该数字必定在这些位置之一
4. 从该行（或列）的其他宫中删除该数字

【棋盘说明】
绿色高亮的格子是该宫中该数字的候选位置（都在同一行/列）。
黄色标注的是将被删除候选数的格子。
点击"下一步"将删除这些候选数。

【适用场景】
困难难度的重要技巧，能有效减少候选数。''',
    boardValues: [
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 1, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [1, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
    ],
    boardCandidates: _emptyCandsPlaceholder(),
    demonstration: TechniqueResult(
      type: TechniqueType.boxElimination,
      description: '在第1行第1列宫中，数字 1 只出现在第1行，因此可以从第1行的其他宫中删除 1',
      highlightCells: [CellPosition(0, 0), CellPosition(0, 1)],
      relatedCells: [CellPosition(0, 3), CellPosition(0, 4), CellPosition(0, 5)],
      eliminateCandidates: {
        CellPosition(0, 3): {1},
        CellPosition(0, 4): {1},
        CellPosition(0, 5): {1},
      },
      targetNumber: 1,
    ),
  ),

  // 5. 行摒除法 (Row Elimination / Claiming)
  TutorialStep(
    type: TechniqueType.rowElimination,
    title: '行摒除法',
    subtitle: '行内候选数局限于一宫，排除该宫其他行',
    description: '''【原理】
当某个数字在某行中，只出现在同一宫内的格中时，该数字可以从该宫的其他格中排除。

【与宫摒除法的关系】
- 宫摒除法：宫 → 行/列（宫内对齐，排除行/列其他宫）
- 行摒除法：行 → 宫（行内局限于一宫，排除该宫其他行）

【如何使用】
1. 在某行中，检查某数字的候选位置
2. 如果所有候选位置都在同一宫内
3. 从该宫的其他行的格中删除该数字

【棋盘说明】
绿色高亮的格子是该行中该数字的候选位置（都在同一宫内）。
黄色标注的是该宫中将被删除候选数的格子。

【适用场景】
与宫摒除法互补，困难难度的重要技巧。''',
    boardValues: [
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [5, 0, 0, 0, 0, 0, 5, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
    ],
    boardCandidates: _emptyCandsPlaceholder(),
    demonstration: TechniqueResult(
      type: TechniqueType.rowElimination,
      description: '在第5行中，数字 5 只出现在第3宫内，因此可以从该宫的其他行中删除 5',
      highlightCells: [CellPosition(4, 0), CellPosition(4, 6)],
      relatedCells: [CellPosition(3, 6), CellPosition(3, 7), CellPosition(5, 7)],
      eliminateCandidates: {
        CellPosition(3, 6): {5},
        CellPosition(3, 7): {5},
        CellPosition(5, 7): {5},
      },
      targetNumber: 5,
    ),
  ),

  // 6. 列摒除法 (Column Elimination)
  TutorialStep(
    type: TechniqueType.colElimination,
    title: '列摒除法',
    subtitle: '列内候选数局限于一宫，排除该宫其他列',
    description: '''【原理】
当某个数字在某列中，只出现在同一宫内的格中时，该数字可以从该宫的其他格中排除。

【如何使用】
1. 在某列中，检查某数字的候选位置
2. 如果所有候选位置都在同一宫内
3. 从该宫的其他列的格中删除该数字

【棋盘说明】
绿色高亮的格子是该列中该数字的候选位置（都在同一宫内）。
黄色标注的是该宫中将被删除候选数的格子。

【适用场景】
与行摒除法类似，是中级解题的重要技巧。''',
    boardValues: [
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
    ],
    boardCandidates: _emptyCandsPlaceholder(),
    demonstration: TechniqueResult(
      type: TechniqueType.colElimination,
      description: '在第1列中，数字 3 只出现在第1宫内，因此可以从该宫的其他列中删除 3',
      highlightCells: [CellPosition(0, 0), CellPosition(1, 0)],
      relatedCells: [CellPosition(0, 1), CellPosition(1, 2)],
      eliminateCandidates: {
        CellPosition(0, 1): {3},
        CellPosition(1, 2): {3},
      },
      targetNumber: 3,
    ),
  ),

  // ============================================================
  // INTERMEDIATE: 中级
  // ============================================================

  // 7. 唯一余数 (Naked Single)
  TutorialStep(
    type: TechniqueType.nakedSingle,
    title: '唯一余数',
    subtitle: '当一格只剩一个候选数',
    description: '''【原理】
当一个空格的候选数只剩一个时，该候选数就是该格的答案。这是因为同行、同列、同宫中的其他数字都已排除。

【如何使用】
1. 选择一个空格
2. 检查同行、同列、同宫已有哪些数字
3. 将 1-9 中未出现的数字列出
4. 如果只剩 1 个候选数，那就是答案

【与宫/行/列唯一数的区别】
- 唯一余数：某格只有一个候选数（从格出发）
- 宫/行/列唯一数：某数字在行/列/宫中只有一个位置（从数字出发）

【适用场景】
最常用的技巧之一，几乎每一步都会用到。''',
    boardValues: [
      [5, 3, 0, 0, 7, 0, 0, 0, 0],
      [6, 0, 0, 1, 9, 5, 0, 0, 0],
      [0, 9, 8, 0, 0, 0, 0, 6, 0],
      [8, 0, 0, 0, 6, 0, 0, 0, 3],
      [4, 0, 0, 8, 0, 3, 0, 0, 1],
      [7, 0, 0, 0, 2, 0, 0, 0, 6],
      [0, 6, 0, 0, 0, 0, 2, 8, 0],
      [0, 0, 0, 4, 1, 9, 0, 0, 5],
      [0, 0, 0, 0, 8, 0, 0, 7, 9],
    ],
    boardCandidates: _emptyCandsPlaceholder(),
    demonstration: TechniqueResult(
      type: TechniqueType.nakedSingle,
      description: 'R1C3 的候选数只剩 4，因此该格填入 4',
      highlightCells: [CellPosition(0, 2)],
      placements: {CellPosition(0, 2): 4},
      targetNumber: 4,
    ),
  ),

  // 8. 宫对行列区块摒除法（显性）
  TutorialStep(
    type: TechniqueType.explicitBoxLineReduction,
    title: '宫对行列区块摒除法（显性）',
    subtitle: '宫内指向对/指向三，排除行/列候选数',
    description: '''【原理】
当某数字在某宫中的候选位置恰好是 2 个或 3 个，且都在同一行或同一列时，称为"指向对"或"指向三"。这意味着该数字必定在这些位置之一，因此可以从该行/列的其他宫中排除。

【如何使用】
1. 在某宫中，找到某数字只有 2-3 个候选位置
2. 检查这些位置是否都在同一行或同一列
3. 如果是，从该行/列的其他宫中删除该候选数

【适用场景】
中级解题的核心技巧，能有效缩小候选范围。''',
    boardValues: [
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
    ],
    boardCandidates: _emptyCandsPlaceholder(),
    demonstration: TechniqueResult(
      type: TechniqueType.explicitBoxLineReduction,
      description: '在第1宫中，数字 7 的 2 个候选位置都在第1行，形成显性区块摒除，可从该行其他位置删除 7',
      highlightCells: [CellPosition(0, 0), CellPosition(0, 2)],
      relatedCells: [CellPosition(0, 4), CellPosition(0, 7)],
      eliminateCandidates: {
        CellPosition(0, 4): {7},
        CellPosition(0, 7): {7},
      },
      targetNumber: 7,
    ),
  ),

  // 9. 直观2数对 (Naked Pair)
  TutorialStep(
    type: TechniqueType.nakedPair,
    title: '直观2数对',
    subtitle: '两格相同两候选，排除同组其他格',
    description: '''【原理】
当同一行/列/宫中有两个空格，它们的候选数完全相同且都只有两个数字时，这两个数字必定分布在这两个格中，可以从同组其他格中排除。

【如何使用】
1. 在某行/列/宫中，找到两个候选数相同的空格（如都是 {3,7}）
2. 从该行/列/宫的其他空格中删除这两个数字
3. 删除后可能产生新的唯一候选数

【适用场景】
困难及以上难度常用。常与隐性单数配合使用。''',
    boardValues: [
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
    ],
    boardCandidates: _emptyCandsPlaceholder(),
    demonstration: TechniqueResult(
      type: TechniqueType.nakedPair,
      description: 'R1C1 和 R1C4 形成数对 {3,7}，可从同行其他格中删除这些数字',
      highlightCells: [CellPosition(0, 0), CellPosition(0, 3)],
      relatedCells: [CellPosition(0, 5), CellPosition(0, 7)],
      eliminateCandidates: {
        CellPosition(0, 5): {3, 7},
        CellPosition(0, 7): {3},
      },
    ),
  ),

  // 10. 宫对行列区块摒除法（隐性）
  TutorialStep(
    type: TechniqueType.hiddenBoxLineReduction,
    title: '宫对行列区块摒除法（隐性）',
    subtitle: '宫内数字的隐性区块对齐排除',
    description: '''【原理】
与显性区块摒除法类似，但这里的候选格有更多候选数字（不仅仅是目标数字）。当某数字在宫中的候选位置都在同一行/列时，即使这些格有其他候选数，仍然可以从该行/列的其他宫中排除该数字。

【与显性的区别】
- 显性：候选格中只有少数候选数，容易发现
- 隐性：候选格中有较多候选数，需要专门检查某个数字的分布

【适用场景】
中级难度的重要进阶技巧。''',
    boardValues: [
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
    ],
    boardCandidates: _emptyCandsPlaceholder(),
    demonstration: TechniqueResult(
      type: TechniqueType.hiddenBoxLineReduction,
      description: '在第1宫中，数字 8 的候选位置都在第2行（隐性区块摒除），可从该行其他位置删除 8',
      highlightCells: [CellPosition(1, 0), CellPosition(1, 1)],
      relatedCells: [CellPosition(1, 4), CellPosition(1, 6)],
      eliminateCandidates: {
        CellPosition(1, 4): {8},
        CellPosition(1, 6): {8},
      },
      targetNumber: 8,
    ),
  ),

  // 11. 行列对宫区块摒除法（隐性）
  TutorialStep(
    type: TechniqueType.lineBoxClaiming,
    title: '行列对宫区块摒除法（隐性）',
    subtitle: '行/列中候选数局限于一宫时排除',
    description: '''【原理】
当某个数字在某行/列中，只出现在同一宫内的格中时，该数字可以从该宫的其他格中排除。

【与宫摒除法的关系】
- 宫摒除法：从宫出发，影响行/列
- 行列区块摒除法：从行/列出发，影响宫

两者方向相反但互补。

【适用场景】
中级到高级难度常用的技巧。''',
    boardValues: [
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
    ],
    boardCandidates: _emptyCandsPlaceholder(),
    demonstration: TechniqueResult(
      type: TechniqueType.lineBoxClaiming,
      description: '第3行中，数字 6 只出现在第2宫内（行列区块摒除），可从该宫其他行中删除 6',
      highlightCells: [CellPosition(2, 3), CellPosition(2, 4)],
      relatedCells: [CellPosition(0, 3), CellPosition(1, 5)],
      eliminateCandidates: {
        CellPosition(0, 3): {6},
        CellPosition(1, 5): {6},
      },
      targetNumber: 6,
    ),
  ),

  // ============================================================
  // ADVANCED: 高级
  // ============================================================

  // 12. 直观3数对 (Naked Triple)
  _makeTutorialStep(
    TechniqueType.nakedTriple,
    '直观3数对',
    '三格共享三个候选数',
    '''【原理】
当同一行/列/宫中有三个空格，它们的候选数的并集恰好是三个数字时，这三个数字可以从同组其他格中排除。

【注意】
三个格不需要每个都包含全部三个候选数。例如：
格 A: {1,2}，格 B: {2,3}，格 C: {1,3}
并集为 {1,2,3}，满足三数组条件。

【适用场景】
专家难度开始需要使用。是数对的扩展形式。''',
  ),

  // 13. X-Wing
  _makeTutorialStep(
    TechniqueType.xWing,
    'X-Wing',
    '两行两列交叉排除',
    '''【原理】
当某个数字在两行中各只出现在相同的两列时，该数字可以从这两列的其他行中排除。

【形象理解】
想象一个矩形的四个角，数字必定在对角线的两组之一。
无论哪种情况，这两列的其他行都不可能有该数字。

【如何使用】
1. 选择一个数字
2. 找两行，该数字都恰好只出现在相同的两列
3. 从这两列的其他行中删除该数字

【适用场景】
高级难度的关键技巧。棋盘上会画出交叉线标示 X 形结构。''',
  ),

  // 14. 隐性2数对 (Hidden Pair)
  _makeTutorialStep(
    TechniqueType.hiddenPair,
    '隐性2数对',
    '两个数字只出现在两格中',
    '''【原理】
当某行/列/宫中，有两个数字只出现在相同的两个空格中时，这两个空格的其他候选数可以被删除。

【与显性数对的区别】
- 显性数对：两格候选数完全相同（如都是 {3,7}）
- 隐性数对：两个数字只出现在两格中，但这两格可能还有其他候选数

【适用场景】
高级难度的重要技巧。通过精简候选数为后续解题创造条件。''',
  ),

  // 15. 显性3数对 (Explicit Naked Triple)
  _makeTutorialStep(
    TechniqueType.explicitNakedTriple,
    '显性3数对',
    '三格候选数完全一致的三数组',
    '''【原理】
显性三数组是直观三数组的特殊情况：三个格的候选数完全相同，都是同样的三个数字。

【与直观3数对的区别】
- 直观3数对：三格候选数的并集为3个数字（每格可以是2或3个）
- 显性3数对：三格的候选数完全一致，都是{A,B,C}

【适用场景】
高级难度。比直观三数组更容易发现，但出现频率较低。''',
  ),

  // 16. 隐性3数对 (Hidden Triple)
  _makeTutorialStep(
    TechniqueType.hiddenTriple,
    '隐性3数对',
    '三个数字只出现在三格中',
    '''【原理】
当某行/列/宫中，有三个数字只出现在相同的三个空格中时，这三个空格的其他候选数可以被删除。

【如何识别】
1. 统计每个数字在该组中的候选位置
2. 找三个数字，它们的候选位置的并集恰好是三个格
3. 将这三格的候选数精简为这三个数字

【适用场景】
高级难度。隐性数组比显性数组更难发现。''',
  ),

  // 17. Swordfish (剑鱼)
  _makeTutorialStep(
    TechniqueType.swordfish,
    'Swordfish / 剑鱼',
    'X-Wing的三行三列扩展',
    '''【原理】
X-Wing 的扩展版。当某个数字在三行中，候选列的并集恰好为三列时，该数字可以从这三列的其他行中排除。

【如何使用】
1. 选择一个数字
2. 找三行，该数字候选位置的列号并集恰好是 3 列
3. 从这三列的其他行中删除该数字

【适用场景】
高级到专家难度。比 X-Wing 更难发现，但原理相同。''',
  ),

  // 18. Skyscraper (摩天楼)
  _makeTutorialStep(
    TechniqueType.skyscraper,
    'Skyscraper / 摩天楼',
    '两行共享一列的双强链结构',
    '''【原理】
当某数字在两行中各只有2个候选位置，且这两行共享一个列位置（"底座"）时，另外两个不共享的位置（"塔顶"）可以产生排除效果。

【结构】
两行形成两条竖直的"柱子"，底部连接（共享列），顶部伸出。
能同时看到两个"塔顶"的格可以排除该数字。

【适用场景】
高级难度。是强链技巧的入门形式。''',
  ),

  // 19. XY-Wing
  _makeTutorialStep(
    TechniqueType.xyWing,
    'XY-Wing / XY翼',
    '三格三数的翼型排除',
    '''【原理】
当三个格形成特定的"翼"形结构时，可以排除特定候选数。

【结构要求】
- 中心格（pivot）有候选数 {A,B}
- 翼格1 与中心同行/列/宫，候选数 {A,C}
- 翼格2 与中心同行/列/宫，候选数 {B,C}

【排除规则】
同时能看到翼格1和翼格2的格，可以排除候选数 C。
因为无论中心格是 A 还是 B，都会导致某个翼格为 C。

【适用场景】
高级难度。需要综合分析多个格之间的关系。''',
  ),

  // 20. Strong Links 2数组
  _makeTutorialStep(
    TechniqueType.strongLinks2,
    'Strong Links / 强链2数组',
    '利用行列共轭对的交叉排除',
    '''【原理】
当某数字在一行中恰好只有2个候选位置，同时在一列中也恰好只有2个候选位置，且它们共享一个格时，可以产生排除效果。

【结构】
- 行中的两个位置形成一条强链
- 列中的两个位置形成另一条强链
- 两条强链共享一个端点
- 两条强链的另外两个端点不共享的那个格可被排除

【适用场景】
高级难度。也被称为"2-String Kite"。''',
  ),

  // 21. XYZ-Wing
  _makeTutorialStep(
    TechniqueType.xyzWing,
    'XYZ-Wing / XYZ翼',
    'XY-Wing的扩展，中心格有三候选数',
    '''【原理】
XY-Wing的扩展。中心格有三个候选数 {X,Y,Z}，两翼各有两个候选数，分别是 {X,Z} 和 {Y,Z}。

【排除规则】
能同时看到中心格和两个翼格的位置，可以排除候选数 Z。

【与XY-Wing的区别】
- XY-Wing：中心2个候选数，翼各2个，共涉及3个数字
- XYZ-Wing：中心3个候选数，翼各2个，共涉及3个数字

【适用场景】
高级难度。由于需要看到所有三格，排除范围通常较小。''',
  ),

  // ============================================================
  // EXPERT: 进阶
  // ============================================================

  // 22. Strong Links 3数组
  _makeTutorialStep(
    TechniqueType.strongLinks3,
    'Strong Links / 强链3数组',
    '利用共轭对着色推理',
    '''【原理】
通过给某数字的共轭对交替着色（如蓝/红），可以推导出矛盾来排除候选数。

【着色规则】
1. 选择一个数字，找出所有共轭对（在行/列/宫中只有2个候选位置）
2. 用两种颜色交替标记
3. 规则1：如果两个同色格在同一组 → 该色全为假
4. 规则2：某格能同时看到两种颜色 → 该格的该数字可排除

【适用场景】
进阶难度。是理解更复杂链式技巧的基础。''',
  ),

  // 23. BUG1
  _makeTutorialStep(
    TechniqueType.bug1,
    'BUG1 / 二向值坟墓1',
    '所有格二值时的唯一三值格',
    '''【原理】
BUG (Bivalue Universal Grave) 状态：如果一个数独盘面除了一个格以外，所有未解格都恰好只有2个候选数，那么那个有3个候选数的格的值可以确定。

【判断方法】
找到唯一的三值格后，看哪个候选数在其所在行/列/宫中出现奇数次，该数字就是答案。

【适用场景】
进阶难度。出现频率不高但一旦出现就能直接确定一个数字。''',
  ),

  // 24. BUG2
  _makeTutorialStep(
    TechniqueType.bug2,
    'BUG2 / 二向值坟墓2',
    '两个三值格的BUG扩展',
    '''【原理】
BUG+2 变体：所有未解格都是二值格，除了两个三值格。如果这两个三值格共享一个"多余"数字且在同一组中，则可以从能看到两格的位置删除该数字。

【适用场景】
进阶难度。是BUG1的扩展形式。''',
  ),

  // 25. VWXYZ-Wing
  _makeTutorialStep(
    TechniqueType.vwxyzWing,
    'VWXYZ-Wing',
    '五格五数的大型翼排除',
    '''【原理】
XY-Wing家族的扩展，涉及5个格和5个不同数字。中心格有4-5个候选数，配合4个二值翼格形成结构。

【排除规则】
所有组成格共同可见的位置，可以排除它们共有的候选数。

【适用场景】
进阶难度。大型翼结构较难发现，但排除效果显著。''',
  ),

  // 26. UVWXYZ-Wing
  _makeTutorialStep(
    TechniqueType.uvwxyzWing,
    'UVWXYZ-Wing',
    '六格六数的超大型翼排除',
    '''【原理】
翼家族中最大的形式，涉及6个格和6个不同数字。

【适用场景】
进阶难度。极少出现，但是完整翼技巧体系的一部分。''',
  ),

  // ============================================================
  // CHAINS: 链
  // ============================================================

  // 27. 双向X链
  _makeTutorialStep(
    TechniqueType.biDirectionalXCycle,
    '双向X链',
    '单数字交替强弱链形成循环',
    '''【原理】
对于某个数字，通过交替使用强链接和弱链接形成循环。

【链的类型】
- Type 1（不连续强链环）：强链两端汇合 → 汇合点必为该数字
- Type 2（不连续弱链环）：弱链两端汇合 → 汇合点排除该数字

【基本概念】
- 强链接：同组中该数字只有2个候选位置
- 弱链接：两个候选位置在同组中（但不一定只有2个）

【适用场景】
链式推理的入门技巧。掌握后可进阶到更复杂的链。''',
  ),

  // 28. 双向链
  _makeTutorialStep(
    TechniqueType.biDirectionalCycle,
    '双向链',
    '多数字交替推理链',
    '''【原理】
AIC（Alternating Inference Chain）是通用的链式推理方法，可以跨越不同数字。

【链接方式】
- 强链接：A假→B真（同组中只有两个候选位置）
- 弱链接：A真→B假（同格不同候选数，或同组互斥）
- 内部链接：同一格内两个候选数之间的推理

【排除规则】
链的两端如果推导出同一个数字的两个位置，能看到两端的格可排除该数字。

【适用场景】
最高级的通用解题框架。X-Wing、Swordfish、XY-Wing 都是 AIC 的特殊形式。''',
  ),

  // 29. 单元格强制链组
  _makeTutorialStep(
    TechniqueType.cellForcingChain,
    '单元格强制链组',
    '假设推理，无论候选数取何值都成立',
    '''【原理】
从一个有2-3个候选数的格出发，分别假设每个候选数为真，追踪推理链。如果所有假设都得出相同的结论，则该结论成立。

【如何使用】
1. 找一个有少量候选数的格（2-3个）
2. 分别假设每个候选数为真
3. 沿着唯一候选数等规则推理
4. 如果所有路径得出相同结论（某格=某值，或某格排除某值），结论确定

【适用场景】
深度推理技巧。需要较强的逻辑推理能力。''',
  ),

  // 30. 区域强制链组
  _makeTutorialStep(
    TechniqueType.regionForcingChain,
    '区域强制链组',
    '从区域中数字的所有位置推理',
    '''【原理】
对于某个数字在某组（行/列/宫）的所有候选位置，分别假设该数字在每个位置，追踪推理链。如果所有假设都得出相同结论，则该结论成立。

【与单元格强制链的区别】
- 单元格强制链：从一格的不同候选数出发
- 区域强制链：从一组中某数字的不同位置出发

【适用场景】
最高级的推理技巧之一。通常作为最后的手段使用。''',
  ),
];

/// Grouped tutorials by category.
Map<TechniqueCategory, List<TutorialStep>> get tutorialsByCategory {
  final map = <TechniqueCategory, List<TutorialStep>>{};
  for (final step in allTutorialSteps) {
    map.putIfAbsent(step.type.category, () => []).add(step);
  }
  return map;
}

TutorialStep _makeTutorialStep(
  TechniqueType type,
  String title,
  String subtitle,
  String description,
) {
  return TutorialStep(
    type: type,
    title: title,
    subtitle: subtitle,
    description: description,
    boardValues: List.generate(9, (_) => List.generate(9, (_) => 0)),
    boardCandidates: _emptyCandsPlaceholder(),
    demonstration: TechniqueResult(
      type: type,
      description: '$title 的演示示例',
      highlightCells: const [],
    ),
  );
}

List<List<Set<int>>> _emptyCandsPlaceholder() {
  return List.generate(9, (_) => List.generate(9, (_) => <int>{}));
}
