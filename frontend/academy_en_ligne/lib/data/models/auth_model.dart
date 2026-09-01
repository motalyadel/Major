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
    final studentData = map['student'] as Map<String, dynamic>? ?? {};
    final roleList = List<Map<String, dynamic>>.from(map['roles'] ?? []);
    final roles = roleList.map((item) => AppRole.fromMap(item['app_role'])).toList();

    return Student(
      id: map['id'] ?? '',
      name: map['name'],
      roles: roles.isNotEmpty ? roles : [AppRole(id: 'student')],
      phone: studentData['phone'],
      branch: studentData['branch'],
      photoUrl: studentData['photo_url'],
      subscriptionStatus: SubscriptionStatus.fromString(
        studentData['subscription_status'],
      ),
      createdAt: studentData['created_at'] != null
          ? DateTime.tryParse(studentData['created_at'])
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