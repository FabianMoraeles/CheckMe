import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:checkme/main.dart';

void main() {
  testWidgets('CheckMe shows both tabs and empty states', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const CheckMeApp());
    await tester.pumpAndSettle();

    expect(find.text('CheckMe'), findsOneWidget);
    expect(find.text('Aún no tienes nada en tu inventario'), findsOneWidget);

    await tester.tap(find.text('Lista de compras'));
    await tester.pumpAndSettle();

    expect(find.text('Tu lista de compras está vacía'), findsOneWidget);
  });

  testWidgets('Add-to-shopping-list sheet renders without layout overflow',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    // Use a phone-sized surface so the bottom sheet fully fits on screen,
    // matching the layout that actually overflowed on a real device.
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CheckMeApp());
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
    SharedPreferences.setMockInitialValues({});

    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CheckMeApp());
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
