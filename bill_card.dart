import 'package:bill_manager/core/theme/app_colors.dart';
import 'package:bill_manager/core/theme/app_font_sizes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/bill_entity.dart';
import 'flip_text.dart';

class BillCard extends StatelessWidget {
  final BillEntity bill;
  final int stackPosition;

  const BillCard({super.key, required this.bill, this.stackPosition = 0});

  @override
  Widget build(BuildContext context) {
    final shadows = stackPosition > 0
        ? [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.03 + (stackPosition * 0.01),
              ),
              blurRadius: 6.0 + (stackPosition * 1.0),
              offset: Offset(0, 1.0 + stackPosition * 0.3),
            ),
          ]
        : const <BoxShadow>[];

    return Container(
      height: 102,
      margin: const EdgeInsets.only(bottom: 0.6, left: 16, right: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
        boxShadow: shadows,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            _buildLogo(),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    bill.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppFontSizes.md,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bill.subTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppFontSizes.sm,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [_buildPayButton(), _buildStatus()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    if (bill.logoUrl.isNotEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CachedNetworkImage(
              imageUrl: bill.logoUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.image_not_supported_outlined, size: 20),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: const Icon(Icons.account_balance_wallet_outlined, size: 20),
    );
  }

  Widget _buildPayButton() {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        child: Text(
          'Pay ${_formatAmount(bill.amount)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: AppFontSizes.sm,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildStatus() {
    return SizedBox(
      width: 120,
      child: Center(
        child: bill.flipper != null
            ? FlipperTextWidget(
                flipper: bill.flipper!,
                fallbackText: bill.footerText ?? '',
              )
            : Text(
                (bill.footerText ?? '').toLowerCase(),
                style: const TextStyle(
                  fontSize: AppFontSizes.xs,
                  color: AppColors.statusDue,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }

  String _formatAmount(String amount) {
    String cleanAmount = amount.replaceAll(RegExp(r'[₹,\s]'), '');
    double? value = double.tryParse(cleanAmount);

    if (value == null) return amount;

    if (value >= 10000000) {
      double crores = value / 10000000;
      return crores % 1 == 0
          ? '₹${crores.toInt()}Cr'
          : '₹${crores.toStringAsFixed(2)}Cr';
    } else if (value >= 100000) {
      double lakhs = value / 100000;
      return lakhs % 1 == 0
          ? '₹${lakhs.toInt()}L'
          : '₹${lakhs.toStringAsFixed(2)}L';
    } else {
      return value % 1 == 0
          ? '₹${value.toInt()}'
          : '₹${value.toStringAsFixed(2)}';
    }
  }
}
