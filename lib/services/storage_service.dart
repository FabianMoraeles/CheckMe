import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/inventory_item.dart';
import '../models/item_category.dart';
import '../models/shopping_group.dart';
import '../models/shopping_item.dart';

class StorageService {
  static const _inventoryTable = 'checkme_inventory_items';
  static const _shoppingTable = 'checkme_shopping_items';
  static const _groupsTable = 'checkme_shopping_groups';

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

  /// Adds [quantity] units of [name] to the inventory: bumps the existing
  /// item if there's one with that name, otherwise creates it.
  Future<void> restockInventoryItem({
    required String name,
    required int quantity,
    required ItemCategory category,
  }) async {
    final existing = await findInventoryItemByName(name);
    if (existing == null) {
      await insertInventoryItem(name: name, quantity: quantity, category: category);
    } else {
      await updateInventoryItemQuantity(existing.id, existing.quantity + quantity);
    }
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
    String? groupId,
  }) async {
    final row = await _client
        .from(_shoppingTable)
        .insert({
          'name': name,
          'quantity': quantity,
          'category': category.name,
          'group_id': groupId,
        })
        .select()
        .single();
    return ShoppingItem.fromJson(row);
  }

  Future<void> deleteShoppingItem(String id) async {
    await _client.from(_shoppingTable).delete().eq('id', id);
  }

  Future<bool> shoppingListHasItemNamed(String name) async {
    final rows = await _client.from(_shoppingTable).select('id').ilike('name', name);
    return rows.isNotEmpty;
  }

  /// Marks a shopping item as bought: adds its quantity to the inventory
  /// and removes it from the shopping list, in one step.
  Future<void> completeShoppingItem(ShoppingItem item) async {
    await restockInventoryItem(name: item.name, quantity: item.quantity, category: item.category);
    await deleteShoppingItem(item.id);
  }

  // --- Shopping groups -----------------------------------------------------

  Future<List<ShoppingGroup>> loadShoppingGroups() async {
    final rows = await _client.from(_groupsTable).select().order('created_at');
    return rows.map(ShoppingGroup.fromJson).toList();
  }

  Future<ShoppingGroup> insertShoppingGroup(String name) async {
    final row = await _client.from(_groupsTable).insert({'name': name}).select().single();
    return ShoppingGroup.fromJson(row);
  }

  Future<void> deleteShoppingGroup(String id) async {
    await _client.from(_groupsTable).delete().eq('id', id);
  }
}
