enum Difficulty {
  easy(name: '简单', clues: 35),
  medium(name: '中级', clues: 28),
  hard(name: '困难', clues: 22),
  expert(name: '专家', clues: 20),
  extreme(name: '极端', clues: 18),
  abyss(name: '深渊', clues: 17);

  const Difficulty({required this.name, required this.clues});

  final String name;
  final int clues;
}
