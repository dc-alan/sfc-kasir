import 'permission.dart';

enum UserRole { admin, cashier, owner }

class User {
  final String id;
  final String username;
  final String password;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final String? avatarUrl;
  final String? phone;
  final UserPermissions? customPermissions;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    this.avatarUrl,
    this.phone,
    this.customPermissions,
  });

  // Get effective permissions (custom permissions override role-based permissions)
  UserPermissions get permissions {
    return customPermissions ?? UserPermissions.fromRole(role);
  }

  // Check if user has specific permission
  bool hasPermission(Permission permission) {
    return permissions.hasPermission(permission);
  }

  // Check if user has any of the specified permissions
  bool hasAnyPermission(List<Permission> permissionList) {
    return permissions.hasAnyPermission(permissionList);
  }

  // Check if user has all of the specified permissions
  bool hasAllPermissions(List<Permission> permissionList) {
    return permissions.hasAllPermissions(permissionList);
  }

  // Get role display name
  String get roleDisplayName {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.owner:
        return 'Pemilik';
      case UserRole.cashier:
        return 'Kasir';
    }
  }

  // Get role color
  String get roleColor {
    switch (role) {
      case UserRole.admin:
        return '#EF4444'; // Red
      case UserRole.owner:
        return '#F59E0B'; // Amber
      case UserRole.cashier:
        return '#6366F1'; // Indigo
    }
  }

  // Get initials for avatar
  String get initials {
    final names = name.trim().split(' ');
    if (names.length >= 2) {
      return '${names.first[0]}${names.last[0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names.first[0].toUpperCase();
    }
    return '?';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'avatar_url': avatarUrl,
      'phone': phone,
      'custom_permissions': customPermissions?.toMap(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      name: map['name'],
      email: map['email'],
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
      ),
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      lastLoginAt: map['last_login_at'] != null
          ? DateTime.parse(map['last_login_at'])
          : null,
      avatarUrl: map['avatar_url'],
      phone: map['phone'],
      customPermissions: map['custom_permissions'] != null
          ? UserPermissions.fromMap(map['custom_permissions'])
          : null,
    );
  }

  User copyWith({
    String? id,
    String? username,
    String? password,
    String? name,
    String? email,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    String? avatarUrl,
    String? phone,
    UserPermissions? customPermissions,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      customPermissions: customPermissions ?? this.customPermissions,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, username: $username, name: $name, role: $role, isActive: $isActive)';
  }
}

// User activity log model
class UserActivity {
  final String id;
  final String userId;
  final String action;
  final String description;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final String? ipAddress;
  final String? userAgent;

  UserActivity({
    required this.id,
    required this.userId,
    required this.action,
    required this.description,
    this.metadata,
    required this.timestamp,
    this.ipAddress,
    this.userAgent,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'action': action,
      'description': description,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'ip_address': ipAddress,
      'user_agent': userAgent,
    };
  }

  factory UserActivity.fromMap(Map<String, dynamic> map) {
    return UserActivity(
      id: map['id'],
      userId: map['user_id'],
      action: map['action'],
      description: map['description'],
      metadata: map['metadata'],
      timestamp: DateTime.parse(map['timestamp']),
      ipAddress: map['ip_address'],
      userAgent: map['user_agent'],
    );
  }
}

// User session model
class UserSession {
  final String id;
  final String userId;
  final String token;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;
  final String? deviceInfo;
  final String? ipAddress;

  UserSession({
    required this.id,
    required this.userId,
    required this.token,
    required this.createdAt,
    required this.expiresAt,
    this.isActive = true,
    this.deviceInfo,
    this.ipAddress,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'token': token,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'device_info': deviceInfo,
      'ip_address': ipAddress,
    };
  }

  factory UserSession.fromMap(Map<String, dynamic> map) {
    return UserSession(
      id: map['id'],
      userId: map['user_id'],
      token: map['token'],
      createdAt: DateTime.parse(map['created_at']),
      expiresAt: DateTime.parse(map['expires_at']),
      isActive: map['is_active'] == 1,
      deviceInfo: map['device_info'],
      ipAddress: map['ip_address'],
    );
  }
}
