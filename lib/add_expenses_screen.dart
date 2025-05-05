import 'package:flutter/material.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  // TODO: Implement form fields (title, amount, category, date, type)
  // TODO: Implement logic to save data to Firestore

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // TODO: Add save logic here
              // Validate input, create map, save to Firestore
              // Then pop the screen: Navigator.pop(context);
              print("Save Tapped - Implement Firestore Save");
            },
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'Add Expense Form Goes Here',
            style: TextStyle(color: Colors.white),
          ),
          // TODO: Build the form UI
        ),
      ),
    );
  }
}
