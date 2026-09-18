import 'package:flutter/material.dart';

import '../models/inventory_item.dart';
import '../models/shopping_item.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
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

  /// Re-reads from storage. Needed because this screen and the inventory
  /// both stay alive inside an IndexedStack, so a change made from one
  /// (e.g. "add to my inventory") won't show up on the other until it
  /// reloads.
  Future<void> reload() => _load();

  Future<void> _persist() => _storage.saveShoppingList(_items);

  Future<void> addItem() async {
    final result = await showAddItemSheet(
      context,
      title: '¿Qué te falta?',
      subtitle: 'Se agregará a tu lista de compras',
      quantityTitle: 'Cantidad a comprar',
      quantitySubtitle: 'Se sumará a tu inventario cuando la compres',
    );
    if (result == null) return;
    setState(() {
      _items.add(ShoppingItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: result.name,
        category: result.category,
        quantity: result.quantity,
      ));
    });
    await _persist();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${result.name}" agregado a tu lista')),
      );
    }
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
        quantity: item.quantity,
        category: item.category,
      ));
    } else {
      existing.quantity += item.quantity;
    }
    await _storage.saveInventory(inventory);
    setState(() => _items.removeWhere((e) => e.id == item.id));
    await _persist();
    if (mounted) {
      final plural = item.quantity == 1 ? 'unidad' : 'unidades';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.quantity} $plural de "${item.name}" agregadas a tu inventario'),
        ),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _Header(pendingCount: pending.length),
        const SizedBox(height: 16),
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
                    color: AppColors.onSurfaceVariant,
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

class _Header extends StatelessWidget {
  final int pendingCount;

  const _Header({required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lista de Compras 🛍️', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 2),
              Text(
                'Todo listo para tu próxima salida',
                style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.secondaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                '$pendingCount ${pendingCount == 1 ? 'pendiente' : 'pendientes'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
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
            Icon(Icons.checklist_rtl, size: 80, color: AppColors.surfaceContainerHighest),
            const SizedBox(height: 16),
            Text(
              'Tu lista de compras está vacía',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Agregar algo que te falte'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
