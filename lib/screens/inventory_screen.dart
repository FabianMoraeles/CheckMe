import 'package:flutter/material.dart';

import '../models/inventory_item.dart';
import '../models/item_category.dart';
import '../models/shopping_item.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/add_item_sheet.dart';
import '../widgets/inventory_item_card.dart';

/// A filter chip can be "all", "out-of-stock" or one specific category.
class _Filter {
  final String key;
  final String label;
  final ItemCategory? category;
  final bool outOfStockOnly;

  const _Filter.all()
      : key = 'all',
        label = 'Todos',
        category = null,
        outOfStockOnly = false;

  const _Filter.category(ItemCategory c)
      : key = 'cat',
        label = '',
        category = c,
        outOfStockOnly = false;

  const _Filter.outOfStock()
      : key = 'out',
        label = 'Sin stock',
        category = null,
        outOfStockOnly = true;
}

class InventoryScreen extends StatefulWidget {
  final VoidCallback onViewShoppingList;

  const InventoryScreen({super.key, required this.onViewShoppingList});

  @override
  State<InventoryScreen> createState() => InventoryScreenState();
}

class InventoryScreenState extends State<InventoryScreen> {
  final _storage = StorageService();
  final _searchController = TextEditingController();
  List<InventoryItem> _items = [];
  bool _loading = true;
  _Filter _filter = const _Filter.all();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await _storage.loadInventory();
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  /// Re-reads from storage. Needed because this screen and the shopping
  /// list both stay alive inside an IndexedStack, so a change made from
  /// one (e.g. "also add to shopping list") won't show up on the other
  /// until it reloads.
  Future<void> reload() => _load();

  Future<void> _persist() => _storage.saveInventory(_items);

  Future<void> addItem() async {
    final result = await showAddItemSheet(
      context,
      title: 'Agregar nuevo objeto',
      subtitle: 'Control rápido de tu despensa',
      quantityTitle: 'Cantidad inicial',
      quantitySubtitle: 'Unidades en inventario',
      showAddToShoppingListToggle: true,
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
    await _persist();

    if (result.alsoAddToShoppingList) {
      final shoppingItems = await _storage.loadShoppingList();
      shoppingItems.add(ShoppingItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: result.name,
        category: result.category,
      ));
      await _storage.saveShoppingList(shoppingItems);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${result.name}" agregado a tu despensa')),
      );
    }
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

  List<InventoryItem> get _visibleItems {
    var list = _items.where((item) {
      if (_query.isNotEmpty && !item.name.toLowerCase().contains(_query)) {
        return false;
      }
      if (_filter.outOfStockOnly) return item.quantity == 0;
      if (_filter.category != null) return item.category == _filter.category;
      return true;
    }).toList();
    list.sort((a, b) {
      final cat = a.category.index.compareTo(b.category.index);
      if (cat != 0) return cat;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  int get _outOfStockCount => _items.where((e) => e.quantity == 0).length;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return _EmptyState(onAdd: addItem);
    }

    final visible = _visibleItems;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _Header(totalCount: _items.length),
            const SizedBox(height: 14),
            _SearchBar(controller: _searchController),
            const SizedBox(height: 12),
            _FilterChips(
              items: _items,
              selected: _filter,
              onSelected: (f) => setState(() => _filter = f),
            ),
            const SizedBox(height: 4),
            if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'No encontramos nada con ese filtro',
                    style: TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                ),
              )
            else
              for (final item in visible)
                InventoryItemCard(
                  item: item,
                  onIncrement: () => _increment(item),
                  onDecrement: () => _decrement(item),
                  onDelete: () => _delete(item),
                  onAddToShoppingList: () => _addToShoppingList(item),
                ),
            const SizedBox(height: 8),
            _DiscoveryCard(onAdd: addItem),
            if (_outOfStockCount > 0) const SizedBox(height: 56),
          ],
        ),
        if (_outOfStockCount > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Center(
              child: _QuickReplenishBar(
                count: _outOfStockCount,
                onViewList: widget.onViewShoppingList,
              ),
            ),
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final int totalCount;

  const _Header({required this.totalCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mi Despensa 🛒', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 2),
              Text(
                'Todo al día para tu semana',
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
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$totalCount ${totalCount == 1 ? 'producto' : 'productos'}',
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

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;

  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Buscar en tu despensa...',
          hintStyle: TextStyle(color: AppColors.outline),
          prefixIcon: Icon(Icons.search, color: AppColors.onSurfaceVariant),
          suffixIcon: IconButton(
            tooltip: 'Escanear código de barras',
            icon: Icon(Icons.qr_code_scanner, color: Theme.of(context).colorScheme.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Escaneo de código próximamente')),
              );
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final List<InventoryItem> items;
  final _Filter selected;
  final ValueChanged<_Filter> onSelected;

  const _FilterChips({
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final outOfStock = items.where((e) => e.quantity == 0).length;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip(
            context,
            label: 'Todos',
            count: items.length,
            selected: selected.key == 'all',
            onTap: () => onSelected(const _Filter.all()),
          ),
          for (final c in ItemCategory.values)
            _chip(
              context,
              label: c.label,
              count: items.where((e) => e.category == c).length,
              selected: selected.category == c,
              iconColor: c.iconColor,
              onTap: () => onSelected(_Filter.category(c)),
            ),
          if (outOfStock > 0)
            _chip(
              context,
              label: 'Sin stock',
              count: outOfStock,
              selected: selected.outOfStockOnly,
              alert: true,
              onTap: () => onSelected(const _Filter.outOfStock()),
            ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
    Color? iconColor,
    bool alert = false,
  }) {
    final bg = selected
        ? (alert ? AppColors.alertContainer : Theme.of(context).colorScheme.secondary)
        : AppColors.surfaceContainerLowest;
    final fg = selected
        ? (alert ? AppColors.alert : Colors.white)
        : AppColors.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (alert) ...[
                  Icon(Icons.warning_amber_rounded, size: 14, color: fg),
                  const SizedBox(width: 4),
                ],
                Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white.withValues(alpha: 0.25) : AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoveryCard extends StatelessWidget {
  final VoidCallback onAdd;

  const _DiscoveryCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.secondaryContainer,
            child: Icon(Icons.emoji_emotions, color: Theme.of(context).colorScheme.primary, size: 32),
          ),
          const SizedBox(height: 12),
          const Text('¿Buscando algo más?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Mantén tu despensa sincronizada antes de ir al supermercado para no comprar de más.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Agregar mi primer objeto', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickReplenishBar extends StatelessWidget {
  final int count;
  final VoidCallback onViewList;

  const _QuickReplenishBar({required this.count, required this.onViewList});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2E3132),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$count ${count == 1 ? 'ítem' : 'ítems'} por reponer',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 10),
          Material(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onViewList,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text('Ver lista', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
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
            Icon(Icons.inventory_2_outlined, size: 80, color: AppColors.surfaceContainerHighest),
            const SizedBox(height: 16),
            Text(
              'Aún no tienes nada en tu inventario',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Agregar mi primer objeto'),
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
