import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/inventory_provider.dart';
import '../models/supplier.dart';
import '../utils/responsive_helper.dart';
import '../widgets/custom_cards.dart';
import '../widgets/loading_widgets.dart';
import '../widgets/custom_form_widgets.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() =>
      _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final inventoryProvider = context.read<InventoryProvider>();
    await Future.wait([
      inventoryProvider.loadInventoryItems(),
      inventoryProvider.loadBatches(),
      inventoryProvider.loadSuppliers(),
      inventoryProvider.loadLocations(),
      inventoryProvider.loadPurchaseOrders(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Inventori'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.inventory), text: 'Stok'),
            Tab(icon: Icon(Icons.batch_prediction), text: 'Batch'),
            Tab(icon: Icon(Icons.business), text: 'Supplier'),
            Tab(icon: Icon(Icons.shopping_cart), text: 'Purchase Order'),
          ],
        ),
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, inventoryProvider, child) {
          if (inventoryProvider.isLoading) {
            return const LoadingOverlay(
              isLoading: true,
              message: 'Memuat data inventori...',
              child: SizedBox.expand(),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildInventoryTab(inventoryProvider),
              _buildBatchTab(inventoryProvider),
              _buildSupplierTab(inventoryProvider),
              _buildPurchaseOrderTab(inventoryProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInventoryTab(InventoryProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.loadInventoryItems(),
      child: ResponsiveBuilder(
        builder: (context, isMobile, isTablet, isDesktop) {
          return SingleChildScrollView(
            padding: ResponsiveHelper.getScreenPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistics Cards
                _buildInventoryStats(provider),
                const SizedBox(height: 24),

                // Search and Filters
                _buildSearchAndFilters(),
                const SizedBox(height: 16),

                // Inventory Items List
                _buildInventoryItemsList(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInventoryStats(InventoryProvider provider) {
    final stats = provider.getInventoryStatistics();

    return ResponsiveBuilder(
      builder: (context, isMobile, isTablet, isDesktop) {
        int crossAxisCount = isMobile ? 2 : (isTablet ? 3 : 4);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            StatCard(
              title: 'Total Item',
              value: '${stats['total_items']}',
              icon: Icons.inventory,
              color: Colors.blue,
            ),
            StatCard(
              title: 'Stok Menipis',
              value: '${stats['low_stock_count']}',
              icon: Icons.warning,
              color: Colors.orange,
            ),
            StatCard(
              title: 'Stok Habis',
              value: '${stats['out_of_stock_count']}',
              icon: Icons.error,
              color: Colors.red,
            ),
            StatCard(
              title: 'Nilai Inventori',
              value: NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(stats['total_inventory_value']),
              icon: Icons.attach_money,
              color: Colors.green,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilters() {
    return ModernCard(
      child: Column(
        children: [
          CustomTextField(
            controller: _searchController,
            label: 'Cari produk...',
            prefixIcon: Icons.search,
            onChanged: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showStockAdjustmentDialog(),
                  icon: const Icon(Icons.tune),
                  label: const Text('Sesuaikan Stok'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showStockTransferDialog(),
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Transfer Stok'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryItemsList(InventoryProvider provider) {
    final items = _searchController.text.isEmpty
        ? provider.inventoryItems
        : provider.searchInventoryItems(_searchController.text);

    if (items.isEmpty) {
      return const ModernCard(
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Tidak ada item inventori'),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ModernCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.isLowStock
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.inventory,
                color: item.isLowStock ? Colors.orange : Colors.green,
              ),
            ),
            title: Text(
              item.productId, // In real app, this would be product name
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stok: ${item.currentStock}'),
                Text('Lokasi: ${item.locationId}'),
                if (item.isLowStock)
                  const Text(
                    'Stok Menipis!',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(item.stockValue),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Min: ${item.minStock}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            onTap: () => _showInventoryItemDetails(item),
          ),
        );
      },
    );
  }

  Widget _buildBatchTab(InventoryProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.loadBatches(),
      child: SingleChildScrollView(
        padding: ResponsiveHelper.getScreenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Batch Statistics
            _buildBatchStats(provider),
            const SizedBox(height: 24),

            // Batch List
            _buildBatchList(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchStats(InventoryProvider provider) {
    return ResponsiveBuilder(
      builder: (context, isMobile, isTablet, isDesktop) {
        int crossAxisCount = isMobile ? 2 : 3;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            StatCard(
              title: 'Total Batch',
              value: '${provider.batches.length}',
              icon: Icons.batch_prediction,
              color: Colors.blue,
            ),
            StatCard(
              title: 'Batch Kadaluarsa',
              value: '${provider.expiredBatches.length}',
              icon: Icons.warning,
              color: Colors.red,
            ),
            StatCard(
              title: 'Hampir Kadaluarsa',
              value: '${provider.nearExpiryBatches.length}',
              icon: Icons.schedule,
              color: Colors.orange,
            ),
          ],
        );
      },
    );
  }

  Widget _buildBatchList(InventoryProvider provider) {
    final batches = provider.batches;

    if (batches.isEmpty) {
      return const ModernCard(
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.batch_prediction_outlined,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text('Tidak ada batch'),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: batches.length,
      itemBuilder: (context, index) {
        final batch = batches[index];
        return ModernCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: batch.isExpired
                    ? Colors.red.withOpacity(0.1)
                    : batch.isNearExpiry
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.batch_prediction,
                color: batch.isExpired
                    ? Colors.red
                    : batch.isNearExpiry
                    ? Colors.orange
                    : Colors.green,
              ),
            ),
            title: Text(
              batch.batchNumber,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Produk: ${batch.productId}'),
                Text('Qty: ${batch.currentQuantity}'),
                if (batch.expiryDate != null)
                  Text(
                    'Exp: ${DateFormat('dd/MM/yyyy').format(batch.expiryDate!)}',
                    style: TextStyle(
                      color: batch.isExpired
                          ? Colors.red
                          : batch.isNearExpiry
                          ? Colors.orange
                          : null,
                    ),
                  ),
              ],
            ),
            trailing: batch.isExpired
                ? const Chip(
                    label: Text('Kadaluarsa'),
                    backgroundColor: Colors.red,
                    labelStyle: TextStyle(color: Colors.white),
                  )
                : batch.isNearExpiry
                ? const Chip(
                    label: Text('Hampir Exp'),
                    backgroundColor: Colors.orange,
                    labelStyle: TextStyle(color: Colors.white),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildSupplierTab(InventoryProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.loadSuppliers(),
      child: SingleChildScrollView(
        padding: ResponsiveHelper.getScreenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add Supplier Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAddSupplierDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Supplier'),
              ),
            ),
            const SizedBox(height: 16),

            // Supplier List
            _buildSupplierList(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierList(InventoryProvider provider) {
    final suppliers = provider.suppliers;

    if (suppliers.isEmpty) {
      return const ModernCard(
        child: Center(
          child: Column(
            children: [
              Icon(Icons.business_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Tidak ada supplier'),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: suppliers.length,
      itemBuilder: (context, index) {
        final supplier = suppliers[index];
        return ModernCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: supplier.isActive
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.business,
                color: supplier.isActive ? Colors.green : Colors.grey,
              ),
            ),
            title: Text(
              supplier.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kode: ${supplier.code}'),
                if (supplier.contactPerson != null)
                  Text('Kontak: ${supplier.contactPerson}'),
                if (supplier.phone != null) Text('Telp: ${supplier.phone}'),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Hapus', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditSupplierDialog(supplier);
                } else if (value == 'delete') {
                  _showDeleteSupplierDialog(supplier);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPurchaseOrderTab(InventoryProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.loadPurchaseOrders(),
      child: SingleChildScrollView(
        padding: ResponsiveHelper.getScreenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add PO Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showCreatePurchaseOrderDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Buat Purchase Order'),
              ),
            ),
            const SizedBox(height: 16),

            // PO Statistics
            _buildPOStats(provider),
            const SizedBox(height: 16),

            // PO List
            _buildPurchaseOrderList(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildPOStats(InventoryProvider provider) {
    return ResponsiveBuilder(
      builder: (context, isMobile, isTablet, isDesktop) {
        int crossAxisCount = isMobile ? 2 : 3;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            StatCard(
              title: 'Total PO',
              value: '${provider.purchaseOrders.length}',
              icon: Icons.shopping_cart,
              color: Colors.blue,
            ),
            StatCard(
              title: 'Pending',
              value: '${provider.pendingPurchaseOrders.length}',
              icon: Icons.pending,
              color: Colors.orange,
            ),
            StatCard(
              title: 'Overdue',
              value: '${provider.overduePurchaseOrders.length}',
              icon: Icons.warning,
              color: Colors.red,
            ),
          ],
        );
      },
    );
  }

  Widget _buildPurchaseOrderList(InventoryProvider provider) {
    final purchaseOrders = provider.purchaseOrders;

    if (purchaseOrders.isEmpty) {
      return const ModernCard(
        child: Center(
          child: Column(
            children: [
              Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Tidak ada purchase order'),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: purchaseOrders.length,
      itemBuilder: (context, index) {
        final po = purchaseOrders[index];
        return ModernCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getPOStatusColor(po.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.shopping_cart,
                color: _getPOStatusColor(po.status),
              ),
            ),
            title: Text(
              po.orderNumber,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Supplier: ${po.supplierId}'),
                Text(
                  'Tanggal: ${DateFormat('dd/MM/yyyy').format(po.orderDate)}',
                ),
                Text(
                  'Total: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(po.total)}',
                ),
              ],
            ),
            trailing: Chip(
              label: Text(_getPOStatusText(po.status)),
              backgroundColor: _getPOStatusColor(po.status),
              labelStyle: const TextStyle(color: Colors.white),
            ),
            onTap: () => _showPurchaseOrderDetails(po),
          ),
        );
      },
    );
  }

  Color _getPOStatusColor(status) {
    // This would need to be implemented based on PurchaseOrderStatus enum
    return Colors.blue; // Default color
  }

  String _getPOStatusText(status) {
    // This would need to be implemented based on PurchaseOrderStatus enum
    return status.toString().split('.').last;
  }

  // Dialog methods (simplified for brevity)
  void _showStockAdjustmentDialog() {
    // Implementation for stock adjustment dialog
  }

  void _showStockTransferDialog() {
    // Implementation for stock transfer dialog
  }

  void _showInventoryItemDetails(item) {
    // Implementation for inventory item details
  }

  void _showAddSupplierDialog() {
    // Implementation for add supplier dialog
  }

  void _showEditSupplierDialog(Supplier supplier) {
    // Implementation for edit supplier dialog
  }

  void _showDeleteSupplierDialog(Supplier supplier) {
    // Implementation for delete supplier dialog
  }

  void _showCreatePurchaseOrderDialog() {
    // Implementation for create purchase order dialog
  }

  void _showPurchaseOrderDetails(po) {
    // Implementation for purchase order details
  }
}
