// lib/features/admin/courses/admin_courses_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:academy_en_ligne/providers/admin_content_provider.dart';
import 'package:academy_en_ligne/data/models/course_model.dart';
import 'package:academy_en_ligne/features/admin/lessons/admin_lessons_page.dart';
import 'package:academy_en_ligne/features/student/home/login_page.dart'; // AppColors

class AdminCoursesPage extends StatefulWidget {
  final int subjectId;
  final String subjectName;

  const AdminCoursesPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<AdminCoursesPage> createState() => _AdminCoursesPageState();
}

class _AdminCoursesPageState extends State<AdminCoursesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminContentProvider>().loadCourses(widget.subjectId);
    });
  }

  Future<void> _showCourseDialog({Course? course}) async {
    final titleCtrl = TextEditingController(text: course?.title ?? '');
    final descCtrl = TextEditingController(text: course?.description ?? '');
    final orderCtrl = TextEditingController(text: '${course?.order ?? 0}');
    final formKey = GlobalKey<FormState>();
    final isEdit = course != null;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Modifier le chapitre' : 'Nouveau chapitre'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Titre',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v != null && v.trim().isNotEmpty ? null : 'Requis',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description (optionnel)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: orderCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ordre',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: Text(isEdit ? 'Enregistrer' : 'Créer'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    final provider = context.read<AdminContentProvider>();
    final order = int.tryParse(orderCtrl.text) ?? 0;
    final description =
        descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim();

    final success = isEdit
        ? await provider.editCourse(
            id: course!.id,
            subjectId: widget.subjectId,
            title: titleCtrl.text.trim(),
            description: description,
            order: order,
          )
        : await provider.addCourse(
            subjectId: widget.subjectId,
            title: titleCtrl.text.trim(),
            description: description,
            order: order,
          );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Chapitre enregistré' : 'Erreur : ${provider.error}',
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Course course) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text(
          'Supprimer le chapitre « ${course.title} » et toutes ses leçons ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      final provider = context.read<AdminContentProvider>();
      final success =
          await provider.removeCourse(course.id, widget.subjectId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Chapitre supprimé' : 'Erreur : ${provider.error}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text('Chapitres — ${widget.subjectName}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCourseDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<AdminContentProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.courses.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.courses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Erreur : ${provider.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (provider.courses.isEmpty) {
            return const Center(
              child: Text(
                'Aucun chapitre.\nAppuie sur + pour en ajouter.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                provider.loadCourses(widget.subjectId),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.courses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final course = provider.courses[index];

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFEEF0F5)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.12),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      course.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: course.description != null &&
                            course.description!.isNotEmpty
                        ? Text(
                            course.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        : Text('Ordre : ${course.order}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          tooltip: 'Modifier',
                          onPressed: () => _showCourseDialog(course: course),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 20,
                            color: Colors.red,
                          ),
                          tooltip: 'Supprimer',
                          onPressed: () => _confirmDelete(course),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminLessonsPage(
                            courseId: course.id,
                            courseTitle: course.title,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}