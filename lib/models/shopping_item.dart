import 'item_category.dart';

class ShoppingItem {
  final String id;
  String name;
  bool checked;
  ItemCategory category;
  int quantity;

  ShoppingItem({
    required this.id,
    required this.name,
    this.checked = false,
    required this.category,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'checked': checked,
        'category': category.name,
        'quantity': quantity,
      };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
        id: json['id'] as String,
        name: json['name'] as String,
        checked: json['checked'] as bool,
        category: categoryFromName(json['category'] as String),
        quantity: (json['quantity'] as int?) ?? 1,
      );
}
