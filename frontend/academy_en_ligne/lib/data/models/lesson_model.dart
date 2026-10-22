// lib/data/models/lesson_model.dart
class Lesson {
  final int id;
  final int courseId;
  final String title;
  final String? videoUrl;
  final int durationSeconds;
  final bool isFree;
  final int order;
  final DateTime? createdAt;

  Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    this.videoUrl,
    required this.durationSeconds,
    required this.isFree,
    required this.order,
    this.createdAt,
  });

  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id'] as int,
      courseId: map['course_id'] as int,
      title: map['title'] as String,
      videoUrl: map['video_url'] as String?,
      durationSeconds: map['duration_seconds'] as int? ?? 0,
      isFree: map['is_free'] as bool? ?? false,
      order: map['order'] as int? ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  /// Accessible si gratuite OU abonnement actif
  bool isLocked(bool isSubscribed) => !isFree && !isSubscribed;

  String get durationLabel {
    if (durationSeconds <= 0) return '';
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    if (m == 0) return '${s}s';
    if (s == 0) return '${m} min';
    return '${m} min ${s}s';
  }
} 