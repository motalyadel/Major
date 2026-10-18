import 'package:academy_en_ligne/providers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:academy_en_ligne/core/utils/navigator.dart';
// import 'package:academy_en_ligne/features/student/home/providers/auth_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _hasRedirected = false;
  String? _error;

  // ============================================================
  // REDIRECTION
  // ============================================================

  Future<void> redirect() async {
    if (_hasRedirected) return;

    _hasRedirected = true;

    try {
      debugPrint(
        'Début de la redirection dans SplashScreen',
      );

      // Durée minimale du Splash
      await Future.delayed(
        const Duration(seconds: 2),
      );

      if (!mounted) return;

      final authController =
          Provider.of<AuthController>(
        context,
        listen: false,
      );

      final success =
          await authController.redirect();

      if (!success) {
        debugPrint(
          'Aucune session trouvée → /login',
        );

        if (!mounted) return;

        AppNavigator.pushReplacement(
          '/login',
        );
      } else {
        debugPrint(
          'Utilisateur trouvé → redirection effectuée ✅',
        );

        // IMPORTANT :
        // AuthController.redirect() appelle déjà
        // pushToHome().
        //
        // Il ne faut donc pas faire une deuxième
        // navigation ici.
      }
    } catch (e, stackTrace) {
      debugPrint(
        'Erreur SplashScreen : $e',
      );

      debugPrint(
        '$stackTrace',
      );

      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });

      await Future.delayed(
        const Duration(seconds: 1),
      );

      if (!mounted) return;

      AppNavigator.pushReplacement(
        '/login',
      );
    }
  }

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1500,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        redirect();
      },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo,

      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,

          child: SlideTransition(
            position: _slideAnimation,

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ------------------------------------------------
                // Logo
                // ------------------------------------------------

                const Icon(
                  Icons.school,
                  size: 80,
                  color: Colors.white,
                ),

                const SizedBox(height: 20),

                // ------------------------------------------------
                // Nom application
                // ------------------------------------------------

                const Text(
                  'Major',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Votre plateforme éducative',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 30),

                // ------------------------------------------------
                // Erreur
                // ------------------------------------------------

                if (_error != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 15),
                ],

                // ------------------------------------------------
                // Loading
                // ------------------------------------------------

                const SizedBox(
                  width: 25,
                  height: 25,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}