enum Difficulty {
  easy(name: '简单', clues: 36, minScore: 0, maxScore: 400),
  medium(name: '中级', clues: 30, minScore: 300, maxScore: 600),
  hard(name: '困难', clues: 25, minScore: 500, maxScore: 800),
  expert(name: '专家', clues: 22, minScore: 700, maxScore: 1000),
  extreme(name: '极端', clues: 17, minScore: 900, maxScore: 1200),
  abyss(name: '深渊', clues: 17, minScore: 1500, maxScore: 9999);

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
