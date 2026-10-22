// lib/data/services/lesson_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:academy_en_ligne/data/models/lesson_model.dart';

class LessonService {
  final _client = Supabase.instance.client;

  Future<List<Lesson>> getByCourseId(int courseId) async {
    final response = await _client
        .from('lessons')
        .select()
        .eq('course_id', courseId)
        .order('order')
        .order('title');

    return (response as List)
        .map((e) => Lesson.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }
}