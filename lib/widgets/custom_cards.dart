import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool isElevated;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.boxShadow,
    this.borderRadius,
    this.onTap,
    this.isElevated = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: margin ?? const EdgeInsets.all(AppTheme.spacing4),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.cardColor,
        borderRadius:
            borderRadius ?? BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow:
            boxShadow ??
            (isElevated ? AppTheme.shadowMedium : AppTheme.shadowSmall),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppTheme.spacing16),
        child: child,
      ),
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius:
              borderRadius ?? BorderRadius.circular(AppTheme.radiusMedium),
          child: card,
        ),
      );
    }

    return card;
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool showTrend;
  final double? trendValue;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
    this.showTrend = false,
    this.trendValue,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return ModernCard(
      onTap: onTap,
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallCard = constraints.maxWidth < 160;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row with icon and trend
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallCard ? 6 : 8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: isSmallCard ? 18 : 20,
                    ),
                  ),
                  if (showTrend && trendValue != null) ...[
                    const SizedBox(width: 4),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallCard ? 4 : 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: trendValue! >= 0
                                ? AppTheme.successColor.withOpacity(0.1)
                                : AppTheme.errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSmall,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                trendValue! >= 0
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                size: isSmallCard ? 12 : 14,
                                color: trendValue! >= 0
                                    ? AppTheme.successColor
                                    : AppTheme.errorColor,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  '${trendValue!.abs().toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: isSmallCard ? 9 : 10,
                                    fontWeight: FontWeight.w600,
                                    color: trendValue! >= 0
                                        ? AppTheme.successColor
                                        : AppTheme.errorColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              SizedBox(height: isSmallCard ? 8 : 12),

              // Value text
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmallCard ? 18 : 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.neutral900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              SizedBox(height: isSmallCard ? 2 : 4),

              // Title text
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallCard ? 11 : 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.neutral600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Subtitle if exists
              if (subtitle != null) ...[
                SizedBox(height: isSmallCard ? 2 : 4),
                Flexible(
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: isSmallCard ? 9 : 10,
                      color: AppTheme.neutral500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }
}

class ActionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isEnabled;

  const ActionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: isEnabled ? onTap : null,
      child: Container(
        constraints: const BoxConstraints(minHeight: 100),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isEnabled ? color : AppTheme.neutral400,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isEnabled
                        ? AppTheme.neutral900
                        : AppTheme.neutral400,
                  ),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppTheme.spacing4),
                Flexible(
                  child: Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isEnabled
                          ? AppTheme.neutral600
                          : AppTheme.neutral400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8));
  }
}

class UserCard extends StatelessWidget {
  final String name;
  final String username;
  final String role;
  final bool isActive;
  final String? avatarUrl;
  final VoidCallback? onTap;
  final List<PopupMenuEntry<String>>? menuItems;
  final void Function(String)? onMenuSelected;

  const UserCard({
    super.key,
    required this.name,
    required this.username,
    required this.role,
    required this.isActive,
    this.avatarUrl,
    this.onTap,
    this.menuItems,
    this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: onTap,
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : AppTheme.neutral200,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: isActive
                    ? AppTheme.primaryColor.withOpacity(0.3)
                    : AppTheme.neutral300,
                width: 2,
              ),
            ),
            child: avatarUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    child: Image.network(
                      avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar();
                      },
                    ),
                  )
                : _buildDefaultAvatar(),
          ),
          const SizedBox(width: AppTheme.spacing12),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppTheme.neutral900 : AppTheme.neutral500,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  '@$username',
                  style: TextStyle(
                    fontSize: 14,
                    color: isActive
                        ? AppTheme.primaryColor
                        : AppTheme.neutral400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing8,
                        vertical: AppTheme.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: _getRoleColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
                      ),
                      child: Text(
                        role,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getRoleColor(),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing8,
                        vertical: AppTheme.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.successColor.withOpacity(0.1)
                            : AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
                      ),
                      child: Text(
                        isActive ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Menu Button
          if (menuItems != null && onMenuSelected != null)
            PopupMenuButton<String>(
              onSelected: onMenuSelected,
              itemBuilder: (context) => menuItems!,
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacing8),
                decoration: BoxDecoration(
                  color: AppTheme.neutral100,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: const Icon(
                  Icons.more_vert,
                  size: 20,
                  color: AppTheme.neutral600,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2, end: 0);
  }

  Widget _buildDefaultAvatar() {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isActive ? AppTheme.primaryColor : AppTheme.neutral500,
        ),
      ),
    );
  }

  Color _getRoleColor() {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppTheme.errorColor;
      case 'owner':
      case 'pemilik':
        return AppTheme.warningColor;
      case 'cashier':
      case 'kasir':
        return AppTheme.primaryColor;
      default:
        return AppTheme.neutral500;
    }
  }
}

class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ModernCard(
        padding: const EdgeInsets.all(AppTheme.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              decoration: BoxDecoration(
                color: AppTheme.neutral100,
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              ),
              child: Icon(icon, size: 48, color: AppTheme.neutral400),
            ),
            const SizedBox(height: AppTheme.spacing20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.neutral900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: AppTheme.neutral600),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppTheme.spacing20),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionText!),
                style: AppTheme.primaryButtonStyle,
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8));
  }
}
