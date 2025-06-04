import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import if using user-specific categories

// --- Define Available Icons ---
// Store icons like this for easy mapping and selection
final Map<String, IconData> categoryIcons = {
  'restaurant': Icons.restaurant_menu_outlined,
  'shopping_bag': Icons.shopping_bag_outlined,
  'movie': Icons.movie_outlined,
  'car': Icons.directions_car_filled_outlined,
  'grocery': Icons.local_grocery_store_outlined,
  'receipt': Icons.receipt_long_outlined,
  'health': Icons.health_and_safety_outlined,
  'money': Icons.attach_money_outlined, // Good for Income/Salary
  'work': Icons.work_outline,
  'home': Icons.home_outlined,
  'build': Icons.build_outlined, // Utilities/Bills
  'flight': Icons.flight_takeoff_outlined, // Travel
  'card_giftcard': Icons.card_giftcard_outlined, // Gifts
  'pets': Icons.pets_outlined,
  'school': Icons.school_outlined, // Education
  'category': Icons.category_outlined, // Default/Other
  // Add more icons as needed
};

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth =
      FirebaseAuth.instance; // Use if categories are user-specific

  // Helper function to get IconData from stored name
  IconData _getIconByName(String? iconName) {
    if (iconName != null && categoryIcons.containsKey(iconName)) {
      return categoryIcons[iconName]!;
    }
    return Icons.category_outlined; // Default icon
  }

  @override
  Widget build(BuildContext context) {
    final String? userId = _auth.currentUser?.uid;

    // Handle case where user is not logged in (if using auth)
    if (userId == null) {
      // Important: If your Firestore rules require auth, this screen
      // MUST only be shown to logged-in users.
      // Consider navigating back or showing a login prompt.
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Categories')),
        body: const Center(
          child: Text(
            'Please log in to manage categories.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Manage Categories'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: Theme.of(context).appBarTheme.elevation,
      ),
      body: _buildCategoryList(userId),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditCategoryDialog(userId: userId),
        tooltip: 'Add Category',
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  // --- Build Category List using StreamBuilder ---
  Widget _buildCategoryList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('categories')
              .where('userId', isEqualTo: userId) // Filter by logged-in user
              .orderBy('name') // Order alphabetically
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print("Firestore Error (Categories): ${snapshot.error}");
          return Center(
            child: Text(
              'Error loading categories: ${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No categories created yet. Tap + to add.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        // Display categories in a ListView
        final categories = snapshot.data!.docs;
        return ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return _buildCategoryTile(categories[index], userId);
          },
        );
      },
    );
  }

  // --- Build Individual Category Tile ---
  Widget _buildCategoryTile(DocumentSnapshot doc, String userId) {
    final data = doc.data() as Map<String, dynamic>;
    final String categoryName = data['name'] ?? 'Unnamed';
    final String iconName = data['iconName'] ?? 'category'; // Default icon name
    final String type = data['type'] ?? 'Expense'; // Default to Expense
    final IconData iconData = _getIconByName(iconName);
    final Color typeColor =
        type == 'Income' ? Colors.greenAccent : Colors.redAccent;

    return Card(
      // Use Card theme from main.dart
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.background, // Icon background
          child: Icon(iconData, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(categoryName, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          type,
          style: TextStyle(color: typeColor.withOpacity(0.8), fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit Button
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: Colors.white70,
                size: 20,
              ),
              tooltip: 'Edit Category',
              onPressed:
                  () => _showAddEditCategoryDialog(
                    userId: userId,
                    existingCategory: doc, // Pass existing data for editing
                  ),
            ),
            // Delete Button
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: 20,
              ),
              tooltip: 'Delete Category',
              onPressed: () => _confirmDelete(doc.id, categoryName),
            ),
          ],
        ),
      ),
    );
  }

  // --- Add/Edit Category Dialog ---
  Future<void> _showAddEditCategoryDialog({
    required String userId,
    DocumentSnapshot?
    existingCategory, // Null when adding, has data when editing
  }) async {
    final bool isEditing = existingCategory != null;
    final categoryData =
        isEditing ? existingCategory!.data() as Map<String, dynamic> : null;
    final docId = isEditing ? existingCategory!.id : null;

    final TextEditingController nameController = TextEditingController(
      text: isEditing ? categoryData!['name'] : '',
    );
    String selectedIconName =
        isEditing ? categoryData!['iconName'] ?? 'category' : 'category';
    String selectedType =
        isEditing ? categoryData!['type'] ?? 'Expense' : 'Expense';

    // Use stateful builder for dialog state management (icon/type selection)
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          // Allows dialog content to update state
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor:
                  Theme.of(context).dialogBackgroundColor, // Use theme
              title: Text(
                isEditing ? 'Edit Category' : 'Add New Category',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: SingleChildScrollView(
                // Prevent overflow
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name Field
                    TextField(
                      controller: nameController,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Category Name',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        // Use input decoration theme from main.dart if defined
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),

                    // Type Selection (Dropdown)
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Type',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        // Use input decoration theme from main.dart
                      ),
                      items:
                          ['Expense', 'Income'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setDialogState(() => selectedType = newValue);
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Icon Selection
                    Text(
                      'Select Icon:',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 150, // Adjust height as needed
                      child: _buildIconSelectionGrid(
                        (iconName) =>
                            setDialogState(() => selectedIconName = iconName),
                        selectedIconName,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final String name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      if (isEditing) {
                        _updateCategory(
                          docId!,
                          name,
                          selectedIconName,
                          selectedType,
                        );
                      } else {
                        _addCategory(
                          name,
                          selectedIconName,
                          selectedType,
                          userId,
                        );
                      }
                      Navigator.of(context).pop(); // Close dialog on success
                    } else {
                      // Show simple validation feedback (optional)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Category name cannot be empty.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  child: Text(
                    isEditing ? 'Save Changes' : 'Add Category',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Icon Selection Grid Widget ---
  Widget _buildIconSelectionGrid(
    Function(String) onSelect,
    String? currentSelection,
  ) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5, // Adjust number of columns
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: categoryIcons.length,
      itemBuilder: (context, index) {
        final iconName = categoryIcons.keys.elementAt(index);
        final iconData = categoryIcons.values.elementAt(index);
        final bool isSelected = iconName == currentSelection;

        return GestureDetector(
          onTap: () => onSelect(iconName),
          child: Container(
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                      : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border:
                  isSelected
                      ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                      : null,
            ),
            child: Icon(
              iconData,
              color:
                  isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white70,
              size: 28,
            ),
          ),
        );
      },
    );
  }

  // --- Firestore Add Operation ---
  Future<void> _addCategory(
    String name,
    String iconName,
    String type,
    String userId,
  ) async {
    try {
      await _firestore.collection('categories').add({
        'name': name,
        'iconName': iconName,
        'type': type,
        'userId': userId, // Store the user ID
        'createdAt':
            FieldValue.serverTimestamp(), // Optional: track creation time
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "$name" added.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Error adding category: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add category: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // --- Firestore Update Operation ---
  Future<void> _updateCategory(
    String docId,
    String name,
    String iconName,
    String type,
  ) async {
    try {
      await _firestore.collection('categories').doc(docId).update({
        'name': name,
        'iconName': iconName,
        'type': type,
        // userId doesn't usually change, don't need to update it
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "$name" updated.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Error updating category: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update category: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // --- Show Delete Confirmation Dialog ---
  Future<void> _confirmDelete(String docId, String categoryName) async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            title: const Text(
              'Delete Category?',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to delete the category "$categoryName"? This action cannot be undone.',
              style: TextStyle(color: Colors.grey[300]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  _deleteCategory(docId);
                  Navigator.of(context).pop(); // Close dialog
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );
  }

  // --- Firestore Delete Operation ---
  Future<void> _deleteCategory(String docId) async {
    try {
      await _firestore.collection('categories').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category deleted.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print("Error deleting category: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete category: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
