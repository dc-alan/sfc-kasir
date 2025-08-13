import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/promotion_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/product_provider.dart';
import '../models/promotion.dart';
import '../models/product.dart';
import '../utils/app_theme.dart';
import '../utils/responsive_helper.dart';
import '../widgets/custom_form_widgets.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PromotionProvider>().loadPromotions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              await context.read<PromotionProvider>().loadPromotions();
            },
            color: primaryColor,
            child: Column(
              children: [
                _buildSearchAndStats(primaryColor),
                _buildTypeFilter(primaryColor),
                Expanded(child: _buildPromotionList()),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showPromotionDialog(),
            backgroundColor: primaryColor,
            elevation: 4,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Tambah Promosi',
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
                hintText: 'Cari promosi...',
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
                          context.read<PromotionProvider>().searchPromotions(
                            '',
                          );
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
                context.read<PromotionProvider>().searchPromotions(value);
                setState(() {});
              },
            ),
          ),

          const SizedBox(height: 12),

          // Quick Stats
          Consumer<PromotionProvider>(
            builder: (context, promotionProvider, child) {
              final stats = promotionProvider.getPromotionStats();

              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total',
                      stats['total'].toString(),
                      Icons.local_offer,
                      primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Aktif',
                      stats['active'].toString(),
                      Icons.check_circle,
                      AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Kedaluwarsa',
                      stats['expired'].toString(),
                      Icons.error,
                      AppTheme.errorColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Mendatang',
                      stats['upcoming'].toString(),
                      Icons.schedule,
                      AppTheme.warningColor,
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
    final isMobile = ResponsiveHelper.isMobile(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = screenWidth < 350;

    return Container(
      padding: EdgeInsets.all(isVerySmall ? 8 : (isMobile ? 10 : 12)),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: isVerySmall ? 16 : (isMobile ? 18 : 20),
          ),
          SizedBox(height: isVerySmall ? 2 : 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isVerySmall ? 12 : (isMobile ? 14 : 16),
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
            ),
          ),
          SizedBox(height: isVerySmall ? 1 : 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isVerySmall ? 8 : (isMobile ? 9 : 10),
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilter(Color primaryColor) {
    return Consumer<PromotionProvider>(
      builder: (context, promotionProvider, child) {
        final types = [
          {'type': null, 'label': 'Semua', 'icon': Icons.all_inclusive},
          {
            'type': PromotionType.discount,
            'label': 'Diskon',
            'icon': Icons.percent,
          },
          {
            'type': PromotionType.coupon,
            'label': 'Kupon',
            'icon': Icons.confirmation_number,
          },
          {
            'type': PromotionType.happyHour,
            'label': 'Happy Hour',
            'icon': Icons.access_time,
          },
          {
            'type': PromotionType.bundle,
            'label': 'Bundle',
            'icon': Icons.inventory,
          },
        ];

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
                  Icon(Icons.filter_list, color: primaryColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Tipe Promosi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${promotionProvider.promotions.length} promosi',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: types.length,
                  itemBuilder: (context, index) {
                    final typeData = types[index];
                    final type = typeData['type'] as PromotionType?;
                    final label = typeData['label'] as String;
                    final icon = typeData['icon'] as IconData;
                    final isSelected = type == promotionProvider.selectedType;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        avatar: Icon(
                          icon,
                          size: 16,
                          color: isSelected ? Colors.white : primaryColor,
                        ),
                        label: Text(
                          label,
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
                          promotionProvider.filterByType(type);
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

  Widget _buildPromotionList() {
    return Consumer<PromotionProvider>(
      builder: (context, promotionProvider, child) {
        if (promotionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (promotionProvider.promotions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada promosi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tambahkan promosi untuk meningkatkan penjualan',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showPromotionDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Promosi'),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.isMobile(context) ? 12 : 16,
          ),
          child: ListView.builder(
            itemCount: promotionProvider.promotions.length,
            itemBuilder: (context, index) {
              final promotion = promotionProvider.promotions[index];
              return _buildPromotionCard(promotion);
            },
          ),
        );
      },
    );
  }

  Widget _buildPromotionCard(Promotion promotion) {
    final isActive = promotion.isValidNow();
    final isExpired = promotion.endDate.isBefore(DateTime.now());
    final isUpcoming = promotion.startDate.isAfter(DateTime.now());
    final isMobile = ResponsiveHelper.isMobile(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = screenWidth < 350;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isExpired) {
      statusColor = AppTheme.errorColor;
      statusText = 'Kedaluwarsa';
      statusIcon = Icons.error;
    } else if (isUpcoming) {
      statusColor = AppTheme.warningColor;
      statusText = 'Mendatang';
      statusIcon = Icons.schedule;
    } else if (isActive) {
      statusColor = AppTheme.successColor;
      statusText = 'Aktif';
      statusIcon = Icons.check_circle;
    } else {
      statusColor = AppTheme.neutral400;
      statusText = 'Nonaktif';
      statusIcon = Icons.pause_circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(isVerySmall ? 8 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: isVerySmall ? 40 : 50,
                  height: isVerySmall ? 40 : 50,
                  decoration: BoxDecoration(
                    color: _getTypeColor(promotion.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getTypeColor(promotion.type).withOpacity(0.2),
                    ),
                  ),
                  child: Icon(
                    _getTypeIcon(promotion.type),
                    color: _getTypeColor(promotion.type),
                    size: isVerySmall ? 20 : 24,
                  ),
                ),
                SizedBox(width: isVerySmall ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promotion.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isVerySmall ? 12 : 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isVerySmall ? 2 : 4),
                      Text(
                        promotion.description,
                        style: TextStyle(
                          fontSize: isVerySmall ? 10 : 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isVerySmall ? 2 : 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isVerySmall ? 4 : 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getTypeColor(
                                promotion.type,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getTypeLabel(promotion.type),
                              style: TextStyle(
                                fontSize: isVerySmall ? 8 : 10,
                                fontWeight: FontWeight.w500,
                                color: _getTypeColor(promotion.type),
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isVerySmall ? 4 : 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  statusIcon,
                                  size: isVerySmall ? 8 : 10,
                                  color: statusColor,
                                ),
                                SizedBox(width: isVerySmall ? 1 : 2),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: isVerySmall ? 8 : 10,
                                    fontWeight: FontWeight.w500,
                                    color: statusColor,
                                  ),
                                ),
                              ],
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
                      _showPromotionDialog(promotion: promotion);
                    } else if (value == 'delete') {
                      _showDeleteDialog(promotion);
                    } else if (value == 'toggle') {
                      context.read<PromotionProvider>().togglePromotionStatus(
                        promotion.id,
                      );
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
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            promotion.isActive ? Icons.pause : Icons.play_arrow,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(promotion.isActive ? 'Nonaktifkan' : 'Aktifkan'),
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
                      size: isVerySmall ? 16 : 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isVerySmall ? 8 : 12),

            // Bottom section with flexible layout
            if (isVerySmall)
              // For very small screens, stack vertically
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _getDiscountText(promotion),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _getTypeColor(promotion.type),
                      ),
                    ),
                  ),
                  if (promotion.couponCode != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.confirmation_number,
                            size: 10,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            promotion.couponCode!,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Berlaku: ${DateFormat('dd/MM/yyyy').format(promotion.startDate)}',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'Sampai: ${DateFormat('dd/MM/yyyy').format(promotion.endDate)}',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (promotion.maxUsage != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          'Digunakan: ${promotion.currentUsage}/${promotion.maxUsage}',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              )
            else
              // For normal screens, use row layout
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _getDiscountText(promotion),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _getTypeColor(promotion.type),
                            ),
                          ),
                        ),
                        if (promotion.couponCode != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.confirmation_number,
                                  size: 12,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  promotion.couponCode!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Berlaku: ${DateFormat('dd/MM/yyyy').format(promotion.startDate)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.end,
                        ),
                        Text(
                          'Sampai: ${DateFormat('dd/MM/yyyy').format(promotion.endDate)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.end,
                        ),
                        if (promotion.maxUsage != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Digunakan: ${promotion.currentUsage}/${promotion.maxUsage}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(PromotionType type) {
    switch (type) {
      case PromotionType.discount:
        return AppTheme.defaultPrimaryColor;
      case PromotionType.coupon:
        return AppTheme.warningColor;
      case PromotionType.happyHour:
        return Colors.purple;
      case PromotionType.bundle:
        return AppTheme.successColor;
    }
  }

  IconData _getTypeIcon(PromotionType type) {
    switch (type) {
      case PromotionType.discount:
        return Icons.percent;
      case PromotionType.coupon:
        return Icons.confirmation_number;
      case PromotionType.happyHour:
        return Icons.access_time;
      case PromotionType.bundle:
        return Icons.inventory;
    }
  }

  String _getTypeLabel(PromotionType type) {
    switch (type) {
      case PromotionType.discount:
        return 'Diskon';
      case PromotionType.coupon:
        return 'Kupon';
      case PromotionType.happyHour:
        return 'Happy Hour';
      case PromotionType.bundle:
        return 'Bundle';
    }
  }

  String _getDiscountText(Promotion promotion) {
    switch (promotion.discountType) {
      case DiscountType.percentage:
        return '${promotion.discountValue.toInt()}% OFF';
      case DiscountType.nominal:
        return NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        ).format(promotion.discountValue);
      case DiscountType.bogo:
        return 'BOGO';
    }
  }

  void _showPromotionDialog({Promotion? promotion}) {
    showDialog(
      context: context,
      builder: (context) => PromotionDialog(
        promotion: promotion,
        onSave: (promotionData) async {
          try {
            if (promotion == null) {
              final newPromotion = Promotion(
                id: const Uuid().v4(),
                name: promotionData['name'],
                description: promotionData['description'],
                type: promotionData['type'],
                discountType: promotionData['discountType'],
                discountValue: promotionData['discountValue'],
                minimumPurchase: promotionData['minimumPurchase'],
                maxUsage: promotionData['maxUsage'],
                startDate: promotionData['startDate'],
                endDate: promotionData['endDate'],
                applicableCategories: List<String>.from(
                  promotionData['applicableCategories'] ?? [],
                ),
                applicableProductIds: List<String>.from(
                  promotionData['applicableProductIds'] ?? [],
                ),
                couponCode: promotionData['couponCode'],
                happyHourStart: promotionData['happyHourStart'],
                happyHourEnd: promotionData['happyHourEnd'],
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              await context.read<PromotionProvider>().addPromotion(
                newPromotion,
              );
            } else {
              final updatedPromotion = promotion.copyWith(
                name: promotionData['name'],
                description: promotionData['description'],
                type: promotionData['type'],
                discountType: promotionData['discountType'],
                discountValue: promotionData['discountValue'],
                minimumPurchase: promotionData['minimumPurchase'],
                maxUsage: promotionData['maxUsage'],
                startDate: promotionData['startDate'],
                endDate: promotionData['endDate'],
                applicableCategories: List<String>.from(
                  promotionData['applicableCategories'] ?? [],
                ),
                applicableProductIds: List<String>.from(
                  promotionData['applicableProductIds'] ?? [],
                ),
                couponCode: promotionData['couponCode'],
                happyHourStart: promotionData['happyHourStart'],
                happyHourEnd: promotionData['happyHourEnd'],
                updatedAt: DateTime.now(),
              );
              await context.read<PromotionProvider>().updatePromotion(
                updatedPromotion,
              );
            }

            if (mounted) {
              _showSuccessSnackBar(
                promotion == null
                    ? 'Promosi berhasil ditambahkan'
                    : 'Promosi berhasil diperbarui',
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

  void _showDeleteDialog(Promotion promotion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.delete, color: AppTheme.errorColor, size: 20),
            const SizedBox(width: 8),
            const Text('Hapus Promosi'),
          ],
        ),
        content: Text('Apakah Anda yakin ingin menghapus "${promotion.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await context.read<PromotionProvider>().deletePromotion(
                  promotion.id,
                );
                if (mounted) {
                  Navigator.pop(context);
                  _showSuccessSnackBar('Promosi berhasil dihapus');
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

class PromotionDialog extends StatefulWidget {
  final Promotion? promotion;
  final Function(Map<String, dynamic>) onSave;

  const PromotionDialog({super.key, this.promotion, required this.onSave});

  @override
  State<PromotionDialog> createState() => _PromotionDialogState();
}

class _PromotionDialogState extends State<PromotionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _minimumPurchaseController = TextEditingController();
  final _maxUsageController = TextEditingController();
  final _couponCodeController = TextEditingController();

  PromotionType _selectedType = PromotionType.discount;
  DiscountType _selectedDiscountType = DiscountType.percentage;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  TimeOfDay? _happyHourStart;
  TimeOfDay? _happyHourEnd;

  // Product selection
  List<String> _selectedProductIds = [];
  List<String> _selectedCategories = [];
  String _productSelectionType = 'all'; // 'all', 'categories', 'products'

  @override
  void initState() {
    super.initState();
    if (widget.promotion != null) {
      _nameController.text = widget.promotion!.name;
      _descriptionController.text = widget.promotion!.description;
      _discountValueController.text = widget.promotion!.discountValue
          .toString();
      _minimumPurchaseController.text =
          widget.promotion!.minimumPurchase?.toString() ?? '';
      _maxUsageController.text = widget.promotion!.maxUsage?.toString() ?? '';
      _couponCodeController.text = widget.promotion!.couponCode ?? '';
      _selectedType = widget.promotion!.type;
      _selectedDiscountType = widget.promotion!.discountType;
      _startDate = widget.promotion!.startDate;
      _endDate = widget.promotion!.endDate;

      // Load existing product selection data
      _selectedCategories = List<String>.from(
        widget.promotion!.applicableCategories,
      );
      _selectedProductIds = List<String>.from(
        widget.promotion!.applicableProductIds,
      );

      // Determine product selection type based on existing data
      if (_selectedCategories.isNotEmpty) {
        _productSelectionType = 'categories';
      } else if (_selectedProductIds.isNotEmpty) {
        _productSelectionType = 'products';
      } else {
        _productSelectionType = 'all';
      }

      if (widget.promotion!.happyHourStart != null) {
        final startTime = widget.promotion!.happyHourStart!;
        _happyHourStart = TimeOfDay(
          hour: startTime.hour,
          minute: startTime.minute,
        );
      }
      if (widget.promotion!.happyHourEnd != null) {
        final endTime = widget.promotion!.happyHourEnd!;
        _happyHourEnd = TimeOfDay(hour: endTime.hour, minute: endTime.minute);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _minimumPurchaseController.dispose();
    _maxUsageController.dispose();
    _couponCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: ResponsiveHelper.isMobile(context) ? null : 500,
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
                      widget.promotion == null ? Icons.add : Icons.edit,
                      color: AppTheme.defaultPrimaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.promotion == null
                            ? 'Tambah Promosi'
                            : 'Edit Promosi',
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
                  label: 'Nama Promosi',
                  prefixIcon: Icons.local_offer,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama promosi tidak boleh kosong';
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Deskripsi tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Type Selection
                DropdownButtonFormField<PromotionType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipe Promosi',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: PromotionType.values.map((type) {
                    String label;
                    IconData icon;
                    switch (type) {
                      case PromotionType.discount:
                        label = 'Diskon';
                        icon = Icons.percent;
                        break;
                      case PromotionType.coupon:
                        label = 'Kupon';
                        icon = Icons.confirmation_number;
                        break;
                      case PromotionType.happyHour:
                        label = 'Happy Hour';
                        icon = Icons.access_time;
                        break;
                      case PromotionType.bundle:
                        label = 'Bundle';
                        icon = Icons.inventory;
                        break;
                    }
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(icon, size: 18),
                          const SizedBox(width: 8),
                          Text(label),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Discount Type Selection
                DropdownButtonFormField<DiscountType>(
                  value: _selectedDiscountType,
                  decoration: const InputDecoration(
                    labelText: 'Tipe Diskon',
                    prefixIcon: Icon(Icons.discount),
                  ),
                  items: DiscountType.values.map((type) {
                    String label;
                    switch (type) {
                      case DiscountType.percentage:
                        label = 'Persentase (%)';
                        break;
                      case DiscountType.nominal:
                        label = 'Nominal (Rp)';
                        break;
                      case DiscountType.bogo:
                        label = 'Buy One Get One';
                        break;
                    }
                    return DropdownMenuItem(value: type, child: Text(label));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDiscountType = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _discountValueController,
                        label: _selectedDiscountType == DiscountType.percentage
                            ? 'Nilai Diskon (%)'
                            : 'Nilai Diskon (Rp)',
                        prefixIcon:
                            _selectedDiscountType == DiscountType.percentage
                            ? Icons.percent
                            : Icons.attach_money,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nilai diskon tidak boleh kosong';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Nilai harus berupa angka';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _minimumPurchaseController,
                        label: 'Min. Pembelian (Rp)',
                        prefixIcon: Icons.shopping_cart,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_selectedType == PromotionType.coupon) ...[
                  CustomTextField(
                    controller: _couponCodeController,
                    label: 'Kode Kupon',
                    prefixIcon: Icons.confirmation_number,
                    validator: (value) {
                      if (_selectedType == PromotionType.coupon &&
                          (value == null || value.isEmpty)) {
                        return 'Kode kupon tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                CustomTextField(
                  controller: _maxUsageController,
                  label: 'Maksimal Penggunaan',
                  prefixIcon: Icons.numbers,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                // Product Selection Type
                Text(
                  'Pilih Produk yang Dapat Diskon',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Semua Produk'),
                        value: 'all',
                        groupValue: _productSelectionType,
                        onChanged: (value) {
                          setState(() {
                            _productSelectionType = value!;
                            _selectedCategories.clear();
                            _selectedProductIds.clear();
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Kategori Produk'),
                        value: 'categories',
                        groupValue: _productSelectionType,
                        onChanged: (value) {
                          setState(() {
                            _productSelectionType = value!;
                            _selectedProductIds.clear();
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Produk Spesifik'),
                        value: 'products',
                        groupValue: _productSelectionType,
                        onChanged: (value) {
                          setState(() {
                            _productSelectionType = value!;
                            _selectedCategories.clear();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (_productSelectionType == 'categories') ...[
                  const SizedBox(height: 8),
                  Consumer<ProductProvider>(
                    builder: (context, productProvider, child) {
                      final categories = productProvider.categories;
                      return Wrap(
                        spacing: 8,
                        children: categories.map((category) {
                          final isSelected = _selectedCategories.contains(
                            category,
                          );
                          return FilterChip(
                            label: Text(
                              category,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppTheme.defaultPrimaryColor,
                            backgroundColor: Colors.grey.shade100,
                            checkmarkColor: Colors.white,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedCategories.add(category);
                                } else {
                                  _selectedCategories.remove(category);
                                }
                              });
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
                if (_productSelectionType == 'products') ...[
                  const SizedBox(height: 8),
                  Consumer<ProductProvider>(
                    builder: (context, productProvider, child) {
                      final products = productProvider.products;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(
                            builder: (context) {
                              TextEditingController searchController =
                                  TextEditingController();

                              return Autocomplete<Product>(
                                optionsBuilder:
                                    (TextEditingValue textEditingValue) {
                                      if (textEditingValue.text.isEmpty) {
                                        return const Iterable<Product>.empty();
                                      }
                                      return products.where((Product product) {
                                        return product.name
                                            .toLowerCase()
                                            .contains(
                                              textEditingValue.text
                                                  .toLowerCase(),
                                            );
                                      });
                                    },
                                displayStringForOption: (Product option) =>
                                    option.name,
                                onSelected: (Product selection) {
                                  setState(() {
                                    if (!_selectedProductIds.contains(
                                      selection.id,
                                    )) {
                                      _selectedProductIds.add(selection.id);
                                    }
                                  });
                                  // Clear search field after selection
                                  searchController.clear();
                                },
                                fieldViewBuilder:
                                    (
                                      BuildContext context,
                                      TextEditingController
                                      textEditingController,
                                      FocusNode focusNode,
                                      VoidCallback onFieldSubmitted,
                                    ) {
                                      searchController = textEditingController;
                                      return TextField(
                                        controller: textEditingController,
                                        focusNode: focusNode,
                                        decoration: InputDecoration(
                                          labelText: 'Cari dan pilih produk',
                                          prefixIcon: const Icon(Icons.search),
                                          hintText:
                                              'Ketik nama produk untuk mencari...',
                                          suffixIcon:
                                              textEditingController
                                                  .text
                                                  .isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(Icons.clear),
                                                  onPressed: () {
                                                    textEditingController
                                                        .clear();
                                                  },
                                                )
                                              : null,
                                        ),
                                      );
                                    },
                                optionsViewBuilder:
                                    (
                                      BuildContext context,
                                      AutocompleteOnSelected<Product>
                                      onSelected,
                                      Iterable<Product> options,
                                    ) {
                                      return Align(
                                        alignment: Alignment.topLeft,
                                        child: Material(
                                          elevation: 4.0,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Container(
                                            constraints: const BoxConstraints(
                                              maxHeight: 200.0,
                                              maxWidth: 350.0,
                                            ),
                                            child: ListView.builder(
                                              padding: EdgeInsets.zero,
                                              itemCount: options.length,
                                              itemBuilder: (BuildContext context, int index) {
                                                final Product option = options
                                                    .elementAt(index);
                                                final bool isSelected =
                                                    _selectedProductIds
                                                        .contains(option.id);

                                                return Container(
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? AppTheme
                                                              .defaultPrimaryColor
                                                              .withOpacity(0.1)
                                                        : null,
                                                    border: isSelected
                                                        ? Border.all(
                                                            color: AppTheme
                                                                .defaultPrimaryColor
                                                                .withOpacity(
                                                                  0.3,
                                                                ),
                                                            width: 1,
                                                          )
                                                        : null,
                                                  ),
                                                  child: ListTile(
                                                    title: Text(
                                                      option.name,
                                                      style: TextStyle(
                                                        color: isSelected
                                                            ? AppTheme
                                                                  .defaultPrimaryColor
                                                            : Colors.black87,
                                                        fontWeight: isSelected
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                      ),
                                                    ),
                                                    subtitle: Text(
                                                      'Rp ${NumberFormat('#,###').format(option.price)}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: isSelected
                                                            ? AppTheme
                                                                  .defaultPrimaryColor
                                                                  .withOpacity(
                                                                    0.8,
                                                                  )
                                                            : Colors
                                                                  .grey
                                                                  .shade600,
                                                      ),
                                                    ),
                                                    leading: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: isSelected
                                                            ? AppTheme
                                                                  .defaultPrimaryColor
                                                            : Colors
                                                                  .transparent,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                        border: Border.all(
                                                          color: isSelected
                                                              ? AppTheme
                                                                    .defaultPrimaryColor
                                                              : Colors
                                                                    .grey
                                                                    .shade400,
                                                          width: 2,
                                                        ),
                                                      ),
                                                      child: Icon(
                                                        isSelected
                                                            ? Icons.check
                                                            : Icons.add,
                                                        color: isSelected
                                                            ? Colors.white
                                                            : Colors
                                                                  .grey
                                                                  .shade400,
                                                        size: 16,
                                                      ),
                                                    ),
                                                    onTap: () {
                                                      onSelected(option);
                                                    },
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                              );
                            },
                          ),
                          if (_selectedProductIds.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Produk yang dipilih (${_selectedProductIds.length}):',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: _selectedProductIds.map((productId) {
                                final product = products.firstWhere(
                                  (p) => p.id == productId,
                                  orElse: () => Product(
                                    id: productId,
                                    name: 'Produk tidak ditemukan',
                                    description:
                                        'Produk tidak ditemukan dalam database',
                                    price: 0,
                                    stock: 0,
                                    category: '',
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  ),
                                );
                                return Chip(
                                  label: Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  deleteIcon: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedProductIds.remove(productId);
                                    });
                                  },
                                  backgroundColor: AppTheme.defaultPrimaryColor,
                                  elevation: 2,
                                  shadowColor: AppTheme.defaultPrimaryColor
                                      .withOpacity(0.3),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
                const SizedBox(height: 12),
                // Date Selection
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setState(() {
                              _startDate = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal Mulai',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(_startDate),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate,
                            firstDate: _startDate,
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setState(() {
                              _endDate = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal Berakhir',
                            prefixIcon: Icon(Icons.event),
                          ),
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(_endDate),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Happy Hour Time Selection
                if (_selectedType == PromotionType.happyHour) ...[
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime:
                                  _happyHourStart ??
                                  const TimeOfDay(hour: 17, minute: 0),
                            );
                            if (time != null) {
                              setState(() {
                                _happyHourStart = time;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Jam Mulai',
                              prefixIcon: Icon(Icons.access_time),
                            ),
                            child: Text(
                              _happyHourStart?.format(context) ?? 'Pilih jam',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime:
                                  _happyHourEnd ??
                                  const TimeOfDay(hour: 19, minute: 0),
                            );
                            if (time != null) {
                              setState(() {
                                _happyHourEnd = time;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Jam Berakhir',
                              prefixIcon: Icon(Icons.schedule),
                            ),
                            child: Text(
                              _happyHourEnd?.format(context) ?? 'Pilih jam',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

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

    // Validate Happy Hour times if needed
    if (_selectedType == PromotionType.happyHour) {
      if (_happyHourStart == null || _happyHourEnd == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jam Happy Hour harus diisi'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final promotionData = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'type': _selectedType,
      'discountType': _selectedDiscountType,
      'discountValue': double.parse(_discountValueController.text),
      'minimumPurchase': _minimumPurchaseController.text.isEmpty
          ? null
          : double.parse(_minimumPurchaseController.text),
      'maxUsage': _maxUsageController.text.isEmpty
          ? null
          : int.parse(_maxUsageController.text),
      'startDate': _startDate,
      'endDate': _endDate,
      'couponCode': _selectedType == PromotionType.coupon
          ? _couponCodeController.text.trim()
          : null,
      'happyHourStart':
          _selectedType == PromotionType.happyHour && _happyHourStart != null
          ? DateTime(2024, 1, 1, _happyHourStart!.hour, _happyHourStart!.minute)
          : null,
      'happyHourEnd':
          _selectedType == PromotionType.happyHour && _happyHourEnd != null
          ? DateTime(2024, 1, 1, _happyHourEnd!.hour, _happyHourEnd!.minute)
          : null,
      'applicableCategories': _productSelectionType == 'categories'
          ? _selectedCategories
          : [],
      'applicableProductIds': _productSelectionType == 'products'
          ? _selectedProductIds
          : [],
    };

    widget.onSave(promotionData);
    Navigator.pop(context);
  }
}
