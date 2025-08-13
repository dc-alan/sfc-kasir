import 'package:flutter/material.dart';
import '../services/backup_service.dart';
import '../utils/app_theme.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService();
  List<Map<String, dynamic>> _backupFiles = [];
  bool _isLoading = false;
  bool _isCreatingBackup = false;

  @override
  void initState() {
    super.initState();
    _loadBackupFiles();
  }

  Future<void> _loadBackupFiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final backups = await _backupService.getAvailableBackups();
      setState(() {
        _backupFiles = backups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showErrorSnackBar('Gagal memuat daftar backup: $e');
      }
    }
  }

  Future<void> _createBackup() async {
    setState(() {
      _isCreatingBackup = true;
    });

    try {
      final backupPath = await _backupService.createBackup();

      if (mounted) {
        _showSuccessSnackBar(
          'Backup berhasil dibuat: ${backupPath.split('/').last}',
        );
        _loadBackupFiles(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Gagal membuat backup: $e');
      }
    } finally {
      setState(() {
        _isCreatingBackup = false;
      });
    }
  }

  Future<void> _restoreBackup(String backupPath, String fileName) async {
    final confirmed = await _showConfirmDialog(
      'Restore Backup',
      'Apakah Anda yakin ingin restore dari backup "$fileName"?\n\n'
          'PERINGATAN: Semua data saat ini akan diganti dengan data dari backup.',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _backupService.restoreBackup(backupPath);

      if (mounted) {
        _showSuccessSnackBar(
          'Backup berhasil di-restore. Silakan restart aplikasi.',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Gagal restore backup: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteBackup(String backupPath, String fileName) async {
    final confirmed = await _showConfirmDialog(
      'Hapus Backup',
      'Apakah Anda yakin ingin menghapus backup "$fileName"?',
    );

    if (!confirmed) return;

    try {
      await _backupService.deleteBackup(backupPath);

      if (mounted) {
        _showSuccessSnackBar('Backup berhasil dihapus');
        _loadBackupFiles(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Gagal menghapus backup: $e');
      }
    }
  }

  // Helper methods for UI feedback
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.getErrorColor(context),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Ya, Lanjutkan'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadBackupFiles,
          ),
        ],
      ),
      body: Column(
        children: [
          // Info Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            child: Card(
              color: AppTheme.infoColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.infoColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Informasi Backup',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Backup akan menyimpan semua data aplikasi\n'
                      '• File backup disimpan dalam format JSON\n'
                      '• Restore akan mengganti semua data saat ini\n'
                      '• Disarankan untuk backup secara berkala',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Create Backup Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _isCreatingBackup ? null : _createBackup,
              icon: _isCreatingBackup
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.backup),
              label: Text(
                _isCreatingBackup ? 'Membuat Backup...' : 'Buat Backup Baru',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Backup Files List
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.folder, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Text(
                            'File Backup Tersedia',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_backupFiles.length} file',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _backupFiles.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.folder_open,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Belum ada file backup',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Buat backup pertama Anda',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _backupFiles.length,
                              itemBuilder: (context, index) {
                                final backup = _backupFiles[index];
                                return _buildBackupItem(backup);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBackupItem(Map<String, dynamic> backup) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        child: Icon(Icons.archive, color: AppTheme.primaryColor),
      ),
      title: Text(
        backup['fileName'],
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dibuat: ${backup['formattedDate']}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Ukuran: ${backup['formattedSize']}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'restore':
              _restoreBackup(backup['filePath'], backup['fileName']);
              break;
            case 'delete':
              _deleteBackup(backup['filePath'], backup['fileName']);
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'restore',
            child: Row(
              children: [
                Icon(Icons.restore, size: 16, color: Colors.green),
                SizedBox(width: 8),
                Text('Restore'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 16, color: Colors.red),
                SizedBox(width: 8),
                Text('Hapus'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
