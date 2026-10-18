// lib/data/models/subject_model.dart
class Subject {
  final int id;
  final String name;
  final String branch;
  final int order;
  final DateTime? createdAt;

  Subject({
    required this.id,
    required this.name,
    required this.branch,
    required this.order,
    this.createdAt,
  });

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] as int,
      name: map['name'] as String,
      branch: map['branch'] as String,
      order: map['order'] as int? ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }
}