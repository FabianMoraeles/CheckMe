import 'item_category.dart';

class ShoppingItem {
  final String id;
  String name;
  ItemCategory category;
  int quantity;
  String? groupId;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.category,
    this.quantity = 1,
    this.groupId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'quantity': quantity,
        'group_id': groupId,
      };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
        id: json['id'] as String,
        name: json['name'] as String,
        category: categoryFromName(json['category'] as String),
        quantity: (json['quantity'] as int?) ?? 1,
        groupId: json['group_id'] as String?,
      );
}
