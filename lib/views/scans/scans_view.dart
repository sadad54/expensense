import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScansView extends StatefulWidget {
  const ScansView({super.key});

  @override
  State<ScansView> createState() => _ScansViewState();
}

class _ScansViewState extends State<ScansView> {
  bool _descending = true;

  Stream<QuerySnapshot<Map<String, dynamic>>> _buildScansStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    // Only include docs that have scannedAt to avoid errors and keep ordering consistent
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .where(
          'scannedAt',
          isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(0),
        )
        .orderBy('scannedAt', descending: _descending)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scans'),
        actions: [
          IconButton(
            tooltip: _descending ? 'Newest first' : 'Oldest first',
            icon: Icon(_descending ? Icons.arrow_downward : Icons.arrow_upward),
            onPressed: () => setState(() => _descending = !_descending),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _buildScansStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No scans yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final scannedAtTs = data['scannedAt'] as Timestamp?;
              final scannedAt = scannedAtTs?.toDate();
              final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
              final categoryName =
                  (data['categoryId'] ?? data['categoryName'] ?? 'Unknown')
                      .toString();
              final rawText = (data['rawText'] ?? '').toString();
              final receiptTs = data['timestamp'] as Timestamp?;
              final receiptTime = receiptTs?.toDate();

              return Card(
                color: theme.colorScheme.surface,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  title: Text(
                    categoryName,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (scannedAt != null)
                        Text(
                          'Scanned: ${DateFormat.yMMMd().add_jm().format(scannedAt)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      if (receiptTime != null)
                        Text(
                          'Receipt time: ${DateFormat.yMMMd().add_jm().format(receiptTime)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      if (rawText.isNotEmpty)
                        Text(
                          rawText.length > 80
                              ? rawText.substring(0, 80) + '…'
                              : rawText,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  trailing: Text(
                    amount == 0 ? '' : 'MYR ${amount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall,
                  ),
                  onTap: () => _showScanDetails(context, data),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showScanDetails(BuildContext context, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final scannedAtTs = data['scannedAt'] as Timestamp?;
    final scannedAt = scannedAtTs?.toDate();
    final receiptTs = data['timestamp'] as Timestamp?;
    final receiptTime = receiptTs?.toDate();
    final categoryName =
        (data['categoryId'] ?? data['categoryName'] ?? 'Unknown').toString();
    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final rawText = (data['rawText'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Scan Details', style: theme.textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Category: $categoryName',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              if (amount != 0)
                Text(
                  'Amount: MYR ${amount.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium,
                ),
              if (scannedAt != null)
                Text(
                  'Scanned: ${DateFormat.yMMMd().add_jm().format(scannedAt)}',
                  style: theme.textTheme.bodySmall,
                ),
              if (receiptTime != null)
                Text(
                  'Receipt time: ${DateFormat.yMMMd().add_jm().format(receiptTime)}',
                  style: theme.textTheme.bodySmall,
                ),
              const SizedBox(height: 12),
              Text('Raw Text', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    rawText.isEmpty ? '(empty)' : rawText,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
