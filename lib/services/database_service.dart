import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/customer_loyalty.dart';
import '../models/user.dart';
import '../models/transaction.dart' as model;
import '../models/cart_item.dart';
import '../models/notification.dart';
import '../models/app_settings.dart';
import '../models/module_permission.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'sfc_cashier_app.db');

    return await openDatabase(
      path,
      version: 10,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Update admin user with new password
      await db.update(
        'users',
        {
          'password': 'admin132',
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'username = ?',
        whereArgs: ['admin'],
      );
    }

    if (oldVersion < 4) {
      // Ensure all sample data exists
      await _ensureSampleDataExists(db);
    }

    if (oldVersion < 5) {
      // Add promotion columns to products table
      try {
        await db.execute('ALTER TABLE products ADD COLUMN promotion_id TEXT');
        await db.execute('ALTER TABLE products ADD COLUMN discount_price REAL');
        await db.execute(
          'ALTER TABLE products ADD COLUMN has_promotion INTEGER NOT NULL DEFAULT 0',
        );
        print('Successfully added promotion columns to products table');
      } catch (e) {
        print('Error adding promotion columns (may already exist): $e');
      }
    }

    if (oldVersion < 6) {
      // Add discount_breakdown column to transactions table
      try {
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN discount_breakdown TEXT',
        );
        print(
          'Successfully added discount_breakdown column to transactions table',
        );
      } catch (e) {
        print('Error adding discount_breakdown column (may already exist): $e');
      }
    }

    if (oldVersion < 7) {
      // Add missing columns to users table
      try {
        await db.execute('ALTER TABLE users ADD COLUMN last_login_at TEXT');
        print('Successfully added last_login_at column to users table');
      } catch (e) {
        print('Error adding last_login_at column (may already exist): $e');
      }
    }

    if (oldVersion < 8) {
      // Add avatar_url and phone columns to users table
      try {
        await db.execute('ALTER TABLE users ADD COLUMN avatar_url TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN phone TEXT');
        await db.execute(
          'ALTER TABLE users ADD COLUMN custom_permissions TEXT',
        );
        print(
          'Successfully added avatar_url, phone, and custom_permissions columns to users table',
        );
      } catch (e) {
        print('Error adding user columns (may already exist): $e');
      }
    }

    if (oldVersion < 9) {
      // Add transaction_storage_days column to app_settings table
      try {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN transaction_storage_days INTEGER NOT NULL DEFAULT 30',
        );
        print(
          'Successfully added transaction_storage_days column to app_settings table',
        );
      } catch (e) {
        print(
          'Error adding transaction_storage_days column (may already exist): $e',
        );
      }
    }
  }

  // Ensure database is ready with all required data
  Future<void> ensureDatabaseReady() async {
    final db = await database;
    await _ensureSampleDataExists(db);
  }

  // Check and insert sample data if missing
  Future<void> _ensureSampleDataExists(Database db) async {
    try {
      // Check if admin user exists
      final adminExists = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: ['admin'],
      );

      if (adminExists.isEmpty) {
        await db.insert('users', {
          'id': 'admin-001',
          'username': 'admin',
          'password': 'admin132',
          'name': 'Administrator',
          'email': 'admin@admin.com',
          'role': 'admin',
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      // Check if products exist
      final productCount = await db.rawQuery(
        'SELECT COUNT(*) as count FROM products',
      );
      final count = productCount.first['count'] as int;

      if (count < 26) {
        // Delete existing products and re-insert all
        await db.delete('products');
        await _insertSampleProducts(db);
      }
    } catch (e) {
      print('Error ensuring sample data exists: $e');
    }
  }

  // Reset database to initial state
  Future<void> resetDatabase() async {
    final db = await database;

    try {
      // Clear all data
      await db.delete('transaction_items');
      await db.delete('transactions');
      await db.delete('customers');
      await db.delete('products');
      await db.delete('users');

      // Re-insert sample data
      await _insertSampleUsers(db);
      await _insertSampleProducts(db);
    } catch (e) {
      print('Error resetting database: $e');
    }
  }

  // Insert sample users
  Future<void> _insertSampleUsers(Database db) async {
    await db.insert('users', {
      'id': 'admin-001',
      'username': 'admin',
      'password': 'admin132',
      'name': 'Administrator',
      'email': 'admin@admin.com',
      'role': 'admin',
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Insert sample products
  Future<void> _insertSampleProducts(Database db) async {
    final sampleProducts = _getSampleProducts();
    for (var product in sampleProducts) {
      try {
        await db.insert(
          'products',
          product,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      } catch (e) {
        print('Error inserting product ${product['name']}: $e');
      }
    }
  }

  // Get complete sample products data
  List<Map<String, dynamic>> _getSampleProducts() {
    final now = DateTime.now().toIso8601String();

    return [
      // Aneka Geprek
      {
        'id': 'prod-001',
        'name': 'Geprek 10K',
        'description': 'Geprek 10K',
        'price': 10000.0,
        'stock': 100,
        'category': 'Makanan',
        'barcode': '1001',
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'prod-002',
        'name': 'Geprek 8K',
        'description': 'Geprek 10K',
        'price': 8000.0,
        'stock': 100,
        'category': 'Makanan',
        'barcode': '1002',
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'prod-003',
        'name': 'Geprek 7K',
        'description': 'Geprek 7K',
        'price': 7000.0,
        'stock': 50,
        'category': 'Makanan',
        'barcode': '1003',
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'prod-004',
        'name': 'Korea',
        'description': 'Korea',
        'price': 1.0,
        'stock': 50,
        'category': 'Makanan',
        'barcode': '1004',
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'prod-005',
        'name': 'Nasi',
        'description': 'Nasi',
        'price': 1.0,
        'stock': 50,
        'category': 'Makanan',
        'barcode': '1005',
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'prod-006',
        'name': 'Sambel',
        'description': 'Sambel',
        'price': 1.0,
        'stock': 50,
        'category': 'Tambahan',
        'barcode': '1006',
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'prod-007',
        'name': 'Teh',
        'description': 'Teh',
        'price': 1.0,
        'stock': 50,
        'category': 'Minuman',
        'barcode': '1007',
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'prod-008',
        'name': 'Jeruk',
        'description': 'Jeruk',
        'price': 1.0,
        'stock': 50,
        'category': 'Minuman',
        'barcode': '1008',
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'prod-009',
        'name': 'Aqua',
        'description': 'Aqua',
        'price': 1.0,
        'stock': 50,
        'category': 'Minuman',
        'barcode': '1009',
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'prod-010',
        'name': 'Krupuk',
        'description': 'Krupuk',
        'price': 15000.0,
        'stock': 50,
        'category': 'Tambahan',
        'barcode': '1010',
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'prod-011',
        'name': 'Jamur',
        'description': 'Jamur',
        'price': 1.0,
        'stock': 50,
        'category': 'Makanan',
        'barcode': '1011',
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'prod-012',
        'name': 'Kopi Hitam',
        'description': 'Kopi Hitam',
        'price': 1.0,
        'stock': 50,
        'category': 'Minuman',
        'barcode': '1012',
        'created_at': now,
        'updated_at': now,
      },

      // Shella Fried Chicken (SFC)
      {
        'id': 'prod-013',
        'name': 'White Kopi',
        'description': 'White Kopi',
        'price': 1.0,
        'stock': 50,
        'category': 'Minuman',
        'barcode': '1013',
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'prod-014',
        'name': 'Snack',
        'description': 'Snack',
        'price': 1.0,
        'stock': 50,
        'category': 'Snack',
        'barcode': '1014',
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'prod-015',
        'name': 'Pentol',
        'description': 'Pentol',
        'price': 1.0,
        'stock': 50,
        'category': 'Tambahan',
        'barcode': '1015',
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'prod-016',
        'name': 'Usus',
        'description': 'Usus',
        'price': 1.0,
        'stock': 50,
        'category': 'Tambahan',
        'barcode': '2004',
        'created_at': now,
        'updated_at': now,
      },

      // Lauk Saja
      {
        'id': 'prod-017',
        'name': 'Kotak Nasi',
        'description': 'Kotak Nasi',
        'price': 1.0,
        'stock': 50,
        'category': 'Tambahan',
        'barcode': '3001',
        'created_at': now,
        'updated_at': now,
      },
    ];
  }

  Future<void> _createTables(Database db, int version) async {
    // Products table
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        stock INTEGER NOT NULL,
        category TEXT NOT NULL,
        barcode TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        promotion_id TEXT,
        discount_price REAL,
        has_promotion INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Promotions table
    await db.execute('''
      CREATE TABLE promotions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        type TEXT NOT NULL,
        discount_type TEXT NOT NULL,
        discount_value REAL NOT NULL,
        minimum_purchase REAL,
        max_usage INTEGER,
        current_usage INTEGER NOT NULL DEFAULT 0,
        max_quantity_per_item INTEGER,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        applicable_product_ids TEXT,
        applicable_categories TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        happy_hour_start TEXT,
        happy_hour_end TEXT,
        coupon_code TEXT,
        bundle_items TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Customers table
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        address TEXT,
        birth_date TEXT,
        anniversary_date TEXT,
        segment TEXT NOT NULL DEFAULT 'regular',
        status TEXT NOT NULL DEFAULT 'active',
        notes TEXT,
        total_spent REAL NOT NULL DEFAULT 0.0,
        total_transactions INTEGER NOT NULL DEFAULT 0,
        last_visit TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Customer loyalty programs table
    await db.execute('''
      CREATE TABLE customer_loyalty (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        total_points INTEGER NOT NULL DEFAULT 0,
        lifetime_points INTEGER NOT NULL DEFAULT 0,
        tier TEXT NOT NULL DEFAULT 'bronze',
        join_date TEXT NOT NULL,
        last_activity TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    // Point transactions table
    await db.execute('''
      CREATE TABLE point_transactions (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        points INTEGER NOT NULL,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        transaction_id TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    // Customer history table
    await db.execute('''
      CREATE TABLE customer_history (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        transaction_id TEXT NOT NULL,
        amount REAL NOT NULL,
        items TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers (id),
        FOREIGN KEY (transaction_id) REFERENCES transactions (id)
      )
    ''');

    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        role TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_login_at TEXT,
        avatar_url TEXT,
        phone TEXT,
        custom_permissions TEXT
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        subtotal REAL NOT NULL,
        tax REAL NOT NULL,
        discount REAL NOT NULL,
        total REAL NOT NULL,
        payment_method TEXT NOT NULL,
        amount_paid REAL NOT NULL,
        change REAL NOT NULL,
        customer_id TEXT,
        cashier_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers (id),
        FOREIGN KEY (cashier_id) REFERENCES users (id)
      )
    ''');

    // Transaction items table
    await db.execute('''
      CREATE TABLE transaction_items (
        id TEXT PRIMARY KEY,
        transaction_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // Notifications table
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        user_id TEXT,
        is_read INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Module permissions table
    await db.execute('''
      CREATE TABLE module_permissions (
        id TEXT PRIMARY KEY,
        module_name TEXT NOT NULL,
        module_key TEXT NOT NULL UNIQUE,
        description TEXT NOT NULL,
        allowed_roles TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // App Settings table
    await db.execute('''
      CREATE TABLE app_settings (
        id INTEGER PRIMARY KEY DEFAULT 1,
        app_name TEXT NOT NULL DEFAULT 'SFC Mobile',
        app_version TEXT NOT NULL DEFAULT '1.0.0',
        primary_color TEXT NOT NULL DEFAULT '#2196F3',
        secondary_color TEXT NOT NULL DEFAULT '#03DAC6',
        logo_path TEXT DEFAULT '',
        splash_screen_duration TEXT NOT NULL DEFAULT '3',
        show_splash_screen INTEGER NOT NULL DEFAULT 1,
        
        receipt_header TEXT NOT NULL DEFAULT 'STRUK PEMBELIAN',
        receipt_footer TEXT NOT NULL DEFAULT 'Terima kasih atas kunjungan Anda',
        business_name TEXT NOT NULL DEFAULT 'Shella Fried Chicken',
        business_address TEXT NOT NULL DEFAULT 'Jl. Contoh No. 123, Kota',
        business_phone TEXT NOT NULL DEFAULT '0812-3456-7890',
        business_email TEXT NOT NULL DEFAULT 'info@sfc.com',
        show_business_logo INTEGER NOT NULL DEFAULT 1,
        print_customer_info INTEGER NOT NULL DEFAULT 1,
        print_item_details INTEGER NOT NULL DEFAULT 1,
        receipt_paper_size TEXT NOT NULL DEFAULT '80mm',
        
        is_dark_mode INTEGER NOT NULL DEFAULT 0,
        font_family TEXT NOT NULL DEFAULT 'Roboto',
        font_size REAL NOT NULL DEFAULT 14.0,
        language TEXT NOT NULL DEFAULT 'id',
        
        enable_notifications INTEGER NOT NULL DEFAULT 1,
        enable_sounds INTEGER NOT NULL DEFAULT 1,
        auto_backup INTEGER NOT NULL DEFAULT 0,
        auto_backup_interval INTEGER NOT NULL DEFAULT 24,
        backup_location TEXT NOT NULL DEFAULT 'local',
        transaction_storage_days INTEGER NOT NULL DEFAULT 30
      )
    ''');

    // Insert default admin user with new password
    await db.insert('users', {
      'id': 'admin-001',
      'username': 'admin',
      'password': 'admin132',
      'name': 'Administrator',
      'email': 'admin@admin.com',
      'role': 'admin',
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    await db.insert('users', {
      'id': 'kasir-001',
      'username': 'kasir',
      'password': 'kasir132',
      'name': 'kasir',
      'email': 'admin@kasir.com',
      'role': 'cashier',
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Insert sample products
    final sampleProducts = _getSampleProducts();
    for (var product in sampleProducts) {
      await db.insert('products', product);
    }
  }

  // Product operations
  Future<List<Product>> getProducts() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'products',
        orderBy: 'name ASC',
      );
      return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
    } catch (e) {
      print('Error getting products: $e');
      return [];
    }
  }

  Future<Product?> getProduct(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return Product.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting product: $e');
      return null;
    }
  }

  Future<void> insertProduct(Product product) async {
    try {
      final db = await database;
      await db.insert('products', product.toMap());
    } catch (e) {
      print('Error inserting product: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      final db = await database;
      await db.update(
        'products',
        product.toMap(),
        where: 'id = ?',
        whereArgs: [product.id],
      );
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      final db = await database;
      await db.delete('products', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }

  // Customer operations
  Future<List<Customer>> getCustomers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('customers');
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  Future<void> insertCustomer(Customer customer) async {
    final db = await database;
    await db.insert('customers', customer.toMap());
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      final db = await database;
      await db.update(
        'customers',
        customer.toMap(),
        where: 'id = ?',
        whereArgs: [customer.id],
      );
    } catch (e) {
      print('Error updating customer: $e');
      rethrow;
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    try {
      final db = await database;
      await db.delete('customers', where: 'id = ?', whereArgs: [customerId]);
      await db.delete(
        'customer_loyalty',
        where: 'customer_id = ?',
        whereArgs: [customerId],
      );
      await db.delete(
        'point_transactions',
        where: 'customer_id = ?',
        whereArgs: [customerId],
      );
      await db.delete(
        'customer_history',
        where: 'customer_id = ?',
        whereArgs: [customerId],
      );
    } catch (e) {
      print('Error deleting customer: $e');
      rethrow;
    }
  }

  // Customer loyalty operations
  Future<List<CustomerLoyalty>> getLoyaltyPrograms() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'customer_loyalty',
      );

      List<CustomerLoyalty> loyaltyPrograms = [];
      for (var map in maps) {
        // Get point history for this customer
        final pointHistory = await getPointTransactions(map['customer_id']);

        loyaltyPrograms.add(
          CustomerLoyalty(
            id: map['id'],
            customerId: map['customer_id'],
            totalPoints: map['total_points'],
            lifetimePoints: map['lifetime_points'],
            tier: CustomerTier.values.firstWhere(
              (e) => e.toString() == 'CustomerTier.${map['tier']}',
              orElse: () => CustomerTier.bronze,
            ),
            joinDate: DateTime.parse(map['join_date']),
            lastActivity: DateTime.parse(map['last_activity']),
            pointHistory: pointHistory,
          ),
        );
      }

      return loyaltyPrograms;
    } catch (e) {
      print('Error getting loyalty programs: $e');
      return [];
    }
  }

  Future<void> insertLoyaltyProgram(CustomerLoyalty loyalty) async {
    try {
      final db = await database;
      await db.insert('customer_loyalty', {
        'id': loyalty.id,
        'customer_id': loyalty.customerId,
        'total_points': loyalty.totalPoints,
        'lifetime_points': loyalty.lifetimePoints,
        'tier': loyalty.tier.toString().split('.').last,
        'join_date': loyalty.joinDate.toIso8601String(),
        'last_activity': loyalty.lastActivity.toIso8601String(),
      });
    } catch (e) {
      print('Error inserting loyalty program: $e');
      rethrow;
    }
  }

  Future<void> updateLoyaltyProgram(CustomerLoyalty loyalty) async {
    try {
      final db = await database;
      await db.update(
        'customer_loyalty',
        {
          'total_points': loyalty.totalPoints,
          'lifetime_points': loyalty.lifetimePoints,
          'tier': loyalty.tier.toString().split('.').last,
          'last_activity': loyalty.lastActivity.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [loyalty.id],
      );

      // Insert new point transactions
      for (var pointTransaction in loyalty.pointHistory) {
        await db.insert(
          'point_transactions',
          pointTransaction.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    } catch (e) {
      print('Error updating loyalty program: $e');
      rethrow;
    }
  }

  Future<List<PointTransaction>> getPointTransactions(String customerId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'point_transactions',
        where: 'customer_id = ?',
        whereArgs: [customerId],
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => PointTransaction.fromMap(map)).toList();
    } catch (e) {
      print('Error getting point transactions: $e');
      return [];
    }
  }

  // Customer history operations
  Future<List<CustomerHistory>> getCustomerHistory(String customerId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'customer_history',
        where: 'customer_id = ?',
        whereArgs: [customerId],
        orderBy: 'date DESC',
      );

      return maps.map((map) => CustomerHistory.fromMap(map)).toList();
    } catch (e) {
      print('Error getting customer history: $e');
      return [];
    }
  }

  Future<void> insertCustomerHistory(CustomerHistory history) async {
    try {
      final db = await database;
      await db.insert('customer_history', history.toMap());
    } catch (e) {
      print('Error inserting customer history: $e');
      rethrow;
    }
  }

  // User operations
  Future<User?> getUser(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ? AND is_active = 1',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  Future<User?> getUserById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert('users', user.toMap());
  }

  Future<void> updateUser(User user) async {
    final db = await database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> deleteUser(String id) async {
    final db = await database;
    await db.update(
      'users',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> activateUser(String id) async {
    final db = await database;
    await db.update(
      'users',
      {'is_active': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> isUsernameExists(String username, {String? excludeId}) async {
    final db = await database;
    String whereClause = 'username = ?';
    List<dynamic> whereArgs = [username];

    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: whereClause,
      whereArgs: whereArgs,
    );
    return maps.isNotEmpty;
  }

  Future<User?> authenticateUser(String username, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ? AND password = ? AND is_active = 1',
      whereArgs: [username, password],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // Transaction operations
  Future<void> insertTransaction(model.Transaction transaction) async {
    final db = await database;
    await db.transaction((txn) async {
      // Insert transaction
      await txn.insert('transactions', transaction.toMap());

      // Insert transaction items
      for (var item in transaction.items) {
        await txn.insert('transaction_items', {
          'id': item.id,
          'transaction_id': transaction.id,
          'product_id': item.product.id,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'discount': item.discount,
        });

        // Update product stock
        await txn.rawUpdate(
          'UPDATE products SET stock = stock - ? WHERE id = ?',
          [item.quantity, item.product.id],
        );
      }
    });
  }

  Future<void> updateTransaction(model.Transaction transaction) async {
    final db = await database;
    await db.transaction((txn) async {
      // Get original transaction to restore stock
      final originalTransactionMaps = await txn.rawQuery(
        '''
        SELECT ti.*, p.* FROM transaction_items ti
        JOIN products p ON ti.product_id = p.id
        WHERE ti.transaction_id = ?
        ''',
        [transaction.id],
      );

      // Restore stock from original transaction
      for (var itemMap in originalTransactionMaps) {
        await txn.rawUpdate(
          'UPDATE products SET stock = stock + ? WHERE id = ?',
          [itemMap['quantity'], itemMap['product_id']],
        );
      }

      // Delete old transaction items
      await txn.delete(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [transaction.id],
      );

      // Update transaction
      await txn.update(
        'transactions',
        transaction.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );

      // Insert new transaction items
      for (var item in transaction.items) {
        await txn.insert('transaction_items', {
          'id': item.id,
          'transaction_id': transaction.id,
          'product_id': item.product.id,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'discount': item.discount,
        });

        // Update product stock with new quantities
        await txn.rawUpdate(
          'UPDATE products SET stock = stock - ? WHERE id = ?',
          [item.quantity, item.product.id],
        );
      }
    });
  }

  Future<void> deleteTransaction(String transactionId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Get transaction items to restore stock
      final itemMaps = await txn.rawQuery(
        '''
        SELECT ti.*, p.* FROM transaction_items ti
        JOIN products p ON ti.product_id = p.id
        WHERE ti.transaction_id = ?
        ''',
        [transactionId],
      );

      // Restore stock
      for (var itemMap in itemMaps) {
        await txn.rawUpdate(
          'UPDATE products SET stock = stock + ? WHERE id = ?',
          [itemMap['quantity'], itemMap['product_id']],
        );
      }

      // Delete transaction items
      await txn.delete(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [transactionId],
      );

      // Delete transaction
      await txn.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [transactionId],
      );
    });
  }

  Future<model.Transaction?> getTransactionById(String transactionId) async {
    final db = await database;

    // Get transaction
    final List<Map<String, dynamic>> transactionMaps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );

    if (transactionMaps.isEmpty) return null;

    final transactionMap = transactionMaps.first;

    // Get transaction items
    final List<Map<String, dynamic>> itemMaps = await db.rawQuery(
      '''
      SELECT ti.*, p.* FROM transaction_items ti
      JOIN products p ON ti.product_id = p.id
      WHERE ti.transaction_id = ?
      ''',
      [transactionId],
    );

    List<CartItem> items = [];
    for (var itemMap in itemMaps) {
      final product = Product.fromMap({
        'id': itemMap['product_id'],
        'name': itemMap['name'],
        'description': itemMap['description'],
        'price': itemMap['price'],
        'stock': itemMap['stock'],
        'category': itemMap['category'],
        'barcode': itemMap['barcode'],
        'created_at': itemMap['created_at'],
        'updated_at': itemMap['updated_at'],
      });

      items.add(
        CartItem(
          id: itemMap['id'],
          product: product,
          quantity: itemMap['quantity'],
          unitPrice: itemMap['unit_price'].toDouble(),
          discount: itemMap['discount'].toDouble(),
        ),
      );
    }

    // Get customer if exists
    Customer? customer;
    if (transactionMap['customer_id'] != null) {
      final customerMaps = await db.query(
        'customers',
        where: 'id = ?',
        whereArgs: [transactionMap['customer_id']],
      );
      if (customerMaps.isNotEmpty) {
        customer = Customer.fromMap(customerMaps.first);
      }
    }

    return model.Transaction.fromMap(transactionMap, items, customer);
  }

  Future<List<model.Transaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? cashierId,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause = 'WHERE created_at BETWEEN ? AND ?';
      whereArgs.addAll([
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ]);
    }

    if (cashierId != null && cashierId.isNotEmpty) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND cashier_id = ?';
      } else {
        whereClause = 'WHERE cashier_id = ?';
      }
      whereArgs.add(cashierId);
    }

    final List<Map<String, dynamic>> transactionMaps = await db.rawQuery(
      'SELECT * FROM transactions $whereClause ORDER BY created_at DESC',
      whereArgs,
    );

    List<model.Transaction> transactions = [];

    for (var transactionMap in transactionMaps) {
      // Get transaction items
      final List<Map<String, dynamic>> itemMaps = await db.rawQuery(
        '''
        SELECT ti.*, p.* FROM transaction_items ti
        JOIN products p ON ti.product_id = p.id
        WHERE ti.transaction_id = ?
      ''',
        [transactionMap['id']],
      );

      List<CartItem> items = [];
      for (var itemMap in itemMaps) {
        final product = Product.fromMap({
          'id': itemMap['product_id'],
          'name': itemMap['name'],
          'description': itemMap['description'],
          'price': itemMap['price'],
          'stock': itemMap['stock'],
          'category': itemMap['category'],
          'barcode': itemMap['barcode'],
          'created_at': itemMap['created_at'],
          'updated_at': itemMap['updated_at'],
        });

        items.add(
          CartItem(
            id: itemMap['id'],
            product: product,
            quantity: itemMap['quantity'],
            unitPrice: itemMap['unit_price'].toDouble(),
            discount: itemMap['discount'].toDouble(),
          ),
        );
      }

      // Get customer if exists
      Customer? customer;
      if (transactionMap['customer_id'] != null) {
        final customerMaps = await db.query(
          'customers',
          where: 'id = ?',
          whereArgs: [transactionMap['customer_id']],
        );
        if (customerMaps.isNotEmpty) {
          customer = Customer.fromMap(customerMaps.first);
        }
      }

      transactions.add(
        model.Transaction.fromMap(transactionMap, items, customer),
      );
    }

    return transactions;
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'name LIKE ? OR barcode LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<Map<String, dynamic>> getDashboardData() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Today's sales
    final todaySales = await db.rawQuery(
      '''
      SELECT COUNT(*) as count, COALESCE(SUM(total), 0) as total
      FROM transactions 
      WHERE created_at >= ? AND created_at < ?
    ''',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );

    // Total products
    final productCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products',
    );

    // Low stock products
    final lowStockProducts = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE stock < 10',
    );

    // Total customers
    final customerCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM customers',
    );

    return {
      'todayTransactions': todaySales.first['count'],
      'todayRevenue': todaySales.first['total'],
      'totalProducts': productCount.first['count'],
      'lowStockProducts': lowStockProducts.first['count'],
      'totalCustomers': customerCount.first['count'],
    };
  }

  // Cashier Performance Reports
  Future<Map<String, dynamic>> getCashierReport(
    String cashierId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await database;

      // Set default date range if not provided (last 30 days)
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      // Get cashier info
      final cashierInfo = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [cashierId],
      );

      if (cashierInfo.isEmpty) {
        throw Exception('Kasir tidak ditemukan');
      }

      // Total transactions and revenue for this cashier
      final salesData = await db.rawQuery(
        '''
        SELECT 
          COUNT(*) as total_transactions,
          COALESCE(SUM(total), 0) as total_revenue,
          COALESCE(AVG(total), 0) as avg_transaction_value,
          MIN(total) as min_transaction,
          MAX(total) as max_transaction
        FROM transactions 
        WHERE cashier_id = ? AND created_at BETWEEN ? AND ?
        ''',
        [cashierId, startDate.toIso8601String(), endDate.toIso8601String()],
      );

      // Daily performance breakdown
      final dailyPerformance = await db.rawQuery(
        '''
        SELECT 
          DATE(created_at) as date,
          COUNT(*) as transactions_count,
          COALESCE(SUM(total), 0) as daily_revenue
        FROM transactions 
        WHERE cashier_id = ? AND created_at BETWEEN ? AND ?
        GROUP BY DATE(created_at)
        ORDER BY DATE(created_at) DESC
        ''',
        [cashierId, startDate.toIso8601String(), endDate.toIso8601String()],
      );

      // Most sold products by this cashier
      final topProducts = await db.rawQuery(
        '''
        SELECT 
          p.name as product_name,
          p.category,
          SUM(ti.quantity) as total_quantity,
          COALESCE(SUM(ti.quantity * ti.unit_price), 0) as total_value
        FROM transaction_items ti
        JOIN transactions t ON ti.transaction_id = t.id
        JOIN products p ON ti.product_id = p.id
        WHERE t.cashier_id = ? AND t.created_at BETWEEN ? AND ?
        GROUP BY p.id, p.name, p.category
        ORDER BY total_quantity DESC
        LIMIT 10
        ''',
        [cashierId, startDate.toIso8601String(), endDate.toIso8601String()],
      );

      // Payment method breakdown
      final paymentMethods = await db.rawQuery(
        '''
        SELECT 
          payment_method,
          COUNT(*) as count,
          COALESCE(SUM(total), 0) as total_amount
        FROM transactions 
        WHERE cashier_id = ? AND created_at BETWEEN ? AND ?
        GROUP BY payment_method
        ORDER BY count DESC
        ''',
        [cashierId, startDate.toIso8601String(), endDate.toIso8601String()],
      );

      // Hourly performance (to see peak hours)
      final hourlyPerformance = await db.rawQuery(
        '''
        SELECT 
          CAST(strftime('%H', created_at) AS INTEGER) as hour,
          COUNT(*) as transactions_count,
          COALESCE(SUM(total), 0) as hourly_revenue
        FROM transactions 
        WHERE cashier_id = ? AND created_at BETWEEN ? AND ?
        GROUP BY CAST(strftime('%H', created_at) AS INTEGER)
        ORDER BY hour
        ''',
        [cashierId, startDate.toIso8601String(), endDate.toIso8601String()],
      );

      return {
        'cashier_info': {
          'id': cashierInfo.first['id'],
          'name': cashierInfo.first['name'],
          'username': cashierInfo.first['username'],
        },
        'period': {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
        'summary': {
          'total_transactions': salesData.first['total_transactions'],
          'total_revenue': salesData.first['total_revenue'],
          'avg_transaction_value': salesData.first['avg_transaction_value'],
          'min_transaction': salesData.first['min_transaction'],
          'max_transaction': salesData.first['max_transaction'],
        },
        'daily_performance': dailyPerformance,
        'top_products': topProducts,
        'payment_methods': paymentMethods,
        'hourly_performance': hourlyPerformance,
      };
    } catch (e) {
      print('Error getting cashier report: $e');
      rethrow;
    }
  }

  // Get all cashiers performance comparison
  Future<List<Map<String, dynamic>>> getAllCashiersPerformance({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await database;

      // Set default date range if not provided (last 30 days)
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      final cashiersPerformance = await db.rawQuery(
        '''
        SELECT 
          u.id,
          u.name,
          u.username,
          COUNT(t.id) as total_transactions,
          COALESCE(SUM(t.total), 0) as total_revenue,
          COALESCE(AVG(t.total), 0) as avg_transaction_value,
          COUNT(DISTINCT DATE(t.created_at)) as active_days
        FROM users u
        LEFT JOIN transactions t ON u.id = t.cashier_id 
          AND t.created_at BETWEEN ? AND ?
        WHERE u.role = 'admin' OR u.role = 'cashier'
        GROUP BY u.id, u.name, u.username
        ORDER BY total_revenue DESC
        ''',
        [startDate.toIso8601String(), endDate.toIso8601String()],
      );

      return cashiersPerformance
          .map(
            (cashier) => {
              'id': cashier['id'],
              'name': cashier['name'],
              'total_transactions': cashier['total_transactions'],
              'total_revenue': cashier['total_revenue'],
              'avg_transaction_value': cashier['avg_transaction_value'],
              'active_days': cashier['active_days'],
              'revenue_per_day': (cashier['active_days'] as int) > 0
                  ? (cashier['total_revenue'] as double) /
                        (cashier['active_days'] as int)
                  : 0.0,
            },
          )
          .toList();
    } catch (e) {
      print('Error getting all cashiers performance: $e');
      return [];
    }
  }

  // Get cashier ranking based on performance metrics
  Future<List<Map<String, dynamic>>> getCashierRanking({
    DateTime? startDate,
    DateTime? endDate,
    String sortBy = 'revenue', // 'revenue', 'transactions', 'avg_value'
  }) async {
    try {
      final db = await database;

      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      String orderByClause;
      switch (sortBy) {
        case 'transactions':
          orderByClause = 'total_transactions DESC';
          break;
        case 'avg_value':
          orderByClause = 'avg_transaction_value DESC';
          break;
        case 'revenue':
        default:
          orderByClause = 'total_revenue DESC';
          break;
      }

      final ranking = await db.rawQuery(
        '''
        SELECT 
          u.id,
          u.name,
          u.username,
          COUNT(t.id) as total_transactions,
          COALESCE(SUM(t.total), 0) as total_revenue,
          COALESCE(AVG(t.total), 0) as avg_transaction_value,
          COUNT(DISTINCT DATE(t.created_at)) as active_days,
          RANK() OVER (ORDER BY $orderByClause) as rank
        FROM users u
        LEFT JOIN transactions t ON u.id = t.cashier_id 
          AND t.created_at BETWEEN ? AND ?
        WHERE u.role = 'admin' OR u.role = 'cashier'
        GROUP BY u.id, u.name, u.username
        ORDER BY $orderByClause
        ''',
        [startDate.toIso8601String(), endDate.toIso8601String()],
      );

      return ranking
          .map(
            (cashier) => {
              'rank': cashier['rank'],
              'id': cashier['id'],
              'name': cashier['name'],
              'username': cashier['username'],
              'total_transactions': cashier['total_transactions'],
              'total_revenue': cashier['total_revenue'],
              'avg_transaction_value': cashier['avg_transaction_value'],
              'active_days': cashier['active_days'],
            },
          )
          .toList();
    } catch (e) {
      print('Error getting cashier ranking: $e');
      return [];
    }
  }

  // Notification operations
  Future<void> insertNotification(AppNotification notification) async {
    try {
      final db = await database;
      await db.insert('notifications', notification.toMap());
    } catch (e) {
      print('Error inserting notification: $e');
      rethrow;
    }
  }

  Future<List<AppNotification>> getNotifications({String? userId}) async {
    try {
      final db = await database;
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (userId != null) {
        whereClause = 'WHERE user_id = ? OR user_id IS NULL';
        whereArgs = [userId];
      }

      final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT * FROM notifications $whereClause ORDER BY created_at DESC',
        whereArgs,
      );

      return List.generate(
        maps.length,
        (i) => AppNotification.fromMap(maps[i]),
      );
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final db = await database;
      await db.update(
        'notifications',
        {'is_read': 1},
        where: 'id = ?',
        whereArgs: [notificationId],
      );
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  Future<void> markAllNotificationsAsRead({String? userId}) async {
    try {
      final db = await database;
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (userId != null) {
        whereClause = 'WHERE user_id = ? OR user_id IS NULL';
        whereArgs = [userId];
      }

      await db.rawUpdate(
        'UPDATE notifications SET is_read = 1 $whereClause',
        whereArgs,
      );
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final db = await database;
      await db.delete(
        'notifications',
        where: 'id = ?',
        whereArgs: [notificationId],
      );
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  Future<void> clearAllNotifications({String? userId}) async {
    try {
      final db = await database;
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (userId != null) {
        whereClause = 'WHERE user_id = ? OR user_id IS NULL';
        whereArgs = [userId];
      }

      await db.rawDelete('DELETE FROM notifications $whereClause', whereArgs);
    } catch (e) {
      print('Error clearing notifications: $e');
      rethrow;
    }
  }

  // App Settings operations
  Future<Map<String, dynamic>?> getAppSettings() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('app_settings');

      if (maps.isNotEmpty) {
        return maps.first;
      }

      // If no settings exist, create default settings
      const defaultSettings = AppSettings();
      await updateAppSettings(defaultSettings);
      return defaultSettings.toMap();
    } catch (e) {
      print('Error getting app settings: $e');
      return null;
    }
  }

  Future<void> updateAppSettings(AppSettings settings) async {
    try {
      final db = await database;

      // Check if settings exist
      final existing = await db.query('app_settings');

      if (existing.isEmpty) {
        // Insert new settings
        await db.insert('app_settings', settings.toMap());
      } else {
        // Update existing settings
        await db.update(
          'app_settings',
          settings.toMap(),
          where: 'id = ?',
          whereArgs: [1], // Assuming single settings record with id = 1
        );
      }
    } catch (e) {
      print('Error updating app settings: $e');
      rethrow;
    }
  }

  Future<void> resetAppSettings() async {
    try {
      final db = await database;
      await db.delete('app_settings');

      const defaultSettings = AppSettings();
      await db.insert('app_settings', {...defaultSettings.toMap(), 'id': 1});
    } catch (e) {
      print('Error resetting app settings: $e');
      rethrow;
    }
  }

  // Promotion operations
  Future<List<Map<String, dynamic>>> getPromotions() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'promotions',
        orderBy: 'created_at DESC',
      );
      return maps;
    } catch (e) {
      print('Error getting promotions: $e');
      return [];
    }
  }

  Future<void> insertPromotion(Map<String, dynamic> promotion) async {
    try {
      final db = await database;
      await db.insert('promotions', promotion);
    } catch (e) {
      print('Error inserting promotion: $e');
      rethrow;
    }
  }

  Future<void> updatePromotion(Map<String, dynamic> promotion) async {
    try {
      final db = await database;
      await db.update(
        'promotions',
        promotion,
        where: 'id = ?',
        whereArgs: [promotion['id']],
      );
    } catch (e) {
      print('Error updating promotion: $e');
      rethrow;
    }
  }

  Future<void> deletePromotion(String id) async {
    try {
      final db = await database;
      await db.delete('promotions', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print('Error deleting promotion: $e');
      rethrow;
    }
  }

  // Module Permission operations
  Future<List<ModulePermission>> getModulePermissions() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'module_permissions',
        orderBy: 'module_name ASC',
      );
      return List.generate(
        maps.length,
        (i) => ModulePermission.fromMap(maps[i]),
      );
    } catch (e) {
      print('Error getting module permissions: $e');
      return [];
    }
  }

  Future<void> insertModulePermission(ModulePermission permission) async {
    try {
      final db = await database;
      await db.insert(
        'module_permissions',
        permission.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error inserting module permission: $e');
      rethrow;
    }
  }

  Future<void> updateModulePermission(ModulePermission permission) async {
    try {
      final db = await database;
      await db.update(
        'module_permissions',
        permission.toMap(),
        where: 'id = ?',
        whereArgs: [permission.id],
      );
    } catch (e) {
      print('Error updating module permission: $e');
      rethrow;
    }
  }

  Future<void> clearModulePermissions() async {
    try {
      final db = await database;
      await db.delete('module_permissions');
    } catch (e) {
      print('Error clearing module permissions: $e');
      rethrow;
    }
  }

  // Transaction Storage Management
  /// Delete transactions older than specified days
  Future<int> deleteOldTransactions(int storageDays) async {
    try {
      final db = await database;
      final cutoffDate = DateTime.now().subtract(Duration(days: storageDays));

      // First, delete transaction items for old transactions
      final deletedItemsCount = await db.rawDelete(
        '''
        DELETE FROM transaction_items 
        WHERE transaction_id IN (
          SELECT id FROM transactions 
          WHERE created_at < ?
        )
        ''',
        [cutoffDate.toIso8601String()],
      );

      // Then delete the transactions themselves
      final deletedTransactionsCount = await db.delete(
        'transactions',
        where: 'created_at < ?',
        whereArgs: [cutoffDate.toIso8601String()],
      );

      print(
        'Deleted $deletedTransactionsCount old transactions and $deletedItemsCount transaction items',
      );
      return deletedTransactionsCount;
    } catch (e) {
      print('Error deleting old transactions: $e');
      rethrow;
    }
  }

  /// Delete all transactions (for complete cleanup)
  Future<int> deleteAllTransactions() async {
    try {
      final db = await database;

      // First, delete all transaction items
      final deletedItemsCount = await db.delete('transaction_items');

      // Then delete all transactions
      final deletedTransactionsCount = await db.delete('transactions');

      print(
        'Deleted all transactions: $deletedTransactionsCount transactions and $deletedItemsCount transaction items',
      );
      return deletedTransactionsCount;
    } catch (e) {
      print('Error deleting all transactions: $e');
      rethrow;
    }
  }

  /// Get count of transactions older than specified days
  Future<int> getOldTransactionsCount(int storageDays) async {
    try {
      final db = await database;
      final cutoffDate = DateTime.now().subtract(Duration(days: storageDays));

      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM transactions WHERE created_at < ?',
        [cutoffDate.toIso8601String()],
      );

      return result.first['count'] as int;
    } catch (e) {
      print('Error getting old transactions count: $e');
      return 0;
    }
  }

  /// Get total transactions count
  Future<int> getTotalTransactionsCount() async {
    try {
      final db = await database;

      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM transactions',
      );

      return result.first['count'] as int;
    } catch (e) {
      print('Error getting total transactions count: $e');
      return 0;
    }
  }

  /// Clean up transactions based on current storage settings
  Future<int> cleanupTransactionsBasedOnSettings() async {
    try {
      final settings = await getAppSettings();
      if (settings != null) {
        final storageDays = settings['transaction_storage_days'] ?? 30;
        return await deleteOldTransactions(storageDays);
      }
      return 0;
    } catch (e) {
      print('Error cleaning up transactions based on settings: $e');
      return 0;
    }
  }
}
