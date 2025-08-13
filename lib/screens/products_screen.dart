import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/product_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/promotion_provider.dart';
import '../models/product.dart';
import '../utils/app_theme.dart';
import '../utils/responsive_helper.dart';
import '../widgets/custom_form_widgets.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProductsWithPromotions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProductsWithPromotions() async {
    final promotionProvider = context.read<PromotionProvider>();
    final productProvider = context.read<ProductProvider>();

    // Load promotions first
    await promotionProvider.loadPromotions();

    // Create sample promotions if none exist (including Air Mineral discount)
    if (promotionProvider.allPromotions.isEmpty) {
      await promotionProvider.createSamplePromotions();
      await promotionProvider.loadPromotions(); // Reload after creating samples
    }

    // Load products with promotions applied
    await productProvider.loadProducts(promotionProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final primaryColor = Color(
          int.parse(
            settingsProvider.settings.primaryColor.replaceAll('#', '0xFF'),
          ),
        );

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: RefreshIndicator(
            onRefresh: () async {
              await _loadProductsWithPromotions();
            },
            color: primaryColor,
            child: Column(
              children: [
                _buildSearchAndStats(primaryColor),
                _buildCategoryFilter(primaryColor),
                Expanded(child: _buildProductGrid()),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showProductDialog(),
            backgroundColor: primaryColor,
            elevation: 4,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Tambah Produk',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchAndStats(Color primaryColor) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.isMobile(context) ? 12 : 16,
        vertical: ResponsiveHelper.isMobile(context) ? 8 : 12,
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
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
          ),

          const SizedBox(height: 12),

          // Quick Stats
          Consumer<ProductProvider>(
            builder: (context, productProvider, child) {
              final totalProducts = productProvider.products.length;
              final lowStockProducts = productProvider.products
                  .where((p) => p.stock < 10 && p.stock > 0)
                  .length;
              final outOfStockProducts = productProvider.products
                  .where((p) => p.stock <= 0)
                  .length;

              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total',
                      totalProducts.toString(),
                      Icons.inventory_2,
                      primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Stok Menipis',
                      lowStockProducts.toString(),
                      Icons.warning,
                      AppTheme.warningColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Habis',
                      outOfStockProducts.toString(),
                      Icons.error,
                      AppTheme.errorColor,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(Color primaryColor) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.isMobile(context) ? 12 : 16,
            vertical: ResponsiveHelper.isMobile(context) ? 4 : 8,
          ),
          padding: const EdgeInsets.all(12),
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
                  Icon(Icons.category, color: primaryColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Kategori',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${productProvider.products.length} produk',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: productProvider.categories.length,
                  itemBuilder: (context, index) {
                    final category = productProvider.categories[index];
                    final isSelected =
                        category == productProvider.selectedCategory;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? Colors.white : primaryColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
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
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
  }

  Widget _buildProductGrid() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (productProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (productProvider.products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada produk',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tambahkan produk pertama Anda',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showProductDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Produk'),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.isMobile(context) ? 12 : 16,
          ),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveHelper.isMobile(context) ? 1 : 2,
              childAspectRatio: ResponsiveHelper.isMobile(context) ? 3.5 : 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: productProvider.products.length,
            itemBuilder: (context, index) {
              final product = productProvider.products[index];
              return _buildProductCard(product);
            },
          ),
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    final isLowStock = product.stock < 10;
    final isOutOfStock = product.stock <= 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _showProductDetails(product),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.defaultPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.defaultPrimaryColor.withOpacity(0.2),
                  ),
                ),
                child: Icon(
                  Icons.fastfood,
                  color: AppTheme.defaultPrimaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(product.price),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppTheme.defaultPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.defaultPrimaryColor.withOpacity(
                              0.1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.category,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.defaultPrimaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isOutOfStock
                                ? AppTheme.errorColor.withOpacity(0.1)
                                : isLowStock
                                ? AppTheme.warningColor.withOpacity(0.1)
                                : AppTheme.successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Stok: ${product.stock}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isOutOfStock
                                  ? AppTheme.errorColor
                                  : isLowStock
                                  ? AppTheme.warningColor
                                  : AppTheme.successColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showProductDialog(product: product);
                  } else if (value == 'delete') {
                    _showDeleteDialog(product);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 16),
                        SizedBox(width: 8),
                        Text('Hapus', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.defaultPrimaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Detail Produk',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Nama', product.name),
              if (product.description.isNotEmpty)
                _buildDetailRow('Deskripsi', product.description),
              _buildDetailRow('Kategori', product.category),
              _buildDetailRow(
                'Harga',
                NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: 'Rp ',
                  decimalDigits: 0,
                ).format(product.price),
              ),
              _buildDetailRow('Stok', '${product.stock} unit'),
              if (product.barcode != null && product.barcode!.isNotEmpty)
                _buildDetailRow('Barcode', product.barcode!),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showProductDialog(product: product);
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showDeleteDialog(product);
                      },
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Hapus'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 12)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showProductDialog({Product? product}) {
    showDialog(
      context: context,
      builder: (context) => ProductDialog(
        product: product,
        onSave: (productData) async {
          try {
            if (product == null) {
              final newProduct = Product(
                id: const Uuid().v4(),
                name: productData['name'],
                description: productData['description'],
                price: productData['price'],
                stock: productData['stock'],
                category: productData['category'],
                barcode: productData['barcode'],
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              await context.read<ProductProvider>().addProduct(newProduct);
            } else {
              final updatedProduct = product.copyWith(
                name: productData['name'],
                description: productData['description'],
                price: productData['price'],
                stock: productData['stock'],
                category: productData['category'],
                barcode: productData['barcode'],
                updatedAt: DateTime.now(),
              );
              await context.read<ProductProvider>().updateProduct(
                updatedProduct,
              );
            }

            if (mounted) {
              _showSuccessSnackBar(
                product == null
                    ? 'Produk berhasil ditambahkan'
                    : 'Produk berhasil diperbarui',
              );
            }
          } catch (e) {
            if (mounted) {
              _showErrorSnackBar('Error: $e');
            }
          }
        },
      ),
    );
  }

  void _showDeleteDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.delete, color: AppTheme.errorColor, size: 20),
            const SizedBox(width: 8),
            const Text('Hapus Produk'),
          ],
        ),
        content: Text('Apakah Anda yakin ingin menghapus "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await context.read<ProductProvider>().deleteProduct(product.id);
                if (mounted) {
                  Navigator.pop(context);
                  _showSuccessSnackBar('Produk berhasil dihapus');
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  _showErrorSnackBar('Error: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class ProductDialog extends StatefulWidget {
  final Product? product;
  final Function(Map<String, dynamic>) onSave;

  const ProductDialog({super.key, this.product, required this.onSave});

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _categoryController = TextEditingController();
  final _barcodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stock.toString();
      _categoryController.text = widget.product!.category;
      _barcodeController.text = widget.product!.barcode ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: ResponsiveHelper.isMobile(context) ? null : 400,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.product == null ? Icons.add : Icons.edit,
                      color: AppTheme.defaultPrimaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.product == null
                            ? 'Tambah Produk'
                            : 'Edit Produk',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _nameController,
                  label: 'Nama Produk',
                  prefixIcon: Icons.fastfood,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama produk tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: _descriptionController,
                  label: 'Deskripsi',
                  prefixIcon: Icons.description,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _priceController,
                        label: 'Harga',
                        prefixIcon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harga tidak boleh kosong';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Harga harus berupa angka';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _stockController,
                        label: 'Stok',
                        prefixIcon: Icons.inventory,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Stok tidak boleh kosong';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Stok harus berupa angka';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: _categoryController,
                  label: 'Kategori',
                  prefixIcon: Icons.category,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kategori tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: _barcodeController,
                  label: 'Barcode (Opsional)',
                  prefixIcon: Icons.qr_code,
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.defaultPrimaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final productData = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.parse(_priceController.text),
      'stock': int.parse(_stockController.text),
      'category': _categoryController.text.trim(),
      'barcode': _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim(),
    };

    widget.onSave(productData);
    Navigator.pop(context);
  }
}
