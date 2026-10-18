import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:academy_en_ligne/core/utils/navigator.dart';
import 'package:academy_en_ligne/providers/auth_controller.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, child) {
        // ------------------------------------------------------
        // Chargement
        // ------------------------------------------------------

        if (auth.loading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // ------------------------------------------------------
        // Vérification authentification + rôle
        // ------------------------------------------------------

        if (!auth.isAuthenticated || !auth.isAdmin) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppNavigator.pushReplacement('/login');
          });

          return const SizedBox.shrink();
        }

        // ------------------------------------------------------
        // Utilisateur admin
        // ------------------------------------------------------

        final admin = auth.currentAdmin;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tableau de bord Admin'),
            actions: [
              IconButton(
                icon: const Icon(Icons.person),
                tooltip: 'Profil / Déconnexion',
                onPressed: () async {
                  await _showLogoutDialog(
                    context,
                    auth,
                  );
                },
              ),
            ],
          ),
          body: Center(
            child: Text(
              'Bienvenue${admin?.name != null ? ', ${admin!.name}' : ''} !',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
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
          content: const Text(
            'Voulez-vous vraiment vous déconnecter ?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
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
