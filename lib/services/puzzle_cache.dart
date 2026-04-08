import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/difficulty.dart';
import '../models/sudoku_board.dart';
import 'sudoku_generator.dart';

class CachedPuzzle {
  final List<List<int>> puzzleValues;
  final List<List<int>> solution;
  CachedPuzzle({required this.puzzleValues, required this.solution});
}

/// Pre-generates puzzles in background isolates for instant game start.
class PuzzleCache {
  static final Map<String, List<CachedPuzzle>> _cache = {};
  static final Set<String> _generating = {};

  /// Target cache size per difficulty.
  static const int _targetSize = 3;

  /// Difficulties to pre-generate.
  static const _warmDifficulties = [
    Difficulty.expert,
    Difficulty.extreme,
    Difficulty.abyss,
  ];

  /// Start background generation for hard difficulties.
  /// Call this once at app startup.
  static void warmUp() {
    for (final diff in _warmDifficulties) {
      _fillCache(diff);
    }
  }

  /// Get a puzzle for the given difficulty.
  /// Returns instantly from cache if available, otherwise generates on demand.
  static Future<({SudokuBoard puzzle, List<List<int>> solution})> getPuzzle(
    Difficulty difficulty,
  ) async {
    final key = difficulty.name;
    final cached = _cache[key];
    if (cached != null && cached.isNotEmpty) {
      final puzzle = cached.removeLast();
      // Refill cache in background
      _fillCache(difficulty);
      return (
        puzzle: SudokuBoard.fromValues(puzzle.puzzleValues),
        solution: puzzle.solution,
      );
    }

    // Cache miss: generate on demand in isolate
    final result = await compute(_generateOne, difficulty);
    // Also start filling cache for next time
    _fillCache(difficulty);
    return (
      puzzle: SudokuBoard.fromValues(result.puzzleValues),
      solution: result.solution,
    );
  }

  /// Check if cache has puzzles ready for the given difficulty.
  static bool hasCache(Difficulty difficulty) {
    final cached = _cache[difficulty.name];
    return cached != null && cached.isNotEmpty;
  }

  static void _fillCache(Difficulty difficulty) {
    final key = difficulty.name;
    _cache.putIfAbsent(key, () => []);
    if (_cache[key]!.length >= _targetSize) return;
    if (_generating.contains(key)) return;

    _generating.add(key);
    final needed = _targetSize - _cache[key]!.length;

    // Generate in a single isolate call for efficiency
    compute(_generateBatch, _BatchRequest(difficulty, needed)).then((results) {
      _cache.putIfAbsent(key, () => []);
      _cache[key]!.addAll(results);
      _generating.remove(key);
    }).catchError((_) {
      _generating.remove(key);
    });
  }

  static CachedPuzzle _generateOne(Difficulty difficulty) {
    final generator = SudokuGenerator();
    final result = generator.generate(difficulty);
    return CachedPuzzle(
      puzzleValues: result.puzzle.toValues(),
      solution: result.solution,
    );
  }

  static List<CachedPuzzle> _generateBatch(_BatchRequest request) {
    final results = <CachedPuzzle>[];
    for (int i = 0; i < request.count; i++) {
      final generator = SudokuGenerator();
      final result = generator.generate(request.difficulty);
      results.add(CachedPuzzle(
        puzzleValues: result.puzzle.toValues(),
        solution: result.solution,
      ));
    }
    return results;
  }
}

class _BatchRequest {
  final Difficulty difficulty;
  final int count;
  _BatchRequest(this.difficulty, this.count);
}
