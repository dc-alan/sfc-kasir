import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/promotion_provider.dart';
import '../models/product.dart';
import '../models/transaction.dart' as model;
import '../models/customer.dart';
import '../widgets/product_grid.dart';
import '../widgets/cart_widget.dart';
import '../widgets/checkout_dialog.dart';
import '../widgets/receipt_preview.dart';
import '../widgets/custom_cards.dart';
import '../utils/app_theme.dart';
import '../utils/responsive_helper.dart';

class POSScreen extends StatefulWidget {
  final model.Transaction? editTransaction;

  const POSScreen({super.key, this.editTransaction});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final TextEditingController _searchController = TextEditingController();
  final bool _isCartExpanded = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.editTransaction != null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProductsWithPromotions();
      if (_isEditMode && widget.editTransaction != null) {
        _populateCartForEdit();
      }
    });
  }

  void _populateCartForEdit() {
    final cartProvider = context.read<CartProvider>();
    cartProvider.populateFromTransaction(widget.editTransaction!);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProductsWithPromotions() async {
    final promotionProvider = context.read<PromotionProvider>();
    final productProvider = context.read<ProductProvider>();
    final cartProvider = context.read<CartProvider>();

    // Load promotions first
    await promotionProvider.loadPromotions();

    // Create sample promotions if none exist (including Air Mineral discount)
    if (promotionProvider.allPromotions.isEmpty) {
      await promotionProvider.createSamplePromotions();
      await promotionProvider.loadPromotions(); // Reload after creating samples
    }

    // Load products with promotions applied
    await productProvider.loadProducts(promotionProvider);

    // Apply promotions to cart items after loading promotions and products
    cartProvider.applyPromotions(promotionProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final Color primaryColor = Color(
          int.parse(
            settingsProvider.settings.primaryColor.replaceAll('#', '0xFF'),
          ),
        );

        return ResponsiveBuilder(
          builder: (context, isMobile, isTablet, isDesktop) {
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: _isEditMode
                  ? AppBar(
                      title: const Text('Edit Transaksi'),
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    )
                  : null,
              body: _buildBody(isMobile, isTablet, isDesktop),
              floatingActionButton: isMobile
                  ? _buildFloatingCheckoutButton()
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildBody(bool isMobile, bool isTablet, bool isDesktop) {
    if (isMobile) {
      return _buildMobileLayout();
    } else {
      return _buildTabletLayout();
    }
  }

  Widget _buildTabletLayout() {
    return ResponsiveBuilder(
      builder: (context, isMobile, isTablet, isDesktop) {
        double cartWidth = 380;
        if (isDesktop) {
          cartWidth = 420;
        } else if (isTablet) {
          cartWidth = 350;
        }

        return Row(
          children: [
            Expanded(flex: isDesktop ? 3 : 2, child: _buildProductArea()),
            Container(
              width: cartWidth,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(left: BorderSide(color: Colors.grey.shade200)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(-2, 0),
                  ),
                ],
              ),
              child: CartWidget(onCheckout: _showCheckoutDialog),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(child: _buildProductArea()),
        if (_isCartExpanded)
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: CartWidget(onCheckout: _showCheckoutDialog),
          ).animate().slideY(begin: 1, end: 0, duration: 300.ms),
      ],
    );
  }

  Widget _buildProductArea() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          _buildSearchSection(),
          _buildCategorySection(),
          Expanded(child: _buildProductGrid()),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final Color primaryColor = Color(
          int.parse(
            settingsProvider.settings.primaryColor.replaceAll('#', '0xFF'),
          ),
        );

        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.isMobile(context) ? 12 : 16,
            vertical: ResponsiveHelper.isMobile(context) ? 8 : 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: primaryColor.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            style: TextStyle(
              fontSize: ResponsiveHelper.isMobile(context) ? 14 : 16,
            ),
            decoration: InputDecoration(
              hintText: 'Cari produk...',
              hintStyle: TextStyle(
                color: Colors.grey.shade600,
                fontSize: ResponsiveHelper.isMobile(context) ? 14 : 16,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: primaryColor,
                size: ResponsiveHelper.isMobile(context) ? 20 : 24,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey.shade600,
                        size: ResponsiveHelper.isMobile(context) ? 20 : 24,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        context.read<ProductProvider>().searchProducts('');
                        setState(() {});
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: ResponsiveHelper.isMobile(context) ? 12 : 14,
              ),
            ),
            onChanged: (value) {
              context.read<ProductProvider>().searchProducts(value);
              setState(() {});
            },
          ),
        );
      },
    );
  }

  Widget _buildCategorySection() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        return Consumer<SettingsProvider>(
          builder: (context, settingsProvider, child) {
            final Color primaryColor = Color(
              int.parse(
                settingsProvider.settings.primaryColor.replaceAll('#', '0xFF'),
              ),
            );

            return Container(
              margin: EdgeInsets.fromLTRB(
                ResponsiveHelper.isMobile(context) ? 12 : 16,
                0,
                ResponsiveHelper.isMobile(context) ? 12 : 16,
                ResponsiveHelper.isMobile(context) ? 8 : 12,
              ),
              padding: EdgeInsets.all(
                ResponsiveHelper.isMobile(context) ? 12 : 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.category,
                        color: primaryColor,
                        size: ResponsiveHelper.isMobile(context) ? 18 : 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Kategori',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.isMobile(context)
                              ? 14
                              : 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: ResponsiveHelper.isMobile(context) ? 32 : 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: productProvider.categories.length,
                      itemBuilder: (context, index) {
                        final String category =
                            productProvider.categories[index];
                        final bool isSelected =
                            category == productProvider.selectedCategory;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              category,
                              style: TextStyle(
                                color: isSelected ? Colors.white : primaryColor,
                                fontWeight: FontWeight.w500,
                                fontSize: ResponsiveHelper.isMobile(context)
                                    ? 12
                                    : 14,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: primaryColor,
                            backgroundColor: primaryColor.withOpacity(0.1),
                            checkmarkColor: Colors.white,
                            side: BorderSide(
                              color: isSelected
                                  ? primaryColor
                                  : primaryColor.withOpacity(0.3),
                            ),
                            onSelected: (selected) {
                              productProvider.filterByCategory(category);
                            },
                            elevation: isSelected ? 2 : 0,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductGrid() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (productProvider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.defaultPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: CircularProgressIndicator(
                    color: AppTheme.defaultPrimaryColor,
                    strokeWidth: 3,
                  ),
                ).animate().scale(duration: 1000.ms, curve: Curves.easeInOut),
                const SizedBox(height: 20),
                Text(
                  'Memuat produk...',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(delay: 500.ms),
              ],
            ),
          );
        }

        if (productProvider.products.isEmpty) {
          return Center(
            child: ModernCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.search_off,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Tidak ada produk ditemukan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Coba ubah kata kunci pencarian atau kategori',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      _searchController.clear();
                      productProvider.searchProducts('');
                      productProvider.filterByCategory('Semua');
                      // Refresh with promotions
                      await _loadProductsWithPromotions();
                      setState(() {});
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Filter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.defaultPrimaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8));
        }

        return Container(
          padding: EdgeInsets.fromLTRB(
            ResponsiveHelper.isMobile(context) ? 12 : 16,
            ResponsiveHelper.isMobile(context) ? 4 : 8,
            ResponsiveHelper.isMobile(context) ? 12 : 16,
            ResponsiveHelper.isMobile(context) ? 12 : 16,
          ),
          child: ProductGrid(
            products: productProvider.products,
            onProductTap: _addToCart,
          ),
        );
      },
    );
  }

  Widget _buildFloatingCheckoutButton() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        if (cartProvider.isEmpty) return const SizedBox.shrink();

        return Consumer<SettingsProvider>(
          builder: (context, settingsProvider, child) {
            final Color primaryColor = Color(
              int.parse(
                settingsProvider.settings.primaryColor.replaceAll('#', '0xFF'),
              ),
            );

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: FloatingActionButton.extended(
                onPressed: _showCheckoutDialog,
                backgroundColor: AppTheme.successColor,
                elevation: 8,
                icon: Icon(
                  _isEditMode ? Icons.save : Icons.payment,
                  color: Colors.white,
                ),
                label: Text(
                  _isEditMode
                      ? 'Update (${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(cartProvider.total)})'
                      : 'Bayar (${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(cartProvider.total)})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ).animate().slideY(begin: 1, end: 0, duration: 300.ms),
            );
          },
        );
      },
    );
  }

  void _addToCart(Product product) {
    if (product.stock <= 0) {
      _showErrorSnackBar('${product.name} sedang habis');
      return;
    }

    final cartProvider = context.read<CartProvider>();
    final promotionProvider = context.read<PromotionProvider>();

    cartProvider.addItem(product);
    cartProvider.applyPromotions(promotionProvider);

    _showSuccessSnackBar(context, '${product.name} ditambahkan ke keranjang');
  }

  void _showCheckoutDialog() {
    showDialog(
      context: context,
      builder: (context) => CheckoutDialog(onCheckout: _processCheckout),
    );
  }

  Future<void> _processCheckout({
    required model.PaymentMethod paymentMethod,
    required double amountPaid,
    Customer? customer,
    String? notes,
  }) async {
    final cartProvider = context.read<CartProvider>();
    final authProvider = context.read<AuthProvider>();
    final transactionProvider = context.read<TransactionProvider>();

    if (cartProvider.isEmpty) return;

    final transaction = model.Transaction(
      id: _isEditMode ? widget.editTransaction!.id : const Uuid().v4(),
      items: cartProvider.items,
      subtotal: cartProvider.promotionAdjustedSubtotal,
      tax: cartProvider.taxAmount,
      discount: cartProvider.totalDiscountWithRounding,
      total: cartProvider.promotionAdjustedTotal,
      paymentMethod: paymentMethod,
      amountPaid: amountPaid,
      change: amountPaid - cartProvider.promotionAdjustedTotal,
      customer: customer,
      cashierId: authProvider.currentUser!.id,
      createdAt: _isEditMode
          ? widget.editTransaction!.createdAt
          : DateTime.now(),
      notes: notes,
      discountBreakdown: cartProvider.discountBreakdown,
    );

    try {
      if (_isEditMode) {
        await transactionProvider.updateTransaction(transaction);
        if (mounted) {
          _showSuccessSnackBar(context, 'Transaksi berhasil diupdate');
          Navigator.of(context).pop(); // Go back to reports screen
        }
      } else {
        await transactionProvider.addTransaction(transaction);
        cartProvider.clear();

        if (mounted) {
          await _loadProductsWithPromotions();
        }

        if (mounted) {
          _showSuccessSnackBar(context, 'Transaksi berhasil disimpan');
        }

        if (mounted) {
          _showReceiptDialog(transaction);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: $e');
      }
    }
  }

  void _showReceiptDialog(model.Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) => ReceiptPreview(
          transaction: transaction,
          cashierName:
              context.read<AuthProvider>().currentUser?.name ?? 'Kasir',
          settings: settingsProvider.settings,
          onPrint: () {
            _showSuccessSnackBar(context, 'Struk berhasil dicetak');
          },
        ),
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxWidth: 250),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Tampilkan overlay
    overlay.insert(overlayEntry);

    // Auto remove setelah 2 detik
    Future.delayed(
      const Duration(seconds: 2),
    ).then((_) => overlayEntry.remove());
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
