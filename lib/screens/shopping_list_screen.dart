import 'package:flutter/material.dart';

import '../models/inventory_item.dart';
import '../models/shopping_item.dart';
import '../services/storage_service.dart';
import '../widgets/add_item_sheet.dart';
import '../widgets/shopping_item_tile.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => ShoppingListScreenState();
}

class ShoppingListScreenState extends State<ShoppingListScreen> {
  final _storage = StorageService();
  List<ShoppingItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _storage.loadShoppingList();
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _persist() => _storage.saveShoppingList(_items);

  Future<void> addItem() async {
    final result = await showAddItemSheet(
      context,
      title: '¿Qué te falta?',
    );
    if (result == null) return;
    setState(() {
      _items.add(ShoppingItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: result.name,
        category: result.category,
      ));
    });
    _persist();
  }

  void _toggle(ShoppingItem item, bool? value) {
    setState(() => item.checked = value ?? false);
    _persist();
  }

  void _delete(ShoppingItem item) {
    setState(() => _items.removeWhere((e) => e.id == item.id));
    _persist();
  }

  Future<void> _addToInventory(ShoppingItem item) async {
    final inventory = await _storage.loadInventory();
    final existing = inventory.firstWhere(
      (e) => e.name.toLowerCase() == item.name.toLowerCase(),
      orElse: () => InventoryItem(id: '', name: '', quantity: 0, category: item.category),
    );
    if (existing.id.isEmpty) {
      inventory.add(InventoryItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: item.name,
        quantity: 1,
        category: item.category,
      ));
    } else {
      existing.quantity++;
    }
    await _storage.saveInventory(inventory);
    setState(() => _items.removeWhere((e) => e.id == item.id));
    await _persist();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${item.name}" agregado a tu inventario')),
      );
    }
  }

  Future<void> _clearChecked() async {
    setState(() => _items.removeWhere((e) => e.checked));
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return _EmptyState(onAdd: addItem);
    }
    final pending = _items.where((e) => !e.checked).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final checked = _items.where((e) => e.checked).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        for (final item in pending)
          ShoppingItemTile(
            item: item,
            onToggle: (v) => _toggle(item, v),
            onDelete: () => _delete(item),
          ),
        if (checked.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comprados (${checked.length})',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: _clearChecked,
                  child: const Text('Vaciar'),
                ),
              ],
            ),
          ),
          for (final item in checked)
            ShoppingItemTile(
              item: item,
              onToggle: (v) => _toggle(item, v),
              onDelete: () => _delete(item),
              onAddToInventory: () => _addToInventory(item),
            ),
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checklist_rtl, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Tu lista de compras está vacía',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Agregar algo que te falte'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
