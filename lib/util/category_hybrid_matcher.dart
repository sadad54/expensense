import 'package:exp_ocr/util/category_keywords.dart';
import 'package:string_similarity/string_similarity.dart';
const Map<String, String> merchantToCategory = {
  "tesco": "Food & Groceries",
  "grabfood": "Dining & Takeout",
  "kfc": "Dining & Takeout",
  "mcdonald": "Dining & Takeout",
  "shell": "Transportation",
  "netflix": "Entertainment & Subscriptions",
  "shopee": "Shopping & Miscellaneous",
  "celcom": "Utilities",
  "guardian": "Health & Personal Care",
};

String hybridCategoryMatch(String text) {
  final lowerText = text.toLowerCase();

  // Step 1: Exact merchant match
  for (final merchant in merchantToCategory.entries) {
    if (lowerText.contains(merchant.key)) {
      return merchant.value;
    }
  }

  // Step 2: Exact keyword match
  for (final entry in categoryKeywords.entries) {
    for (final keyword in entry.value) {
      if (lowerText.contains(keyword)) {
        return entry.key;
      }
    }
  }

  // Step 3: Fuzzy match using string_similarity
  String bestMatch = "Uncategorized";
  double bestScore = 0.0;

  for (final entry in categoryKeywords.entries) {
    for (final keyword in entry.value) {
      final score = keyword.similarityTo(lowerText);
      if (score > bestScore && score > 0.35) {
        // Tune threshold
        bestScore = score;
        bestMatch = entry.key;
      }
    }
  }

  return bestMatch;
}
