import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/location.dart';
import '../models/inventory_item.dart';
import '../models/batch.dart' as batch_model;
import '../models/supplier.dart';
import '../services/database_service.dart';

class InventoryService {
  static final InventoryService _instance = InventoryService._internal();
  factory InventoryService() => _instance;
  InventoryService._internal();

  final DatabaseService _databaseService = DatabaseService();

  // Location operations
  Future<List<Location>> getLocations() async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'locations',
        orderBy: 'name ASC',
      );
      return List.generate(maps.length, (i) => Location.fromMap(maps[i]));
    } catch (e) {
      print('Error getting locations: $e');
      return [];
    }
  }

  Future<void> insertLocation(Location location) async {
    try {
      final db = await _databaseService.database;
      await db.insert('locations', location.toMap());
    } catch (e) {
      print('Error inserting location: $e');
      rethrow;
    }
  }

  Future<void> updateLocation(Location location) async {
    try {
      final db = await _databaseService.database;
      await db.update(
        'locations',
        location.toMap(),
        where: 'id = ?',
        whereArgs: [location.id],
      );
    } catch (e) {
      print('Error updating location: $e');
      rethrow;
    }
  }

  Future<void> deleteLocation(String locationId) async {
    try {
      final db = await _databaseService.database;
      await db.delete('locations', where: 'id = ?', whereArgs: [locationId]);
    } catch (e) {
      print('Error deleting location: $e');
      rethrow;
    }
  }

  // Inventory Item operations
  Future<List<InventoryItem>> getInventoryItems({String? locationId}) async {
    try {
      final db = await _databaseService.database;
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (locationId != null) {
        whereClause = 'WHERE location_id = ?';
        whereArgs = [locationId];
      }

      final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT * FROM inventory_items $whereClause ORDER BY product_id ASC',
        whereArgs,
      );
      return List.generate(maps.length, (i) => InventoryItem.fromMap(maps[i]));
    } catch (e) {
      print('Error getting inventory items: $e');
      return [];
    }
  }

  Future<void> insertInventoryItem(InventoryItem item) async {
    try {
      final db = await _databaseService.database;
      await db.insert('inventory_items', item.toMap());
    } catch (e) {
      print('Error inserting inventory item: $e');
      rethrow;
    }
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    try {
      final db = await _databaseService.database;
      await db.update(
        'inventory_items',
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
    } catch (e) {
      print('Error updating inventory item: $e');
      rethrow;
    }
  }

  // Stock Movement operations
  Future<List<StockMovement>> getStockMovements({
    String? locationId,
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await _databaseService.database;
      String whereClause = '';
      List<dynamic> whereArgs = [];

      List<String> conditions = [];
      if (locationId != null) {
        conditions.add('location_id = ?');
        whereArgs.add(locationId);
      }
      if (productId != null) {
        conditions.add('product_id = ?');
        whereArgs.add(productId);
      }
      if (startDate != null && endDate != null) {
        conditions.add('created_at BETWEEN ? AND ?');
        whereArgs.addAll([
          startDate.toIso8601String(),
          endDate.toIso8601String(),
        ]);
      }

      if (conditions.isNotEmpty) {
        whereClause = 'WHERE ${conditions.join(' AND ')}';
      }

      final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT * FROM stock_movements $whereClause ORDER BY created_at DESC',
        whereArgs,
      );
      return List.generate(maps.length, (i) => StockMovement.fromMap(maps[i]));
    } catch (e) {
      print('Error getting stock movements: $e');
      return [];
    }
  }

  Future<void> insertStockMovement(StockMovement movement) async {
    try {
      final db = await _databaseService.database;
      await db.insert('stock_movements', movement.toMap());
    } catch (e) {
      print('Error inserting stock movement: $e');
      rethrow;
    }
  }

  // Stock adjustment and transfer operations
  Future<void> adjustStock({
    required String productId,
    required String locationId,
    required int quantity,
    required String reason,
    String? batchNumber,
    required String userId,
  }) async {
    try {
      final db = await _databaseService.database;
      await db.transaction((txn) async {
        // Get current inventory item
        final inventoryItems = await txn.query(
          'inventory_items',
          where: 'product_id = ? AND location_id = ?',
          whereArgs: [productId, locationId],
        );

        if (inventoryItems.isNotEmpty) {
          // Update existing inventory item
          final currentItem = InventoryItem.fromMap(inventoryItems.first);
          final updatedItem = currentItem.copyWith(
            currentStock: currentItem.currentStock + quantity,
            updatedAt: DateTime.now(),
          );
          await txn.update(
            'inventory_items',
            updatedItem.toMap(),
            where: 'id = ?',
            whereArgs: [currentItem.id],
          );
        } else {
          // Create new inventory item if it doesn't exist
          final newItem = InventoryItem(
            id: const Uuid().v4(),
            productId: productId,
            locationId: locationId,
            currentStock: quantity > 0 ? quantity : 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await txn.insert('inventory_items', newItem.toMap());
        }

        // Record stock movement
        final movement = StockMovement(
          id: const Uuid().v4(),
          productId: productId,
          locationId: locationId,
          type: StockMovementType.adjustment,
          quantity: quantity,
          batchNumber: batchNumber,
          notes: reason,
          userId: userId,
          createdAt: DateTime.now(),
        );
        await txn.insert('stock_movements', movement.toMap());
      });
    } catch (e) {
      print('Error adjusting stock: $e');
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
      final db = await _databaseService.database;
      await db.transaction((txn) async {
        // Check if source location has enough stock
        final fromInventoryItems = await txn.query(
          'inventory_items',
          where: 'product_id = ? AND location_id = ?',
          whereArgs: [productId, fromLocationId],
        );

        if (fromInventoryItems.isEmpty) {
          throw Exception('Product not found in source location');
        }

        final fromItem = InventoryItem.fromMap(fromInventoryItems.first);
        if (fromItem.availableStock < quantity) {
          throw Exception('Insufficient stock in source location');
        }

        // Update source location stock
        final updatedFromItem = fromItem.copyWith(
          currentStock: fromItem.currentStock - quantity,
          updatedAt: DateTime.now(),
        );
        await txn.update(
          'inventory_items',
          updatedFromItem.toMap(),
          where: 'id = ?',
          whereArgs: [fromItem.id],
        );

        // Update or create destination location stock
        final toInventoryItems = await txn.query(
          'inventory_items',
          where: 'product_id = ? AND location_id = ?',
          whereArgs: [productId, toLocationId],
        );

        if (toInventoryItems.isNotEmpty) {
          final toItem = InventoryItem.fromMap(toInventoryItems.first);
          final updatedToItem = toItem.copyWith(
            currentStock: toItem.currentStock + quantity,
            updatedAt: DateTime.now(),
          );
          await txn.update(
            'inventory_items',
            updatedToItem.toMap(),
            where: 'id = ?',
            whereArgs: [toItem.id],
          );
        } else {
          final newToItem = InventoryItem(
            id: const Uuid().v4(),
            productId: productId,
            locationId: toLocationId,
            currentStock: quantity,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await txn.insert('inventory_items', newToItem.toMap());
        }

        // Record stock movements
        final outMovement = StockMovement(
          id: const Uuid().v4(),
          productId: productId,
          locationId: fromLocationId,
          toLocationId: toLocationId,
          type: StockMovementType.transfer,
          quantity: -quantity,
          batchNumber: batchNumber,
          notes: notes,
          userId: userId,
          createdAt: DateTime.now(),
        );
        await txn.insert('stock_movements', outMovement.toMap());

        final inMovement = StockMovement(
          id: const Uuid().v4(),
          productId: productId,
          locationId: toLocationId,
          fromLocationId: fromLocationId,
          type: StockMovementType.transfer,
          quantity: quantity,
          batchNumber: batchNumber,
          notes: notes,
          userId: userId,
          createdAt: DateTime.now(),
        );
        await txn.insert('stock_movements', inMovement.toMap());
      });
    } catch (e) {
      print('Error transferring stock: $e');
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
      final db = await _databaseService.database;
      await db.transaction((txn) async {
        // Update or create inventory item
        final inventoryItems = await txn.query(
          'inventory_items',
          where: 'product_id = ? AND location_id = ?',
          whereArgs: [productId, locationId],
        );

        if (inventoryItems.isNotEmpty) {
          final currentItem = InventoryItem.fromMap(inventoryItems.first);
          final updatedItem = currentItem.copyWith(
            currentStock: currentItem.currentStock + quantity,
            averageCost:
                ((currentItem.averageCost * currentItem.currentStock) +
                    (unitCost * quantity)) /
                (currentItem.currentStock + quantity),
            lastRestocked: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await txn.update(
            'inventory_items',
            updatedItem.toMap(),
            where: 'id = ?',
            whereArgs: [currentItem.id],
          );
        } else {
          final newItem = InventoryItem(
            id: const Uuid().v4(),
            productId: productId,
            locationId: locationId,
            currentStock: quantity,
            averageCost: unitCost,
            lastRestocked: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await txn.insert('inventory_items', newItem.toMap());
        }

        // Create batch if batch number is provided
        if (batchNumber != null) {
          final batch = batch_model.Batch(
            id: const Uuid().v4(),
            productId: productId,
            batchNumber: batchNumber,
            initialQuantity: quantity,
            currentQuantity: quantity,
            unitCost: unitCost,
            expiryDate: expiryDate,
            supplierId: supplierId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await txn.insert('batches', batch.toMap());
        }

        // Record stock movement
        final movement = StockMovement(
          id: const Uuid().v4(),
          productId: productId,
          locationId: locationId,
          type: StockMovementType.stockIn,
          quantity: quantity,
          unitCost: unitCost,
          batchNumber: batchNumber,
          reference: reference,
          userId: userId,
          createdAt: DateTime.now(),
        );
        await txn.insert('stock_movements', movement.toMap());
      });
    } catch (e) {
      print('Error receiving stock: $e');
      rethrow;
    }
  }

  // Batch operations
  Future<List<batch_model.Batch>> getBatches({String? productId}) async {
    try {
      final db = await _databaseService.database;
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (productId != null) {
        whereClause = 'WHERE product_id = ?';
        whereArgs = [productId];
      }

      final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT * FROM batches $whereClause ORDER BY expiry_date ASC',
        whereArgs,
      );
      return List.generate(
        maps.length,
        (i) => batch_model.Batch.fromMap(maps[i]),
      );
    } catch (e) {
      print('Error getting batches: $e');
      return [];
    }
  }

  Future<void> insertBatch(batch_model.Batch batch) async {
    try {
      final db = await _databaseService.database;
      await db.insert('batches', batch.toMap());
    } catch (e) {
      print('Error inserting batch: $e');
      rethrow;
    }
  }

  Future<void> updateBatch(batch_model.Batch batch) async {
    try {
      final db = await _databaseService.database;
      await db.update(
        'batches',
        batch.toMap(),
        where: 'id = ?',
        whereArgs: [batch.id],
      );
    } catch (e) {
      print('Error updating batch: $e');
      rethrow;
    }
  }

  // Supplier operations
  Future<List<Supplier>> getSuppliers() async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'suppliers',
        orderBy: 'name ASC',
      );
      return List.generate(maps.length, (i) => Supplier.fromMap(maps[i]));
    } catch (e) {
      print('Error getting suppliers: $e');
      return [];
    }
  }

  Future<void> insertSupplier(Supplier supplier) async {
    try {
      final db = await _databaseService.database;
      await db.insert('suppliers', supplier.toMap());
    } catch (e) {
      print('Error inserting supplier: $e');
      rethrow;
    }
  }

  Future<void> updateSupplier(Supplier supplier) async {
    try {
      final db = await _databaseService.database;
      await db.update(
        'suppliers',
        supplier.toMap(),
        where: 'id = ?',
        whereArgs: [supplier.id],
      );
    } catch (e) {
      print('Error updating supplier: $e');
      rethrow;
    }
  }

  Future<void> deleteSupplier(String supplierId) async {
    try {
      final db = await _databaseService.database;
      await db.delete('suppliers', where: 'id = ?', whereArgs: [supplierId]);
    } catch (e) {
      print('Error deleting supplier: $e');
      rethrow;
    }
  }

  // Purchase Order operations
  Future<List<PurchaseOrder>> getPurchaseOrders({String? supplierId}) async {
    try {
      final db = await _databaseService.database;
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (supplierId != null) {
        whereClause = 'WHERE supplier_id = ?';
        whereArgs = [supplierId];
      }

      final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT * FROM purchase_orders $whereClause ORDER BY order_date DESC',
        whereArgs,
      );

      List<PurchaseOrder> purchaseOrders = [];
      for (var map in maps) {
        // Get purchase order items
        final itemMaps = await db.query(
          'purchase_order_items',
          where: 'purchase_order_id = ?',
          whereArgs: [map['id']],
        );
        final items = itemMaps
            .map((itemMap) => PurchaseOrderItem.fromMap(itemMap))
            .toList();

        purchaseOrders.add(PurchaseOrder.fromMap(map, items));
      }

      return purchaseOrders;
    } catch (e) {
      print('Error getting purchase orders: $e');
      return [];
    }
  }

  Future<void> insertPurchaseOrder(PurchaseOrder purchaseOrder) async {
    try {
      final db = await _databaseService.database;
      await db.transaction((txn) async {
        // Insert purchase order
        await txn.insert('purchase_orders', purchaseOrder.toMap());

        // Insert purchase order items
        for (var item in purchaseOrder.items) {
          await txn.insert('purchase_order_items', item.toMap());
        }
      });
    } catch (e) {
      print('Error inserting purchase order: $e');
      rethrow;
    }
  }

  Future<void> updatePurchaseOrder(PurchaseOrder purchaseOrder) async {
    try {
      final db = await _databaseService.database;
      await db.update(
        'purchase_orders',
        purchaseOrder.toMap(),
        where: 'id = ?',
        whereArgs: [purchaseOrder.id],
      );
    } catch (e) {
      print('Error updating purchase order: $e');
      rethrow;
    }
  }

  Future<void> approvePurchaseOrder(
    String purchaseOrderId,
    String approvedBy,
  ) async {
    try {
      final db = await _databaseService.database;
      await db.update(
        'purchase_orders',
        {
          'status': PurchaseOrderStatus.approved.toString(),
          'approved_by': approvedBy,
          'approved_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [purchaseOrderId],
      );
    } catch (e) {
      print('Error approving purchase order: $e');
      rethrow;
    }
  }

  Future<void> receivePurchaseOrder(String purchaseOrderId) async {
    try {
      final db = await _databaseService.database;
      await db.transaction((txn) async {
        // Get purchase order details
        final poMaps = await txn.query(
          'purchase_orders',
          where: 'id = ?',
          whereArgs: [purchaseOrderId],
        );

        if (poMaps.isEmpty) {
          throw Exception('Purchase order not found');
        }

        final po = poMaps.first;

        // Get purchase order items
        final itemMaps = await txn.query(
          'purchase_order_items',
          where: 'purchase_order_id = ?',
          whereArgs: [purchaseOrderId],
        );

        // Receive each item into inventory
        for (var itemMap in itemMaps) {
          final item = PurchaseOrderItem.fromMap(itemMap);
          await receiveStock(
            productId: item.productId,
            locationId: po['location_id'] as String,
            quantity: item.quantity,
            unitCost: item.unitPrice,
            reference: 'PO-${po['order_number']}',
            userId: po['created_by'] as String,
          );
        }

        // Update purchase order status
        await txn.update(
          'purchase_orders',
          {
            'status': PurchaseOrderStatus.received.toString(),
            'received_date': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [purchaseOrderId],
        );
      });
    } catch (e) {
      print('Error receiving purchase order: $e');
      rethrow;
    }
  }

  // Automatic reorder functionality
  Future<List<PurchaseOrder>> generateAutomaticReorders() async {
    try {
      final db = await _databaseService.database;

      // Get items that need reordering
      final itemsNeedingReorder = await db.rawQuery('''
        SELECT ii.*, p.name as product_name, p.category
        FROM inventory_items ii
        JOIN products p ON ii.product_id = p.id
        WHERE ii.available_stock <= ii.reorder_point 
        AND ii.reorder_point > 0 
        AND ii.reorder_quantity > 0
      ''');

      if (itemsNeedingReorder.isEmpty) {
        return [];
      }

      // Group by location and create purchase orders
      Map<String, List<Map<String, dynamic>>> itemsByLocation = {};
      for (var item in itemsNeedingReorder) {
        final locationId = item['location_id'] as String;
        if (!itemsByLocation.containsKey(locationId)) {
          itemsByLocation[locationId] = [];
        }
        itemsByLocation[locationId]!.add(item);
      }

      List<PurchaseOrder> generatedOrders = [];

      for (var entry in itemsByLocation.entries) {
        final locationId = entry.key;
        final items = entry.value;

        // For simplicity, create one PO per location with default supplier
        // In a real implementation, you'd group by preferred supplier
        final orderNumber = 'AUTO-${DateTime.now().millisecondsSinceEpoch}';

        List<PurchaseOrderItem> poItems = [];
        double subtotal = 0.0;

        for (var item in items) {
          final reorderQty = item['reorder_quantity'] as int;
          final avgCost = item['average_cost'] as double;
          final lineTotal = reorderQty * avgCost;

          poItems.add(
            PurchaseOrderItem(
              id: const Uuid().v4(),
              purchaseOrderId: '', // Will be set after PO creation
              productId: item['product_id'],
              quantity: reorderQty,
              unitPrice: avgCost,
              total: lineTotal,
            ),
          );

          subtotal += lineTotal;
        }

        final purchaseOrder = PurchaseOrder(
          id: const Uuid().v4(),
          orderNumber: orderNumber,
          supplierId:
              'default-supplier', // You'd need to implement supplier selection logic
          locationId: locationId,
          orderDate: DateTime.now(),
          expectedDate: DateTime.now().add(const Duration(days: 7)),
          status: PurchaseOrderStatus.draft,
          subtotal: subtotal,
          total: subtotal,
          createdBy: 'system',
          items: poItems,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        generatedOrders.add(purchaseOrder);
      }

      return generatedOrders;
    } catch (e) {
      print('Error generating automatic reorders: $e');
      return [];
    }
  }

  // Initialize inventory tables
  Future<void> initializeInventoryTables() async {
    try {
      final db = await _databaseService.database;

      // Create locations table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS locations (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          code TEXT NOT NULL UNIQUE,
          address TEXT NOT NULL,
          phone TEXT,
          email TEXT,
          type TEXT NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1,
          manager_id TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Create inventory_items table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS inventory_items (
          id TEXT PRIMARY KEY,
          product_id TEXT NOT NULL,
          location_id TEXT NOT NULL,
          current_stock INTEGER NOT NULL DEFAULT 0,
          reserved_stock INTEGER NOT NULL DEFAULT 0,
          min_stock INTEGER NOT NULL DEFAULT 0,
          max_stock INTEGER NOT NULL DEFAULT 0,
          reorder_point INTEGER NOT NULL DEFAULT 0,
          reorder_quantity INTEGER NOT NULL DEFAULT 0,
          average_cost REAL NOT NULL DEFAULT 0.0,
          last_restocked TEXT,
          last_sold TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (product_id) REFERENCES products (id),
          FOREIGN KEY (location_id) REFERENCES locations (id),
          UNIQUE(product_id, location_id)
        )
      ''');

      // Create stock_movements table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS stock_movements (
          id TEXT PRIMARY KEY,
          product_id TEXT NOT NULL,
          location_id TEXT NOT NULL,
          from_location_id TEXT,
          to_location_id TEXT,
          type TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          unit_cost REAL NOT NULL DEFAULT 0.0,
          batch_number TEXT,
          reference TEXT,
          notes TEXT,
          user_id TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (product_id) REFERENCES products (id),
          FOREIGN KEY (location_id) REFERENCES locations (id),
          FOREIGN KEY (from_location_id) REFERENCES locations (id),
          FOREIGN KEY (to_location_id) REFERENCES locations (id),
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      ''');

      // Create batches table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS batches (
          id TEXT PRIMARY KEY,
          product_id TEXT NOT NULL,
          batch_number TEXT NOT NULL,
          lot_number TEXT,
          manufacture_date TEXT,
          expiry_date TEXT,
          initial_quantity INTEGER NOT NULL,
          current_quantity INTEGER NOT NULL,
          unit_cost REAL NOT NULL,
          supplier_id TEXT,
          notes TEXT,
          status TEXT NOT NULL DEFAULT 'BatchStatus.active',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (product_id) REFERENCES products (id),
          FOREIGN KEY (supplier_id) REFERENCES suppliers (id)
        )
      ''');

      // Create suppliers table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS suppliers (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          code TEXT NOT NULL UNIQUE,
          contact_person TEXT,
          email TEXT,
          phone TEXT,
          address TEXT,
          city TEXT,
          country TEXT,
          tax_id TEXT,
          type TEXT NOT NULL DEFAULT 'SupplierType.regular',
          status TEXT NOT NULL DEFAULT 'SupplierStatus.active',
          payment_terms TEXT NOT NULL DEFAULT 'PaymentTerms.net30',
          credit_days INTEGER NOT NULL DEFAULT 30,
          credit_limit REAL NOT NULL DEFAULT 0.0,
          current_balance REAL NOT NULL DEFAULT 0.0,
          notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Create purchase_orders table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS purchase_orders (
          id TEXT PRIMARY KEY,
          order_number TEXT NOT NULL UNIQUE,
          supplier_id TEXT NOT NULL,
          location_id TEXT NOT NULL,
          order_date TEXT NOT NULL,
          expected_date TEXT,
          received_date TEXT,
          status TEXT NOT NULL DEFAULT 'PurchaseOrderStatus.draft',
          subtotal REAL NOT NULL,
          tax REAL NOT NULL DEFAULT 0.0,
          discount REAL NOT NULL DEFAULT 0.0,
          total REAL NOT NULL,
          notes TEXT,
          created_by TEXT NOT NULL,
          approved_by TEXT,
          approved_at TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (supplier_id) REFERENCES suppliers (id),
          FOREIGN KEY (location_id) REFERENCES locations (id),
          FOREIGN KEY (created_by) REFERENCES users (id),
          FOREIGN KEY (approved_by) REFERENCES users (id)
        )
      ''');

      // Create purchase_order_items table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS purchase_order_items (
          id TEXT PRIMARY KEY,
          purchase_order_id TEXT NOT NULL,
          product_id TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          received_quantity INTEGER NOT NULL DEFAULT 0,
          unit_price REAL NOT NULL,
          discount REAL NOT NULL DEFAULT 0.0,
          total REAL NOT NULL,
          notes TEXT,
          FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders (id),
          FOREIGN KEY (product_id) REFERENCES products (id)
        )
      ''');

      // Insert default main location if not exists
      final existingLocations = await db.query('locations');
      if (existingLocations.isEmpty) {
        final mainLocation = Location(
          id: 'main-location',
          name: 'Lokasi Utama',
          code: 'MAIN',
          address: 'Alamat Utama',
          type: LocationType.headquarters,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await db.insert('locations', mainLocation.toMap());
      }
    } catch (e) {
      print('Error initializing inventory tables: $e');
      rethrow;
    }
  }
}
