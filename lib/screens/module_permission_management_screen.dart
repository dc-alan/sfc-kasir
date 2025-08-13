import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/module_permission.dart';
import '../providers/module_permission_provider.dart';

class ModulePermissionManagementScreen extends StatefulWidget {
  const ModulePermissionManagementScreen({Key? key}) : super(key: key);

  @override
  State<ModulePermissionManagementScreen> createState() =>
      _ModulePermissionManagementScreenState();
}

class _ModulePermissionManagementScreenState
    extends State<ModulePermissionManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showOnlyActive = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<ModulePermissionProvider>(
      context,
      listen: false,
    );
    await provider.loadModulePermissions();
  }

  void _handleMenuAction(String value) {
    final provider = Provider.of<ModulePermissionProvider>(
      context,
      listen: false,
    );
    switch (value) {
      case 'reset_defaults':
        provider.resetToDefaults();
        break;
      case 'bulk_activate':
        for (var module in provider.modulePermissions) {
          if (!module.isActive) {
            provider.toggleModuleStatus(module.id);
          }
        }
        break;
      case 'bulk_deactivate':
        for (var module in provider.modulePermissions) {
          if (module.isActive) {
            provider.toggleModuleStatus(module.id);
          }
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Hak Akses Modul'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Daftar Modul'),
            Tab(icon: Icon(Icons.analytics), text: 'Statistik'),
            Tab(icon: Icon(Icons.settings), text: 'Pengaturan'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset_defaults',
                child: Text('Reset ke Default'),
              ),
              const PopupMenuItem(
                value: 'bulk_activate',
                child: Text('Aktifkan Semua'),
              ),
              const PopupMenuItem(
                value: 'bulk_deactivate',
                child: Text('Nonaktifkan Semua'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<ModulePermissionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildModuleListTab(provider),
              _buildStatisticsTab(provider),
              _buildSettingsTab(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModuleListTab(ModulePermissionProvider provider) {
    final filteredModules = _getFilteredModules(provider);

    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              itemCount: filteredModules.length,
              itemBuilder: (context, index) {
                final module = filteredModules[index];
                return _buildModuleCard(module, provider);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari Modul',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(_showOnlyActive ? 'Aktif' : 'Semua'),
            selected: _showOnlyActive,
            onSelected: (selected) {
              setState(() {
                _showOnlyActive = selected;
              });
            },
          ),
        ],
      ),
    );
  }

  List<ModulePermission> _getFilteredModules(
    ModulePermissionProvider provider,
  ) {
    var modules = provider.modulePermissions;
    if (_showOnlyActive) {
      modules = modules.where((m) => m.isActive).toList();
    }
    if (_searchQuery.isNotEmpty) {
      modules = modules.where((m) {
        final query = _searchQuery.toLowerCase();
        return m.moduleName.toLowerCase().contains(query) ||
            m.moduleKey.toLowerCase().contains(query) ||
            m.description.toLowerCase().contains(query);
      }).toList();
    }
    return modules;
  }

  Widget _buildModuleCard(
    ModulePermission module,
    ModulePermissionProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: module.isActive ? Colors.green : Colors.grey,
          child: Icon(
            module.isActive ? Icons.check_circle : Icons.cancel,
            color: Colors.white,
          ),
        ),
        title: Text(
          module.moduleName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: module.isActive ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(module.description),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: module.allowedRoles
                  .map(
                    (role) => Chip(
                      label: Text(
                        provider.getRoleDisplayName(role),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: module.isActive,
              onChanged: (value) => _toggleModuleStatus(module, provider),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditDialog(module, provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsTab(ModulePermissionProvider provider) {
    final stats = provider.getModuleStatistics();
    final modules = provider.modulePermissions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatCard(
            'Total Modul',
            stats['total_modules'].toString(),
            Icons.apps,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Modul Aktif',
                  stats['active_modules'].toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Modul Nonaktif',
                  stats['inactive_modules'].toString(),
                  Icons.cancel,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Akses Berdasarkan Role',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildRoleAccessChart(stats['role_statistics'], provider),
          const SizedBox(height: 24),
          const Text(
            'Daftar Modul',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildModuleList(modules, provider),
        ],
      ),
    );
  }

  Widget _buildRoleAccessChart(
    Map<String, dynamic> roleStats,
    ModulePermissionProvider provider,
  ) {
    final total = roleStats.values.fold<num>(0, (sum, val) => sum + val);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: roleStats.entries.map((entry) {
            final value = entry.value as int;
            final percentage = total > 0 ? value / total : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(provider.getRoleDisplayName(entry.key)),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text('$value modul', textAlign: TextAlign.end),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleList(
    List<ModulePermission> modules,
    ModulePermissionProvider provider,
  ) {
    return Column(
      children: modules.map((module) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(module.moduleName),
            subtitle: Text(
              'Akses: ${module.allowedRoles.map(provider.getRoleDisplayName).join(', ')}',
            ),
            trailing: Icon(module.isActive ? Icons.check_circle : Icons.cancel),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSettingsTab(ModulePermissionProvider provider) {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Reset ke Default'),
              content: const Text(
                'Apakah Anda yakin ingin mereset semua hak akses modul ke pengaturan default?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Ya'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            await provider.resetToDefaults();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Hak akses modul telah direset')),
            );
          }
        },
        child: const Text('Reset Hak Akses Modul ke Default'),
      ),
    );
  }

  void _toggleModuleStatus(
    ModulePermission module,
    ModulePermissionProvider provider,
  ) {
    provider.toggleModuleStatus(module.id);
  }

  void _showEditDialog(
    ModulePermission module,
    ModulePermissionProvider provider,
  ) {
    final roles = List<String>.from(module.allowedRoles);
    final TextEditingController nameController = TextEditingController(
      text: module.moduleName,
    );
    final TextEditingController descriptionController = TextEditingController(
      text: module.description,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Hak Akses Modul'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Modul',
                      ),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Deskripsi'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Role yang diizinkan:'),
                    Wrap(
                      spacing: 8,
                      children: provider.availableRoles.map((role) {
                        final isSelected = roles.contains(role);
                        return FilterChip(
                          label: Text(provider.getRoleDisplayName(role)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                roles.add(role);
                              } else {
                                roles.remove(role);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedModule = module.copyWith(
                  moduleName: nameController.text,
                  description: descriptionController.text,
                  allowedRoles: roles,
                );
                provider.updateModulePermission(updatedModule);
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}
