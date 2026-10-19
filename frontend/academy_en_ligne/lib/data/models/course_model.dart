// lib/data/models/course_model.dart
class Course {
  final int id;
  final int subjectId;
  final String title;
  final String? description;
  final int order;
  final DateTime? createdAt;

  Course({
    required this.id,
    required this.subjectId,
    required this.title,
    this.description,
    required this.order,
    this.createdAt,
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as int,
      subjectId: map['subject_id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      order: map['order'] as int? ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }
}