import 'package:exp_ocr/util/category_keywords.dart';
import 'package:string_similarity/string_similarity.dart';

const Map<String, String> merchantToCategory = {
  // Food & Groceries
  "tesco": "Food & Groceries",
  "giant": "Food & Groceries",
  "aeon": "Food & Groceries",
  "jaya grocer": "Food & Groceries",
  "nsk": "Food & Groceries",
  "village grocer": "Food & Groceries",
  "99 speedmart": "Food & Groceries",
  "mydin": "Food & Groceries",
  "familymart": "Food & Groceries",

  // Dining & Takeout
  "grabfood": "Dining & Takeout",
  "foodpanda": "Dining & Takeout",
  "kfc": "Dining & Takeout",
  "mcdonald": "Dining & Takeout",
  "burger king": "Dining & Takeout",
  "dominos": "Dining & Takeout",
  "starbucks": "Dining & Takeout",
  "subway": "Dining & Takeout",
  "pizzahut": "Dining & Takeout",
  "secret recipe": "Dining & Takeout",
  "a&w": "Dining & Takeout",

  // Transportation
  "shell": "Transportation",
  "petronas": "Transportation",
  "caltex": "Transportation",
  "bhp": "Transportation",
  "grab": "Transportation",
  "rapidkl": "Transportation",
  "tng reload": "Transportation",
  "touch n go": "Transportation",
  "mrt": "Transportation",

  // Utilities
  "celcom": "Utilities",
  "digi": "Utilities",
  "maxis": "Utilities",
  "unifi": "Utilities",
  "tmb": "Utilities",
  "syabas": "Utilities",
  "tenaga nasional": "Utilities",
  "tng digital": "Utilities",
  "indah water": "Utilities",

  // Health & Personal Care
  "guardian": "Health & Personal Care",
  "watsons": "Health & Personal Care",
  "caring pharmacy": "Health & Personal Care",
  "farmasi": "Health & Personal Care",
  "hospital": "Health & Personal Care",
  "clinic": "Health & Personal Care",

  // Entertainment & Subscriptions
  "netflix": "Entertainment & Subscriptions",
  "spotify": "Entertainment & Subscriptions",
  "youtube premium": "Entertainment & Subscriptions",
  "astro": "Entertainment & Subscriptions",
  "apple music": "Entertainment & Subscriptions",
  "iflix": "Entertainment & Subscriptions",
  "disney+": "Entertainment & Subscriptions",

  // Shopping & Miscellaneous
  "shopee": "Shopping & Miscellaneous",
  "lazada": "Shopping & Miscellaneous",
  "zalora": "Shopping & Miscellaneous",
  "uniqlo": "Shopping & Miscellaneous",
  "mr diy": "Shopping & Miscellaneous",
  "ikea": "Shopping & Miscellaneous",
  "sports direct": "Shopping & Miscellaneous",
  "decathlon": "Shopping & Miscellaneous",

  // Books & Education
  "popular": "Books & Education",
  "kinokuniya": "Books & Education",
  "mph": "Books & Education",
  "bookstore": "Books & Education",
  "textbook": "Books & Education",
  "pelangi": "Books & Education",
  "oxford": "Books & Education",
  "longman": "Books & Education",
  "nugget": "Food & Groceries",
  "meijer": "Food & Groceries",
  "morrisons": "Food & Groceries",
  "walmart": "Food & Groceries",

  // Dining & Takeout
  "epic steakhouse": "Dining & Takeout",
  "the coffee shop": "Dining & Takeout",

  // Transportation

  // Utilities

  // Housing & Rent
  "city of manhattan beach":
      "Housing & Rent", // Business licensing can relate to rent/space usage

  // Health & Personal Care
  "walmart pharmacy": "Health & Personal Care",

  // Food & Groceries
  "aldi": "Food & Groceries",
  "costco": "Food & Groceries",
  "target": "Food & Groceries",

  // Dining & Takeout

  // Transportation
  "uber": "Transportation",
  "lyft": "Transportation",

  // Utilities

  // Housing & Rent
  "city council": "Housing & Rent",
  "municipal office": "Housing & Rent",
  "property management": "Housing & Rent",

  // Health & Personal Care
  "walgreens": "Health & Personal Care",
  "cvs": "Health & Personal Care",

  // Entertainment & Subscriptions
  "twitch": "Entertainment & Subscriptions",

  // Shopping & Miscellaneous
  "amazon": "Shopping & Miscellaneous",
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
      if (score > bestScore && score > 0.5) {
        bestScore = score;
        bestMatch = entry.key;
      }
    }
  }

  return bestMatch;
}
