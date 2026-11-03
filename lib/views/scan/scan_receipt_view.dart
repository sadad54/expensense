import 'dart:io';

import 'package:exp_ocr/models/scanned_receipt.dart';
import 'package:exp_ocr/services/receipt_api.dart';
import 'package:exp_ocr/util/expense_categories.dart';
import 'package:exp_ocr/util/transaction_utils.dart';
import 'package:exp_ocr/viewmodels/tax_category_notifier.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Scan a receipt photo, review what the API extracted, then save it.
///
/// OCR, parsing and categorisation run on the ExpenSense API (server/). The
/// app only resizes the photo to keep the upload small, then shows the result
/// for the user to confirm or correct before anything is written to Firestore.
class ScanReceiptScreen extends StatefulWidget {
  final ReceiptApi? api; // injectable for tests

  const ScanReceiptScreen({super.key, this.api});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  final ImagePicker _picker = ImagePicker();
  final _money = NumberFormat.currency(locale: 'en', symbol: 'RM ', decimalDigits: 2);
  final _amountController = TextEditingController();

  File? _image;
  ScannedReceipt? _receipt;
  String? _category;
  DateTime? _date;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  ReceiptApi? _apiInstance;
  ReceiptApi get _api => _apiInstance ??= widget.api ?? ReceiptApi.fromEnv();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 2000, maxHeight: 2000, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      _image = File(picked.path);
      _receipt = null;
      _error = null;
      _loading = true;
    });
    try {
      final receipt = await _api.scan(_image!);
      if (!mounted) return;
      setState(() {
        _receipt = receipt;
        _category = receipt.isUncategorized ? null : receipt.category;
        _date = receipt.date ?? DateTime.now();
        _amountController.text = receipt.total?.toStringAsFixed(2) ?? '';
      });
    } on ReceiptApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not scan this receipt. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double? get _amount => double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9.]'), ''));

  Future<void> _save() async {
    final receipt = _receipt;
    final amount = _amount;
    if (receipt == null || _category == null || amount == null || amount <= 0) return;
    setState(() => _saving = true);
    try {
      await saveTransactionAndUpdateBudget(
        context: context,
        categoryName: _category!,
        amount: amount,
        rawText: receipt.rawText,
        timestamp: _date ?? DateTime.now(),
      );
      if (!mounted) return;
      if (incomeTaxRelevant(_category!)) {
        Provider.of<TaxCategoryNotifier>(context, listen: false).refresh();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${_money.format(amount)} logged under '$_category'")),
      );
      setState(() {
        _receipt = null;
        _image = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Receipt')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Preview(image: _image),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _loading ? null : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
                ElevatedButton.icon(
                  onPressed: _loading ? null : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(
                child: Column(children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Reading receipt...'),
                ]),
              ),
            if (_error != null)
              Card(
                color: theme.colorScheme.errorContainer,
                child: ListTile(
                  key: const Key('scan-error'),
                  leading: Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
                  title: Text(_error!, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                ),
              ),
            if (_receipt != null) _buildReview(theme, _receipt!),
          ],
        ),
      ),
    );
  }

  Widget _buildReview(ThemeData theme, ScannedReceipt receipt) {
    final canSave = _category != null && (_amount ?? 0) > 0 && !_saving;
    return Card(
      key: const Key('scan-review'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(receipt.merchant ?? 'Unknown merchant', style: theme.textTheme.titleLarge),
            if (receipt.needsReview)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Some details need checking before you save.',
                    style: TextStyle(color: theme.colorScheme.tertiary)),
              ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('scan-amount'),
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Total', prefixText: 'RM '),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(DateFormat.yMMMd().format(_date ?? DateTime.now())),
              subtitle: Text(receipt.date == null ? 'Date not found on receipt' : 'Date from receipt'),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickDate,
            ),
            DropdownButtonFormField<String>(
              key: const Key('scan-category'),
              value: _category,
              hint: const Text('Choose a category'),
              decoration: InputDecoration(
                labelText: 'Category',
                helperText: receipt.isUncategorized
                    ? 'Could not tell from the receipt'
                    : 'Matched by ${receipt.categorySource}',
              ),
              items: [
                for (final c in [...expenseCategories, 'Other Expense'])
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) => setState(() => _category = v),
            ),
            if (receipt.lineItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('${receipt.lineItems.length} items'),
                children: [
                  for (final item in receipt.lineItems)
                    ListTile(
                      dense: true,
                      title: Text(item.description),
                      trailing: Text(_money.format(item.amount)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('scan-save'),
              onPressed: canSave ? _save : null,
              icon: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: const Text('Save expense'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  final File? image;

  const _Preview({required this.image});

  @override
  Widget build(BuildContext context) {
    if (image != null && image!.existsSync()) {
      return AspectRatio(
        aspectRatio: 4 / 3,
        child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(image!, fit: BoxFit.contain)),
      );
    }
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: Text('Take or choose a photo of a receipt')),
    );
  }
}

bool incomeTaxRelevant(String category) => expenseCategories.contains(category);
