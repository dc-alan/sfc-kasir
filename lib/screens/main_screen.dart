import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/user.dart';
import '../utils/responsive_helper.dart';
import 'dashboard_screen.dart';
import 'pos_screen.dart';
import 'products_screen.dart';
import 'transactions_screen.dart';
import 'reports_screen_tabbed.dart';
import 'user_management_screen.dart';
import 'profile_screen.dart';
import 'cashier_reports_screen.dart';
import 'settings_screen.dart';
import 'promotions_screen.dart';
import 'customer_analytics_screen.dart';
import 'inventory_management_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      context.read<TransactionProvider>().loadTransactions();
    });
  }

  List<Widget> _getScreensForRole(UserRole? role) {
    switch (role) {
      case UserRole.owner:
        return _getOwnerScreens();
      case UserRole.cashier:
        return _getCashierScreens();
      default:
        return _getAdminScreens();
    }
  }

  List<Widget> _getOwnerScreens() {
    return const [
      DashboardScreen(),
      ProductsScreen(),
      TransactionsScreen(),
      ReportsScreenTabbed(),
      ProfileScreen(),
    ];
  }

  List<Widget> _getCashierScreens() {
    return const [POSScreen(), CashierReportsScreen(), ProfileScreen()];
  }

  List<Widget> _getAdminScreens() {
    return const [
      DashboardScreen(),
      POSScreen(),
      ProductsScreen(),
      TransactionsScreen(),
      ReportsScreenTabbed(),
      PromotionsScreen(),
      UserManagementScreen(),
      ProfileScreen(),
      // Add ModulePermissionManagementScreen to admin screens
      // Note: Import statement for ModulePermissionManagementScreen should be added at the top
    ];
  }

  List<BottomNavigationBarItem> _getNavItemsForRole(UserRole? role) {
    switch (role) {
      case UserRole.owner:
        return _getOwnerNavItems();
      case UserRole.cashier:
        return _getCashierNavItems();
      default:
        return _getAdminNavItems();
    }
  }

  List<BottomNavigationBarItem> _getOwnerNavItems() {
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
      BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Produk'),
      BottomNavigationBarItem(
        icon: Icon(Icons.receipt_long),
        label: 'Transaksi',
      ),
      BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Laporan'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ];
  }

  List<BottomNavigationBarItem> _getCashierNavItems() {
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Kasir'),
      BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Laporan'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ];
  }

  List<BottomNavigationBarItem> _getAdminNavItems() {
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
      BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Kasir'),
      BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Produk'),
      BottomNavigationBarItem(
        icon: Icon(Icons.receipt_long),
        label: 'Transaksi',
      ),
      BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Laporan'),
      BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'Promo'),
      BottomNavigationBarItem(icon: Icon(Icons.people), label: 'User'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      // Add navigation item for ModulePermissionManagementScreen
      // BottomNavigationBarItem(icon: Icon(Icons.security), label: 'Hak Akses'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        final screens = _getScreensForRole(user?.role);
        final navItems = _getNavItemsForRole(user?.role);

        if (_currentIndex >= screens.length) {
          _currentIndex = 0;
        }

        return ResponsiveBuilder(
          builder: (context, isMobile, isTablet, isDesktop) {
            return ResponsiveOrientationBuilder(
              builder: (context, isPortrait, isLandscape) {
                final useBottomNav =
                    isMobile && isPortrait && navItems.length > 1;
                final useNavigationRail =
                    (isTablet || isDesktop) || (isMobile && isLandscape);
                final showDrawer = isMobile && isLandscape;

                if (useNavigationRail && !showDrawer) {
                  return _buildNavigationRailLayout(screens, navItems, user);
                } else {
                  return _buildStandardLayout(
                    screens,
                    navItems,
                    user,
                    useBottomNav,
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStandardLayout(
    List<Widget> screens,
    List<BottomNavigationBarItem> navItems,
    User? user,
    bool useBottomNav,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getScreenTitle(user?.role, _currentIndex),
          style: ResponsiveHelper.getHeadingStyle(context).copyWith(
            color: Colors.white,
            fontSize: ResponsiveHelper.isMobile(context) ? 18 : 20,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        toolbarHeight: ResponsiveHelper.getAppBarHeight(context),
        actions: [
          if (_currentIndex == 0 && user?.role != UserRole.cashier)
            IconButton(
              icon: Icon(
                Icons.refresh,
                size: ResponsiveHelper.getIconSize(context) - 4,
              ),
              onPressed: _refreshCurrentScreen,
            ),
          if (ResponsiveHelper.isLandscape(context)) const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ResponsiveHelper.adaptiveContainer(
          context: context,
          padding: EdgeInsets.zero,
          child: IndexedStack(index: _currentIndex, children: screens),
        ),
      ),
      bottomNavigationBar: useBottomNav
          ? _buildBottomNavigationBar(navItems)
          : null,
      drawer: _buildDrawer(),
    );
  }

  Widget _buildNavigationRailLayout(
    List<Widget> screens,
    List<BottomNavigationBarItem> navItems,
    User? user,
  ) {
    return Scaffold(
      body: Row(
        children: [
          _buildNavigationRail(navItems),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Column(
              children: [
                _buildCustomAppBar(user),
                Expanded(
                  child: IndexedStack(index: _currentIndex, children: screens),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail(List<BottomNavigationBarItem> navItems) {
    return NavigationRail(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      labelType: ResponsiveHelper.isDesktop(context)
          ? NavigationRailLabelType.all
          : NavigationRailLabelType.selected,
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      selectedIconTheme: IconThemeData(
        color: Theme.of(context).primaryColor,
        size: ResponsiveHelper.getIconSize(context),
      ),
      unselectedIconTheme: IconThemeData(
        color: Colors.grey.shade600,
        size: ResponsiveHelper.getIconSize(context) - 4,
      ),
      selectedLabelTextStyle: TextStyle(
        color: Theme.of(context).primaryColor,
        fontWeight: FontWeight.w600,
        fontSize: ResponsiveHelper.isMobile(context) ? 12 : 14,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: Colors.grey.shade600,
        fontSize: ResponsiveHelper.isMobile(context) ? 11 : 13,
      ),
      destinations: navItems.map((item) {
        return NavigationRailDestination(
          icon: item.icon,
          label: Text(item.label ?? ''),
        );
      }).toList(),
      leading: _buildNavigationRailHeader(),
      trailing: _buildNavigationRailFooter(),
    );
  }

  Widget _buildNavigationRailHeader() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.store,
            color: Colors.white,
            size: ResponsiveHelper.getIconSize(context),
          ),
        ),
        const SizedBox(height: 8),
        if (ResponsiveHelper.isDesktop(context))
          Text(
            'SFC',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
              fontSize: 16,
            ),
          ),
      ],
    );
  }

  Widget _buildNavigationRailFooter() {
    return Expanded(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.settings,
                  size: ResponsiveHelper.getIconSize(context) - 4,
                ),
                onPressed: _navigateToSettings,
                tooltip: 'Pengaturan',
              ),
              IconButton(
                icon: Icon(
                  Icons.logout,
                  size: ResponsiveHelper.getIconSize(context) - 4,
                ),
                onPressed: _showLogoutDialog,
                tooltip: 'Keluar',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(User? user) {
    return Container(
      height: ResponsiveHelper.getAppBarHeight(context),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            _getScreenTitle(user?.role, _currentIndex),
            style: ResponsiveHelper.getHeadingStyle(
              context,
            ).copyWith(color: Colors.white),
          ),
          const Spacer(),
          if (_currentIndex == 0 && user?.role != UserRole.cashier)
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: Colors.white,
                size: ResponsiveHelper.getIconSize(context) - 4,
              ),
              onPressed: _refreshCurrentScreen,
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(List<BottomNavigationBarItem> navItems) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      items: navItems,
      selectedFontSize: ResponsiveHelper.isMobile(context) ? 12 : 14,
      unselectedFontSize: ResponsiveHelper.isMobile(context) ? 10 : 12,
      iconSize: ResponsiveHelper.getIconSize(context) - 4,
    );
  }

  Widget _buildDrawer() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        return Drawer(
          child: SafeArea(
            child: Column(
              children: [
                _buildDrawerHeader(user),
                Expanded(
                  child: SingleChildScrollView(child: _buildDrawerItems(user)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerHeader(User? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Color(0xFF2196F3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              user?.name.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user?.name ?? 'Unknown',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? 'unknown@email.com',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItems(User? user) {
    return Column(
      children: [
        if (user?.role != UserRole.cashier) ...[
          _buildDrawerItem(
            Icons.dashboard,
            'Dashboard',
            () => _navigateToIndex(0),
          ),
        ],
        if (user?.role == UserRole.admin || user?.role == UserRole.cashier) ...[
          _buildDrawerItem(
            Icons.point_of_sale,
            'Kasir',
            () => _navigateToIndex(user?.role == UserRole.cashier ? 0 : 1),
          ),
        ],
        if (user?.role != UserRole.cashier) ...[
          _buildDrawerItem(
            Icons.inventory,
            'Produk',
            () => _navigateToIndex(user?.role == UserRole.owner ? 1 : 2),
          ),
          _buildDrawerItem(
            Icons.receipt_long,
            'Transaksi',
            () => _navigateToIndex(user?.role == UserRole.owner ? 2 : 3),
          ),
          _buildDrawerItem(
            Icons.analytics,
            'Laporan',
            () => _navigateToIndex(user?.role == UserRole.owner ? 3 : 4),
          ),
        ],
        if (user?.role == UserRole.admin || user?.role == UserRole.owner) ...[
          _buildDrawerItem(
            Icons.assessment,
            'Laporan Kasir',
            () => _navigateToCashierReports(),
          ),
        ],
        const Divider(),
        if (user?.role == UserRole.admin) ...[
          _buildDrawerItem(
            Icons.people,
            'Manajemen User',
            () => _navigateToIndex(6),
          ),
          _buildDrawerItem(
            Icons.people_alt,
            'Customer Analytics',
            _navigateToCustomerAnalytics,
          ),
          _buildDrawerItem(
            Icons.warehouse,
            'Inventory Management',
            _navigateToInventoryManagement,
          ),
          _buildDrawerItem(
            Icons.data_usage,
            'Dummy Data Manager',
            _navigateToDummyData,
          ),
        ],
        const Divider(),
        if (user?.role == UserRole.cashier) ...[
          _buildDrawerItem(
            Icons.bluetooth,
            'Printer Bluetooth',
            _navigateToBluetoothPrinter,
          ),
        ],
        _buildDrawerItem(
          Icons.person,
          'Profile',
          () => _navigateToProfile(user),
        ),
        _buildDrawerItem(Icons.settings, 'Pengaturan', _navigateToSettings),
        _buildDrawerItem(Icons.logout, 'Keluar', _showLogoutDialog),
      ],
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _navigateToIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToProfile(User? user) {
    setState(() {
      if (user?.role == UserRole.cashier) {
        _currentIndex = 2;
      } else if (user?.role == UserRole.owner) {
        _currentIndex = 4;
      } else {
        _currentIndex = 7;
      }
    });
  }

  void _navigateToCashierReports() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CashierReportsScreen()),
    );
  }

  void _navigateToDummyData() {
    Navigator.pushNamed(context, '/dummy-data');
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _navigateToPromotions() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PromotionsScreen()),
    );
  }

  void _navigateToCustomerAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomerAnalyticsScreen()),
    );
  }

  void _navigateToInventoryManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InventoryManagementScreen(),
      ),
    );
  }

  void _navigateToBluetoothPrinter() {
    Navigator.pushNamed(context, '/bluetooth-printer');
  }

  String _getScreenTitle(UserRole? role, int index) {
    switch (role) {
      case UserRole.owner:
        return _getOwnerScreenTitle(index);
      case UserRole.cashier:
        return _getCashierScreenTitle(index);
      default:
        return _getAdminScreenTitle(index);
    }
  }

  String _getOwnerScreenTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Produk';
      case 2:
        return 'Transaksi';
      case 3:
        return 'Laporan';
      case 4:
        return 'Profile';
      default:
        return 'SFC Mobile';
    }
  }

  String _getCashierScreenTitle(int index) {
    switch (index) {
      case 0:
        return 'Kasir';
      case 1:
        return 'Laporan Kinerja Saya';
      case 2:
        return 'Profile';
      default:
        return 'SFC Mobile';
    }
  }

  String _getAdminScreenTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Kasir';
      case 2:
        return 'Produk';
      case 3:
        return 'Transaksi';
      case 4:
        return 'Laporan';
      case 5:
        return 'Promosi';
      case 6:
        return 'Manajemen User';
      case 7:
        return 'Profile';
      default:
        return 'SFC Mobile';
    }
  }

  void _refreshCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        context.read<ProductProvider>().loadProducts();
        context.read<TransactionProvider>().loadTransactions();
        break;
      case 2:
        context.read<ProductProvider>().loadProducts();
        break;
      case 3:
        context.read<TransactionProvider>().loadTransactions();
        break;
      default:
        context.read<ProductProvider>().loadProducts();
        context.read<TransactionProvider>().loadTransactions();
        break;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
