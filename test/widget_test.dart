import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:checkme/main.dart';
import 'package:checkme/models/inventory_item.dart';
import 'package:checkme/models/item_category.dart';
import 'package:checkme/models/shopping_group.dart';
import 'package:checkme/models/shopping_item.dart';
import 'package:checkme/services/storage_service.dart';

/// In-memory stand-in for the real Supabase-backed StorageService, so
/// widget tests don't hit the network. Mirrors the same CRUD surface.
class FakeStorageService extends StorageService {
  final List<InventoryItem> inventory = [];
  final List<ShoppingItem> shopping = [];
  final List<ShoppingGroup> groups = [];
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

  @override
  Future<List<ShoppingItem>> loadShoppingList() async => List.of(shopping);

  @override
  Future<ShoppingItem> insertShoppingItem({
    required String name,
    required int quantity,
    required ItemCategory category,
    String? groupId,
  }) async {
    final item = ShoppingItem(
      id: _newId(),
      name: name,
      quantity: quantity,
      category: category,
      groupId: groupId,
    );
    shopping.add(item);
    return item;
  }

  @override
  Future<void> deleteShoppingItem(String id) async {
    shopping.removeWhere((e) => e.id == id);
  }

  @override
  Future<bool> shoppingListHasItemNamed(String name) async {
    return shopping.any((e) => e.name.toLowerCase() == name.toLowerCase());
  }

  @override
  Future<void> completeShoppingItem(ShoppingItem item) async {
    await restockInventoryItem(name: item.name, quantity: item.quantity, category: item.category);
    await deleteShoppingItem(item.id);
  }

  @override
  Future<List<ShoppingGroup>> loadShoppingGroups() async => List.of(groups);

  @override
  Future<ShoppingGroup> insertShoppingGroup(String name) async {
    final group = ShoppingGroup(id: _newId(), name: name);
    groups.add(group);
    return group;
  }

  @override
  Future<void> deleteShoppingGroup(String id) async {
    groups.removeWhere((g) => g.id == id);
  }
}

/// Opens the shopping-list picker from the empty state and adds one new
/// (not-yet-in-inventory) product with the given quantity, then confirms.
Future<void> _addNewShoppingProduct(
  WidgetTester tester, {
  required String name,
  int quantityIncrements = 0,
}) async {
  await tester.tap(find.text('Agregar algo que te falte'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Algo que no tienes en tu despensa'));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextField), name);
  for (var i = 0; i < quantityIncrements; i++) {
    await tester.tap(find.byKey(const Key('quantity_increment')));
  }
  await tester.pump();
  await tester.tap(find.text('Agregar objeto'));
  await tester.pumpAndSettle();

  await tester.tap(find.textContaining('Agregar 1 a la lista'));
  await tester.pumpAndSettle();
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

  testWidgets('Add-a-new-product sheet renders without layout overflow',
      (tester) async {
    // Use a phone-sized surface so the sheet fully fits on screen,
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

    expect(find.text('¿Qué vas a comprar?'), findsOneWidget);

    await tester.tap(find.text('Algo que no tienes en tu despensa'));
    await tester.pumpAndSettle();

    expect(find.text('Cantidad a comprar'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextField), 'Detergente en polvo');
    await tester.tap(find.text('Agregar objeto'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Detergente en polvo ×1'), findsOneWidget);
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

    await _addNewShoppingProduct(tester, name: 'Papel higiénico', quantityIncrements: 2);

    expect(find.text('Papel higiénico'), findsOneWidget);
    expect(find.text('×3'), findsOneWidget);

    // Check it off as bought -> it should vanish from the list and land
    // in the inventory with that same quantity.
    await tester.tap(find.text('Papel higiénico'));
    await tester.pumpAndSettle();

    expect(find.text('Papel higiénico'), findsNothing);

    await tester.tap(find.text('Inventario'));
    await tester.pumpAndSettle();

    expect(find.text('Papel higiénico'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('A shopping group completes all its items in one tap',
      (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(CheckMeApp(storageService: FakeStorageService()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lista de compras'));
    await tester.pumpAndSettle();

    // Add the first item and create a group for it.
    await tester.tap(find.text('Agregar algo que te falte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nuevo grupo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Súper del sábado');
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();

    expect(find.text('Súper del sábado'), findsOneWidget);

    await tester.tap(find.text('Algo que no tienes en tu despensa'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Leche');
    await tester.tap(find.text('Agregar objeto'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Algo que no tienes en tu despensa'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Huevos');
    await tester.tap(find.text('Agregar objeto'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Agregar 2 a la lista'));
    await tester.pumpAndSettle();

    expect(find.text('Súper del sábado (2)'), findsOneWidget);
    expect(find.text('Leche'), findsOneWidget);
    expect(find.text('Huevos'), findsOneWidget);

    await tester.tap(find.text('Completar todo'));
    await tester.pumpAndSettle();

    expect(find.text('Leche'), findsNothing);
    expect(find.text('Huevos'), findsNothing);
    expect(find.text('Tu lista de compras está vacía'), findsOneWidget);

    await tester.tap(find.text('Inventario'));
    await tester.pumpAndSettle();

    expect(find.text('Leche'), findsOneWidget);
    expect(find.text('Huevos'), findsOneWidget);
  });
}
