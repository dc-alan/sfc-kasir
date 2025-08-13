import 'dart:math';
import '../models/transaction.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/customer.dart';

class DummyDataGenerator {
  static final Random _random = Random();

  // Sample products for Ayam Geprek (Fried Chicken) Cashier
  static final List<Product> _sampleProducts = [
    Product(
      id: 'ayam-001',
      name: 'Ayam Geprek Original',
      description: 'Ayam crispy dengan sambal geprek level 1-5',
      price: 15000,
      stock: 50,
      category: 'Ayam Geprek',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 'ayam-002',
      name: 'Ayam Geprek Keju',
      description: 'Ayam geprek dengan topping keju mozarella',
      price: 18000,
      stock: 40,
      category: 'Ayam Geprek',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 'ayam-003',
      name: 'Ayam Geprek Jumbo',
      description: 'Ayam geprek ukuran jumbo dengan nasi',
      price: 22000,
      stock: 30,
      category: 'Ayam Geprek',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 'ayam-004',
      name: 'Ayam Bakar Madu',
      description: 'Ayam bakar dengan bumbu madu spesial',
      price: 20000,
      stock: 35,
      category: 'Ayam Bakar',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 'ayam-005',
      name: 'Ayam Bakar Kecap',
      description: 'Ayam bakar dengan bumbu kecap manis',
      price: 19000,
      stock: 40,
      category: 'Ayam Bakar',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 'ayam-006',
      name: 'Ayam Crispy Original',
      description: 'Ayam crispy renyah tanpa sambal',
      price: 16000,
      stock: 45,
      category: 'Ayam Crispy',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 'ayam-007',
      name: 'Ayam Crispy Pedas',
      description: 'Ayam crispy dengan bumbu pedas',
      price: 17000,
      stock: 35,
      category: 'Ayam Crispy',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 'minuman-001',
      name: 'Es Teh Manis',
      description: 'Es teh manis segar',
      price: 5000,
      stock: 100,
      category: 'Minuman',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 'minuman-002',
      name: 'Es Jeruk',
      description: 'Es jeruk segar asli',
      price: 7000,
      stock: 80,
      category: 'Minuman',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 'minuman-003',
      name: 'Jus Alpukat',
      description: 'Jus alpukat creamy',
      price: 12000,
      stock: 25,
      category: 'Minuman',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 'snack-001',
      name: 'Kerupuk',
      description: 'Kerupuk renyah pelengkap',
      price: 3000,
      stock: 200,
      category: 'Snack',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 'snack-002',
      name: 'Tempe Goreng',
      description: 'Tempe goreng crispy',
      price: 5000,
      stock: 50,
      category: 'Snack',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 'prod_001',
      name: 'Ayam Goreng Original',
      price: 15000,
      stock: 100,
      category: 'Ayam Goreng',
      description: 'Ayam goreng dengan bumbu rahasia SFC',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 'prod_002',
      name: 'Ayam Goreng Pedas',
      price: 16000,
      stock: 80,
      category: 'Ayam Goreng',
      description: 'Ayam goreng dengan level kepedasan tinggi',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 'prod_003',
      name: 'Nasi Putih',
      price: 5000,
      stock: 200,
      category: 'Nasi',
      description: 'Nasi putih hangat',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 'prod_004',
      name: 'Es Teh Manis',
      price: 3000,
      stock: 150,
      category: 'Minuman',
      description: 'Es teh manis segar',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 'prod_005',
      name: 'Es Jeruk',
      price: 4000,
      stock: 120,
      category: 'Minuman',
      description: 'Es jeruk segar',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 'prod_006',
      name: 'Kentang Goreng',
      price: 8000,
      stock: 90,
      category: 'Snack',
      description: 'Kentang goreng crispy',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 'prod_007',
      name: 'Ayam Bakar',
      price: 18000,
      stock: 60,
      category: 'Ayam Bakar',
      description: 'Ayam bakar dengan bumbu kecap',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 'prod_008',
      name: 'Paket Hemat A',
      price: 25000,
      stock: 50,
      category: 'Paket',
      description: 'Ayam goreng + nasi + es teh',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 'prod_009',
      name: 'Paket Hemat B',
      price: 30000,
      stock: 40,
      category: 'Paket',
      description: 'Ayam bakar + nasi + kentang + es jeruk',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 'prod_010',
      name: 'Sambal Terasi',
      price: 2000,
      stock: 100,
      category: 'Sambal',
      description: 'Sambal terasi pedas',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
  ];

  // Sample customers
  static final List<Customer> _sampleCustomers = [
    Customer(
      id: 'cust_001',
      name: 'Budi Santoso',
      phone: '081234567890',
      email: 'budi@email.com',
      address: 'Jl. Merdeka No. 123',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now(),
    ),
    Customer(
      id: 'cust_002',
      name: 'Siti Nurhaliza',
      phone: '081234567891',
      email: 'siti@email.com',
      address: 'Jl. Sudirman No. 456',
      createdAt: DateTime.now().subtract(const Duration(days: 50)),
      updatedAt: DateTime.now(),
    ),
    Customer(
      id: 'cust_003',
      name: 'Ahmad Wijaya',
      phone: '081234567892',
      email: 'ahmad@email.com',
      address: 'Jl. Thamrin No. 789',
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      updatedAt: DateTime.now(),
    ),
    Customer(
      id: 'cust_004',
      name: 'Dewi Sartika',
      phone: '081234567893',
      email: 'dewi@email.com',
      address: 'Jl. Diponegoro No. 321',
      createdAt: DateTime.now().subtract(const Duration(days: 40)),
      updatedAt: DateTime.now(),
    ),
    Customer(
      id: 'cust_005',
      name: 'Rudi Hartono',
      phone: '081234567894',
      email: 'rudi@email.com',
      address: 'Jl. Gatot Subroto No. 654',
      createdAt: DateTime.now().subtract(const Duration(days: 35)),
      updatedAt: DateTime.now(),
    ),
  ];

  // Sample cashiers
  static final List<String> _cashierIds = [
    'user_001', // Admin
    'user_002', // Cashier 1
    'user_003', // Cashier 2
  ];

  // Payment methods
  static final List<PaymentMethod> _paymentMethods = [
    PaymentMethod.cash,
    PaymentMethod.card,
    PaymentMethod.digital,
    PaymentMethod.mixed,
  ];

  static List<Transaction> generateDummyTransactions(int count) {
    final List<Transaction> transactions = [];
    final DateTime now = DateTime.now();

    for (int i = 0; i < count; i++) {
      // Random date within last 30 days
      final DateTime transactionDate = now.subtract(
        Duration(
          days: _random.nextInt(30),
          hours: _random.nextInt(24),
          minutes: _random.nextInt(60),
        ),
      );

      // Random number of items (1-5)
      final int itemCount = _random.nextInt(5) + 1;
      final List<CartItem> items = [];
      double subtotal = 0;

      for (int j = 0; j < itemCount; j++) {
        final Product product =
            _sampleProducts[_random.nextInt(_sampleProducts.length)];
        final int quantity = _random.nextInt(3) + 1; // 1-3 quantity
        final double discount = _random.nextBool()
            ? (_random.nextDouble() * product.price * 0.1)
            : 0.0;

        final CartItem item = CartItem(
          id: 'item_${DateTime.now().millisecondsSinceEpoch}_${i}_$j',
          product: product,
          quantity: quantity,
          unitPrice: product.price,
          discount: discount,
        );

        items.add(item);
        subtotal += item.totalPrice;
      }

      // Random tax (0-10%)
      final double taxRate = _random.nextDouble() * 0.1;
      final double tax = subtotal * taxRate;

      // Random discount (0-20%)
      final double discountRate = _random.nextDouble() * 0.2;
      final double discount = subtotal * discountRate;

      final double total = subtotal + tax - discount;

      // Random customer (sometimes null for walk-in customers)
      final Customer? customer = _random.nextBool()
          ? _sampleCustomers[_random.nextInt(_sampleCustomers.length)]
          : null;

      final double amountPaid =
          total + (_random.nextDouble() * 10000); // Add some extra for change
      final double change = amountPaid - total;

      final Transaction transaction = Transaction(
        id: 'txn_${DateTime.now().millisecondsSinceEpoch}_$i',
        items: items,
        subtotal: subtotal,
        tax: tax,
        discount: discount,
        total: total,
        paymentMethod: _paymentMethods[_random.nextInt(_paymentMethods.length)],
        amountPaid: amountPaid,
        change: change,
        customer: customer,
        cashierId: _cashierIds[_random.nextInt(_cashierIds.length)],
        createdAt: transactionDate,
        notes: _random.nextBool()
            ? 'Pesanan ${_random.nextBool() ? 'dine-in' : 'take-away'}'
            : null,
      );

      transactions.add(transaction);
    }

    // Sort by date (newest first)
    transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return transactions;
  }

  static List<Product> getSampleProducts() {
    return List.from(_sampleProducts);
  }

  static List<Customer> getSampleCustomers() {
    return List.from(_sampleCustomers);
  }

  // Generate additional random products for chicken restaurant
  static List<Product> generateRandomProducts(int count) {
    final List<Product> products = [];
    final List<String> categories = [
      'Ayam Geprek',
      'Ayam Bakar',
      'Ayam Crispy',
      'Minuman',
      'Snack',
      'Ayam Goreng',
      'Ayam Bakar',
      'Nasi',
      'Minuman',
      'Snack',
      'Paket',
      'Sambal',
      'Dessert',
    ];

    final List<String> productNames = [
      'Ayam Geprek Spesial',
      'Ayam Geprek Keju',
      'Ayam Geprek Jumbo',
      'Ayam Bakar Madu',
      'Ayam Bakar Kecap',
      'Ayam Bakar Bumbu Rujak',
      'Ayam Crispy Original',
      'Ayam Crispy Pedas',
      'Ayam Crispy Keju',
      'Es Teh Manis',
      'Es Jeruk',
      'Es Campur',
      'Jus Alpukat',
      'Jus Mangga',
      'Air Mineral',
      'Kerupuk',
      'Tempe Goreng',
      'Tahu Goreng',
      'Lalapan',
      'Sambal Extra',
      'Ayam Bumbu Bali',
      'Ayam Teriyaki',
      'Nasi Gudeg',
      'Nasi Liwet',
      'Es Campur',
      'Jus Alpukat',
      'Kerupuk',
      'Tahu Goreng',
      'Tempe Goreng',
      'Paket Keluarga',
      'Paket Spesial',
      'Sambal Matah',
      'Sambal Ijo',
      'Es Krim',
    ];

    for (int i = 0; i < count; i++) {
      final String name = productNames[_random.nextInt(productNames.length)];
      final String category = categories[_random.nextInt(categories.length)];
      final double price = (_random.nextInt(20) + 1) * 1000.0; // 1k - 20k
      final int stock = _random.nextInt(200) + 10; // 10 - 210

      products.add(
        Product(
          id: 'prod_gen_${DateTime.now().millisecondsSinceEpoch}_$i',
          name: '$name ${i + 1}',
          price: price,
          stock: stock,
          category: category,
          description: 'Produk $name dengan kualitas terbaik',
          createdAt: DateTime.now().subtract(
            Duration(days: _random.nextInt(60)),
          ),
          updatedAt: DateTime.now(),
        ),
      );
    }

    return products;
  }

  // Generate performance data for cashier reports
  static Map<String, dynamic> generateCashierPerformanceData(
    String cashierId,
    List<Transaction> transactions,
  ) {
    final cashierTransactions = transactions
        .where((t) => t.cashierId == cashierId)
        .toList();

    if (cashierTransactions.isEmpty) {
      return {
        'cashier_id': cashierId,
        'total_transactions': 0,
        'total_revenue': 0.0,
        'average_transaction': 0.0,
        'daily_performance': <Map<String, dynamic>>[],
        'top_products': <Map<String, dynamic>>[],
        'payment_methods': <Map<String, dynamic>>[],
        'summary': {
          'best_day': 'N/A',
          'worst_day': 'N/A',
          'total_items_sold': 0,
          'customer_satisfaction': 0.0,
        },
      };
    }

    // Calculate daily performance
    final Map<String, double> dailyRevenue = {};
    final Map<String, int> dailyTransactions = {};
    final Map<String, int> productSales = {};
    final Map<String, int> paymentMethodCount = {};

    for (final transaction in cashierTransactions) {
      final String dateKey =
          '${transaction.createdAt.year}-${transaction.createdAt.month.toString().padLeft(2, '0')}-${transaction.createdAt.day.toString().padLeft(2, '0')}';

      dailyRevenue[dateKey] = (dailyRevenue[dateKey] ?? 0) + transaction.total;
      dailyTransactions[dateKey] = (dailyTransactions[dateKey] ?? 0) + 1;

      paymentMethodCount[transaction.paymentMethod.toString().split('.').last] =
          (paymentMethodCount[transaction.paymentMethod
                  .toString()
                  .split('.')
                  .last] ??
              0) +
          1;

      for (final item in transaction.items) {
        productSales[item.product.name] =
            (productSales[item.product.name] ?? 0) + item.quantity;
      }
    }

    // Sort and get top products
    final topProducts = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate totals
    final double totalRevenue = cashierTransactions.fold(
      0,
      (sum, t) => sum + t.total,
    );
    final int totalTransactions = cashierTransactions.length;
    final double averageTransaction = totalRevenue / totalTransactions;
    final int totalItemsSold = cashierTransactions.fold(
      0,
      (sum, t) =>
          sum + t.items.fold(0, (itemSum, item) => itemSum + item.quantity),
    );

    return {
      'cashier_id': cashierId,
      'total_transactions': totalTransactions,
      'total_revenue': totalRevenue,
      'average_transaction': averageTransaction,
      'daily_performance': dailyRevenue.entries
          .map(
            (e) => {
              'date': e.key,
              'revenue': e.value,
              'transactions': dailyTransactions[e.key] ?? 0,
            },
          )
          .toList(),
      'top_products': topProducts
          .take(5)
          .map(
            (e) => {
              'name': e.key,
              'quantity': e.value,
              'percentage': (e.value / totalItemsSold * 100).toStringAsFixed(1),
            },
          )
          .toList(),
      'payment_methods': paymentMethodCount.entries
          .map(
            (e) => {
              'method': e.key,
              'count': e.value,
              'percentage': (e.value / totalTransactions * 100).toStringAsFixed(
                1,
              ),
            },
          )
          .toList(),
      'summary': {
        'best_day': dailyRevenue.entries.isNotEmpty
            ? dailyRevenue.entries
                  .reduce((a, b) => a.value > b.value ? a : b)
                  .key
            : 'N/A',
        'worst_day': dailyRevenue.entries.isNotEmpty
            ? dailyRevenue.entries
                  .reduce((a, b) => a.value < b.value ? a : b)
                  .key
            : 'N/A',
        'total_items_sold': totalItemsSold,
        'customer_satisfaction':
            4.2 + (_random.nextDouble() * 0.8), // Random 4.2-5.0
      },
    };
  }

  // Generate summary statistics
  static Map<String, dynamic> generateSummaryStats(
    List<Transaction> transactions,
  ) {
    if (transactions.isEmpty) {
      return {
        'total_revenue': 0.0,
        'total_transactions': 0,
        'average_transaction': 0.0,
        'total_items_sold': 0,
        'top_selling_products': <Map<String, dynamic>>[],
        'revenue_by_category': <Map<String, dynamic>>[],
        'payment_method_distribution': <Map<String, dynamic>>[],
        'daily_revenue': <Map<String, dynamic>>[],
        'monthly_growth': 0.0,
      };
    }

    final Map<String, int> productSales = {};
    final Map<String, double> categoryRevenue = {};
    final Map<String, int> paymentMethods = {};
    final Map<String, double> dailyRevenue = {};

    double totalRevenue = 0;
    int totalItemsSold = 0;

    for (final transaction in transactions) {
      totalRevenue += transaction.total;

      final String dateKey =
          '${transaction.createdAt.year}-${transaction.createdAt.month.toString().padLeft(2, '0')}-${transaction.createdAt.day.toString().padLeft(2, '0')}';
      dailyRevenue[dateKey] = (dailyRevenue[dateKey] ?? 0) + transaction.total;

      paymentMethods[transaction.paymentMethod.toString().split('.').last] =
          (paymentMethods[transaction.paymentMethod
                  .toString()
                  .split('.')
                  .last] ??
              0) +
          1;

      for (final item in transaction.items) {
        totalItemsSold += item.quantity;
        productSales[item.product.name] =
            (productSales[item.product.name] ?? 0) + item.quantity;

        categoryRevenue[item.product.category] =
            (categoryRevenue[item.product.category] ?? 0) + item.totalPrice;
      }
    }

    // Sort top products
    final topProducts = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'total_revenue': totalRevenue,
      'total_transactions': transactions.length,
      'average_transaction': totalRevenue / transactions.length,
      'total_items_sold': totalItemsSold,
      'top_selling_products': topProducts
          .take(10)
          .map(
            (e) => {
              'name': e.key,
              'quantity': e.value,
              'percentage': (e.value / totalItemsSold * 100).toStringAsFixed(1),
            },
          )
          .toList(),
      'revenue_by_category': categoryRevenue.entries
          .map(
            (e) => {
              'category': e.key,
              'revenue': e.value,
              'percentage': (e.value / totalRevenue * 100).toStringAsFixed(1),
            },
          )
          .toList(),
      'payment_method_distribution': paymentMethods.entries
          .map(
            (e) => {
              'method': e.key,
              'count': e.value,
              'percentage': (e.value / transactions.length * 100)
                  .toStringAsFixed(1),
            },
          )
          .toList(),
      'daily_revenue': dailyRevenue.entries
          .map((e) => {'date': e.key, 'revenue': e.value})
          .toList(),
      'monthly_growth': (_random.nextDouble() * 20) - 5, // Random -5% to +15%
    };
  }

  // Method to populate database with dummy data
  static Future<void> populateDatabase() async {
    // This method would be called to insert dummy data into the database
    // For now, it just generates the data
    final transactions = generateDummyTransactions(50);
    final products = getSampleProducts();
    final customers = getSampleCustomers();

    print('Generated ${transactions.length} dummy transactions');
    print('Generated ${products.length} sample products');
    print('Generated ${customers.length} sample customers');

    // Here you would typically insert this data into your database
    // Example:
    // final databaseService = DatabaseService();
    // for (final product in products) {
    //   await databaseService.insertProduct(product);
    // }
    // for (final customer in customers) {
    //   await databaseService.insertCustomer(customer);
    // }
    // for (final transaction in transactions) {
    //   await databaseService.insertTransaction(transaction);
    // }
  }
}
