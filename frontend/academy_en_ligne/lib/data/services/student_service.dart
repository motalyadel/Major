import 'package:academy_en_ligne/data/models/auth_model.dart';
import 'package:academy_en_ligne/data/services/base_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentService extends BaseService<Student> {
  // @override
  // Future<Student?> getUser() async {
  //   try {
  //     final user = clientSpb.auth.currentUser;
  //     if (user == null) {
  //       print('Aucun utilisateur connecté');
  //       return null;
  //     }

  //     final response = await clientSpb.from('users').select('''
  //           id, name,
  //           student:students(*),
  //           roles:user_roles(app_role(id))
  //         ''').eq('id', user.id).single();

  //     if (response['student'] == null) {
  //       print('Données student absentes pour ${user.id}');
  //       return null;
  //     }

  //     return Student.fromMap(response);
  //   } catch (e, s) {
  //     print('❌ Échec de getUser(): $e');
  //     print('Stack trace: $s');
  //     return null;
  //   }
  // }

  @override
  Future<AuthModel?> getUser() async {
    try {
      final user = clientSpb.auth.currentUser;
      if (user == null) {
        debugPrint('Aucun utilisateur connecté');
        return null;
      }

      final response = await clientSpb.from('users').select('''
      id,
      name,
      student:students(*),
      roles:user_roles(
        role_id,
        app_role(id)
      )
    ''').eq('id', user.id).maybeSingle();

      if (response == null) {
        debugPrint('Aucune ligne users pour ${user.id}');
        return null;
      }

      // ---- Parser les rôles ----
      final roles = _parseRoles(response['roles']);

      final isAdmin = roles.any((r) => r.id == 'admin');

      if (isAdmin) {
        return Admin(
          id: response['id'] as String,
          name: response['name'] as String?,
          roles: roles.isNotEmpty ? roles : [AppRole(id: 'admin')],
        );
      }

      // ---- Student ----
      if (response['student'] == null) {
        debugPrint('Données student absentes pour ${user.id}');
        return null;
      }

      return Student.fromMap(response);
    } catch (e, s) {
      debugPrint('❌ Échec de getUser(): $e');
      debugPrint('Stack trace: $s');
      return null;
    }
  }

  List<AppRole> _parseRoles(dynamic rolesRaw) {
    final roles = <AppRole>[];

    if (rolesRaw is List) {
      for (final item in rolesRaw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);

        if (map['app_role'] != null) {
          roles.add(
            AppRole.fromMap(Map<String, dynamic>.from(map['app_role'])),
          );
        } else if (map['role_id'] != null) {
          roles.add(AppRole(id: map['role_id'] as String));
        }
      }
    } else if (rolesRaw is Map) {
      final map = Map<String, dynamic>.from(rolesRaw);
      if (map['app_role'] != null) {
        roles.add(
          AppRole.fromMap(Map<String, dynamic>.from(map['app_role'])),
        );
      } else if (map['role_id'] != null) {
        roles.add(AppRole(id: map['role_id'] as String));
      }
    }

    return roles;
  }

  /// Inscription 100% côté Supabase (pas d'API custom) :
  /// 1. crée le compte auth
  /// 2. insère la ligne `users`
  /// 3. insère la ligne `students` (phone/branch, subscription_status
  ///    reste "inactive" par défaut — seul un admin peut l'activer)
  /// 4. assigne le rôle 'student' dans `user_roles`
  ///
  /// Nécessite les policies RLS d'insertion (voir rls_patch_manual_signup.sql).
  // Future<bool> createUser({
  //   required String email,
  //   required String password,
  //   required String name,
  //   String? phone,
  //   String? branch,
  //   String? photoUrl,
  //   DateTime? createdAt,
  // }) async {
  //   try {
  //     // ==========================================================
  //     // 1. Créer l'utilisateur dans Supabase Auth
  //     // ==========================================================

  //     final authResponse = await clientSpb.auth.signUp(
  //       email: email.trim(),
  //       password: password,
  //     );

  //     if (authResponse.user == null) {
  //       debugPrint(
  //         '❌ Échec création utilisateur : utilisateur null',
  //       );
  //       print('eeeee');
  //       return false;
  //     }

  //     final userId = authResponse.user!.id;

  //     debugPrint(
  //       '✅ Utilisateur Auth créé : $userId',
  //     );

  //     // ==========================================================
  //     // 2. Créer le profil dans public.users
  //     // ==========================================================

  //     await clientSpb.from('users').insert({
  //       'id': userId,
  //       'email': email.trim(),
  //       'name': name.trim(),
  //     });

  //     debugPrint(
  //       '✅ Profil users créé',
  //     );

  //     // ==========================================================
  //     // 3. Créer le profil étudiant
  //     // ==========================================================

  //     await clientSpb.from('students').insert({
  //       'id': userId,
  //       'phone': phone,
  //       'branch': branch,
  //       'photo_url': photoUrl,

  //       // L'étudiant commence toujours avec un abonnement
  //       // inactif.
  //       'subscription_status': 'inactive',

  //       'created_at':
  //           createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
  //     });

  //     debugPrint(
  //       '✅ Profil étudiant créé',
  //     );

  //     // ==========================================================
  //     // 4. Donner automatiquement le rôle student
  //     // ==========================================================

  //     await clientSpb.from('user_roles').insert({
  //       'user_id': userId,
  //       'role_id': 'student',
  //     });

  //     debugPrint(
  //       '✅ Rôle student attribué',
  //     );

  //     return true;
  //   } on AuthApiException catch (e) {
  //     debugPrint(
  //       '⚠️ AuthApiException : ${e.message}',
  //     );

  //     return false;
  //   } catch (e, stackTrace) {
  //     debugPrint(
  //       '❌ Échec createUser : $e',
  //     );

  //     debugPrint(
  //       'Stack trace : $stackTrace',
  //     );

  //     return false;
  //   }
  // }

  Future<bool> createUser({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? branch,
    String? photoUrl,
    DateTime? createdAt,
  }) async {
    try {
      final authResponse = await clientSpb.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'name': name.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
          if (branch != null && branch.trim().isNotEmpty)
            'branch': branch.trim(),
          if (photoUrl != null && photoUrl.isNotEmpty) 'photo_url': photoUrl,
        },
      );

      if (authResponse.user == null) {
        debugPrint('❌ Échec création utilisateur : utilisateur null');
        return false;
      }

      debugPrint('✅ Utilisateur Auth créé : ${authResponse.user!.id}');
      // Le trigger a déjà créé users + students (avec phone/branch) + user_roles
      return true;
    } on AuthApiException catch (e) {
      debugPrint('⚠️ AuthApiException : ${e.message}');
      return false;
    } catch (e, stackTrace) {
      debugPrint('❌ Échec createUser : $e');
      debugPrint('Stack trace : $stackTrace');
      return false;
    }
  }

  /// Mise à jour du profil student (name -> users, reste -> students).
  /// subscription_status n'est volontairement PAS modifiable ici :
  /// protégé côté DB par le trigger protect_subscription_status.
  Future<bool> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? branch,
    String? photoUrl,
  }) async {
    try {
      if (name != null && name.trim().isNotEmpty) {
        await clientSpb
            .from('users')
            .update({'name': name.trim()}).eq('id', userId);
      }

      final studentUpdates = <String, dynamic>{};
      if (phone != null && phone.trim().isNotEmpty)
        studentUpdates['phone'] = phone.trim();
      if (branch != null && branch.trim().isNotEmpty)
        studentUpdates['branch'] = branch.trim();
      if (photoUrl != null && photoUrl.isNotEmpty)
        studentUpdates['photo_url'] = photoUrl;

      if (studentUpdates.isNotEmpty) {
        await clientSpb
            .from('students')
            .update(studentUpdates)
            .eq('id', userId);
      }

      return true;
    } catch (e, s) {
      print('❌ updateProfile() failed: $e');
      print('Stack trace: $s');
      return false;
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = clientSpb.auth.currentUser;
      final email = user?.email?.trim();

      if (email == null || email.isEmpty) {
        return 'Utilisateur non connecté';
      }

      // 1. Vérifier l'ancien mot de passe
      try {
        await clientSpb.auth.signInWithPassword(
          email: email,
          password: currentPassword,
        );
      } on AuthApiException catch (e) {
        // Mot de passe actuel faux
        if (e.statusCode == '400' ||
            e.message.toLowerCase().contains('invalid') ||
            e.message.toLowerCase().contains('credentials')) {
          return 'Ancien mot de passe incorrect';
        }
        return e.message;
      }

      // 2. Mettre à jour
      final update = await clientSpb.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (update.user == null) {
        return 'Échec de la mise à jour du mot de passe';
      }

      return null; // succès
    } on AuthApiException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }
}
