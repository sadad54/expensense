import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart'; // For IconData related properties

class BudgetCategoryModel extends Equatable {
  final String id;
  final String name;
  final double allocatedAmount;
  final double spentAmount;
  final int iconCodepoint;
  final String iconFontFamily;
  final String
  colorHex; // Stored as ARGB hex string e.g., "FFFF0000" for opaque red
  final Timestamp createdAt;

  const BudgetCategoryModel({
    required this.id,
    required this.name,
    required this.allocatedAmount,
    required this.spentAmount,
    required this.iconCodepoint,
    required this.iconFontFamily,
    required this.colorHex,
    required this.createdAt,
  });

  Color get color => Color(int.parse(colorHex, radix: 16));
  IconData get iconData => IconData(iconCodepoint, fontFamily: iconFontFamily);

  @override
  List<Object?> get props => [
    id,
    name,
    allocatedAmount,
    spentAmount,
    iconCodepoint,
    iconFontFamily,
    colorHex,
    createdAt,
  ];

  factory BudgetCategoryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return BudgetCategoryModel(
      id: doc.id,
      name: data['name'] ?? 'Unnamed',
      allocatedAmount: (data['allocatedAmount'] as num?)?.toDouble() ?? 0.0,
      spentAmount: (data['spentAmount'] as num?)?.toDouble() ?? 0.0,
      iconCodepoint: data['iconCodepoint'] ?? Icons.category.codePoint,
      iconFontFamily: data['iconFontFamily'] ?? Icons.category.fontFamily!,
      colorHex: data['colorHex'] ?? 'FFFFE0B2', // Default light orange
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'allocatedAmount': allocatedAmount,
      'spentAmount': spentAmount,
      'iconCodepoint': iconCodepoint,
      'iconFontFamily': iconFontFamily,
      'colorHex': colorHex,
      'createdAt': createdAt,
    };
  }

  BudgetCategoryModel copyWith({
    String? id,
    String? name,
    double? allocatedAmount,
    double? spentAmount,
    int? iconCodepoint,
    String? iconFontFamily,
    String? colorHex,
    Timestamp? createdAt,
  }) {
    return BudgetCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      iconCodepoint: iconCodepoint ?? this.iconCodepoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
