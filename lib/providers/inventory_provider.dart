import 'package:flutter/foundation.dart';
import '../models/location.dart';
import '../models/inventory_item.dart';
import '../models/batch.dart' as batch_model;
import '../models/supplier.dart';
import '../services/inventory_service.dart';

class InventoryProvider with ChangeNotifier {
  final InventoryService _inventoryService = InventoryService();

  // State variables
  final List<Location> _locations = [];
  final List<InventoryItem> _inventoryItems = [];
  final List<StockMovement> _stockMovements = [];
  final List<batch_model.Batch> _batches = [];
  final List<Supplier> _suppliers = [];
  final List<PurchaseOrder> _purchaseOrders = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Location> get locations => List.unmodifiable(_locations);
  List<InventoryItem> get inventoryItems => List.unmodifiable(_inventoryItems);
  List<StockMovement> get stockMovements => List.unmodifiable(_stockMovements);
  List<batch_model.Batch> get batches => List.unmodifiable(_batches);
  List<Supplier> get suppliers => List.unmodifiable(_suppliers);
  List<PurchaseOrder> get purchaseOrders => List.unmodifiable(_purchaseOrders);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered getters
  List<Location> get activeLocations =>
      _locations.where((l) => l.isActive).toList();

  List<InventoryItem> get lowStockItems =>
      _inventoryItems.where((i) => i.isLowStock).toList();

  List<InventoryItem> get outOfStockItems =>
      _inventoryItems.where((i) => i.isOutOfStock).toList();

  List<InventoryItem> get itemsNeedingReorder =>
      _inventoryItems.where((i) => i.needsReorder).toList();

  List<batch_model.Batch> get expiredBatches =>
      _batches.where((b) => b.isExpired).toList();

  List<batch_model.Batch> get nearExpiryBatches =>
      _batches.where((b) => b.isNearExpiry && !b.isExpired).toList();

  List<Supplier> get activeSuppliers =>
      _suppliers.where((s) => s.isActive).toList();

  List<PurchaseOrder> get pendingPurchaseOrders => _purchaseOrders
      .where((po) => po.status == PurchaseOrderStatus.pending)
      .toList();

  List<PurchaseOrder> get overduePurchaseOrders =>
      _purchaseOrders.where((po) => po.isOverdue).toList();

  // Load data methods
  Future<void> loadLocations() async {
    _setLoading(true);
    try {
      final locations = await _inventoryService.getLocations();
      _locations.clear();
      _locations.addAll(locations);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading locations: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadInventoryItems({String? locationId}) async {
    _setLoading(true);
    try {
      final items = await _inventoryService.getInventoryItems(
        locationId: locationId,
      );
      _inventoryItems.clear();
      _inventoryItems.addAll(items);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading inventory items: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadStockMovements({
    String? locationId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _setLoading(true);
    try {
      final movements = await _inventoryService.getStockMovements(
        locationId: locationId,
        startDate: startDate,
        endDate: endDate,
      );
      _stockMovements.clear();
      _stockMovements.addAll(movements);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading stock movements: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadBatches({String? productId}) async {
    _setLoading(true);
    try {
      final batches = await _inventoryService.getBatches(productId: productId);
      _batches.clear();
      _batches.addAll(batches);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading batches: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSuppliers() async {
    _setLoading(true);
    try {
      final suppliers = await _inventoryService.getSuppliers();
      _suppliers.clear();
      _suppliers.addAll(suppliers);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading suppliers: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPurchaseOrders({String? supplierId}) async {
    _setLoading(true);
    try {
      final orders = await _inventoryService.getPurchaseOrders(
        supplierId: supplierId,
      );
      _purchaseOrders.clear();
      _purchaseOrders.addAll(orders);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading purchase orders: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Location management
  Future<void> addLocation(Location location) async {
    try {
      await _inventoryService.insertLocation(location);
      _locations.add(location);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding location: $e');
      rethrow;
    }
  }

  Future<void> updateLocation(Location location) async {
    try {
      await _inventoryService.updateLocation(location);
      final index = _locations.indexWhere((l) => l.id == location.id);
      if (index != -1) {
        _locations[index] = location;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating location: $e');
      rethrow;
    }
  }

  Future<void> deleteLocation(String locationId) async {
    try {
      await _inventoryService.deleteLocation(locationId);
      _locations.removeWhere((l) => l.id == locationId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting location: $e');
      rethrow;
    }
  }

  // Stock management
  Future<void> adjustStock({
    required String productId,
    required String locationId,
    required int quantity,
    required String reason,
    String? batchNumber,
    required String userId,
  }) async {
    try {
      await _inventoryService.adjustStock(
        productId: productId,
        locationId: locationId,
        quantity: quantity,
        reason: reason,
        batchNumber: batchNumber,
        userId: userId,
      );

      // Reload inventory items to reflect changes
      await loadInventoryItems();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adjusting stock: $e');
      rethrow;
    }
  }

  Future<void> transferStock({
    required String productId,
    required String fromLocationId,
    required String toLocationId,
    required int quantity,
    String? notes,
    String? batchNumber,
    required String userId,
  }) async {
    try {
      await _inventoryService.transferStock(
        productId: productId,
        fromLocationId: fromLocationId,
        toLocationId: toLocationId,
        quantity: quantity,
        notes: notes,
        batchNumber: batchNumber,
        userId: userId,
      );

      // Reload inventory items to reflect changes
      await loadInventoryItems();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error transferring stock: $e');
      rethrow;
    }
  }

  Future<void> receiveStock({
    required String productId,
    required String locationId,
    required int quantity,
    required double unitCost,
    String? batchNumber,
    DateTime? expiryDate,
    String? supplierId,
    String? reference,
    required String userId,
  }) async {
    try {
      await _inventoryService.receiveStock(
        productId: productId,
        locationId: locationId,
        quantity: quantity,
        unitCost: unitCost,
        batchNumber: batchNumber,
        expiryDate: expiryDate,
        supplierId: supplierId,
        reference: reference,
        userId: userId,
      );

      // Reload inventory items and batches to reflect changes
      await loadInventoryItems();
      await loadBatches();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error receiving stock: $e');
      rethrow;
    }
  }

  // Batch management
  Future<void> addBatch(batch_model.Batch batch) async {
    try {
      await _inventoryService.insertBatch(batch);
      _batches.add(batch);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding batch: $e');
      rethrow;
    }
  }

  Future<void> updateBatch(batch_model.Batch batch) async {
    try {
      await _inventoryService.updateBatch(batch);
      final index = _batches.indexWhere((b) => b.id == batch.id);
      if (index != -1) {
        _batches[index] = batch;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating batch: $e');
      rethrow;
    }
  }

  // Supplier management
  Future<void> addSupplier(Supplier supplier) async {
    try {
      await _inventoryService.insertSupplier(supplier);
      _suppliers.add(supplier);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding supplier: $e');
      rethrow;
    }
  }

  Future<void> updateSupplier(Supplier supplier) async {
    try {
      await _inventoryService.updateSupplier(supplier);
      final index = _suppliers.indexWhere((s) => s.id == supplier.id);
      if (index != -1) {
        _suppliers[index] = supplier;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating supplier: $e');
      rethrow;
    }
  }

  Future<void> deleteSupplier(String supplierId) async {
    try {
      await _inventoryService.deleteSupplier(supplierId);
      _suppliers.removeWhere((s) => s.id == supplierId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting supplier: $e');
      rethrow;
    }
  }

  // Purchase Order management
  Future<void> createPurchaseOrder(PurchaseOrder purchaseOrder) async {
    try {
      await _inventoryService.insertPurchaseOrder(purchaseOrder);
      _purchaseOrders.add(purchaseOrder);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating purchase order: $e');
      rethrow;
    }
  }

  Future<void> updatePurchaseOrder(PurchaseOrder purchaseOrder) async {
    try {
      await _inventoryService.updatePurchaseOrder(purchaseOrder);
      final index = _purchaseOrders.indexWhere(
        (po) => po.id == purchaseOrder.id,
      );
      if (index != -1) {
        _purchaseOrders[index] = purchaseOrder;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating purchase order: $e');
      rethrow;
    }
  }

  Future<void> approvePurchaseOrder(
    String purchaseOrderId,
    String approvedBy,
  ) async {
    try {
      await _inventoryService.approvePurchaseOrder(purchaseOrderId, approvedBy);
      final index = _purchaseOrders.indexWhere(
        (po) => po.id == purchaseOrderId,
      );
      if (index != -1) {
        final updatedPO = _purchaseOrders[index].copyWith(
          status: PurchaseOrderStatus.approved,
          approvedBy: approvedBy,
          approvedAt: DateTime.now(),
        );
        _purchaseOrders[index] = updatedPO;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error approving purchase order: $e');
      rethrow;
    }
  }

  Future<void> receivePurchaseOrder(String purchaseOrderId) async {
    try {
      await _inventoryService.receivePurchaseOrder(purchaseOrderId);
      final index = _purchaseOrders.indexWhere(
        (po) => po.id == purchaseOrderId,
      );
      if (index != -1) {
        final updatedPO = _purchaseOrders[index].copyWith(
          status: PurchaseOrderStatus.received,
          receivedDate: DateTime.now(),
        );
        _purchaseOrders[index] = updatedPO;
        notifyListeners();
      }

      // Reload inventory items to reflect received stock
      await loadInventoryItems();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error receiving purchase order: $e');
      rethrow;
    }
  }

  // Automatic reorder functionality
  Future<List<PurchaseOrder>> generateAutomaticReorders() async {
    try {
      final reorders = await _inventoryService.generateAutomaticReorders();
      return reorders;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error generating automatic reorders: $e');
      return [];
    }
  }

  // Utility methods
  InventoryItem? getInventoryItem(String productId, String locationId) {
    try {
      return _inventoryItems.firstWhere(
        (item) => item.productId == productId && item.locationId == locationId,
      );
    } catch (e) {
      return null;
    }
  }

  List<InventoryItem> getInventoryItemsByLocation(String locationId) {
    return _inventoryItems
        .where((item) => item.locationId == locationId)
        .toList();
  }

  List<InventoryItem> getInventoryItemsByProduct(String productId) {
    return _inventoryItems
        .where((item) => item.productId == productId)
        .toList();
  }

  List<StockMovement> getStockMovementsByProduct(String productId) {
    return _stockMovements
        .where((movement) => movement.productId == productId)
        .toList();
  }

  List<batch_model.Batch> getBatchesByProduct(String productId) {
    return _batches.where((batch) => batch.productId == productId).toList();
  }

  // Statistics and analytics
  Map<String, dynamic> getInventoryStatistics() {
    final totalItems = _inventoryItems.length;
    final lowStockCount = lowStockItems.length;
    final outOfStockCount = outOfStockItems.length;
    final totalValue = _inventoryItems.fold<double>(
      0.0,
      (sum, item) => sum + item.stockValue,
    );
    final expiredBatchCount = expiredBatches.length;
    final nearExpiryBatchCount = nearExpiryBatches.length;

    return {
      'total_items': totalItems,
      'low_stock_count': lowStockCount,
      'out_of_stock_count': outOfStockCount,
      'total_inventory_value': totalValue,
      'expired_batch_count': expiredBatchCount,
      'near_expiry_batch_count': nearExpiryBatchCount,
      'low_stock_percentage': totalItems > 0
          ? (lowStockCount / totalItems) * 100
          : 0,
      'out_of_stock_percentage': totalItems > 0
          ? (outOfStockCount / totalItems) * 100
          : 0,
    };
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Search and filter methods
  List<InventoryItem> searchInventoryItems(String query) {
    if (query.isEmpty) return _inventoryItems;

    return _inventoryItems.where((item) {
      // This would need to be enhanced to search by product name
      // For now, we'll search by product ID
      return item.productId.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  List<Supplier> searchSuppliers(String query) {
    if (query.isEmpty) return _suppliers;

    return _suppliers.where((supplier) {
      return supplier.name.toLowerCase().contains(query.toLowerCase()) ||
          supplier.code.toLowerCase().contains(query.toLowerCase()) ||
          (supplier.contactPerson?.toLowerCase().contains(
                query.toLowerCase(),
              ) ??
              false);
    }).toList();
  }
}

extension PurchaseOrderExtension on PurchaseOrder {
  PurchaseOrder copyWith({
    String? id,
    String? orderNumber,
    String? supplierId,
    String? locationId,
    DateTime? orderDate,
    DateTime? expectedDate,
    DateTime? receivedDate,
    PurchaseOrderStatus? status,
    double? subtotal,
    double? tax,
    double? discount,
    double? total,
    String? notes,
    String? createdBy,
    String? approvedBy,
    DateTime? approvedAt,
    List<PurchaseOrderItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      supplierId: supplierId ?? this.supplierId,
      locationId: locationId ?? this.locationId,
      orderDate: orderDate ?? this.orderDate,
      expectedDate: expectedDate ?? this.expectedDate,
      receivedDate: receivedDate ?? this.receivedDate,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
