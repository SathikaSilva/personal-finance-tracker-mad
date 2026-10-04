import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../services/currency_api_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/category_badge.dart';
import '../widgets/subscription_card.dart';

/// Dashboard Screen
/// Compact, simple, beginner-friendly (lecturer style)
class DashboardScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;
  final Function(Subscription sub)? onEditSubscription;
  final VoidCallback? toggleTheme;
  final bool isDarkMode;

  const DashboardScreen({
    super.key,
    this.onNavigateTab,
    this.onEditSubscription,
    this.toggleTheme,
    this.isDarkMode = false,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String userName = AppFirebaseService.currentUserName;
  String dailyTip = "Some of life's best lessons are learnt at the worst times.";
  final NumberFormat currencyFormat = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    userName = AppFirebaseService.formatName(AppFirebaseService().currentUser);
    loadTip();
    loadUserName();
  }

  // Load logged in user name
  void loadUserName() async {
    final user = AppFirebaseService().currentUser;
    if (user != null) {
      String? foundName;
      if (user.displayName != null && user.displayName!.isNotEmpty && user.displayName != "User") {
        foundName = user.displayName;
      } else {
        final profile = await AppFirebaseService().getUserProfile(user.uid);
        if (profile != null && profile['name'] != null && profile['name'].toString().isNotEmpty && profile['name'].toString() != "User") {
          foundName = profile['name'].toString();
        }
      }
      final resolved = AppFirebaseService.formatName(user, foundName);
      if (mounted) setState(() => userName = resolved);
      AppFirebaseService.currentUserName = resolved;
    }
  }

  // Fetch tip from External API
  void loadTip() async {
    final tip = await CurrencyApiService.getDailyTip();
    if (mounted) setState(() => dailyTip = tip);
  }

  // Calculate total monthly spending in LKR
  Future<double> getTotalSpending(List<Subscription> list) async {
    double total = 0.0;
    for (var sub in list) {
      if (sub.currency == 'LKR') {
        total += sub.monthlyCost;
      } else {
        total += await CurrencyApiService.convertToLkr(sub.monthlyCost, sub.currency);
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final user = AppFirebaseService().currentUser;
    final userId = user?.uid ?? "demo";
    final displayName = (userName.isNotEmpty && userName != "User")
        ? userName
        : AppFirebaseService.formatName(user);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            Text('Welcome, $displayName!', style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
        actions: [
          if (widget.toggleTheme != null)
            IconButton(
              icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
              tooltip: widget.isDarkMode ? 'Light Mode' : 'Dark Mode',
              onPressed: widget.toggleTheme,
            ),
        ],
      ),
      body: StreamBuilder<List<Subscription>>(
        stream: AppFirebaseService().getSubscriptionsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final subs = snapshot.data ?? [];

          // Calculate category counts
          Map<String, int> catCounts = {for (var c in CategoryHelper.categories) c: 0};
          for (var s in subs) {
            catCounts[s.category] = (catCounts[s.category] ?? 0) + 1;
          }

          return FutureBuilder<double>(
            future: getTotalSpending(subs),
            builder: (context, spendSnap) {
              final total = spendSnap.data ?? 0.0;

              // Responsive Layout using OrientationBuilder (Lecturer style)
              return OrientationBuilder(
                builder: (context, orientation) {
                  // 1. Landscape Layout: Distinct 2-column view
                  if (orientation == Orientation.landscape) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column: Daily Tip, Total Spending Card, Categories
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildTipBanner(),
                                _buildSpendingCard(total),
                                const SizedBox(height: 8),
                                _buildCategoriesCard(catCounts),
                              ],
                            ),
                          ),
                          // Right Column: Summary Card, Upcoming Renewals, Add Button, Footer
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildSummaryCard(subs.length, total),
                                const SizedBox(height: 8),
                                _buildRenewalsSection(subs, userId),
                                const SizedBox(height: 16),
                                _buildAddButton(),
                                const SizedBox(height: 16),
                                _buildFooter(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // 2. Portrait Layout: Standard single vertical column
                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTipBanner(),
                        _buildDeskBanner(),
                        const SizedBox(height: 12),
                        _buildSpendingCard(total),
                        const SizedBox(height: 16),
                        _buildRenewalsSection(subs, userId),
                        const SizedBox(height: 12),
                        _buildCategoriesCard(catCounts),
                        const SizedBox(height: 12),
                        _buildSummaryCard(subs.length, total),
                        const SizedBox(height: 16),
                        _buildAddButton(),
                        const SizedBox(height: 16),
                        _buildFooter(),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ================= HELPER WIDGETS (LECTURER STYLE) =================

  // 1. Daily Tip Banner
  Widget _buildTipBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F1F5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DAILY TIP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary)),
                  const SizedBox(height: 2),
                  Text('"$dailyTip"', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.black87)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Desk Banner Image
  Widget _buildDeskBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset('assets/images/desk_banner.jpg', height: 160, width: double.infinity, fit: BoxFit.cover),
      ),
    );
  }

  // 3. Total Monthly Spending Card with AnimatedSwitcher (Lecturer style)
  Widget _buildSpendingCard(double total) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            const Text('Total Monthly Spending', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
              child: Text(
                'Rs. ${currencyFormat.format(total)}',
                key: ValueKey<double>(total),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Upcoming Renewals Header & List
  Widget _buildRenewalsSection(List<Subscription> subs, String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Upcoming Renewals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (subs.isNotEmpty)
                GestureDetector(
                  onTap: () => widget.onNavigateTab?.call(2),
                  child: const Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (subs.isEmpty)
          const Card(
            margin: EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 36, color: AppColors.primary),
                  SizedBox(height: 10),
                  Text('No subscriptions yet', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Add your first subscription to start tracking.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          )
        else
          for (var sub in subs.take(3))
            SubscriptionCard(
              subscription: sub,
              onEdit: () => widget.onEditSubscription?.call(sub),
              onDelete: () => AppFirebaseService().deleteSubscription(userId, sub.id),
            ),
      ],
    );
  }

  // 5. Categories Card
  Widget _buildCategoriesCard(Map<String, int> catCounts) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pie_chart_outline, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Text('Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 14),
            for (var cat in CategoryHelper.categories)
              CategoryItemRow(categoryName: cat, count: catCounts[cat] ?? 0),
          ],
        ),
      ),
    );
  }

  // 6. Active Subscriptions & Cost Card
  Widget _buildSummaryCard(int count, double total) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Active Subscriptions', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('$count', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple)),
                ],
              ),
            ),
            Container(width: 1, height: 35, color: Colors.grey.withAlpha(50)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Cost', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('Rs. ${currencyFormat.format(total)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 7. Add Subscription Button
  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: () => widget.onNavigateTab?.call(1),
        child: const Text('+ Add Subscription', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // 8. Footer
  Widget _buildFooter() {
    return const Center(
      child: Column(
        children: [
          Text('Personal Finance Tracker', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          Text('© 2026 Personal Finance Tracker v1.0.0', style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
