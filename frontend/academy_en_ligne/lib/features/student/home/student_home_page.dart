import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:academy_en_ligne/core/utils/navigator.dart';
import 'package:academy_en_ligne/providers/auth_controller.dart';
import 'package:academy_en_ligne/providers/subject_provider.dart';
import 'package:academy_en_ligne/features/student/home/login_page.dart'; // AppColors

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      final branch = auth.currentStudent?.branch;
      context.read<SubjectProvider>().loadByBranch(branch);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, _) {
        if (auth.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!auth.isAuthenticated || !auth.isStudent) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppNavigator.pushReplacement('/login');
          });
          return const SizedBox.shrink();
        }

        final student = auth.currentStudent;
        final firstName = _firstName(student?.name);

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FB),
          body: SafeArea(
            child: Column(
              children: [
                _buildAppBar(firstName),
                Expanded(
                  child: _currentIndex == 0
                      ? _buildHomeBody(student)
                      : _buildPlaceholderTab(_currentIndex),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  Widget _buildAppBar(String firstName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BAC STUDY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Accueil',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
            color: const Color(0xFF1A1A2E),
          ),
          GestureDetector(
            onTap: () => _showLogoutDialog(
              context,
              context.read<AuthController>(),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: Text(
                firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BODY ACCUEIL
  // ============================================================

  Widget _buildHomeBody(student) {
    return RefreshIndicator(
      onRefresh: () async {
        final branch = student?.branch;
        await context.read<SubjectProvider>().loadByBranch(branch);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            'Bonjour, ${_firstName(student?.name)} ! 👋',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Prêt à progresser aujourd\'hui ?',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          _buildSerieBanner(student),
          const SizedBox(height: 28),
          _buildSubjectsSection(),
        ],
      ),
    );
  }

  Widget _buildSerieBanner(student) {
    final branch = student?.branch ?? '—';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'BAC 2027',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Terminale $branch',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Série ${_branchLabel(branch)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            student?.isSubscribed == true
                ? 'Abonnement actif'
                : 'Abonnement inactif',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MES MATIÈRES – cartes bleues comme la photo
  // ============================================================

  Widget _buildSubjectsSection() {
    return Consumer<SubjectProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Mes matières',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(width: 8),
                if (!provider.loading && provider.subjects.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${provider.subjects.length} matières',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Navigator.pushNamed(context, '/subjects');
                  },
                  child: const Text(
                    'Tout voir >',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (provider.loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  provider.error!,
                  style: const TextStyle(color: Colors.grey),
                ),
              )
            else if (provider.subjects.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Aucune matière pour ta filière.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.subjects.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  final subject = provider.subjects[index];
                  return _SubjectCard(
                    name: subject.name,
                    icon: _subjectIcon(subject.name),
                    backgroundColor: _subjectBlue(index),
                    onTap: () {
                      // TODO: ouvrir les chapitres de cette matière
                    },
                  );
                },
              ),
          ],
        );
      },
    );
  }

  // ============================================================
  // BOTTOM NAVBAR
  // ============================================================

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Matières',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Résultats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderTab(int index) {
    final labels = ['Accueil', 'Matières', 'Résultats', 'Profil'];
    return Center(
      child: Text(
        'Page ${labels[index]} – à venir',
        style: const TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _firstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return 'Élève';
    return fullName.trim().split(' ').first;
  }

  String _branchLabel(String branch) {
    switch (branch.toUpperCase()) {
      case 'SM':
        return 'Sciences Mathématiques';
      case 'SVT':
        return 'Sciences de la Vie et de la Terre';
      case 'LM':
        return 'Lettres Modernes';
      default:
        return branch;
    }
  }

  Color _subjectBlue(int index) {
    const blues = [
      Color(0xFF1E6FD9),
      Color(0xFF1A5FBF),
      Color(0xFF2563EB),
      Color(0xFF1D4ED8),
      Color(0xFF3B82F6),
      Color(0xFF1E40AF),
    ];
    return blues[index % blues.length];
  }

  /// Change les icônes ici selon tes matières
  IconData _subjectIcon(String name) {
    final n = name.toLowerCase();

    if (n.contains('math') || n.contains('ریاض') || n.contains('رياض')) {
      return Icons.calculate_rounded;
    }
    if (n.contains('physique') || n.contains('chimie')) {
      return Icons.science_rounded;
    }
    if (n.contains('svt') || n.contains('bio')) {
      return Icons.biotech_rounded;
    }
    if (n.contains('histoire') || n.contains('géo') || n.contains('تاريخ')) {
      return Icons.public_rounded;
    }
    if (n.contains('français') || n.contains('francais')) {
      return Icons.menu_book_rounded;
    }
    if (n.contains('anglais') || n.contains('english')) {
      return Icons.translate_rounded;
    }
    if (n.contains('philo') || n.contains('فكر')) {
      return Icons.account_balance_rounded;
    }
    if (n.contains('islam') || n.contains('شرع') || n.contains('تشريع')) {
      return Icons.balance_rounded;
    }
    if (n.contains('عربي') || n.contains('arabe') || n.contains('arabic')) {
      return Icons.translate_rounded;
    }
    if (n.contains('قرآن') || n.contains('حديث') || n.contains('quran')) {
      return Icons.brightness_2_rounded;
    }

    return Icons.book_rounded;
  }

  Future<void> _showLogoutDialog(
    BuildContext context,
    AuthController auth,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Voulez-vous vraiment vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Déconnecter'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await auth.signOut();
    }
  }
}

// ============================================================
// CARTE MATIÈRE (style photo – carré bleu + icône blanche)
// ============================================================

class _SubjectCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;

  const _SubjectCard({
    required this.name,
    required this.icon,
    required this.onTap,
    this.backgroundColor = const Color(0xFF1E6FD9),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 52,
                color: Colors.white,
              ),
              const SizedBox(height: 14),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
