import 'package:flutter/material.dart';

const List<String> expenseCategories = [
  "Food & Groceries",
  "Dining & Takeout",
  "Transportation",
  "Utilities",
  "Housing & Rent",
  "Health & Personal Care",
  "Entertainment & Subscriptions",
  "Shopping & Miscellaneous",
];
// lib/util/default_categories.dart
// For Icons

// This list should align with the categories used in ScanReceiptScreen's picker
final List<Map<String, dynamic>> defaultBudgetCategoryData = [
  {
    "name": "Food & Groceries",
    "iconCodepoint": Icons.shopping_basket_outlined.codePoint,
    "iconFontFamily": Icons.shopping_basket_outlined.fontFamily!,
    "colorHex": "FF4CAF50", // Green
    "isDefault": true, // Add a flag to identify them if needed later
  },
  {
    "name": "Dining & Takeout",
    "iconCodepoint": Icons.restaurant_menu_outlined.codePoint,
    "iconFontFamily": Icons.restaurant_menu_outlined.fontFamily!,
    "colorHex": "FFFF9800", // Orange
    "isDefault": true,
  },
  {
    "name": "Transportation",
    "iconCodepoint": Icons.directions_car_outlined.codePoint,
    "iconFontFamily": Icons.directions_car_outlined.fontFamily!,
    "colorHex": "FF2196F3", // Blue
    "isDefault": true,
  },
  {
    "name": "Utilities",
    "iconCodepoint": Icons.lightbulb_outline.codePoint,
    "iconFontFamily": Icons.lightbulb_outline.fontFamily!,
    "colorHex": "FFFFC107", // Amber (was Yellow, made it a bit richer)
    "isDefault": true,
  },
  {
    "name": "Housing & Rent",
    "iconCodepoint": Icons.home_outlined.codePoint,
    "iconFontFamily": Icons.home_outlined.fontFamily!,
    "colorHex": "FF795548", // Brown
    "isDefault": true,
  },
  {
    "name": "Health & Personal Care",
    "iconCodepoint": Icons.healing_outlined.codePoint,
    "iconFontFamily": Icons.healing_outlined.fontFamily!,
    "colorHex": "FFE91E63", // Pink
    "isDefault": true,
  },
  {
    "name": "Entertainment & Subscriptions",
    "iconCodepoint": Icons.movie_filter_outlined.codePoint,
    "iconFontFamily": Icons.movie_filter_outlined.fontFamily!,
    "colorHex": "FF9C27B0", // Purple
    "isDefault": true,
  },
  {
    "name": "Shopping & Miscellaneous",
    "iconCodepoint": Icons.shopping_bag_outlined.codePoint,
    "iconFontFamily": Icons.shopping_bag_outlined.fontFamily!,
    "colorHex": "FF607D8B", // Blue Grey
    "isDefault": true,
  },
];
