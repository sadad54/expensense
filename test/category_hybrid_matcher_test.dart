import 'package:exp_ocr/util/category_hybrid_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('known Malaysian merchants map to their category', () {
    expect(hybridCategoryMatch('99 SPEEDMART SDN BHD'), 'Food & Groceries');
    expect(hybridCategoryMatch('PETRONAS DAGANGAN BHD'), 'Transportation');
    expect(hybridCategoryMatch('UNIFI BILL PAYMENT'), 'Utilities');
  });

  test('falls back to keywords when the merchant is unknown', () {
    expect(hybridCategoryMatch('KEDAI XYZ\nGROCERIES 12.00'), 'Food & Groceries');
  });

  test('returns Uncategorized when nothing matches', () {
    expect(hybridCategoryMatch('zzzz qqqq'), 'Uncategorized');
  });
}
