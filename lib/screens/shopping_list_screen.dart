import 'package:flutter/material.dart';

import '../models/shopping_group.dart';
import '../models/shopping_item.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shopping_item_tile.dart';
import 'pick_shopping_items_screen.dart';

class ShoppingListScreen extends StatefulWidget {
  final StorageService? storageService;

  const ShoppingListScreen({super.key, this.storageService});

  @override
  State<ShoppingListScreen> createState() => ShoppingListScreenState();
}

class ShoppingListScreenState extends State<ShoppingListScreen> {
  late final StorageService _storage = widget.storageService ?? StorageService();
  List<ShoppingItem> _items = [];
  List<ShoppingGroup> _groups = [];
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
      final groups = await _storage.loadShoppingGroups();
      setState(() {
        _items = items;
        _groups = groups;
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
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PickShoppingItemsScreen(storageService: _storage)),
    );
    if (added == true) {
      await _load();
    }
  }

  void _delete(ShoppingItem item) {
    setState(() => _items.removeWhere((e) => e.id == item.id));
    _storage.deleteShoppingItem(item.id).catchError((_) {
      _showSaveError();
    });
  }

  Future<void> _complete(ShoppingItem item) async {
    setState(() => _items.removeWhere((e) => e.id == item.id));
    try {
      await _storage.completeShoppingItem(item);
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
      await _load();
    }
  }

  Future<void> _completeGroup(ShoppingGroup group) async {
    final groupItems = _items.where((e) => e.groupId == group.id).toList();
    if (groupItems.isEmpty) return;
    setState(() => _items.removeWhere((e) => e.groupId == group.id));
    try {
      for (final item in groupItems) {
        await _storage.completeShoppingItem(item);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${group.name}" completado: todo se agregó a tu inventario')),
        );
      }
    } catch (_) {
      _showSaveError();
      await _load();
    }
  }

  Future<void> _deleteGroup(ShoppingGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Eliminar "${group.name}"?'),
        content: const Text('Los productos de este grupo se quedan en tu lista, solo se quita la agrupación.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _groups.removeWhere((g) => g.id == group.id);
      for (final item in _items) {
        if (item.groupId == group.id) item.groupId = null;
      }
    });
    try {
      await _storage.deleteShoppingGroup(group.id);
    } catch (_) {
      _showSaveError();
      await _load();
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

    final ungrouped = _items.where((e) => e.groupId == null).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final groupedByGroupId = <String, List<ShoppingItem>>{};
    for (final item in _items) {
      if (item.groupId != null) {
        groupedByGroupId.putIfAbsent(item.groupId!, () => []).add(item);
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _Header(pendingCount: _items.length),
        const SizedBox(height: 16),
        for (final item in ungrouped)
          ShoppingItemTile(
            item: item,
            onComplete: () => _complete(item),
            onDelete: () => _delete(item),
          ),
        for (final group in _groups)
          if ((groupedByGroupId[group.id] ?? []).isNotEmpty) ...[
            const SizedBox(height: 12),
            _GroupSection(
              group: group,
              items: groupedByGroupId[group.id]!
                ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
              onCompleteAll: () => _completeGroup(group),
              onDeleteGroup: () => _deleteGroup(group),
              onCompleteItem: _complete,
              onDeleteItem: _delete,
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

class _GroupSection extends StatelessWidget {
  final ShoppingGroup group;
  final List<ShoppingItem> items;
  final VoidCallback onCompleteAll;
  final VoidCallback onDeleteGroup;
  final ValueChanged<ShoppingItem> onCompleteItem;
  final ValueChanged<ShoppingItem> onDeleteItem;

  const _GroupSection({
    required this.group,
    required this.items,
    required this.onCompleteAll,
    required this.onDeleteGroup,
    required this.onCompleteItem,
    required this.onDeleteItem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder_open, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${group.name} (${items.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Eliminar grupo',
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDeleteGroup,
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final item in items)
            ShoppingItemTile(
              item: item,
              onComplete: () => onCompleteItem(item),
              onDelete: () => onDeleteItem(item),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCompleteAll,
              icon: const Icon(Icons.done_all),
              label: const Text('Completar todo'),
            ),
          ),
        ],
      ),
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
