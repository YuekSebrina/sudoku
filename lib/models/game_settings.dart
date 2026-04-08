import 'package:flutter/foundation.dart';

class GameSettings extends ChangeNotifier {
  bool _autoRemoveNotes = true;
  bool _highlightSameNumbers = true;
  bool _highlightRelatedCells = true;
  bool _highlightCandidates = true;
  bool _showRemainingCount = true;
  bool _showTimer = true;
  bool _autoPauseOnLeave = true;

  bool get autoRemoveNotes => _autoRemoveNotes;
  set autoRemoveNotes(bool v) {
    _autoRemoveNotes = v;
    notifyListeners();
  }

  bool get highlightSameNumbers => _highlightSameNumbers;
  set highlightSameNumbers(bool v) {
    _highlightSameNumbers = v;
    notifyListeners();
  }

  bool get highlightRelatedCells => _highlightRelatedCells;
  set highlightRelatedCells(bool v) {
    _highlightRelatedCells = v;
    notifyListeners();
  }

  bool get highlightCandidates => _highlightCandidates;
  set highlightCandidates(bool v) {
    _highlightCandidates = v;
    notifyListeners();
  }

  bool get showRemainingCount => _showRemainingCount;
  set showRemainingCount(bool v) {
    _showRemainingCount = v;
    notifyListeners();
  }

  bool get showTimer => _showTimer;
  set showTimer(bool v) {
    _showTimer = v;
    notifyListeners();
  }

  bool get autoPauseOnLeave => _autoPauseOnLeave;
  set autoPauseOnLeave(bool v) {
    _autoPauseOnLeave = v;
    notifyListeners();
  }
}
