// lib/features/student/home/subjects_page.dart
import 'package:academy_en_ligne/providers/auth_controller.dart';
import 'package:academy_en_ligne/providers/subject_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:academy_en_ligne/features/student/home/login_page.dart'; // AppColors

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
      final auth = context.read<AuthController>();
      final branch = auth.currentStudent?.branch ;
          // ?? auth.user?. /* si tu as branch sur le modèle */ null;
      
      // Adapte selon ton AuthModel / Profile
      // Exemple si tu as un getter branch :
      // final branch = auth.currentProfile?.branch;
      
      context.read<SubjectProvider>().loadByBranch(branch);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Consumer<SubjectProvider>(
          builder: (_, provider, __) {
            final branch = provider.currentBranch ?? '...';
            return Text('Matières – $branch');
          },
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<SubjectProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          final subjects = provider.subjects;

          if (subjects.isEmpty) {
            return const Center(
              child: Text(
                'Aucune matière pour ta filière.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadByBranch(provider.currentBranch);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: subjects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final subject = subjects[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.12),
                      child: const Icon(Icons.menu_book, color: AppColors.primary),
                    ),
                    title: Text(
                      subject.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text('Filière : ${subject.branch}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigator vers CoursesPage(subjectId: subject.id)
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