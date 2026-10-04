import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Helper class for subscription categories, icons, and colors
class CategoryHelper {
  static const List<String> categories = [
    'Entertainment',
    'Music',
    'Health',
    'Education',
    'AI Tools',
    'Bills',
    'Cloud Storage',
    'Gaming',
    'Other',
  ];

  static IconData getIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'entertainment': return Icons.movie_creation_outlined;
      case 'music': return Icons.music_note_rounded;
      case 'health': return Icons.favorite_border_rounded;
      case 'education': return Icons.school_outlined;
      case 'ai tools': return Icons.smart_toy_outlined;
      case 'bills': return Icons.receipt_long_outlined;
      case 'cloud storage': return Icons.cloud_outlined;
      case 'gaming': return Icons.sports_esports_outlined;
      default: return Icons.category_outlined;
    }
  }

  static Color getColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'entertainment': return const Color(0xFFEC4899);
      case 'music': return const Color(0xFF10B981);
      case 'health': return const Color(0xFFEF4444);
      case 'education': return const Color(0xFF8B5CF6);
      case 'ai tools': return const Color(0xFFF97316);
      case 'bills': return const Color(0xFFEAB308);
      case 'cloud storage': return const Color(0xFF06B6D4);
      case 'gaming': return const Color(0xFF6366F1);
      default: return AppColors.primary;
    }
  }
}

class CategoryItemRow extends StatelessWidget {
  final String categoryName;
  final int count;

  const CategoryItemRow({super.key, required this.categoryName, required this.count});

  @override
  Widget build(BuildContext context) {
    final color = CategoryHelper.getColor(categoryName);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withAlpha(35),
            child: Icon(CategoryHelper.getIcon(categoryName), color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(categoryName, style: const TextStyle(fontWeight: FontWeight.w600))),
          Text('$count SUB', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}
