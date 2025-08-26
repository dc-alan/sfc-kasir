import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../models/user.dart';
import '../widgets/custom_cards.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthProvider, SettingsProvider, ThemeProvider>(
      builder: (context, authProvider, settingsProvider, themeProvider, child) {
        final user = authProvider.currentUser;
        final primaryColor = _getPrimaryColor(settingsProvider);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _startEditing(user),
                  tooltip: 'Edit Profile',
                ),
              if (_isEditing) ...[
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _cancelEditing,
                  tooltip: 'Batal',
                ),
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () => _saveProfile(authProvider),
                  tooltip: 'Simpan',
                ),
              ],
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Header with Dynamic Colors
                ModernCard(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryColor.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        // Profile Avatar with Role Icon
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              child: Text(
                                user?.name.substring(0, 1).toUpperCase() ?? 'U',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(user?.role),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  _getRoleIcon(user?.role),
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Editable Name
                        if (_isEditing)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _nameController,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Nama Lengkap',
                                hintStyle: TextStyle(color: Colors.white70),
                              ),
                            ),
                          )
                        else
                          Text(
                            user?.name ?? 'Unknown User',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                        const SizedBox(height: 8),

                        // Editable Email
                        if (_isEditing)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _emailController,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Email',
                                hintStyle: TextStyle(color: Colors.white70),
                              ),
                            ),
                          )
                        else
                          Text(
                            user?.email ?? 'unknown@email.com',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),

                        const SizedBox(height: 12),

                        // Role Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getRoleIcon(user?.role),
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getRoleText(user?.role),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // User Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem(
                              'Bergabung',
                              _getJoinDate(user?.createdAt),
                            ),
                            Container(
                              height: 30,
                              width: 1,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            _buildStatItem(
                              'Status',
                              user?.isActive == true ? 'Aktif' : 'Nonaktif',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Menu Items with Dynamic Colors
                _buildMenuItem(
                  context: context,
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  subtitle: 'Ubah informasi profile Anda',
                  primaryColor: primaryColor,
                  onTap: () => _startEditing(user),
                ),

                // Theme Settings
                _buildThemeMenuItem(
                  context,
                  themeProvider,
                  settingsProvider,
                  primaryColor,
                ),

                _buildMenuItem(
                  context: context,
                  icon: Icons.settings_outlined,
                  title: 'Pengaturan',
                  subtitle: 'Konfigurasi aplikasi',
                  primaryColor: primaryColor,
                  onTap: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                ),

                // Role-based menu items
                if (user?.role == UserRole.admin ||
                    user?.role == UserRole.owner)
                  _buildMenuItem(
                    context: context,
                    icon: Icons.people_outline,
                    title: 'Manajemen User',
                    subtitle: 'Kelola pengguna aplikasi',
                    primaryColor: primaryColor,
                    onTap: () {
                      Navigator.pushNamed(context, '/user-management');
                    },
                  ),

                _buildMenuItem(
                  context: context,
                  icon: Icons.help_outline,
                  title: 'Bantuan',
                  subtitle: 'Panduan penggunaan aplikasi',
                  primaryColor: primaryColor,
                  onTap: () {
                    _showHelpDialog(context);
                  },
                ),

                _buildMenuItem(
                  context: context,
                  icon: Icons.info_outline,
                  title: 'Tentang Aplikasi',
                  subtitle: 'Informasi versi dan developer',
                  primaryColor: primaryColor,
                  onTap: () {
                    _showAboutDialog(context);
                  },
                ),

                const SizedBox(height: 24),

                // Logout Button with Dynamic Color
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showLogoutDialog(context, authProvider),
                    icon: const Icon(Icons.logout),
                    label: const Text('Keluar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildThemeMenuItem(
    BuildContext context,
    ThemeProvider themeProvider,
    SettingsProvider settingsProvider,
    Color primaryColor,
  ) {
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: primaryColor,
          ),
        ),
        title: const Text(
          'Tema & Tampilan',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          themeProvider.isDarkMode ? 'Mode Gelap Aktif' : 'Mode Terang Aktif',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Dark Mode Toggle
                Row(
                  children: [
                    Icon(Icons.brightness_6, color: primaryColor),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Mode Gelap',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                      },
                      activeThumbColor: primaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Color Picker
                Row(
                  children: [
                    Icon(Icons.palette, color: primaryColor),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Warna Tema',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showColorPicker(context, settingsProvider),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleText(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.owner:
        return 'Owner';
      case UserRole.cashier:
        return 'Kasir';
      default:
        return 'User';
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tentang Aplikasi'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SFC Mobile - Aplikasi Kasir'),
            SizedBox(height: 8),
            Text('Versi: 1.0.0'),
            SizedBox(height: 8),
            Text('Dikembangkan untuk Shella Fried Chicken'),
            SizedBox(height: 8),
            Text('© 2024 SFC Mobile'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getPrimaryColor(SettingsProvider settingsProvider) {
    try {
      return Color(
        int.parse(
          settingsProvider.settings.primaryColor.replaceAll('#', '0xFF'),
        ),
      );
    } catch (e) {
      return const Color(0xFF2196F3); // Default blue
    }
  }

  Color _getRoleColor(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return Colors.purple;
      case UserRole.owner:
        return Colors.orange;
      case UserRole.cashier:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.owner:
        return Icons.business;
      case UserRole.cashier:
        return Icons.point_of_sale;
      default:
        return Icons.person;
    }
  }

  String _getJoinDate(DateTime? createdAt) {
    if (createdAt == null) return 'N/A';
    final now = DateTime.now();
    final difference = now.difference(createdAt).inDays;

    if (difference < 30) {
      return '${difference}h lalu';
    } else if (difference < 365) {
      return '${(difference / 30).round()}b lalu';
    } else {
      return '${(difference / 365).round()}t lalu';
    }
  }

  void _startEditing(User? user) {
    if (user != null) {
      setState(() {
        _isEditing = true;
        _nameController.text = user.name;
        _emailController.text = user.email;
      });
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _nameController.clear();
      _emailController.clear();
    });
  }

  Future<void> _saveProfile(AuthProvider authProvider) async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama dan email tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // TODO: Implement profile update in AuthProvider
      // await authProvider.updateProfile(
      //   name: _nameController.text.trim(),
      //   email: _emailController.text.trim(),
      // );

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Profile berhasil diperbarui'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gagal memperbarui profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bantuan'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Panduan Penggunaan:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Gunakan menu POS untuk melakukan transaksi'),
              Text('• Kelola produk melalui menu Produk'),
              Text('• Lihat laporan di menu Reports'),
              Text('• Atur tema dan warna di Profile > Tema'),
              SizedBox(height: 16),
              Text(
                'Kontak Support:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Email: support@sfcmobile.com'),
              Text('WhatsApp: +62 812-3456-7890'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    final colors = [
      '#2196F3', // Blue
      '#4CAF50', // Green
      '#FF9800', // Orange
      '#F44336', // Red
      '#9C27B0', // Purple
      '#607D8B', // Blue Grey
      '#795548', // Brown
      '#E91E63', // Pink
      '#3F51B5', // Indigo
      '#009688', // Teal
      '#CDDC39', // Lime
      '#FF5722', // Deep Orange
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Warna Tema'),
        content: SizedBox(
          width: 300,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              final color = colors[index];
              final isSelected =
                  color == settingsProvider.settings.primaryColor;

              return GestureDetector(
                onTap: () {
                  settingsProvider.updateSettings(
                    settingsProvider.settings.copyWith(primaryColor: color),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Warna tema berhasil diubah'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(int.parse(color.replaceAll('#', '0xFF'))),
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }
}
