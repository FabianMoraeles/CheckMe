class ShoppingGroup {
  final String id;
  String name;

  ShoppingGroup({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory ShoppingGroup.fromJson(Map<String, dynamic> json) => ShoppingGroup(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}
