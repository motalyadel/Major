// lib/providers/admin_content_provider.dart
import 'package:flutter/material.dart';
import 'package:academy_en_ligne/data/models/subject_model.dart';
import 'package:academy_en_ligne/data/models/course_model.dart';
import 'package:academy_en_ligne/data/models/lesson_model.dart';
import 'package:academy_en_ligne/data/services/admin_content_service.dart';

class AdminContentProvider extends ChangeNotifier {
  final _service = AdminContentService();

  List<Subject> subjects = [];
  List<Course> courses = [];
  List<Lesson> lessons = [];
  bool loading = false;
  String? error;

  Future<void> loadSubjects() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      subjects = await _service.getAllSubjects();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadCourses(int subjectId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      courses = await _service.getCoursesBySubject(subjectId);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadLessons(int courseId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      lessons = await _service.getLessonsByCourse(courseId);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // --- Subjects CRUD ---
  Future<bool> addSubject({required String name, required String branch, int order = 0}) async {
    try {
      await _service.createSubject(name: name, branch: branch, order: order);
      await loadSubjects();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> editSubject({required int id, required String name, required String branch, int? order}) async {
    try {
      await _service.updateSubject(id: id, name: name, branch: branch, order: order);
      await loadSubjects();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeSubject(int id) async {
    try {
      await _service.deleteSubject(id);
      await loadSubjects();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // --- Courses CRUD ---
  Future<bool> addCourse({
    required int subjectId,
    required String title,
    String? description,
    int order = 0,
  }) async {
    try {
      await _service.createCourse(
        subjectId: subjectId,
        title: title,
        description: description,
        order: order,
      );
      await loadCourses(subjectId);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> editCourse({
    required int id,
    required int subjectId,
    required String title,
    String? description,
    int? order,
  }) async {
    try {
      await _service.updateCourse(id: id, title: title, description: description, order: order);
      await loadCourses(subjectId);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeCourse(int id, int subjectId) async {
    try {
      await _service.deleteCourse(id);
      await loadCourses(subjectId);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // --- Lessons CRUD ---
  Future<bool> addLesson({
    required int courseId,
    required String title,
    String? videoUrl,
    int durationSeconds = 0,
    bool isFree = false,
    int order = 0,
  }) async {
    try {
      await _service.createLesson(
        courseId: courseId,
        title: title,
        videoUrl: videoUrl,
        durationSeconds: durationSeconds,
        isFree: isFree,
        order: order,
      );
      await loadLessons(courseId);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> editLesson({
    required int id,
    required int courseId,
    required String title,
    String? videoUrl,
    int? durationSeconds,
    bool? isFree,
    int? order,
  }) async {
    try {
      await _service.updateLesson(
        id: id,
        title: title,
        videoUrl: videoUrl,
        durationSeconds: durationSeconds,
        isFree: isFree,
        order: order,
      );
      await loadLessons(courseId);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeLesson(int id, int courseId) async {
    try {
      await _service.deleteLesson(id);
      await loadLessons(courseId);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}