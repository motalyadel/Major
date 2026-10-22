// lib/providers/lesson_provider.dart
import 'package:flutter/material.dart';
import 'package:academy_en_ligne/data/models/lesson_model.dart';
import 'package:academy_en_ligne/data/services/lesson_service.dart';

class LessonProvider extends ChangeNotifier {
  final LessonService _service = LessonService();

  List<Lesson> _lessons = [];
  bool _loading = false;
  String? _error;
  int? _courseId;
  String? _courseTitle;

  List<Lesson> get lessons => _lessons;
  bool get loading => _loading;
  String? get error => _error;
  String? get courseTitle => _courseTitle;

  Future<void> loadByCourse({
    required int courseId,
    String? courseTitle,
  }) async {
    _loading = true;
    _error = null;
    _courseId = courseId;
    _courseTitle = courseTitle;
    notifyListeners();

    try {
      _lessons = await _service.getByCourseId(courseId);
    } catch (e) {
      _error = e.toString();
      _lessons = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _lessons = [];
    _error = null;
    _courseId = null;
    _courseTitle = null;
    notifyListeners();
  }
}