import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/user.dart';
import '../models/permission.dart';
import '../services/database_service.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/loading_widgets.dart';
import '../widgets/custom_form_widgets.dart';
import '../widgets/custom_cards.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  UserRole? _selectedRoleFilter;
  bool? _selectedStatusFilter;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _databaseService.getAllUsers();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showSnackBar('Error loading users: $e', isError: true);
      }
    }
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers = _users.where((user) {
        final matchesSearch =
            user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesRole =
            _selectedRoleFilter == null || user.role == _selectedRoleFilter;

        final matchesStatus =
            _selectedStatusFilter == null ||
            user.isActive == _selectedStatusFilter;

        return matchesSearch && matchesRole && matchesStatus;
      }).toList();
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: const Text('Manajemen User'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Daftar User', icon: Icon(Icons.people)),
            Tab(text: 'Statistik', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildUserListTab(), _buildStatisticsTab()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserFormDialog(),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah User'),
      ).animate().scale(delay: 300.ms),
    );
  }

  Widget _buildUserListTab() {
    return Column(
      children: [
        _buildSearchAndFilterSection(),
        Expanded(child: _buildUserListContent()),
      ],
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: AppTheme.spacing12),
          _buildFilterRow(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return CustomTextField(
      controller: _searchController,
      label: 'Cari user...',
      hint: 'Nama, username, atau email',
      prefixIcon: Icons.search,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
        _filterUsers();
      },
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(child: _buildRoleFilter()),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(child: _buildStatusFilter()),
      ],
    );
  }

  Widget _buildRoleFilter() {
    return CustomDropdown<UserRole?>(
      label: 'Filter Role',
      value: _selectedRoleFilter,
      items: [
        const DropdownMenuItem(value: null, child: Text('Semua Role')),
        ...UserRole.values.map((role) {
          return DropdownMenuItem(value: role, child: Text(_getRoleText(role)));
        }),
      ],
      onChanged: (value) {
        setState(() {
          _selectedRoleFilter = value;
        });
        _filterUsers();
      },
    );
  }

  Widget _buildStatusFilter() {
    return CustomDropdown<bool?>(
      label: 'Filter Status',
      value: _selectedStatusFilter,
      items: const [
        DropdownMenuItem(value: null, child: Text('Semua Status')),
        DropdownMenuItem(value: true, child: Text('Aktif')),
        DropdownMenuItem(value: false, child: Text('Nonaktif')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedStatusFilter = value;
        });
        _filterUsers();
      },
    );
  }

  Widget _buildUserListContent() {
    if (_isLoading) {
      return const LoadingOverlay(
        isLoading: true,
        message: 'Memuat data user...',
        child: SizedBox.expand(),
      );
    }

    if (_filteredUsers.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        itemCount: _filteredUsers.length,
        itemBuilder: _buildUserListItem,
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilters =
        _searchQuery.isNotEmpty ||
        _selectedRoleFilter != null ||
        _selectedStatusFilter != null;

    return EmptyStateCard(
      icon: Icons.people_outline,
      title: hasFilters ? 'Tidak ada user yang sesuai' : 'Belum ada user',
      subtitle: hasFilters
          ? 'Coba ubah filter pencarian'
          : 'Tambahkan user pertama untuk memulai',
      actionText: _users.isEmpty ? 'Tambah User' : null,
      onAction: _users.isEmpty ? () => _showUserFormDialog() : null,
    );
  }

  Widget _buildUserListItem(BuildContext context, int index) {
    final user = _filteredUsers[index];
    return UserCard(
      name: user.name,
      username: user.username,
      role: _getRoleText(user.role),
      isActive: user.isActive,
      avatarUrl: user.avatarUrl,
      onTap: () => _showUserDetailDialog(user),
      menuItems: _buildUserMenuItems(user),
      onMenuSelected: (value) => _handleUserMenuAction(value, user),
    ).animate(delay: (index * 50).ms).fadeIn().slideX();
  }

  Widget _buildStatisticsTab() {
    final totalUsers = _users.length;
    final activeUsers = _users.where((u) => u.isActive).length;
    final inactiveUsers = totalUsers - activeUsers;

    final adminCount = _users.where((u) => u.role == UserRole.admin).length;
    final ownerCount = _users.where((u) => u.role == UserRole.owner).length;
    final cashierCount = _users.where((u) => u.role == UserRole.cashier).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Stats
          const Text(
            'Ringkasan User',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.neutral900,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),

          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total User',
                  value: totalUsers.toString(),
                  icon: Icons.people,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: StatCard(
                  title: 'User Aktif',
                  value: activeUsers.toString(),
                  icon: Icons.check_circle,
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),

          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'User Nonaktif',
                  value: inactiveUsers.toString(),
                  icon: Icons.block,
                  color: AppTheme.errorColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: StatCard(
                  title: 'Persentase Aktif',
                  value: totalUsers > 0
                      ? '${((activeUsers / totalUsers) * 100).toStringAsFixed(1)}%'
                      : '0%',
                  icon: Icons.trending_up,
                  color: AppTheme.infoColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacing32),

          // Role Distribution
          const Text(
            'Distribusi Role',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.neutral900,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),

          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Administrator',
                  value: adminCount.toString(),
                  icon: Icons.admin_panel_settings,
                  color: AppTheme.errorColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: StatCard(
                  title: 'Pemilik',
                  value: ownerCount.toString(),
                  icon: Icons.business,
                  color: AppTheme.warningColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),

          StatCard(
            title: 'Kasir',
            value: cashierCount.toString(),
            icon: Icons.point_of_sale,
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildUserMenuItems(User user) {
    final currentUser = context.read<AuthProvider>().currentUser;
    final canEdit = currentUser?.hasPermission(Permission.editUser) ?? false;
    final canDelete =
        currentUser?.hasPermission(Permission.deleteUser) ?? false;

    return [
      const PopupMenuItem(
        value: 'view',
        child: Row(
          children: [
            Icon(Icons.visibility, size: 16),
            SizedBox(width: 8),
            Text('Lihat Detail'),
          ],
        ),
      ),
      if (canEdit)
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 16),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
      PopupMenuItem(
        value: 'toggle',
        child: Row(
          children: [
            Icon(user.isActive ? Icons.block : Icons.check_circle, size: 16),
            const SizedBox(width: 8),
            Text(user.isActive ? 'Nonaktifkan' : 'Aktifkan'),
          ],
        ),
      ),
      if (canDelete && user.username != 'admin')
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 16, color: AppTheme.errorColor),
              SizedBox(width: 8),
              Text('Hapus', style: TextStyle(color: AppTheme.errorColor)),
            ],
          ),
        ),
    ];
  }

  void _handleUserMenuAction(String action, User user) {
    switch (action) {
      case 'view':
        _showUserDetailDialog(user);
        break;
      case 'edit':
        _showUserFormDialog(user: user);
        break;
      case 'toggle':
        _toggleUserStatus(user);
        break;
      case 'delete':
        _showDeleteConfirmation(user);
        break;
    }
  }

  void _showUserFormDialog({User? user}) {
    showDialog(
      context: context,
      builder: (context) => ModernUserFormDialog(
        user: user,
        onSave: user == null ? _addUser : _updateUser,
      ),
    );
  }

  void _showUserDetailDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => UserDetailDialog(user: user),
    );
  }

  Future<void> _addUser(User user) async {
    try {
      await _databaseService.insertUser(user);
      _loadUsers();
      _showSnackBar('User berhasil ditambahkan');
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _updateUser(User user) async {
    try {
      await _databaseService.updateUser(user);
      _loadUsers();
      _showSnackBar('User berhasil diupdate');
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  void _showDeleteConfirmation(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus user "${user.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          CustomButton(
            text: 'Hapus',
            type: ButtonType.danger,
            size: ButtonSize.small,
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(user);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(User user) async {
    try {
      await _databaseService.deleteUser(user.id);
      _loadUsers();
      _showSnackBar('User berhasil dihapus');
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _toggleUserStatus(User user) async {
    try {
      final updatedUser = user.copyWith(isActive: !user.isActive);
      await _databaseService.updateUser(updatedUser);
      _loadUsers();
      _showSnackBar(
        user.isActive
            ? 'User berhasil dinonaktifkan'
            : 'User berhasil diaktifkan',
      );
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.cashier:
        return 'Kasir';
      case UserRole.owner:
        return 'Pemilik';
    }
  }
}

// Modern User Form Dialog
class ModernUserFormDialog extends StatefulWidget {
  final User? user;
  final Function(User) onSave;

  const ModernUserFormDialog({super.key, this.user, required this.onSave});

  @override
  State<ModernUserFormDialog> createState() => _ModernUserFormDialogState();
}

class _ModernUserFormDialogState extends State<ModernUserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  UserRole _selectedRole = UserRole.cashier;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _nameController.text = widget.user!.name;
      _usernameController.text = widget.user!.username;
      _passwordController.text = widget.user!.password;
      _emailController.text = widget.user!.email;
      _phoneController.text = widget.user!.phone ?? '';
      _selectedRole = widget.user!.role;
      _isActive = widget.user!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusMedium),
                  topRight: Radius.circular(AppTheme.radiusMedium),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.user == null ? Icons.person_add : Icons.edit,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Text(
                    widget.user == null ? 'Tambah User Baru' : 'Edit User',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacing20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _nameController,
                        label: 'Nama Lengkap',
                        prefixIcon: Icons.person,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacing16),

                      CustomTextField(
                        controller: _usernameController,
                        label: 'Username',
                        prefixIcon: Icons.alternate_email,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Username tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacing16),

                      CustomTextField(
                        controller: _passwordController,
                        label: 'Password',
                        prefixIcon: Icons.lock,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password tidak boleh kosong';
                          }
                          if (value.length < 6) {
                            return 'Password minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacing16),

                      CustomTextField(
                        controller: _emailController,
                        label: 'Email',
                        prefixIcon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          if (!value.contains('@')) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacing16),

                      CustomTextField(
                        controller: _phoneController,
                        label: 'Nomor Telepon (Opsional)',
                        prefixIcon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: AppTheme.spacing16),

                      CustomDropdown<UserRole>(
                        label: 'Role',
                        prefixIcon: Icons.security,
                        value: _selectedRole,
                        items: UserRole.values.map((role) {
                          String roleText;
                          switch (role) {
                            case UserRole.admin:
                              roleText = 'Administrator';
                              break;
                            case UserRole.cashier:
                              roleText = 'Kasir';
                              break;
                            case UserRole.owner:
                              roleText = 'Pemilik';
                              break;
                          }
                          return DropdownMenuItem(
                            value: role,
                            child: Text(roleText),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                      const SizedBox(height: AppTheme.spacing16),

                      CustomSwitch(
                        title: 'Status Aktif',
                        subtitle: _isActive
                            ? 'User dapat login'
                            : 'User tidak dapat login',
                        value: _isActive,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              decoration: BoxDecoration(
                color: AppTheme.neutral50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppTheme.radiusMedium),
                  bottomRight: Radius.circular(AppTheme.radiusMedium),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Batal',
                      type: ButtonType.secondary,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: CustomButton(
                      text: widget.user == null ? 'Tambah' : 'Update',
                      type: ButtonType.primary,
                      isLoading: _isLoading,
                      onPressed: _saveUser,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if username already exists
      final databaseService = DatabaseService();
      final usernameExists = await databaseService.isUsernameExists(
        _usernameController.text.trim(),
        excludeId: widget.user?.id,
      );

      if (usernameExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Username sudah digunakan'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final user = User(
        id: widget.user?.id ?? const Uuid().v4(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        role: _selectedRole,
        isActive: _isActive,
        createdAt: widget.user?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onSave(user);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }
}

// User Detail Dialog
class UserDetailDialog extends StatelessWidget {
  final User user;

  const UserDetailDialog({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusMedium),
                  topRight: Radius.circular(AppTheme.radiusMedium),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    ),
                    child: Center(
                      child: Text(
                        user.initials,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '@${user.username}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Email', user.email, Icons.email),
                  if (user.phone != null)
                    _buildDetailRow('Telepon', user.phone!, Icons.phone),
                  _buildDetailRow('Role', user.roleDisplayName, Icons.security),
                  _buildDetailRow(
                    'Status',
                    user.isActive ? 'Aktif' : 'Nonaktif',
                    user.isActive ? Icons.check_circle : Icons.block,
                    valueColor: user.isActive
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                  ),
                  _buildDetailRow(
                    'Dibuat',
                    DateFormat('dd MMMM yyyy, HH:mm').format(user.createdAt),
                    Icons.calendar_today,
                  ),
                  if (user.lastLoginAt != null)
                    _buildDetailRow(
                      'Login Terakhir',
                      DateFormat(
                        'dd MMMM yyyy, HH:mm',
                      ).format(user.lastLoginAt!),
                      Icons.login,
                    ),
                ],
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              decoration: BoxDecoration(
                color: AppTheme.neutral50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppTheme.radiusMedium),
                  bottomRight: Radius.circular(AppTheme.radiusMedium),
                ),
              ),
              child: CustomButton(
                text: 'Tutup',
                type: ButtonType.primary,
                isFullWidth: true,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.neutral500),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.neutral500,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppTheme.neutral900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
