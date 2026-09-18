import 'package:flutter/material.dart';

import '../models/shopping_item.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/add_item_sheet.dart';
import '../widgets/shopping_item_tile.dart';

class ShoppingListScreen extends StatefulWidget {
  final StorageService? storageService;

  const ShoppingListScreen({super.key, this.storageService});

  @override
  State<ShoppingListScreen> createState() => ShoppingListScreenState();
}

class ShoppingListScreenState extends State<ShoppingListScreen> {
  late final StorageService _storage = widget.storageService ?? StorageService();
  List<ShoppingItem> _items = [];
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final items = await _storage.loadShoppingList();
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  /// Re-reads from storage. Needed because this screen and the inventory
  /// both stay alive inside an IndexedStack, so a change made from one
  /// (e.g. "add to my inventory") won't show up on the other until it
  /// reloads.
  Future<void> reload() => _load();

  void _showSaveError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo guardar el cambio. Revisa tu conexión.')),
    );
  }

  Future<void> addItem() async {
    final result = await showAddItemSheet(
      context,
      title: '¿Qué te falta?',
      subtitle: 'Se agregará a tu lista de compras',
      quantityTitle: 'Cantidad a comprar',
      quantitySubtitle: 'Se sumará a tu inventario cuando la compres',
    );
    if (result == null) return;

    try {
      final inserted = await _storage.insertShoppingItem(
        name: result.name,
        quantity: result.quantity,
        category: result.category,
      );
      setState(() => _items.add(inserted));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${result.name}" agregado a tu lista')),
        );
      }
    } catch (_) {
      _showSaveError();
    }
  }

  void _toggle(ShoppingItem item, bool? value) {
    setState(() => item.checked = value ?? false);
    _storage.updateShoppingItemChecked(item.id, item.checked).catchError((_) {
      _showSaveError();
    });
  }

  void _delete(ShoppingItem item) {
    setState(() => _items.removeWhere((e) => e.id == item.id));
    _storage.deleteShoppingItem(item.id).catchError((_) {
      _showSaveError();
    });
  }

  Future<void> _addToInventory(ShoppingItem item) async {
    try {
      final existing = await _storage.findInventoryItemByName(item.name);
      if (existing == null) {
        await _storage.insertInventoryItem(
          name: item.name,
          quantity: item.quantity,
          category: item.category,
        );
      } else {
        await _storage.updateInventoryItemQuantity(
          existing.id,
          existing.quantity + item.quantity,
        );
      }
      await _storage.deleteShoppingItem(item.id);
      setState(() => _items.removeWhere((e) => e.id == item.id));
      if (mounted) {
        final plural = item.quantity == 1 ? 'unidad' : 'unidades';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.quantity} $plural de "${item.name}" agregadas a tu inventario'),
          ),
        );
      }
    } catch (_) {
      _showSaveError();
    }
  }

  Future<void> _clearChecked() async {
    final removedIds = _items.where((e) => e.checked).map((e) => e.id).toSet();
    setState(() => _items.removeWhere((e) => removedIds.contains(e.id)));
    try {
      await _storage.deleteCheckedShoppingItems();
    } catch (_) {
      _showSaveError();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError) {
      return _ErrorState(onRetry: _load);
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

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 80, color: AppColors.surfaceContainerHighest),
            const SizedBox(height: 16),
            Text(
              'No pudimos cargar tu lista. Revisa tu conexión.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
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
