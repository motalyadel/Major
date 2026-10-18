import 'package:academy_en_ligne/core/utils/auth_error_handler.dart';
import 'package:academy_en_ligne/data/models/auth_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ⚠️ Remplace "bac_study_app" par le vrai nom de ton package
// (celui déclaré dans pubspec.yaml), comme dans ton ancien projet.

abstract class BaseService<T extends AuthModel> {
  final SupabaseClient clientSpb = Supabase.instance.client;

  Future<bool> signIn({required String email, required String password}) async {
    try {
      final response = await clientSpb.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        print('✅ Connexion réussie pour ${response.user!.email}');
        return true;
      } else {
        print('⚠️ Échec : user est null');
        return false;
      }
    } on AuthApiException catch (e) {
      print('⚠️ AuthApiException: ${e.message}');
      return false;
    } catch (e, s) {
      print('❌ Erreur inattendue : $e\n$s');
      return false;
    }
  }

  /// Inscription. Le trigger côté Supabase (`handle_new_user`) crée
  /// automatiquement les lignes `public.users` + `public.students`.
  /// `branch` est optionnel ici : si fourni, il est passé dans les
  /// métadonnées, mais il faudra un `updateStudentProfile` (dans
  /// StudentService) pour l'écrire réellement dans `public.students`,
  /// puisque le trigger ne connaît que `name` pour l'instant.
  Future<AuthResponse?> signUp({
    required String name,
    required String email,
    required String password,
    String? branch,
    String? phone,
  }) async {
    try {
      final response = await clientSpb.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name, // doit matcher raw_user_meta_data ->> 'full_name' utilisé par le trigger SQL
        },
      );
      return response;
    } catch (e) {
      final message = AuthErrorHandler.getMessage(e);
      throw Exception(message);
    }
  }

  Future<void> signOut() async {
    await clientSpb.auth.signOut();
  }

  Future<AuthModel?> getUser();
}