// lib/features/student/subjects/subjects_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:academy_en_ligne/providers/auth_controller.dart';
import 'package:academy_en_ligne/providers/subject_provider.dart';
import 'package:academy_en_ligne/features/student/courses/courses_page.dart';
import 'package:academy_en_ligne/features/student/home/login_page.dart';

class SubjectsPage extends StatefulWidget {
  const SubjectsPage({super.key});

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final branch = context.read<AuthController>().currentStudent?.branch;
      context.read<SubjectProvider>().loadByBranch(branch);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Mes matières'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<SubjectProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text(provider.error!));
          }
          if (provider.subjects.isEmpty) {
            return const Center(
              child: Text('Aucune matière pour ta filière.'),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.subjects.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final subject = provider.subjects[index];
              return Material(
                color: const Color(0xFF1E6FD9),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CoursesPage(
                          subjectId: subject.id,
                          subjectName: subject.name,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.menu_book,
                            size: 48, color: Colors.white),
                        const SizedBox(height: 12),
                        Text(
                          subject.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
