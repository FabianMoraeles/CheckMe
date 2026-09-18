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
        return Icons.inventory_2;
    }
  }

  /// Color used for the icon inside its round badge.
  Color get iconColor {
    switch (this) {
      case ItemCategory.comida:
        return const Color(0xFFEA580C);
      case ItemCategory.limpieza:
        return const Color(0xFF0284C7);
      case ItemCategory.higiene:
        return const Color(0xFF9333EA);
      case ItemCategory.otros:
        return const Color(0xFF3D4A3F);
    }
  }

  /// Soft background color behind the icon and the category badge.
  Color get bgColor {
    switch (this) {
      case ItemCategory.comida:
        return const Color(0xFFFFF3E0);
      case ItemCategory.limpieza:
        return const Color(0xFFE0F2FE);
      case ItemCategory.higiene:
        return const Color(0xFFF3E8FF);
      case ItemCategory.otros:
        return const Color(0xFFE7E8EA);
    }
  }

  /// Text color used for the small category badge label.
  Color get labelColor {
    switch (this) {
      case ItemCategory.comida:
        return const Color(0xFFC2410C);
      case ItemCategory.limpieza:
        return const Color(0xFF0369A1);
      case ItemCategory.higiene:
        return const Color(0xFF7E22CE);
      case ItemCategory.otros:
        return const Color(0xFF3D4A3F);
    }
  }
}

ItemCategory categoryFromName(String name) {
  return ItemCategory.values.firstWhere(
    (c) => c.name == name,
    orElse: () => ItemCategory.otros,
  );
}
