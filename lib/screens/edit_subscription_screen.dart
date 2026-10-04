import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../services/cloudinary_service.dart';
import '../services/currency_api_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/category_badge.dart';
import '../widgets/subscription_card.dart';

/// Edit Subscription Screen (Master/Detail Flow)
/// Short, clean, beginner-friendly (lecturer style)
class EditSubscriptionScreen extends StatefulWidget {
  final Subscription? initialSubscriptionToEdit;
  final VoidCallback? onClearedSelection;
  final VoidCallback? toggleTheme;
  final bool isDarkMode;

  const EditSubscriptionScreen({
    super.key,
    this.initialSubscriptionToEdit,
    this.onClearedSelection,
    this.toggleTheme,
    this.isDarkMode = false,
  });

  @override
  State<EditSubscriptionScreen> createState() => _EditSubscriptionScreenState();
}

class _EditSubscriptionScreenState extends State<EditSubscriptionScreen> {
  Subscription? selectedSub;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController costController = TextEditingController();

  String selectedCategory = 'Entertainment';
  String selectedCurrency = 'LKR';
  DateTime? selectedDate;

  String? currentReceiptUrl;
  File? newReceiptFile;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSubscriptionToEdit != null) selectSub(widget.initialSubscriptionToEdit!);
  }

  @override
  void didUpdateWidget(covariant EditSubscriptionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSubscriptionToEdit != null &&
        widget.initialSubscriptionToEdit?.id != oldWidget.initialSubscriptionToEdit?.id) {
      selectSub(widget.initialSubscriptionToEdit!);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    costController.dispose();
    super.dispose();
  }

  void selectSub(Subscription sub) {
    setState(() {
      selectedSub = sub;
      nameController.text = sub.name;
      costController.text = sub.monthlyCost.toString();
      selectedCategory = sub.category;
      selectedCurrency = sub.currency;
      currentReceiptUrl = sub.receiptUrl;
      newReceiptFile = null;
      try {
        selectedDate = DateTime.parse(sub.renewalDate);
      } catch (_) {
        selectedDate = DateTime.now();
      }
    });
  }

  void clearSub() {
    setState(() {
      selectedSub = null;
      newReceiptFile = null;
      currentReceiptUrl = null;
    });
    widget.onClearedSelection?.call();
  }

  void pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  void pickNewPhoto(ImageSource source) async {
    final photo = await ImagePicker().pickImage(source: source, imageQuality: 75);
    if (photo != null) setState(() => newReceiptFile = File(photo.path));
  }

  // Update subscription in Firebase
  void updateSub() async {
    if (nameController.text.trim().isEmpty || costController.text.trim().isEmpty) return;
    setState(() => isSaving = true);

    String? receiptUrl = currentReceiptUrl;
    if (newReceiptFile != null && CloudinaryService.isConfigured) {
      receiptUrl = await CloudinaryService().uploadImage(newReceiptFile!);
    }

    final user = AppFirebaseService().currentUser;
    final userId = user?.uid ?? "demo";

    final updated = selectedSub!.copyWith(
      name: nameController.text.trim(),
      category: selectedCategory,
      monthlyCost: double.tryParse(costController.text.trim()) ?? 0.0,
      currency: selectedCurrency,
      renewalDate: selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : selectedSub!.renewalDate,
      receiptUrl: receiptUrl,
    );

    await AppFirebaseService().updateSubscription(userId, updated);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscription updated successfully!'), backgroundColor: AppColors.success),
    );
    setState(() => isSaving = false);
    clearSub();
  }

  // Delete subscription confirmation dialog
  void confirmDelete(Subscription sub) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Subscription'),
        content: Text('Delete "${sub.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final user = AppFirebaseService().currentUser;
              final userId = user?.uid ?? "demo";
              await AppFirebaseService().deleteSubscription(userId, sub.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted "${sub.name}"')));
              clearSub();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AppFirebaseService().currentUser;
    final userId = user?.uid ?? "demo";

    // 1. DETAIL / EDIT VIEW
    if (selectedSub != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Update Subscription'),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: clearSub),
          actions: [
            if (widget.toggleTheme != null)
              IconButton(
                icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                tooltip: widget.isDarkMode ? 'Light Mode' : 'Dark Mode',
                onPressed: widget.toggleTheme,
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset('assets/images/desk_banner.jpg', height: 140, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 14),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Subscription Name', prefixIcon: Icon(Icons.subscriptions_outlined))),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined)),
                        items: CategoryHelper.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) => setState(() => selectedCategory = val!),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: TextFormField(
                              controller: costController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Monthly Cost', prefixIcon: Icon(Icons.payments_outlined)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedCurrency,
                              items: CurrencyApiService.supportedCurrencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: (val) => setState(() => selectedCurrency = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      InkWell(
                        onTap: pickDate,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(selectedDate == null ? 'Select Date' : DateFormat('yyyy-MM-dd').format(selectedDate!)),
                              const Icon(Icons.calendar_today_outlined, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Receipt Photo Management
                      if (newReceiptFile != null) ...[
                        ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(newReceiptFile!, height: 130, fit: BoxFit.cover)),
                        TextButton(onPressed: () => setState(() => newReceiptFile = null), child: const Text('Remove Photo', style: TextStyle(color: AppColors.danger))),
                      ] else if (currentReceiptUrl != null && currentReceiptUrl!.isNotEmpty) ...[
                        ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(currentReceiptUrl!, height: 130, fit: BoxFit.cover)),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                          onPressed: () => setState(() => currentReceiptUrl = null),
                          child: const Text('Remove Current Receipt'),
                        ),
                      ],

                      Row(
                        children: [
                          Expanded(child: OutlinedButton.icon(onPressed: () => pickNewPhoto(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text('Camera'))),
                          const SizedBox(width: 8),
                          Expanded(child: OutlinedButton.icon(onPressed: () => pickNewPhoto(ImageSource.gallery), icon: const Icon(Icons.photo_library), label: const Text('Gallery'))),
                        ],
                      ),
                      const SizedBox(height: 18),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: isSaving ? null : updateSub,
                        child: isSaving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Update Subscription', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),

                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
                        onPressed: () => confirmDelete(selectedSub!),
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                        label: const Text('Delete Subscription', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. MASTER LIST VIEW (ListView.builder)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Subscriptions'),
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
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final list = snapshot.data ?? [];

          if (list.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.subscriptions_outlined, size: 48, color: AppColors.primary),
                  SizedBox(height: 12),
                  Text('No subscriptions available.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Add a subscription to view or edit it here.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final sub = list[index];
              return SubscriptionCard(
                subscription: sub,
                onEdit: () => selectSub(sub),
                onDelete: () => confirmDelete(sub),
              );
            },
          );
        },
      ),
    );
  }
}
