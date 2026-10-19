import 'package:academy_en_ligne/features/student/profile/change_password_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:academy_en_ligne/providers/auth_controller.dart';
import 'package:academy_en_ligne/data/services/student_service.dart';
import 'package:academy_en_ligne/features/student/home/login_page.dart'; // AppColors

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _studentService = StudentService();

  bool _editing = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final student = context.read<AuthController>().currentStudent;
    final name = student?.name ?? context.read<AuthController>().user?.name;
    if (!_editing) {
      _nameController.text = name ?? '';
      _phoneController.text = student?.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthController>();
    final userId = auth.user?.id;
    if (userId == null) return;

    setState(() => _saving = true);

    try {
      final ok = await _studentService.updateProfile(
        userId: userId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        // branch et subscription_status volontairement absents
      );

      if (!mounted) return;

      if (ok) {
        await auth.getUser(); // recharger le profil
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de la mise à jour')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _cancelEdit() {
    final student = context.read<AuthController>().currentStudent;
    final name = student?.name ?? context.read<AuthController>().user?.name;
    _nameController.text = name ?? '';
    _phoneController.text = student?.phone ?? '';
    setState(() => _editing = false);
  }

  Future<void> _showChangePasswordDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ChangePasswordDialog(),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe modifié avec succès')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, _) {
        final student = auth.currentStudent;
        final name = student?.name ?? auth.user?.name ?? 'Élève';
        final email = auth.client.auth.currentUser?.email ?? '—';
        final branch = student?.branch ?? '—';
        final isSubscribed = student?.isSubscribed ?? false;
        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FB),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Row(
                    children: [
                      const Text(
                        'Profil',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const Spacer(),
                      if (!_editing)
                        TextButton.icon(
                          onPressed: () => setState(() => _editing = true),
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: const Text('Modifier'),
                        )
                      else
                        Row(
                          children: [
                            TextButton(
                              onPressed: _saving ? null : _cancelEdit,
                              child: const Text('Annuler'),
                            ),
                            const SizedBox(width: 4),
                            ElevatedButton(
                              onPressed: _saving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Enregistrer'),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Avatar
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.primary.withOpacity(0.15),
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (!_editing) ...[
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSubscribed
                                ? Colors.green.withOpacity(0.12)
                                : Colors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isSubscribed
                                ? 'Abonnement actif'
                                : 'Abonnement inactif',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSubscribed
                                  ? Colors.green.shade700
                                  : Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  _sectionTitle('Informations'),
                  const SizedBox(height: 10),

                  // ---- Champs éditables : nom + téléphone ----
                  if (_editing) ...[
                    _editField(
                      controller: _nameController,
                      label: 'Nom complet',
                      icon: Icons.person_rounded,
                      validator: (v) => v != null && v.trim().length >= 3
                          ? null
                          : 'Nom invalide (3 caractères min.)',
                    ),
                    const SizedBox(height: 12),
                    _editField(
                      controller: _phoneController,
                      label: 'Téléphone',
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        return v.trim().length >= 8 ? null : 'Numéro invalide';
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ---- Champs lecture seule ----
                  _infoCard([
                    if (!_editing) _infoTile(Icons.person_rounded, 'Nom', name),
                    if (!_editing) _divider(),
                    _infoTile(Icons.email_rounded, 'Email', email),
                    _divider(),
                    _infoTile(
                      Icons.school_rounded,
                      'Filière',
                      branch,
                      subtitle: 'Non modifiable',
                    ),
                    _divider(),
                    _infoTile(
                      Icons.verified_rounded,
                      'Abonnement',
                      isSubscribed ? 'Actif' : 'Inactif',
                      subtitle: 'Géré par l\'administration',
                    ),
                    if (!_editing) ...[
                      _divider(),
                      _infoTile(
                        Icons.phone_rounded,
                        'Téléphone',
                        student?.phone?.isNotEmpty == true
                            ? student!.phone!
                            : '—',
                      ),
                    ],
                  ]),

                  const SizedBox(height: 24),
                  _sectionTitle('Compte'),
                  const SizedBox(height: 10),
                  _infoCard([
                    _actionTile(
                      icon: Icons.lock_rounded,
                      label: 'Changer le mot de passe',
                      onTap: _showChangePasswordDialog,
                    ),
                    _divider(),
                    _actionTile(
                      icon: Icons.logout_rounded,
                      label: 'Déconnexion',
                      color: Colors.red,
                      onTap: () => _confirmLogout(context, auth),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _editField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A2E),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF0F5)),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoTile(
    IconData icon,
    String label,
    String value, {
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? const Color(0xFF1A1A2E);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: c, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade100,
      indent: 52,
    );
  }

  Future<void> _confirmLogout(
    BuildContext context,
    AuthController auth,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
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
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await auth.signOut();
    }
  }
}
