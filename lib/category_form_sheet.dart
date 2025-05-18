import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart'
    as FlutterIconPicker;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp
import '../models/budget_category_model.dart';
import '../providers/modern_budget_provider.dart';

class CategoryFormSheet extends StatefulWidget {
  final BudgetCategoryModel? existingCategory;

  const CategoryFormSheet({super.key, this.existingCategory});

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late double _allocatedAmount;
  IconData _selectedIcon = Icons.category;
  Color _selectedColor = Colors.orangeAccent; // Default color

  bool get _isEditing => widget.existingCategory != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final cat = widget.existingCategory!;
      _name = cat.name;
      _allocatedAmount = cat.allocatedAmount;
      _selectedIcon = cat.iconData;
      _selectedColor = cat.color;
    } else {
      _name = '';
      _allocatedAmount = 0.0;
    }
  }

  void _pickIcon() async {
    IconData? icon = await FlutterIconPicker.showIconPicker(
      context,
      iconPackModes: [IconPack.material],
      title: const Text('Pick an icon'),
      searchHintText: 'Search icon...',
      closeChild: const Text('Close'),
    );

    if (icon != null) {
      setState(() => _selectedIcon = icon);
    }
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Pick a color'),
            content: SingleChildScrollView(
              child: BlockPicker(
                pickerColor: _selectedColor,
                onColorChanged:
                    (color) => setState(() => _selectedColor = color),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Done'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final provider = Provider.of<ModernBudgetProvider>(
        context,
        listen: false,
      );

      final category = BudgetCategoryModel(
        id:
            _isEditing
                ? widget.existingCategory!.id
                : const Uuid().v4(), // Use existing ID if editing
        name: _name,
        allocatedAmount: _allocatedAmount,
        spentAmount:
            _isEditing
                ? widget.existingCategory!.spentAmount
                : 0.0, // Preserve spent amount
        iconCodepoint: _selectedIcon.codePoint,
        iconFontFamily: _selectedIcon.fontFamily!,
        colorHex:
            _selectedColor.value
                .toRadixString(16)
                .padLeft(8, '0')
                .toUpperCase(), // ARGB
        createdAt:
            _isEditing ? widget.existingCategory!.createdAt : Timestamp.now(),
      );

      if (_isEditing) {
        provider.updateCategory(category);
      } else {
        provider.addCategory(category);
      }
      Navigator.of(context).pop(); // Close the bottom sheet
    }
  }

  @override
  Widget build(BuildContext context) {
    // Makes the sheet's content start above the keyboard
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Important for bottom sheet
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'Edit Category' : 'Add New Category',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter a name'
                            : null,
                onSaved: (value) => _name = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _allocatedAmount.toStringAsFixed(0),
                decoration: const InputDecoration(
                  labelText: 'Allocated Amount',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter an amount';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  if (double.parse(value) < 0)
                    return 'Amount cannot be negative';
                  return null;
                },
                onSaved:
                    (value) =>
                        _allocatedAmount = double.tryParse(value!) ?? 0.0,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickIcon,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Icon',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Icon(_selectedIcon, color: _selectedColor),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _pickColor,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Color',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Container(
                              width: 24,
                              height: 24,
                              color: _selectedColor,
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(
                  _isEditing
                      ? Icons.save_alt_outlined
                      : Icons.add_circle_outline,
                ),
                label: Text(_isEditing ? 'Save Changes' : 'Add Category'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _submitForm,
              ),
            ],
          ),
        ),
      ).animate().slideY(
        begin: 0.3,
        end: 0,
        duration: 300.ms,
        curve: Curves.easeOutCubic,
      ),
    );
  }
}
