import 'package:flutter/material.dart';
import 'package:exp_ocr/services/dummy_data_service.dart'; // Import the file with insertDummyData()

class DummyDataScreen extends StatelessWidget {
  const DummyDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Insert Dummy Data")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await uploadDummyTransactions();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Dummy data inserted!")),
            );
          },
          child: const Text("Insert Dummy Data"),
        ),
      ),
    );
  }
}
