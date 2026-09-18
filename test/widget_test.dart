import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:checkme/main.dart';

void main() {
  testWidgets('CheckMe shows both tabs and empty states', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const CheckMeApp());
    await tester.pumpAndSettle();

    expect(find.text('Mi Inventario'), findsOneWidget);
    expect(find.text('Aún no tienes nada en tu inventario'), findsOneWidget);

    await tester.tap(find.text('Lista de compras'));
    await tester.pumpAndSettle();

    expect(find.text('Lista de Compras'), findsOneWidget);
    expect(find.text('Tu lista de compras está vacía'), findsOneWidget);
  });
}
