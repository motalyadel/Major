abstract class AuthModel {
  final String id;
  final String? name;
  final List<AppRole> roles;

  AppRole get currentRole => roles[0];

  AuthModel({
    required this.id,
    this.name,
    required this.roles,
  });

  Map<String, dynamic> toMap();
  AuthModel copyWith();

  static String get usersTableName => "users";

  get token => null;
}

class AppRole {
  final String id;

  AppRole({required this.id});

  factory AppRole.fromMap(Map<String, dynamic> map) {
    return AppRole(
      id: map['id'] as String,
    );
  }
}

class Admin extends AuthModel {
  Admin({
    required super.id,
    required super.roles,
    super.name,
  });

  static String get tableName => "admin";

  factory Admin.fromMap(Map<String, dynamic> map) {
    return Admin(
      id: map['id'] as String,
      name: map['name'] as String?,
      roles: List<Map<String, dynamic>>.from(map['roles'] ?? [])
          .map((item) => AppRole.fromMap(item['app_role']))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'name': name,
      };

  @override
  Admin copyWith({
    String? name,
  }) {
    return Admin(
      id: id,
      roles: roles,
      name: name ?? this.name,
    );
  }
}

enum SubscriptionStatus {
  active('active'),
  inactive('inactive');

  final String value;
  const SubscriptionStatus(this.value);

  static SubscriptionStatus fromString(String? value) {
    return SubscriptionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SubscriptionStatus.inactive,
    );
  }
}

class Student extends AuthModel {
  final String? phone;
  final String? branch;
  final String? photoUrl;
  final SubscriptionStatus subscriptionStatus;
  final DateTime? createdAt;

  Student({
    required super.id,
    required super.roles,
    super.name,
    this.phone,
    this.branch,
    this.photoUrl,
    this.subscriptionStatus = SubscriptionStatus.inactive,
    this.createdAt,
  });

  bool get isSubscribed => subscriptionStatus == SubscriptionStatus.active;

  static String get tableName => "students";

  factory Student.fromMap(Map<String, dynamic> map) {
    // ---- student (one-to-one) ----
    final dynamic studentRaw = map['student'];
    final Map<String, dynamic> studentData = studentRaw is Map<String, dynamic>
        ? studentRaw
        : (studentRaw is List && studentRaw.isNotEmpty
            ? Map<String, dynamic>.from(studentRaw.first)
            : <String, dynamic>{});

    // ---- roles (one-to-many) ----
    final dynamic rolesRaw = map['roles'];
    List<AppRole> roles = [];

    if (rolesRaw is List) {
      roles = rolesRaw.map((item) {
        if (item is Map<String, dynamic>) {
          // Format : { app_role: { id: 'student' } }
          if (item['app_role'] != null) {
            return AppRole.fromMap(
              Map<String, dynamic>.from(item['app_role']),
            );
          }
          // Format alternatif : { role_id: 'student' }
          if (item['role_id'] != null) {
            return AppRole(id: item['role_id'] as String);
          }
        }
        return AppRole(id: 'student');
      }).toList();
    } else if (rolesRaw is Map<String, dynamic>) {
      // Cas rare : un seul rôle renvoyé comme objet
      if (rolesRaw['app_role'] != null) {
        roles = [
          AppRole.fromMap(Map<String, dynamic>.from(rolesRaw['app_role']))
        ];
      } else if (rolesRaw['role_id'] != null) {
        roles = [AppRole(id: rolesRaw['role_id'] as String)];
      }
    }

    // Fallback de sécurité
    if (roles.isEmpty) {
      roles = [AppRole(id: 'student')];
    }

    return Student(
      id: map['id']?.toString() ?? '',
      name: map['name'] as String?,
      roles: roles,
      phone: studentData['phone'] as String?,
      branch: studentData['branch'] as String?,
      photoUrl: studentData['photo_url'] as String?,
      subscriptionStatus: SubscriptionStatus.fromString(
        studentData['subscription_status'] as String?,
      ),
      createdAt: studentData['created_at'] != null
          ? DateTime.tryParse(studentData['created_at'].toString())
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'branch': branch,
        'photo_url': photoUrl,
        // subscription_status volontairement absent : ne doit jamais être
        // écrit depuis le client (protégé côté DB par trigger + RLS admin-only)
        'created_at': createdAt?.toIso8601String(),
      };

  @override
  Student copyWith({
    String? id,
    String? name,
    String? phone,
    String? branch,
    String? photoUrl,
    SubscriptionStatus? subscriptionStatus,
    DateTime? createdAt,
    List<AppRole>? roles,
  }) {
    return Student(
      id: id ?? this.id,
      roles: roles ?? this.roles,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      branch: branch ?? this.branch,
      photoUrl: photoUrl ?? this.photoUrl,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
