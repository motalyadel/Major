import 'package:academy_en_ligne/data/services/student_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:academy_en_ligne/core/utils/navigator.dart';
import 'package:academy_en_ligne/data/models/auth_model.dart';
import 'package:academy_en_ligne/data/services/base_service.dart';

class AuthController extends ChangeNotifier {
  static AuthController? _instance;

  AuthController._();

  factory AuthController() {
    _instance ??= AuthController._();
    return _instance!;
  }

  final SupabaseClient client = Supabase.instance.client;

  BaseService? _service;

  AuthModel? _user;

  bool _isRedirecting = false;

  bool loading = true;

  String? error;

  // ============================================================
  // GETTERS
  // ============================================================

  AuthModel? get user => _user;

  Admin? get currentAdmin =>
      _user is Admin ? _user as Admin : null;

  Student? get currentStudent =>
      _user is Student ? _user as Student : null;

  String get currentRole =>
      _user?.currentRole.id ?? '';

  bool get isAuthenticated =>
      _user != null;

  bool get isAdmin =>
      currentRole == 'admin';

  bool get isStudent =>
      currentRole == 'student';

  bool get isSubscribed =>
      currentStudent?.isSubscribed ?? false;

  BaseService? get service => _service;

  // ============================================================
  // REDIRECT
  // ============================================================

  Future<bool> redirect() async {
    if (_isRedirecting) {
      debugPrint(
        'Redirection déjà en cours.',
      );

      return false;
    }

    _isRedirecting = true;

    try {
      final session = client.auth.currentSession;

      if (session == null) {
        debugPrint(
          'Aucune session Supabase.',
        );

        return false;
      }

      debugPrint(
        'Utilisateur connecté : ${session.user.email}',
      );

      _service = StudentService();

      await getUserAndPushToHome();

      return _user != null;
    } catch (e, stackTrace) {
      debugPrint(
        'Erreur redirect(): $e',
      );

      debugPrint(
        '$stackTrace',
      );

      error = e.toString();

      return false;
    } finally {
      _isRedirecting = false;
    }
  }

  // ============================================================
  // GET USER + REDIRECT
  // ============================================================

  Future<void> getUserAndPushToHome() async {
    try {
      await getUser();

      if (_user == null) {
        debugPrint(
          'Aucune donnée utilisateur trouvée.',
        );

        AppNavigator.pushReplacement('/login');

        return;
      }

      debugPrint(
        'Utilisateur chargé : '
        '${_user!.name} - rôle : $currentRole',
      );

      pushToHome();
    } catch (e, stackTrace) {
      debugPrint(
        'Erreur getUserAndPushToHome(): $e',
      );

      debugPrint(
        '$stackTrace',
      );

      AppNavigator.pushReplacement('/login');
    }
  }

  // ============================================================
  // GET USER
  // ============================================================

  Future<void> getUser() async {
    if (_service == null){
      throw Exception("Service non initialisé dans AuthController");
    }

    try {
      loading = true;
      error = null;

      notifyListeners();

      final response = await _service!.getUser();

      if (response == null) {
        throw Exception(
          'Utilisateur introuvable.',
        );
      }

      _user = response;

      debugPrint(
        'Utilisateur récupéré : ${_user!.id}',
      );

      debugPrint(
        'Rôle : $currentRole',
      );
    } catch (e, stackTrace) {
      error = e.toString();

      debugPrint(
        'Erreur getUser(): $e',
      );

      debugPrint(
        '$stackTrace',
      );

      _user = null;
    } finally {
      loading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // REDIRECTION ROLE
  // ============================================================

  void pushToHome() {
    if (_user == null) {
      AppNavigator.pushReplacement('/login');

      return;
    }

    debugPrint(
      'pushToHome() → rôle : $currentRole',
    );

    switch (currentRole) {
      case 'admin':
        AppNavigator.pushReplacement(
          '/admin_home',
        );
        break;

      case 'student':
        AppNavigator.pushReplacement(
          '/student_home',
        );
        break;

      default:
        debugPrint(
          'Rôle inconnu : $currentRole',
        );

        AppNavigator.pushReplacement(
          '/login',
        );
    }
  }

  // ============================================================
  // ADMIN
  // ============================================================

  Future<bool> canAccessAdminFeatures() async {
    if (_user == null) {
      await getUser();
    }

    return isAdmin;
  }

  Future<void> tryAccessAdminFeatures() async {
    if (await canAccessAdminFeatures()) {
      AppNavigator.push(
        '/admin_dashboard',
      );
    } else {
      AppNavigator.pushReplacement(
        '/login',
      );
    }
  }

  // ============================================================
  // STUDENT
  // ============================================================

  Future<bool> canAccessStudentFeatures() async {
    if (_user == null) {
      await getUser();
    }

    return isStudent;
  }

  Future<void> tryAccessStudentFeatures() async {
    if (await canAccessStudentFeatures()) {
      AppNavigator.push(
        '/student_home',
      );
    } else {
      AppNavigator.pushReplacement(
        '/login',
      );
    }
  }

  // ============================================================
  // SUBSCRIPTION
  // ============================================================

  bool canAccessPremiumFeatures() {
    if (!isStudent) {
      return false;
    }

    return isSubscribed;
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> signOut() async {
    try {
      debugPrint(
        'Déconnexion en cours...',
      );

      await client.auth.signOut();

      _user = null;
      _service = null;
      error = null;

      notifyListeners();

      AppNavigator.pushReplacement(
        '/login',
      );
    } catch (e, stackTrace) {
      error =
          'Échec de la déconnexion : $e';

      debugPrint(
        'Erreur signOut(): $e',
      );

      debugPrint(
        '$stackTrace',
      );

      notifyListeners();
    }
  }

  // ============================================================
  // ADMIN OR STUDENT
  // ============================================================

  Future<bool> isAdminOrStudent() async {
    if (_user == null) {
      await getUser();
    }

    return isAdmin || isStudent;
  }
}