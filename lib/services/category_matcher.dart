import 'package:exp_ocr/util/category_keywords.dart';
import 'package:string_similarity/string_similarity.dart';

String matchCategoryFuzzy(String text) {
  final lowerText = text.toLowerCase();
  double bestScore = 0.0;
  String bestCategory = "Uncategorized";

  for (final entry in categoryKeywords.entries) {
    for (final keyword in entry.value) {
      final score = keyword.similarityTo(lowerText);
      if (score > bestScore && score > 0.3) {
        // tune threshold
        bestScore = score;
        bestCategory = entry.key;
      }
    }
  }
  return bestCategory;
}

String matchCategory(String text) {
  final lowerText = text.toLowerCase();
  for (final entry in categoryKeywords.entries) {
    for (final keyword in entry.value) {
      if (lowerText.contains(keyword)) {
        return entry.key;
      }
    }
  }
  return "Uncategorized"; // fallback
}
