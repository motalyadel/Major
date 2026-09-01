// lib/core/utils/auth_error_handler.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthErrorHandler {
  static String getMessage(dynamic error) {
    if (error is AuthApiException) {
      switch (error.code) {
        case 'email_address_invalid':
          return 'Adresse e-mail invalide. Vérifiez le format.';
        case 'invalid_credentials':
          return 'E-mail ou mot de passe incorrect.';
        case 'email_not_confirmed':
          return 'Veuillez confirmer votre adresse e-mail avant de vous connecter.';
        case 'user_already_exists':
          return 'Un compte existe déjà avec cette adresse e-mail.';
        case 'weak_password':
          return 'Le mot de passe est trop faible. Utilisez au moins 6 caractères.';
        case 'signup_disabled':
          return 'Les inscriptions sont temporairement désactivées.';
        default:
          return 'Erreur d’authentification : ${error.message}';
      }
    } else if (error is AuthException) {
      return 'Erreur d’authentification : ${error.message}';
    } else {
      return 'Une erreur inattendue est survenue. Veuillez réessayer.';
    }
  }
}