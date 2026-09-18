import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/inventory_item.dart';
import '../models/item_category.dart';
import '../models/shopping_item.dart';

class StorageService {
  static const _inventoryTable = 'checkme_inventory_items';
  static const _shoppingTable = 'checkme_shopping_items';

  SupabaseClient get _client => Supabase.instance.client;

  // --- Inventory ---------------------------------------------------------

  Future<List<InventoryItem>> loadInventory() async {
    final rows = await _client
        .from(_inventoryTable)
        .select()
        .order('category')
        .order('name');
    return rows.map(InventoryItem.fromJson).toList();
  }

  Future<InventoryItem> insertInventoryItem({
    required String name,
    required int quantity,
    required ItemCategory category,
  }) async {
    final row = await _client
        .from(_inventoryTable)
        .insert({'name': name, 'quantity': quantity, 'category': category.name})
        .select()
        .single();
    return InventoryItem.fromJson(row);
  }

  Future<void> updateInventoryItemQuantity(String id, int quantity) async {
    await _client.from(_inventoryTable).update({'quantity': quantity}).eq('id', id);
  }

  Future<void> deleteInventoryItem(String id) async {
    await _client.from(_inventoryTable).delete().eq('id', id);
  }

  /// Finds an inventory item with this exact name (case-insensitive), if any.
  Future<InventoryItem?> findInventoryItemByName(String name) async {
    final rows = await _client.from(_inventoryTable).select().ilike('name', name);
    if (rows.isEmpty) return null;
    return InventoryItem.fromJson(rows.first);
  }

  // --- Shopping list -------------------------------------------------------

  Future<List<ShoppingItem>> loadShoppingList() async {
    final rows = await _client.from(_shoppingTable).select().order('name');
    return rows.map(ShoppingItem.fromJson).toList();
  }

  Future<ShoppingItem> insertShoppingItem({
    required String name,
    required int quantity,
    required ItemCategory category,
  }) async {
    final row = await _client
        .from(_shoppingTable)
        .insert({'name': name, 'quantity': quantity, 'category': category.name, 'checked': false})
        .select()
        .single();
    return ShoppingItem.fromJson(row);
  }

  Future<void> updateShoppingItemChecked(String id, bool checked) async {
    await _client.from(_shoppingTable).update({'checked': checked}).eq('id', id);
  }

  Future<void> deleteShoppingItem(String id) async {
    await _client.from(_shoppingTable).delete().eq('id', id);
  }

  Future<void> deleteCheckedShoppingItems() async {
    await _client.from(_shoppingTable).delete().eq('checked', true);
  }

  Future<bool> shoppingListHasItemNamed(String name) async {
    final rows = await _client.from(_shoppingTable).select('id').ilike('name', name);
    return rows.isNotEmpty;
  }
}
