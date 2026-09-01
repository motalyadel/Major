import 'package:flutter/material.dart';
import 'package:academy_en_ligne/data/services/student_service.dart';
import 'package:academy_en_ligne/features/student/home/login_page.dart';
// ^ réutilise la classe AppColors définie dans login_page.dart

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _branchController = TextEditingController();
  final StudentService _studentService = StudentService();

  bool _isLoading = false;
  String? _error;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await _studentService.createUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        branch: _branchController.text.trim().isEmpty
            ? null
            : _branchController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        setState(() => _error = "Erreur lors de l'inscription.");
      }
    } catch (e) {
      setState(() => _error = "Erreur : ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isMobile ? 400 : 500),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const Icon(Icons.school,
                                size: 64, color: AppColors.primary),
                            const SizedBox(height: 16),
                            Text(
                              "Créer un compte",
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 32),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: "Nom complet",
                                prefixIcon: const Icon(Icons.person),
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) =>
                                  value != null && value.trim().length >= 3
                                      ? null
                                      : "Nom invalide",
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _branchController,
                              decoration: InputDecoration(
                                labelText: "Filière (ex: SM, SVT, LM...)",
                                prefixIcon: const Icon(Icons.menu_book),
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: "Téléphone",
                                prefixIcon: const Icon(Icons.phone),
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) => value == null ||
                                      value.trim().isEmpty ||
                                      value.trim().length >= 8
                                  ? null
                                  : "Numéro invalide",
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: "Email",
                                prefixIcon: const Icon(Icons.email),
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) =>
                                  value != null && value.contains('@')
                                      ? null
                                      : "Email invalide",
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: "Mot de passe",
                                prefixIcon: const Icon(Icons.lock),
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) =>
                                  value != null && value.length >= 6
                                      ? null
                                      : "6 caractères minimum",
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: "Confirmer le mot de passe",
                                prefixIcon: const Icon(Icons.lock_outline),
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) => value ==
                                      _passwordController.text
                                  ? null
                                  : "Les mots de passe ne correspondent pas",
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: _isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: _register,
                                      child: const Text("S'inscrire"),
                                    ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context)
                                    .pushReplacementNamed('/login');
                              },
                              child: const Text(
                                "Déjà un compte ? Se connecter",
                                style: TextStyle(color: AppColors.secondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
