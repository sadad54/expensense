final Map<String, String> keywordCategoryMap = {
  'restaurant': 'Food',
  'coffee': 'Food',
  'burger': 'Food',
  'petrol': 'Transport',
  'uber': 'Transport',
  'fuel': 'Transport',
  'grocery': 'Groceries',
  'supermarket': 'Groceries',
  'electricity': 'Utilities',
  'water': 'Utilities',
  'internet': 'Utilities',
  'income': 'Income',
  'salary': 'Income',
  'tax': 'Income Tax',
};

String categorizeReceipt(String text) {
  final lowerText = text.toLowerCase();
  for (final keyword in keywordCategoryMap.keys) {
    if (lowerText.contains(keyword)) {
      return keywordCategoryMap[keyword]!;
    }
  }
  return 'Uncategorized';
}

Map<String, dynamic> extractDataFromReceipt(String text) {
  final lines =
      text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  String vendor = lines.isNotEmpty ? lines.first : "Unknown Vendor";
  String category = categorizeReceipt(text);

  RegExp amountRegex = RegExp(
    r'(total|amount|paid)[^\d]*([\d,]+\.\d{2})',
    caseSensitive: false,
  );
  RegExp dateRegex = RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b');

  String? amount = amountRegex.firstMatch(text)?.group(2);
  String? date = dateRegex.firstMatch(text)?.group(0);

  return {
    'vendor': vendor,
    'amount': amount ?? '0.00',
    'date': date ?? DateTime.now().toIso8601String(),
    'category': category,
    'rawText': text,
  };
}
