import 'package:exp_ocr/models/scanned_receipt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a full API response', () {
    final r = ScannedReceipt.fromJson({
      'merchant': 'AEON CO. (M) BHD',
      'total': 19.7,
      'currency': 'MYR',
      'date': '2018-12-25',
      'category': {'name': 'Food & Groceries', 'source': 'merchant', 'matched': 'aeon', 'confidence': 0.95},
      'line_items': [
        {'description': 'MILO 3IN1', 'amount': 15.9, 'quantity': 1},
      ],
      'raw_text': 'AEON...',
      'needs_review': false,
    });
    expect(r.merchant, 'AEON CO. (M) BHD');
    expect(r.total, 19.7);
    expect(r.date, DateTime(2018, 12, 25));
    expect(r.category, 'Food & Groceries');
    expect(r.categorySource, 'merchant');
    expect(r.lineItems.single.quantity, 1.0);
    expect(r.isUncategorized, isFalse);
  });

  test('tolerates missing fields and flags review', () {
    final r = ScannedReceipt.fromJson({'category': {'name': 'Uncategorized'}});
    expect(r.total, isNull);
    expect(r.date, isNull);
    expect(r.currency, 'MYR');
    expect(r.isUncategorized, isTrue);
    expect(r.needsReview, isTrue);
    expect(r.lineItems, isEmpty);
  });
}
