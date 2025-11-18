import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// Order Tracking Screen with shipping timeline
class TrackingScreen extends StatelessWidget {
  final String orderId;
  final String trackingNumber;

  const TrackingScreen({
    super.key,
    required this.orderId,
    required this.trackingNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.pureWhite,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Track Order',
          style: TextStyle(
            color: AppTheme.primaryBlack,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Order Info Card
            Container(
              margin: const EdgeInsets.all(AppTheme.spacing2),
              padding: const EdgeInsets.all(AppTheme.spacing2),
              decoration: BoxDecoration(
                color: AppTheme.pureWhite,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlack,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing2),
                  _buildInfoRow('Order ID:', orderId),
                  const SizedBox(height: AppTheme.spacing1),
                  _buildInfoRow('Tracking Number:', trackingNumber),
                  const SizedBox(height: AppTheme.spacing1),
                  _buildInfoRow(
                    'Estimated Delivery:',
                    'Dec 25, 2024',
                    valueColor: AppTheme.primaryBlack,
                    valueBold: true,
                  ),
                ],
              ),
            ),

            // Shipping Timeline
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing2),
              padding: const EdgeInsets.all(AppTheme.spacing2),
              decoration: BoxDecoration(
                color: AppTheme.pureWhite,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shipping Timeline',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlack,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing3),
                  _buildTimelineItem(
                    'Order Placed',
                    'Your order has been confirmed',
                    'Dec 18, 2024 - 10:30 AM',
                    isCompleted: true,
                    isFirst: true,
                  ),
                  _buildTimelineItem(
                    'Order Accepted',
                    'Your order has been accepted by seller',
                    'Dec 18, 2024 - 11:00 AM',
                    isCompleted: true,
                  ),
                  _buildTimelineItem(
                    'In Transit',
                    'Your package is on the way',
                    'Dec 19, 2024 - 2:00 PM',
                    isCompleted: true,
                    isCurrent: true,
                  ),
                  _buildTimelineItem(
                    'Out for Delivery',
                    'Package is out for delivery',
                    'Pending',
                    isCompleted: false,
                  ),
                  _buildTimelineItem(
                    'Delivered',
                    'Package has been delivered',
                    'Pending',
                    isCompleted: false,
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacing2),

            // Package Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Packages',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlack,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing1),
                  _buildPackageCard(
                    'Package 1 of 1',
                    'Contains 3 items',
                    '2.5 kg',
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacing3),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.secondaryGrey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: valueColor ?? AppTheme.primaryBlack,
            fontWeight: valueBold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(
    String title,
    String subtitle,
    String time, {
    required bool isCompleted,
    bool isCurrent = false,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            if (!isFirst)
              Container(
                width: 2,
                height: 20,
                color: isCompleted ? AppTheme.successGreen : AppTheme.lightGrey,
              ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppTheme.successGreen
                    : AppTheme.backgroundWhite,
                border: Border.all(
                  color: isCompleted ? AppTheme.successGreen : AppTheme.lightGrey,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: AppTheme.pureWhite,
                    )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: isCompleted && !isCurrent
                    ? AppTheme.successGreen
                    : AppTheme.lightGrey,
              ),
          ],
        ),
        const SizedBox(width: AppTheme.spacing2),
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isCurrent
                      ? AppTheme.successGreen
                      : isCompleted
                          ? AppTheme.primaryBlack
                          : AppTheme.secondaryGrey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.secondaryGrey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.secondaryGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPackageCard(String packageNum, String items, String weight) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing2),
      padding: const EdgeInsets.all(AppTheme.spacing2),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing2),
            decoration: BoxDecoration(
              color: AppTheme.backgroundWhite,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              color: AppTheme.primaryBlack,
              size: 32,
            ),
          ),
          const SizedBox(width: AppTheme.spacing2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  packageNum,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$items • $weight',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.secondaryGrey,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppTheme.secondaryGrey,
          ),
        ],
      ),
    );
  }
}
