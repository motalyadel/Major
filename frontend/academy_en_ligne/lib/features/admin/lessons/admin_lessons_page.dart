// lib/features/admin/lessons/admin_lessons_page.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import 'package:academy_en_ligne/providers/admin_content_provider.dart';
import 'package:academy_en_ligne/data/services/admin_content_service.dart';
import 'package:academy_en_ligne/data/models/lesson_model.dart';
import 'package:academy_en_ligne/features/student/home/login_page.dart'; // AppColors

class AdminLessonsPage extends StatefulWidget {
  final int courseId;
  final String courseTitle;

  const AdminLessonsPage({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<AdminLessonsPage> createState() => _AdminLessonsPageState();
}

class _AdminLessonsPageState extends State<AdminLessonsPage> {
  final _adminService = AdminContentService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminContentProvider>().loadLessons(widget.courseId);
    });
  }

  Future<void> _showLessonDialog({Lesson? lesson}) async {
    final titleCtrl = TextEditingController(text: lesson?.title ?? '');
    final durationCtrl = TextEditingController(
      text: '${lesson?.durationSeconds ?? 0}',
    );
    final orderCtrl = TextEditingController(text: '${lesson?.order ?? 0}');

    bool isFree = lesson?.isFree ?? false;
    String? videoPath = lesson?.videoUrl;
    String? pickedFileName;
    Uint8List? pickedBytes;

    final formKey = GlobalKey<FormState>();
    final isEdit = lesson != null;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Modifier la leçon' : 'Nouvelle leçon'),
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
                            v != null && v.trim().isNotEmpty
                                ? null
                                : 'Requis',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: durationCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Durée (secondes)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
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
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Leçon gratuite'),
                        subtitle: const Text(
                          'Accessible sans abonnement',
                        ),
                        value: isFree,
                        activeColor: AppColors.primary,
                        onChanged: (v) {
                          setDialogState(() => isFree = v);
                        },
                      ),
                      const SizedBox(height: 8),

                      // ---------- Upload vidéo ----------
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Vidéo',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            if (pickedFileName != null)
                              Text(
                                'Nouveau fichier : $pickedFileName',
                                style: const TextStyle(fontSize: 13),
                              )
                            else if (videoPath != null &&
                                videoPath!.isNotEmpty)
                              Text(
                                'Actuel : $videoPath',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              )
                            else
                              Text(
                                'Aucune vidéo',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final result =
                                    await FilePicker.platform.pickFiles(
                                  type: FileType.video,
                                  withData: true,
                                );

                                if (result == null ||
                                    result.files.isEmpty) {
                                  return;
                                }

                                final file = result.files.first;
                                if (file.bytes == null) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Impossible de lire le fichier',
                                        ),
                                      ),
                                    );
                                  }
                                  return;
                                }

                                setDialogState(() {
                                  pickedBytes = file.bytes;
                                  pickedFileName = file.name;
                                });
                              },
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Choisir une vidéo'),
                            ),
                          ],
                        ),
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
            );
          },
        );
      },
    );

    if (ok != true || !mounted) return;

    final provider = context.read<AdminContentProvider>();
    String? finalVideoPath = videoPath;

    // Upload si un nouveau fichier a été choisi
    if (pickedBytes != null && pickedFileName != null) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload de la vidéo…')),
        );

        finalVideoPath = await _adminService.uploadLessonVideo(
          bytes: pickedBytes!,
          fileName: pickedFileName!,
          isFree: isFree,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec upload : $e')),
        );
        return;
      }
    }

    final duration = int.tryParse(durationCtrl.text) ?? 0;
    final order = int.tryParse(orderCtrl.text) ?? 0;

    final success = isEdit
        ? await provider.editLesson(
            id: lesson!.id,
            courseId: widget.courseId,
            title: titleCtrl.text.trim(),
            videoUrl: finalVideoPath,
            durationSeconds: duration,
            isFree: isFree,
            order: order,
          )
        : await provider.addLesson(
            courseId: widget.courseId,
            title: titleCtrl.text.trim(),
            videoUrl: finalVideoPath,
            durationSeconds: duration,
            isFree: isFree,
            order: order,
          );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Leçon enregistrée' : 'Erreur : ${provider.error}',
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Lesson lesson) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Supprimer la leçon « ${lesson.title} » ?'),
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
          await provider.removeLesson(lesson.id, widget.courseId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Leçon supprimée' : 'Erreur : ${provider.error}',
          ),
        ),
      );
    }
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '—';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s}s';
    if (s == 0) return '${m} min';
    return '${m} min ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text('Leçons — ${widget.courseTitle}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLessonDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<AdminContentProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.lessons.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.lessons.isEmpty) {
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

          if (provider.lessons.isEmpty) {
            return const Center(
              child: Text(
                'Aucune leçon.\nAppuie sur + pour en ajouter.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadLessons(widget.courseId),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.lessons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final lesson = provider.lessons[index];

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
                      backgroundColor: lesson.isFree
                          ? Colors.green.withOpacity(0.15)
                          : Colors.orange.withOpacity(0.15),
                      child: Icon(
                        lesson.isFree
                            ? Icons.lock_open_rounded
                            : Icons.lock_rounded,
                        color:
                            lesson.isFree ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      lesson.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: lesson.isFree
                                    ? Colors.green.withOpacity(0.12)
                                    : Colors.orange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                lesson.isFree ? 'Gratuit' : 'Premium',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: lesson.isFree
                                      ? Colors.green.shade700
                                      : Colors.orange.shade800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDuration(lesson.durationSeconds),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        if (lesson.videoUrl != null &&
                            lesson.videoUrl!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            lesson.videoUrl!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          tooltip: 'Modifier',
                          onPressed: () =>
                              _showLessonDialog(lesson: lesson),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 20,
                            color: Colors.red,
                          ),
                          tooltip: 'Supprimer',
                          onPressed: () => _confirmDelete(lesson),
                        ),
                      ],
                    ),
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