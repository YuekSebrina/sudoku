import '../models/technique.dart';
import 'techniques/advanced_techniques.dart';
import 'techniques/beginner_techniques.dart';
import 'techniques/chain_techniques.dart';
import 'techniques/expert_techniques.dart';
import 'techniques/intermediate_techniques.dart';
import 'techniques/technique_utils.dart';

/// Core engine that detects applicable solving techniques on a given board.
///
/// Each detection method returns a [TechniqueResult] with full visualization
/// data, or `null` if the technique doesn't apply.
///
/// This file serves as the main entry point and coordinator. Individual
/// technique implementations are organized by difficulty level in the
/// `techniques/` subdirectory.
class TechniqueFinder {
  /// Find the simplest applicable technique on the current board.
  /// Techniques are tried in priority order (easiest first).
  static TechniqueResult? findNext(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    final finders = <TechniqueResult? Function()>[
      // Beginner
      () => BeginnerTechniques.findBoxHiddenSingle(grid, candidates),
      () => BeginnerTechniques.findRowHiddenSingle(grid, candidates),
      () => BeginnerTechniques.findColHiddenSingle(grid, candidates),
      () => BeginnerTechniques.findBoxElimination(grid, candidates),
      () => BeginnerTechniques.findRowElimination(grid, candidates),
      () => BeginnerTechniques.findColElimination(grid, candidates),
      // Intermediate
      () => IntermediateTechniques.findNakedSingle(grid, candidates),
      () => IntermediateTechniques.findExplicitPointing(grid, candidates),
      () => IntermediateTechniques.findNakedPair(grid, candidates),
      () => IntermediateTechniques.findHiddenPointing(grid, candidates),
      () => IntermediateTechniques.findLineBoxClaiming(grid, candidates),
      // Advanced
      () => AdvancedTechniques.findNakedTriple(grid, candidates),
      () => AdvancedTechniques.findXWing(grid, candidates),
      () => AdvancedTechniques.findHiddenPair(grid, candidates),
      () => AdvancedTechniques.findHiddenTriple(grid, candidates),
      () => AdvancedTechniques.findSwordfish(grid, candidates),
      () => AdvancedTechniques.findSkyscraper(grid, candidates),
      () => AdvancedTechniques.findXYWing(grid, candidates),
      () => AdvancedTechniques.findStrongLinks2(grid, candidates),
      () => AdvancedTechniques.findXYZWing(grid, candidates),
      // Expert
      () => ExpertTechniques.findStrongLinks3(grid, candidates),
      () => ExpertTechniques.findBUG1(grid, candidates),
      () => ExpertTechniques.findBUG2(grid, candidates),
      () => ExpertTechniques.findVWXYZWing(grid, candidates),
      () => ExpertTechniques.findUVWXYZWing(grid, candidates),
      // Chains
      () => ChainTechniques.findBiDirectionalXCycle(grid, candidates),
      () => ChainTechniques.findBiDirectionalCycle(grid, candidates),
      () => ChainTechniques.findCellForcingChain(grid, candidates),
      () => ChainTechniques.findRegionForcingChain(grid, candidates),
    ];

    for (final finder in finders) {
      final result = finder();
      if (result != null) return result;
    }
    return null;
  }

  /// Find a specific technique application.
  static TechniqueResult? findSpecific(
    TechniqueType type,
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    switch (type) {
      case TechniqueType.boxHiddenSingle:
        return BeginnerTechniques.findBoxHiddenSingle(grid, candidates);
      case TechniqueType.rowHiddenSingle:
        return BeginnerTechniques.findRowHiddenSingle(grid, candidates);
      case TechniqueType.colHiddenSingle:
        return BeginnerTechniques.findColHiddenSingle(grid, candidates);
      case TechniqueType.boxElimination:
        return BeginnerTechniques.findBoxElimination(grid, candidates);
      case TechniqueType.rowElimination:
        return BeginnerTechniques.findRowElimination(grid, candidates);
      case TechniqueType.colElimination:
        return BeginnerTechniques.findColElimination(grid, candidates);
      case TechniqueType.nakedSingle:
        return IntermediateTechniques.findNakedSingle(grid, candidates);
      case TechniqueType.explicitBoxLineReduction:
        return IntermediateTechniques.findExplicitPointing(grid, candidates);
      case TechniqueType.nakedPair:
        return IntermediateTechniques.findNakedPair(grid, candidates);
      case TechniqueType.hiddenBoxLineReduction:
        return IntermediateTechniques.findHiddenPointing(grid, candidates);
      case TechniqueType.lineBoxClaiming:
        return IntermediateTechniques.findLineBoxClaiming(grid, candidates);
      case TechniqueType.nakedTriple:
        return AdvancedTechniques.findNakedTriple(grid, candidates);
      case TechniqueType.xWing:
        return AdvancedTechniques.findXWing(grid, candidates);
      case TechniqueType.hiddenPair:
        return AdvancedTechniques.findHiddenPair(grid, candidates);
      case TechniqueType.explicitNakedTriple:
        return AdvancedTechniques.findNakedTriple(grid, candidates);
      case TechniqueType.hiddenTriple:
        return AdvancedTechniques.findHiddenTriple(grid, candidates);
      case TechniqueType.swordfish:
        return AdvancedTechniques.findSwordfish(grid, candidates);
      case TechniqueType.skyscraper:
        return AdvancedTechniques.findSkyscraper(grid, candidates);
      case TechniqueType.xyWing:
        return AdvancedTechniques.findXYWing(grid, candidates);
      case TechniqueType.strongLinks2:
        return AdvancedTechniques.findStrongLinks2(grid, candidates);
      case TechniqueType.xyzWing:
        return AdvancedTechniques.findXYZWing(grid, candidates);
      case TechniqueType.strongLinks3:
        return ExpertTechniques.findStrongLinks3(grid, candidates);
      case TechniqueType.bug1:
        return ExpertTechniques.findBUG1(grid, candidates);
      case TechniqueType.bug2:
        return ExpertTechniques.findBUG2(grid, candidates);
      case TechniqueType.vwxyzWing:
        return ExpertTechniques.findVWXYZWing(grid, candidates);
      case TechniqueType.uvwxyzWing:
        return ExpertTechniques.findUVWXYZWing(grid, candidates);
      case TechniqueType.biDirectionalXCycle:
        return ChainTechniques.findBiDirectionalXCycle(grid, candidates);
      case TechniqueType.biDirectionalCycle:
        return ChainTechniques.findBiDirectionalCycle(grid, candidates);
      case TechniqueType.cellForcingChain:
        return ChainTechniques.findCellForcingChain(grid, candidates);
      case TechniqueType.regionForcingChain:
        return ChainTechniques.findRegionForcingChain(grid, candidates);
    }
  }

  /// Compute candidates for the entire grid.
  static List<List<Set<int>>> computeAllCandidates(List<List<int>> grid) {
    return TechniqueUtils.computeAllCandidates(grid);
  }
}
