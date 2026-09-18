import 'package:flutter/material.dart';

import '../models/inventory_item.dart';
import '../models/shopping_item.dart';
import '../services/storage_service.dart';
import '../widgets/add_item_sheet.dart';
import '../widgets/inventory_item_card.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => InventoryScreenState();
}

class InventoryScreenState extends State<InventoryScreen> {
  final _storage = StorageService();
  List<InventoryItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _storage.loadInventory();
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _persist() => _storage.saveInventory(_items);

  Future<void> addItem() async {
    final result = await showAddItemSheet(
      context,
      title: 'Nuevo objeto',
      withQuantity: true,
    );
    if (result == null) return;
    setState(() {
      _items.add(InventoryItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: result.name,
        quantity: result.quantity,
        category: result.category,
      ));
    });
    _persist();
  }

  void _increment(InventoryItem item) {
    setState(() => item.quantity++);
    _persist();
  }

  void _decrement(InventoryItem item) {
    if (item.quantity == 0) return;
    setState(() => item.quantity--);
    _persist();
  }

  void _delete(InventoryItem item) {
    setState(() => _items.removeWhere((e) => e.id == item.id));
    _persist();
  }

  Future<void> _addToShoppingList(InventoryItem item) async {
    final shoppingItems = await _storage.loadShoppingList();
    final alreadyThere =
        shoppingItems.any((e) => e.name.toLowerCase() == item.name.toLowerCase());
    if (!alreadyThere) {
      shoppingItems.add(ShoppingItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: item.name,
        category: item.category,
      ));
      await _storage.saveShoppingList(shoppingItems);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${item.name}" agregado a tu lista de compras')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return _EmptyState(onAdd: addItem);
    }
    final sorted = [..._items]
      ..sort((a, b) {
        final cat = a.category.index.compareTo(b.category.index);
        if (cat != 0) return cat;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final item = sorted[index];
        return InventoryItemCard(
          item: item,
          onIncrement: () => _increment(item),
          onDecrement: () => _decrement(item),
          onDelete: () => _delete(item),
          onAddToShoppingList: () => _addToShoppingList(item),
        );
      },
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
            Icon(Icons.inventory_2_outlined,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Aún no tienes nada en tu inventario',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Agregar mi primer objeto'),
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
