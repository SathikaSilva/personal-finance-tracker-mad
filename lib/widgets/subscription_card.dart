import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../services/currency_api_service.dart';
import '../theme/app_theme.dart';
import 'category_badge.dart';

// Card widget to display subscription details with category icon, cost, renewal countdown, and action buttons
class SubscriptionCard extends StatefulWidget {
  final Subscription subscription;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends State<SubscriptionCard> {
  double? convertedLkr;
  final NumberFormat numFormat = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    loadConversion();
  }

  void loadConversion() async {
    final sub = widget.subscription;
    if (sub.currency == 'LKR') {
      setState(() => convertedLkr = sub.monthlyCost);
      return;
    }
    final lkr = await CurrencyApiService.convertToLkr(sub.monthlyCost, sub.currency);
    if (mounted) {
      setState(() => convertedLkr = lkr);
    }
  }

  // Open receipt image in dialog
  void showReceiptDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.subscription.name} Receipt'),
        content: widget.subscription.receiptUrl != null
            ? Image.network(widget.subscription.receiptUrl!, fit: BoxFit.contain)
            : const Text('No receipt image available'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.subscription;
    final color = CategoryHelper.getColor(sub.category);
    final days = sub.daysUntilRenewal;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Icon
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withAlpha(35),
                  child: Icon(CategoryHelper.getIcon(sub.category), color: color, size: 22),
                ),
                const SizedBox(width: 12),

                // Name & Renewal Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sub.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('${sub.category} • Renews ${sub.renewalDate}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),

                // Cost & Days Left Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      sub.currency == 'LKR' ? 'Rs. ${numFormat.format(sub.monthlyCost)}' : '${sub.currency} ${numFormat.format(sub.monthlyCost)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    if (sub.currency != 'LKR' && convertedLkr != null)
                      Text('≈ Rs. ${numFormat.format(convertedLkr)}', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: days <= 3 ? AppColors.danger.withAlpha(30) : AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        days <= 0 ? 'Overdue' : '$days days left',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: days <= 3 ? AppColors.danger : AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (sub.receiptUrl != null && sub.receiptUrl!.isNotEmpty)
                  TextButton.icon(
                    onPressed: showReceiptDialog,
                    icon: const Icon(Icons.receipt_long, size: 16, color: Colors.blue),
                    label: const Text('Receipt', style: TextStyle(color: Colors.blue, fontSize: 12)),
                  ),
                if (widget.onEdit != null)
                  TextButton.icon(
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit, size: 16, color: AppColors.primary),
                    label: const Text('Edit', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                  ),
                if (widget.onDelete != null)
                  TextButton.icon(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                    label: const Text('Delete', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
