import 'package:academy_en_ligne/features/student/lessons/video_player_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:academy_en_ligne/providers/auth_controller.dart';
import 'package:academy_en_ligne/providers/lesson_provider.dart';
import 'package:academy_en_ligne/data/models/lesson_model.dart';
import 'package:academy_en_ligne/features/student/home/login_page.dart'; // AppColors

class LessonsPage extends StatefulWidget {
  final int courseId;
  final String courseTitle;

  const LessonsPage({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<LessonsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessonProvider>().loadByCourse(
            courseId: widget.courseId,
            courseTitle: widget.courseTitle,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSubscribed = context.watch<AuthController>().isSubscribed;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(widget.courseTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<LessonProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Text(
                'Erreur : ${provider.error}',
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }

          final lessons = provider.lessons;

          if (lessons.isEmpty) {
            return const Center(
              child: Text(
                'Aucune leçon dans ce chapitre.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadByCourse(
                courseId: widget.courseId,
                courseTitle: widget.courseTitle,
              );
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: lessons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                final locked = lesson.isLocked(isSubscribed);

                return _LessonTile(
                  index: index + 1,
                  lesson: lesson,
                  locked: locked,
                  onTap: () {
                    if (locked) {
                      _showLockedDialog(context);
                      return;
                    }

                    // Vérifier qu'il y a une URL
                    if (lesson.videoUrl == null ||
                        lesson.videoUrl!.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vidéo non disponible')),
                      );
                      return;
                    }

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VideoPlayerPage(lesson: lesson),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showLockedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leçon premium'),
        content: const Text(
          'Cette leçon est réservée aux abonnés.\n'
          'Active ton abonnement pour y accéder.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              // TODO : naviguer vers la page abonnement
            },
            child: const Text('Voir l\'abonnement'),
          ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final int index;
  final Lesson lesson;
  final bool locked;
  final VoidCallback onTap;

  const _LessonTile({
    required this.index,
    required this.lesson,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEF0F5)),
          ),
          child: Row(
            children: [
              // Numéro ou cadenas
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: locked
                      ? Colors.grey.shade200
                      : AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: locked
                    ? Icon(Icons.lock_rounded,
                        size: 20, color: Colors.grey.shade600)
                    : Text(
                        '$index',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: locked
                            ? Colors.grey.shade500
                            : const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (lesson.isFree)
                          _badge('Gratuit', Colors.green)
                        else
                          _badge('Premium', Colors.orange),
                        if (lesson.durationLabel.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            lesson.durationLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                locked ? Icons.lock_outline : Icons.play_circle_fill_rounded,
                color: locked ? Colors.grey : AppColors.primary,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
