import 'item_category.dart';

class InventoryItem {
  final String id;
  String name;
  int quantity;
  ItemCategory category;

  InventoryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'category': category.name,
      };

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        id: json['id'] as String,
        name: json['name'] as String,
        quantity: json['quantity'] as int,
        category: categoryFromName(json['category'] as String),
      );
}
