import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/module_permission.dart';
import '../services/database_service.dart';

class ModulePermissionProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final List<ModulePermission> _modulePermissions = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ModulePermission> get modulePermissions =>
      List.unmodifiable(_modulePermissions);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load module permissions
  Future<void> loadModulePermissions() async {
    _setLoading(true);
    try {
      final permissions = await _databaseService.getModulePermissions();
      _modulePermissions.clear();
      _modulePermissions.addAll(permissions);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading module permissions: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Initialize default module permissions
  Future<void> initializeDefaultModules() async {
    try {
      final existingModules = await _databaseService.getModulePermissions();
      final existingKeys = existingModules.map((m) => m.moduleKey).toSet();

      for (var module in AppModule.values) {
        if (!existingKeys.contains(module.key)) {
          final permission = ModulePermission(
            id: const Uuid().v4(),
            moduleName: module.displayName,
            moduleKey: module.key,
            description: module.description,
            allowedRoles: module.defaultRoles,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await _databaseService.insertModulePermission(permission);
          _modulePermissions.add(permission);
        }
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error initializing default modules: $e');
    }
  }

  // Update module permission
  Future<void> updateModulePermission(ModulePermission permission) async {
    try {
      final updatedPermission = permission.copyWith(updatedAt: DateTime.now());

      await _databaseService.updateModulePermission(updatedPermission);

      final index = _modulePermissions.indexWhere((p) => p.id == permission.id);
      if (index != -1) {
        _modulePermissions[index] = updatedPermission;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating module permission: $e');
      rethrow;
    }
  }

  // Toggle module active status
  Future<void> toggleModuleStatus(String moduleId) async {
    try {
      final index = _modulePermissions.indexWhere((p) => p.id == moduleId);
      if (index != -1) {
        final permission = _modulePermissions[index];
        final updatedPermission = permission.copyWith(
          isActive: !permission.isActive,
          updatedAt: DateTime.now(),
        );

        await updateModulePermission(updatedPermission);
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error toggling module status: $e');
      rethrow;
    }
  }

  // Update module roles
  Future<void> updateModuleRoles(String moduleId, List<String> roles) async {
    try {
      final index = _modulePermissions.indexWhere((p) => p.id == moduleId);
      if (index != -1) {
        final permission = _modulePermissions[index];
        final updatedPermission = permission.copyWith(
          allowedRoles: roles,
          updatedAt: DateTime.now(),
        );

        await updateModulePermission(updatedPermission);
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating module roles: $e');
      rethrow;
    }
  }

  // Check if user has access to module
  bool hasModuleAccess(String moduleKey, String userRole) {
    try {
      final permission = _modulePermissions.firstWhere(
        (p) => p.moduleKey == moduleKey,
      );
      return permission.isAllowedForRole(userRole);
    } catch (e) {
      // If module not found, deny access by default
      return false;
    }
  }

  // Get modules accessible by role
  List<ModulePermission> getModulesForRole(String userRole) {
    return _modulePermissions
        .where((permission) => permission.isAllowedForRole(userRole))
        .toList();
  }

  // Get all available roles
  List<String> get availableRoles => [
    'admin',
    'owner',
    'manager',
    'cashier',
    'staff',
  ];

  // Get role display names
  String getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'owner':
        return 'Pemilik';
      case 'manager':
        return 'Manager';
      case 'cashier':
        return 'Kasir';
      case 'staff':
        return 'Staff';
      default:
        return role.toUpperCase();
    }
  }

  // Get modules by status
  List<ModulePermission> get activeModules =>
      _modulePermissions.where((p) => p.isActive).toList();

  List<ModulePermission> get inactiveModules =>
      _modulePermissions.where((p) => !p.isActive).toList();

  // Search modules
  List<ModulePermission> searchModules(String query) {
    if (query.isEmpty) return _modulePermissions;

    return _modulePermissions.where((permission) {
      return permission.moduleName.toLowerCase().contains(
            query.toLowerCase(),
          ) ||
          permission.description.toLowerCase().contains(query.toLowerCase()) ||
          permission.moduleKey.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Get module statistics
  Map<String, dynamic> getModuleStatistics() {
    final totalModules = _modulePermissions.length;
    final activeModules = _modulePermissions.where((p) => p.isActive).length;
    final inactiveModules = totalModules - activeModules;

    // Count modules by role
    final roleStats = <String, int>{};
    for (var role in availableRoles) {
      roleStats[role] = getModulesForRole(role).length;
    }

    return {
      'total_modules': totalModules,
      'active_modules': activeModules,
      'inactive_modules': inactiveModules,
      'role_statistics': roleStats,
    };
  }

  // Reset module permissions to default
  Future<void> resetToDefaults() async {
    try {
      _setLoading(true);

      // Clear existing permissions
      await _databaseService.clearModulePermissions();
      _modulePermissions.clear();

      // Reinitialize with defaults
      await initializeDefaultModules();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error resetting to defaults: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Bulk update module permissions
  Future<void> bulkUpdateModules(List<ModulePermission> permissions) async {
    try {
      _setLoading(true);

      for (var permission in permissions) {
        await _databaseService.updateModulePermission(permission);

        final index = _modulePermissions.indexWhere(
          (p) => p.id == permission.id,
        );
        if (index != -1) {
          _modulePermissions[index] = permission;
        }
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error bulk updating modules: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
