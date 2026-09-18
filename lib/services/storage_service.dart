import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/inventory_item.dart';
import '../models/shopping_item.dart';

class StorageService {
  static const _inventoryKey = 'inventory_items';
  static const _shoppingKey = 'shopping_items';

  Future<List<InventoryItem>> loadInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_inventoryKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveInventory(List<InventoryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_inventoryKey, raw);
  }

  Future<List<ShoppingItem>> loadShoppingList() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_shoppingKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveShoppingList(List<ShoppingItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_shoppingKey, raw);
  }
}
