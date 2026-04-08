enum Difficulty {
  easy(name: '简单', clues: 36, minScore: 0, maxScore: 250),
  medium(name: '中级', clues: 30, minScore: 200, maxScore: 500),
  hard(name: '困难', clues: 25, minScore: 400, maxScore: 700),
  expert(name: '专家', clues: 22, minScore: 500, maxScore: 9999),
  extreme(name: '极端', clues: 19, minScore: 700, maxScore: 9999),
  abyss(name: '深渊', clues: 17, minScore: 900, maxScore: 9999);

  const Difficulty({
    required this.name,
    required this.clues,
    required this.minScore,
    required this.maxScore,
  });

  final String name;
  final int clues;
  final int minScore;
  final int maxScore;
}
