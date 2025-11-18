import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// PrestaShop-style breadcrumb navigation
/// Example: Home > Men > Shoes > Sneakers
class BreadcrumbBar extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const BreadcrumbBar({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing2,
        vertical: AppTheme.spacing1,
      ),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        boxShadow: AppTheme.softShadow,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              GestureDetector(
                onTap: items[i].onTap,
                child: Text(
                  items[i].label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: i == items.length - 1
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: i == items.length - 1
                        ? AppTheme.primaryBlack
                        : AppTheme.secondaryGrey,
                  ),
                ),
              ),
              if (i < items.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppTheme.secondaryGrey,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;

  BreadcrumbItem({
    required this.label,
    this.onTap,
  });
}
