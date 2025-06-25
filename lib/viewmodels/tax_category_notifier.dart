// tax_category_notifier.dart
import 'package:flutter/material.dart';

class TaxCategoryNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}
