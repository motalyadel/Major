import 'package:flutter/material.dart';
import 'package:academy_en_ligne/data/models/subject_model.dart';
import 'package:academy_en_ligne/data/services/subject_service.dart';

class SubjectProvider extends ChangeNotifier {
  final SubjectService _service = SubjectService();

  List<Subject> _subjects = [];
  bool _loading = false;
  String? _error;
  String? _currentBranch;

  List<Subject> get subjects => _subjects;
  bool get loading => _loading;
  String? get error => _error;
  String? get currentBranch => _currentBranch;

  Future<void> loadByBranch(String? branch) async {
    if (branch == null || branch.trim().isEmpty) {
      _subjects = [];
      _error = 'Aucune filière définie dans ton profil.';
      _currentBranch = null;
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    _currentBranch = branch.trim();
    notifyListeners();

    try {
      _subjects = await _service.getByBranch(_currentBranch!);
    } catch (e) {
      _error = e.toString();
      _subjects = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _subjects = [];
    _error = null;
    _currentBranch = null;
    notifyListeners();
  }
}