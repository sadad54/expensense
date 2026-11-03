/// A receipt as returned by the ExpenSense API (`POST /v1/receipts/scan`).
class ScannedReceipt {
  final String? merchant;
  final double? total;
  final String currency;
  final DateTime? date;
  final String category;
  final String categorySource; // merchant | keyword | fuzzy | none
  final double categoryConfidence;
  final List<ReceiptLineItem> lineItems;
  final String rawText;
  final bool needsReview;

  const ScannedReceipt({
    required this.merchant,
    required this.total,
    required this.currency,
    required this.date,
    required this.category,
    required this.categorySource,
    required this.categoryConfidence,
    required this.lineItems,
    required this.rawText,
    required this.needsReview,
  });

  bool get isUncategorized => category == 'Uncategorized';

  factory ScannedReceipt.fromJson(Map<String, dynamic> json) {
    final category = (json['category'] as Map?)?.cast<String, dynamic>() ?? const {};
    final rawDate = json['date'] as String?;
    return ScannedReceipt(
      merchant: json['merchant'] as String?,
      total: (json['total'] as num?)?.toDouble(),
      currency: (json['currency'] as String?) ?? 'MYR',
      // The API sends a calendar date (YYYY-MM-DD); keep it in local time.
      date: rawDate == null ? null : DateTime.tryParse(rawDate),
      category: (category['name'] as String?) ?? 'Uncategorized',
      categorySource: (category['source'] as String?) ?? 'none',
      categoryConfidence: (category['confidence'] as num?)?.toDouble() ?? 0,
      lineItems: ((json['line_items'] as List?) ?? const [])
          .map((e) => ReceiptLineItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      rawText: (json['raw_text'] as String?) ?? '',
      needsReview: (json['needs_review'] as bool?) ?? true,
    );
  }
}

class ReceiptLineItem {
  final String description;
  final double amount;
  final double? quantity;

  const ReceiptLineItem({required this.description, required this.amount, this.quantity});

  factory ReceiptLineItem.fromJson(Map<String, dynamic> json) => ReceiptLineItem(
        description: json['description'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        quantity: (json['quantity'] as num?)?.toDouble(),
      );
}
