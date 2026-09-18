import 'package:flutter/material.dart';

enum ItemCategory { comida, limpieza, higiene, otros }

extension ItemCategoryX on ItemCategory {
  String get label {
    switch (this) {
      case ItemCategory.comida:
        return 'Comida';
      case ItemCategory.limpieza:
        return 'Limpieza';
      case ItemCategory.higiene:
        return 'Higiene';
      case ItemCategory.otros:
        return 'Otros';
    }
  }

  IconData get icon {
    switch (this) {
      case ItemCategory.comida:
        return Icons.restaurant;
      case ItemCategory.limpieza:
        return Icons.cleaning_services;
      case ItemCategory.higiene:
        return Icons.soap;
      case ItemCategory.otros:
        return Icons.category;
    }
  }

  Color get color {
    switch (this) {
      case ItemCategory.comida:
        return const Color(0xFFFF9F5A);
      case ItemCategory.limpieza:
        return const Color(0xFF4FC3F7);
      case ItemCategory.higiene:
        return const Color(0xFF9575CD);
      case ItemCategory.otros:
        return const Color(0xFF81C784);
    }
  }
}

ItemCategory categoryFromName(String name) {
  return ItemCategory.values.firstWhere(
    (c) => c.name == name,
    orElse: () => ItemCategory.otros,
  );
}
