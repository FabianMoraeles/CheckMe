import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:checkme/main.dart';
import 'package:checkme/models/inventory_item.dart';
import 'package:checkme/models/item_category.dart';
import 'package:checkme/models/shopping_item.dart';
import 'package:checkme/services/storage_service.dart';

/// In-memory stand-in for the real Supabase-backed StorageService, so
/// widget tests don't hit the network. Mirrors the same CRUD surface.
class FakeStorageService extends StorageService {
  final List<InventoryItem> inventory = [];
  final List<ShoppingItem> shopping = [];
  int _nextId = 0;
  String _newId() => 'fake-${_nextId++}';

  @override
  Future<List<InventoryItem>> loadInventory() async => List.of(inventory);

  @override
  Future<InventoryItem> insertInventoryItem({
    required String name,
    required int quantity,
    required ItemCategory category,
  }) async {
    final item = InventoryItem(id: _newId(), name: name, quantity: quantity, category: category);
    inventory.add(item);
    return item;
  }

  @override
  Future<void> updateInventoryItemQuantity(String id, int quantity) async {
    inventory.firstWhere((e) => e.id == id).quantity = quantity;
  }

  @override
  Future<void> deleteInventoryItem(String id) async {
    inventory.removeWhere((e) => e.id == id);
  }

  @override
  Future<InventoryItem?> findInventoryItemByName(String name) async {
    for (final item in inventory) {
      if (item.name.toLowerCase() == name.toLowerCase()) return item;
    }
    return null;
  }

  @override
  Future<List<ShoppingItem>> loadShoppingList() async => List.of(shopping);

  @override
  Future<ShoppingItem> insertShoppingItem({
    required String name,
    required int quantity,
    required ItemCategory category,
  }) async {
    final item = ShoppingItem(id: _newId(), name: name, quantity: quantity, category: category);
    shopping.add(item);
    return item;
  }

  @override
  Future<void> updateShoppingItemChecked(String id, bool checked) async {
    shopping.firstWhere((e) => e.id == id).checked = checked;
  }

  @override
  Future<void> deleteShoppingItem(String id) async {
    shopping.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> deleteCheckedShoppingItems() async {
    shopping.removeWhere((e) => e.checked);
  }

  @override
  Future<bool> shoppingListHasItemNamed(String name) async {
    return shopping.any((e) => e.name.toLowerCase() == name.toLowerCase());
  }
}

void main() {
  testWidgets('CheckMe shows both tabs and empty states', (tester) async {
    await tester.pumpWidget(CheckMeApp(storageService: FakeStorageService()));
    await tester.pumpAndSettle();

    expect(find.text('CheckMe'), findsOneWidget);
    expect(find.text('Aún no tienes nada en tu inventario'), findsOneWidget);

    await tester.tap(find.text('Lista de compras'));
    await tester.pumpAndSettle();

    expect(find.text('Tu lista de compras está vacía'), findsOneWidget);
  });

  testWidgets('Add-to-shopping-list sheet renders without layout overflow',
      (tester) async {
    // Use a phone-sized surface so the bottom sheet fully fits on screen,
    // matching the layout that actually overflowed on a real device.
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(CheckMeApp(storageService: FakeStorageService()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lista de compras'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agregar algo que te falte'));
    await tester.pumpAndSettle();

    expect(find.text('Cantidad a comprar'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextField), 'Detergente en polvo');
    await tester.tap(find.text('Agregar objeto'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Detergente en polvo'), findsOneWidget);
  });

  testWidgets(
      'Buying a shopping-list item adds its chosen quantity to the inventory',
      (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(CheckMeApp(storageService: FakeStorageService()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lista de compras'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agregar algo que te falte'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Papel higiénico');
    // Bump the quantity from 1 to 3 before adding it to the shopping list.
    await tester.tap(find.byKey(const Key('quantity_increment')));
    await tester.tap(find.byKey(const Key('quantity_increment')));
    await tester.pump();
    await tester.tap(find.text('Agregar objeto'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // Check it off as bought, then push it into the inventory.
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Agregar a mi inventario'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Inventario'));
    await tester.pumpAndSettle();

    expect(find.text('Papel higiénico'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });
}
