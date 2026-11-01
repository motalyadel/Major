// lib/features/admin/subjects/admin_subjects_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:academy_en_ligne/providers/admin_content_provider.dart';
import 'package:academy_en_ligne/data/models/subject_model.dart';
import 'package:academy_en_ligne/features/admin/courses/admin_courses_page.dart';
import 'package:academy_en_ligne/features/student/home/login_page.dart'; // AppColors

class AdminSubjectsPage extends StatefulWidget {
  const AdminSubjectsPage({super.key});

  @override
  State<AdminSubjectsPage> createState() => _AdminSubjectsPageState();
}

class _AdminSubjectsPageState extends State<AdminSubjectsPage> {
  static const Map<String, String> branchLabels = {
    'SN': 'Bac D (SN)',
    'LM': 'Bac A (LM)',
    'LO': 'Bac O (LO)',
  };

  /// null = écran des 3 cartes ; sinon code branche sélectionnée
  String? _selectedBranch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminContentProvider>().loadSubjects();
    });
  }

  List<Subject> _subjectsForBranch(List<Subject> all, String branch) {
    final list =
        all.where((s) => s.branch.trim().toUpperCase() == branch).toList();
    list.sort((a, b) {
      final o = a.order.compareTo(b.order);
      if (o != 0) return o;
      return a.name.compareTo(b.name);
    });
    return list;
  }

  int _countForBranch(List<Subject> all, String branch) {
    return all.where((s) => s.branch.trim().toUpperCase() == branch).length;
  }

  Color _branchColor(String code) {
    switch (code) {
      case 'SN':
        return const Color(0xFF2563EB);
      case 'LM':
        return const Color(0xFF059669);
      case 'LO':
        return const Color(0xFFEA580C);
      default:
        return AppColors.primary;
    }
  }

  Future<void> _showSubjectDialog({
    Subject? subject,
    required String branch,
  }) async {
    final nameCtrl = TextEditingController(text: subject?.name ?? '');
    final orderCtrl = TextEditingController(text: '${subject?.order ?? 0}');
    final formKey = GlobalKey<FormState>();
    final isEdit = subject != null;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Modifier la matière' : 'Nouvelle matière'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                branchLabels[branch] ?? branch,
                style: TextStyle(
                  color: _branchColor(branch),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v != null && v.trim().isNotEmpty ? null : 'Requis',
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

    final success = isEdit
        ? await provider.editSubject(
            id: subject!.id,
            name: nameCtrl.text.trim(),
            branch: branch,
            order: order,
          )
        : await provider.addSubject(
            name: nameCtrl.text.trim(),
            branch: branch,
            order: order,
          );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Enregistré' : 'Erreur : ${provider.error}'),
      ),
    );
  }

  Future<void> _confirmDelete(Subject subject) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text(
          'Supprimer « ${subject.name} » et tous ses chapitres/leçons ?',
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
      await context.read<AdminContentProvider>().removeSubject(subject.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedBranch;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          selected == null ? 'Filières' : (branchLabels[selected] ?? selected),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        // Bouton retour vers les 3 cartes
        leading: selected != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedBranch = null),
              )
            : null,
      ),
      floatingActionButton: selected != null
          ? FloatingActionButton(
              onPressed: () => _showSubjectDialog(branch: selected),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Consumer<AdminContentProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.subjects.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // ========== Écran 1 : 3 cartes filières ==========
          if (selected == null) {
            return RefreshIndicator(
              onRefresh: provider.loadSubjects,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Choisis une filière',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final entry in branchLabels.entries) ...[
                    _BranchCard(
                      label: entry.value,
                      count: _countForBranch(provider.subjects, entry.key),
                      color: _branchColor(entry.key),
                      onTap: () => setState(() => _selectedBranch = entry.key),
                    ),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            );
          }

          // ========== Écran 2 : matières de la filière ==========
          final subjects = _subjectsForBranch(provider.subjects, selected);

          return RefreshIndicator(
            onRefresh: provider.loadSubjects,
            child: subjects.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text(
                          'Aucune matière.\nAppuie sur + pour en ajouter.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: subjects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final s = subjects[index];
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFEEF0F5)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor:
                                _branchColor(selected).withOpacity(0.12),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: _branchColor(selected),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            s.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text('Ordre : ${s.order}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _showSubjectDialog(
                                  subject: s,
                                  branch: selected,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                onPressed: () => _confirmDelete(s),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminCoursesPage(
                                  subjectId: s.id,
                                  subjectName: s.name,
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

// ============================================================
// Carte filière (écran principal)
// ============================================================

class _BranchCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _BranchCard({
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEEF0F5)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.school_rounded, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count matière${count > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
