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

// Screen for creating and adding a new subscription
class AddSubscriptionScreen extends StatefulWidget {
  final VoidCallback? onSubscriptionSaved;
  final VoidCallback? toggleTheme;
  final bool isDarkMode;

  const AddSubscriptionScreen({
    super.key,
    this.onSubscriptionSaved,
    this.toggleTheme,
    this.isDarkMode = false,
  });

  @override
  State<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends State<AddSubscriptionScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController costController = TextEditingController();

  String selectedCategory = 'Entertainment';
  String selectedCurrency = 'LKR';
  DateTime? selectedDate;
  File? receiptImage;

  bool isLoading = false;
  double? previewLkr;
  final NumberFormat numFormat = NumberFormat('#,##0.00', 'en_US');

  @override
  void dispose() {
    nameController.dispose();
    costController.dispose();
    super.dispose();
  }

  // Live currency conversion to LKR preview
  void updatePreview() async {
    final text = costController.text.trim();
    if (text.isEmpty) {
      setState(() => previewLkr = null);
      return;
    }
    final amount = double.tryParse(text) ?? 0.0;
    if (amount <= 0) {
      setState(() => previewLkr = null);
      return;
    }
    if (selectedCurrency == 'LKR') {
      setState(() => previewLkr = amount);
      return;
    }
    final lkr = await CurrencyApiService.convertToLkr(amount, selectedCurrency);
    if (mounted) setState(() => previewLkr = lkr);
  }

  // Camera / Gallery Image Picker
  void pickImage(ImageSource source) async {
    final photo = await ImagePicker().pickImage(source: source, imageQuality: 75);
    if (photo != null) {
      setState(() => receiptImage = File(photo.path));
    }
  }

  // DatePicker Dialog
  void pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  // Save Subscription to Firebase
  void saveSubscription() async {
    if (nameController.text.trim().isEmpty || costController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter name and cost')));
      return;
    }
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a renewal date')));
      return;
    }

    setState(() => isLoading = true);

    String? receiptUrl;
    if (receiptImage != null && CloudinaryService.isConfigured) {
      receiptUrl = await CloudinaryService().uploadImage(receiptImage!);
    }

    final user = AppFirebaseService().currentUser;
    final userId = user?.uid ?? "demo";

    final newSub = Subscription(
      id: '',
      name: nameController.text.trim(),
      category: selectedCategory,
      monthlyCost: double.tryParse(costController.text.trim()) ?? 0.0,
      currency: selectedCurrency,
      renewalDate: DateFormat('yyyy-MM-dd').format(selectedDate!),
      receiptUrl: receiptUrl,
      createdAt: DateTime.now().toIso8601String(),
    );

    await AppFirebaseService().addSubscription(userId, newSub);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscription added successfully!'), backgroundColor: AppColors.success),
    );

    nameController.clear();
    costController.clear();
    setState(() {
      selectedDate = null;
      receiptImage = null;
      previewLkr = null;
      isLoading = false;
    });

    widget.onSubscriptionSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Subscription'),
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
            // Banner Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset('assets/images/apps_banner.jpg', height: 140, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 14),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Subscription Name', prefixIcon: Icon(Icons.subscriptions_outlined)),
                    ),
                    const SizedBox(height: 12),

                    // Category
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined)),
                      items: CategoryHelper.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => selectedCategory = val!),
                    ),
                    const SizedBox(height: 12),

                    // Cost & Currency
                    Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: TextFormField(
                            controller: costController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Monthly Cost', prefixIcon: Icon(Icons.payments_outlined)),
                            onChanged: (_) => updatePreview(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedCurrency,
                            items: CurrencyApiService.supportedCurrencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) {
                              setState(() => selectedCurrency = val!);
                              updatePreview();
                            },
                          ),
                        ),
                      ],
                    ),

                    if (selectedCurrency != 'LKR' && previewLkr != null) ...[
                      const SizedBox(height: 6),
                      Text('Converted: ≈ Rs. ${numFormat.format(previewLkr)}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                    const SizedBox(height: 12),

                    // Renewal Date
                    InkWell(
                      onTap: pickDate,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(selectedDate == null ? 'Select Renewal Date' : DateFormat('yyyy-MM-dd').format(selectedDate!)),
                            const Icon(Icons.calendar_today_outlined, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Receipt Photo
                    if (receiptImage != null) ...[
                      ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(receiptImage!, height: 130, fit: BoxFit.cover)),
                      TextButton(onPressed: () => setState(() => receiptImage = null), child: const Text('Remove Photo', style: TextStyle(color: AppColors.danger))),
                    ] else
                      Row(
                        children: [
                          Expanded(child: OutlinedButton.icon(onPressed: () => pickImage(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text('Camera'))),
                          const SizedBox(width: 8),
                          Expanded(child: OutlinedButton.icon(onPressed: () => pickImage(ImageSource.gallery), icon: const Icon(Icons.photo_library), label: const Text('Gallery'))),
                        ],
                      ),
                    const SizedBox(height: 18),

                    // Save Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: isLoading ? null : saveSubscription,
                      child: isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save Subscription', style: TextStyle(fontWeight: FontWeight.bold)),
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
}
