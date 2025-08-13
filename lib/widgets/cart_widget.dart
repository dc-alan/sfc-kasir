import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/cart_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/promotion_provider.dart';
import '../models/cart_item.dart';

class CartWidget extends StatelessWidget {
  final VoidCallback? onCheckout;

  const CartWidget({super.key, this.onCheckout});

  @override
  Widget build(BuildContext context) {
    return Consumer2<CartProvider, SettingsProvider>(
      builder: (context, cartProvider, settingsProvider, child) {
        final primaryColor = Color(
          int.parse(
            settingsProvider.settings.primaryColor.replaceAll('#', '0xFF'),
          ),
        );

        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor,
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
                  const Icon(Icons.shopping_cart, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Keranjang',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  if (cartProvider.isNotEmpty)
                    TextButton(
                      onPressed: () => _showClearCartDialog(context),
                      child: const Text(
                        'Kosongkan',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),

            // Cart items
            Expanded(
              child: cartProvider.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Keranjang kosong',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Pilih produk untuk\nmenambahkan ke keranjang',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: cartProvider.items.length,
                      itemBuilder: (context, index) {
                        final item = cartProvider.items[index];
                        return CartItemCard(
                          item: item,
                          onQuantityChanged: (quantity) {
                            cartProvider.updateItemQuantity(item.id, quantity);
                            final promotionProvider = context
                                .read<PromotionProvider>();
                            cartProvider.applyPromotions(promotionProvider);
                          },
                          onRemove: () {
                            cartProvider.removeItem(item.id);
                            final promotionProvider = context
                                .read<PromotionProvider>();
                            cartProvider.applyPromotions(promotionProvider);
                          },
                          onDiscountChanged: (discount) {
                            cartProvider.updateItemDiscount(item.id, discount);
                            final promotionProvider = context
                                .read<PromotionProvider>();
                            cartProvider.applyPromotions(promotionProvider);
                          },
                        );
                      },
                    ),
            ),

            // Summary and Checkout Button
            if (cartProvider.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Subtotal', cartProvider.subtotal),
                    if (cartProvider.totalDiscount > 0)
                      _buildSummaryRow('Diskon', -cartProvider.totalDiscount),
                    if (cartProvider.taxAmount > 0)
                      _buildSummaryRow('Pajak', cartProvider.taxAmount),
                    const Divider(),
                    _buildSummaryRow(
                      'Total',
                      cartProvider.total,
                      isTotal: true,
                    ),
                    const SizedBox(height: 16),

                    // Checkout Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: onCheckout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.payment, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'PROSES PEMBAYARAN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final primaryColor = Color(
          int.parse(
            settingsProvider.settings.primaryColor.replaceAll('#', '0xFF'),
          ),
        );

        // Ensure good contrast for total amount
        final totalColor = isTotal
            ? (primaryColor.computeLuminance() > 0.5
                  ? primaryColor.withOpacity(0.8)
                  : primaryColor)
            : Colors.grey.shade800;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isTotal ? 16 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: 'Rp ',
                  decimalDigits: 0,
                ).format(amount),
                style: TextStyle(
                  fontSize: isTotal ? 16 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  color: totalColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kosongkan Keranjang'),
        content: const Text('Apakah Anda yakin ingin mengosongkan keranjang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CartProvider>().clear();
              Navigator.pop(context);
            },
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    );
  }
}

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;
  final Function(double) onDiscountChanged;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.onDiscountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final primaryColor = Color(
          int.parse(
            settingsProvider.settings.primaryColor.replaceAll('#', '0xFF'),
          ),
        );

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name and remove button
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.product.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: onRemove,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Price and quantity controls
                Row(
                  children: [
                    // Enhanced price display with promotion support
                    Consumer<CartProvider>(
                      builder: (context, cartProvider, child) {
                        final itemPromotion = cartProvider.getItemPromotion(
                          item.id,
                        );
                        final hasPromotion =
                            itemPromotion != null && itemPromotion.discount > 0;

                        if (hasPromotion) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Original price with strikethrough
                              Text(
                                NumberFormat.currency(
                                  locale: 'id_ID',
                                  symbol: 'Rp ',
                                  decimalDigits: 0,
                                ).format(item.unitPrice),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              // Discounted price
                              Text(
                                NumberFormat.currency(
                                  locale: 'id_ID',
                                  symbol: 'Rp ',
                                  decimalDigits: 0,
                                ).format(itemPromotion.finalPrice),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Text(
                            NumberFormat.currency(
                              locale: 'id_ID',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(item.unitPrice),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          );
                        }
                      },
                    ),
                    const Spacer(),

                    // Quantity controls
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: item.quantity > 1
                                ? () => onQuantityChanged(item.quantity - 1)
                                : null,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.remove, size: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: item.quantity < item.product.stock
                                ? () => onQuantityChanged(item.quantity + 1)
                                : null,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.add, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Discount and total
                Row(
                  children: [
                    if (item.discount > 0)
                      Text(
                        'Diskon: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(item.discount)}',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    const Spacer(),
                    Text(
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(item.totalPrice),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryColor.computeLuminance() > 0.5
                            ? Colors.green.shade700
                            : primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
