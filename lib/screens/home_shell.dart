import 'package:flutter/material.dart';

import 'inventory_screen.dart';
import 'shopping_list_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _inventoryKey = GlobalKey<InventoryScreenState>();
  final _shoppingKey = GlobalKey<ShoppingListScreenState>();

  @override
  Widget build(BuildContext context) {
    final isInventory = _index == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isInventory ? 'Mi Inventario' : 'Lista de Compras'),
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _index,
        children: [
          InventoryScreen(key: _inventoryKey),
          ShoppingListScreen(key: _shoppingKey),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (isInventory) {
            _inventoryKey.currentState?.addItem();
          } else {
            _shoppingKey.currentState?.addItem();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(isInventory ? 'Agregar objeto' : 'Agregar a la lista'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventario',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_rtl_outlined),
            selectedIcon: Icon(Icons.checklist_rtl),
            label: 'Lista de compras',
          ),
        ],
      ),
    );
  }
}
