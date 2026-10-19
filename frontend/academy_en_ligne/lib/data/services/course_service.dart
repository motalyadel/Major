// lib/data/services/course_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:academy_en_ligne/data/models/course_model.dart';

class CourseService {
  final _client = Supabase.instance.client;

  /// Chapitres d'une matière, triés par order
  Future<List<Course>> getBySubjectId(int subjectId) async {
    final response = await _client
        .from('courses')
        .select()
        .eq('subject_id', subjectId)
        .order('order')
        .order('title');

    return (response as List)
        .map((e) => Course.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }
}