// lib/providers/course_provider.dart
import 'package:flutter/material.dart';
import 'package:academy_en_ligne/data/models/course_model.dart';
import 'package:academy_en_ligne/data/services/course_service.dart';

class CourseProvider extends ChangeNotifier {
  final CourseService _service = CourseService();

  List<Course> _courses = [];
  bool _loading = false;
  String? _error;
  int? _currentSubjectId;
  String? _currentSubjectName;

  List<Course> get courses => _courses;
  bool get loading => _loading;
  String? get error => _error;
  int? get currentSubjectId => _currentSubjectId;
  String? get currentSubjectName => _currentSubjectName;

  Future<void> loadBySubject({
    required int subjectId,
    String? subjectName,
  }) async {
    _loading = true;
    _error = null;
    _currentSubjectId = subjectId;
    _currentSubjectName = subjectName;
    notifyListeners();

    try {
      _courses = await _service.getBySubjectId(subjectId);
    } catch (e) {
      _error = e.toString();
      _courses = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _courses = [];
    _error = null;
    _currentSubjectId = null;
    _currentSubjectName = null;
    notifyListeners();
  }
}
