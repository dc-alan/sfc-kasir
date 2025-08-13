import 'package:equatable/equatable.dart';
import '../../core/constants/permissions.dart';

enum UserRole { admin, owner, cashier }

class UserEntity extends Equatable {
  final String id;
  final String username;
  final String password;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final List<AppPermission> permissions;

  const UserEntity({
    required this.id,
    required this.username,
    required this.password,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    required this.permissions,
  });

  bool hasPermission(AppPermission permission) {
    return permissions.contains(permission);
  }

  bool hasAnyPermission(List<AppPermission> requiredPermissions) {
    return requiredPermissions.any(
      (permission) => permissions.contains(permission),
    );
  }

  bool hasAllPermissions(List<AppPermission> requiredPermissions) {
    return requiredPermissions.every(
      (permission) => permissions.contains(permission),
    );
  }

  String get initials {
    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

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

  UserEntity copyWith({
    String? id,
    String? username,
    String? password,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    List<AppPermission>? permissions,
  }) {
    return UserEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      permissions: permissions ?? this.permissions,
    );
  }

  @override
  List<Object?> get props => [
    id,
    username,
    password,
    name,
    email,
    phone,
    avatarUrl,
    role,
    isActive,
    createdAt,
    updatedAt,
    lastLoginAt,
    permissions,
  ];
}
