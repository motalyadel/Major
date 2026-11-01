// lib/data/services/admin_content_service.dart
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:academy_en_ligne/data/models/subject_model.dart';
import 'package:academy_en_ligne/data/models/course_model.dart';
import 'package:academy_en_ligne/data/models/lesson_model.dart';

class AdminContentService {
  final _client = Supabase.instance.client;

  // ========== SUBJECTS ==========
  Future<List<Subject>> getAllSubjects() async {
    final res =
        await _client.from('subjects').select().order('order').order('name');
    return (res as List)
        .map((e) => Subject.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Subject> createSubject({
    required String name,
    required String branch,
    int order = 0,
  }) async {
    final res = await _client
        .from('subjects')
        .insert({
          'name': name,
          'branch': branch,
          'order': order,
        })
        .select()
        .single();
    return Subject.fromMap(Map<String, dynamic>.from(res));
  }

  Future<void> updateSubject({
    required int id,
    required String name,
    required String branch,
    int? order,
  }) async {
    await _client.from('subjects').update({
      'name': name,
      'branch': branch,
      if (order != null) 'order': order,
    }).eq('id', id);
  }

  Future<void> deleteSubject(int id) async {
    await _client.from('subjects').delete().eq('id', id);
  }

  // ========== COURSES ==========
  Future<List<Course>> getCoursesBySubject(int subjectId) async {
    final res = await _client
        .from('courses')
        .select()
        .eq('subject_id', subjectId)
        .order('order', ascending: true);
    return (res as List)
        .map((e) => Course.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Course> createCourse({
    required int subjectId,
    required String title,
    String? description,
    int order = 0,
  }) async {
    final res = await _client
        .from('courses')
        .insert({
          'subject_id': subjectId,
          'title': title,
          'description': description,
          'order': order,
        })
        .select()
        .single();
    return Course.fromMap(Map<String, dynamic>.from(res));
  }

  Future<void> updateCourse({
    required int id,
    required String title,
    String? description,
    int? order,
  }) async {
    await _client.from('courses').update({
      'title': title,
      'description': description,
      if (order != null) 'order': order,
    }).eq('id', id);
  }

  Future<void> deleteCourse(int id) async {
    await _client.from('courses').delete().eq('id', id);
  }

  // ========== LESSONS ==========
  Future<List<Lesson>> getLessonsByCourse(int courseId) async {
    final res = await _client
        .from('lessons')
        .select()
        .eq('course_id', courseId)
        .order('order', ascending: true);
    return (res as List)
        .map((e) => Lesson.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Lesson> createLesson({
    required int courseId,
    required String title,
    String? videoUrl,
    int durationSeconds = 0,
    bool isFree = false,
    int order = 0,
  }) async {
    final res = await _client
        .from('lessons')
        .insert({
          'course_id': courseId,
          'title': title,
          'video_url': videoUrl,
          'duration_seconds': durationSeconds,
          'is_free': isFree,
          'order': order,
        })
        .select()
        .single();
    return Lesson.fromMap(Map<String, dynamic>.from(res));
  }

  Future<void> updateLesson({
    required int id,
    required String title,
    String? videoUrl,
    int? durationSeconds,
    bool? isFree,
    int? order,
  }) async {
    await _client.from('lessons').update({
      'title': title,
      if (videoUrl != null) 'video_url': videoUrl,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (isFree != null) 'is_free': isFree,
      if (order != null) 'order': order,
    }).eq('id', id);
  }

  Future<void> deleteLesson(int id) async {
    await _client.from('lessons').delete().eq('id', id);
  }

  /// Upload un fichier vidéo vers le bucket videos.
/// Retourne le chemin à stocker dans lessons.video_url
Future<String> uploadLessonVideo({
  required Uint8List bytes,
  required String fileName,
  required bool isFree,
}) async {
  final folder = isFree ? 'free' : 'premium';
  final safeName = fileName
      .replaceAll(RegExp(r'[^\w\.\-]'), '_')
      .toLowerCase();
  final path =
      '$folder/${DateTime.now().millisecondsSinceEpoch}_$safeName';

  await _client.storage.from('videos').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(
          upsert: true,
          contentType: 'video/mp4',
        ),
      );

  return path; // ex: free/173000_test.mp4
}
}
