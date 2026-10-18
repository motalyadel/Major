// lib/data/services/subject_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:academy_en_ligne/data/models/subject_model.dart';

class SubjectService {
  final _client = Supabase.instance.client;

  Future<List<Subject>> getByBranch(String branch) async {
    final response = await _client
        .from('subjects')
        .select()
        .eq('branch', branch)
        .order('order')
        .order('name');

    return (response as List)
        .map((e) => Subject.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }
}