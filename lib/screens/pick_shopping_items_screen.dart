import 'package:flutter/material.dart';

import '../models/inventory_item.dart';
import '../models/item_category.dart';
import '../models/shopping_group.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/add_item_sheet.dart';

class _NewShoppingEntry {
  final String name;
  final int quantity;
  final ItemCategory category;

  _NewShoppingEntry({required this.name, required this.quantity, required this.category});
}

/// Full-screen picker for building a shopping trip: choose how many of
/// each thing already in the pantry to buy, add anything new, optionally
/// group it all under one trip, then commit everything at once.
class PickShoppingItemsScreen extends StatefulWidget {
  final StorageService storageService;

  const PickShoppingItemsScreen({super.key, required this.storageService});

  @override
  State<PickShoppingItemsScreen> createState() => _PickShoppingItemsScreenState();
}

class _PickShoppingItemsScreenState extends State<PickShoppingItemsScreen> {
  bool _loading = true;
  bool _hasError = false;
  bool _saving = false;
  List<InventoryItem> _inventory = [];
  List<ShoppingGroup> _groups = [];
  String? _selectedGroupId;
  final Map<String, int> _quantities = {};
  final List<_NewShoppingEntry> _newEntries = [];
  final _searchController = TextEditingController();
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
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final inventory = await widget.storageService.loadInventory();
      final groups = await widget.storageService.loadShoppingGroups();
      setState(() {
        _inventory = inventory;
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

  int get _totalPicked =>
      _quantities.values.where((q) => q > 0).length + _newEntries.length;

  void _setQuantity(InventoryItem item, int quantity) {
    setState(() => _quantities[item.id] = quantity.clamp(0, 999));
  }

  Future<void> _createGroup() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nuevo grupo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Ej. Súper del sábado'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;
    try {
      final group = await widget.storageService.insertShoppingGroup(name);
      setState(() {
        _groups.add(group);
        _selectedGroupId = group.id;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo crear el grupo.')),
        );
      }
    }
  }

  Future<void> _addNewItem() async {
    final result = await showAddItemSheet(
      context,
      title: 'Agregar producto nuevo',
      subtitle: 'Algo que no tienes en tu despensa',
      quantityTitle: 'Cantidad a comprar',
    );
    if (result == null) return;
    setState(() {
      _newEntries.add(_NewShoppingEntry(
        name: result.name,
        quantity: result.quantity,
        category: result.category,
      ));
    });
  }

  Future<void> _confirm() async {
    if (_totalPicked == 0 || _saving) return;
    setState(() => _saving = true);
    try {
      for (final item in _inventory) {
        final qty = _quantities[item.id] ?? 0;
        if (qty > 0) {
          await widget.storageService.insertShoppingItem(
            name: item.name,
            quantity: qty,
            category: item.category,
            groupId: _selectedGroupId,
          );
        }
      }
      for (final entry in _newEntries) {
        await widget.storageService.insertShoppingItem(
          name: entry.name,
          quantity: entry.quantity,
          category: entry.category,
          groupId: _selectedGroupId,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar. Revisa tu conexión.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleInventory = _query.isEmpty
        ? _inventory
        : _inventory.where((e) => e.name.toLowerCase().contains(_query)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('¿Qué vas a comprar?')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off, size: 64, color: AppColors.surfaceContainerHighest),
                        const SizedBox(height: 16),
                        Text(
                          'No pudimos cargar tu despensa. Revisa tu conexión.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Grupo (opcional)',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 8),
                          _GroupChips(
                            groups: _groups,
                            selectedGroupId: _selectedGroupId,
                            onSelect: (id) => setState(() => _selectedGroupId = id),
                            onCreate: _createGroup,
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: _addNewItem,
                            icon: const Icon(Icons.add),
                            label: const Text('Algo que no tienes en tu despensa'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                          if (_newEntries.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            for (final entry in _newEntries)
                              _NewEntryChip(
                                entry: entry,
                                onRemove: () => setState(() => _newEntries.remove(entry)),
                              ),
                          ],
                          const SizedBox(height: 14),
                          if (_inventory.isNotEmpty)
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Buscar en tu despensa...',
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: AppColors.surfaceContainerLow,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _inventory.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  'Aún no tienes productos en tu despensa.\nUsa el botón de arriba para agregar algo nuevo.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.onSurfaceVariant),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: visibleInventory.length,
                              itemBuilder: (context, index) {
                                final item = visibleInventory[index];
                                return _InventoryPickRow(
                                  item: item,
                                  quantity: _quantities[item.id] ?? 0,
                                  onChanged: (q) => _setQuantity(item, q),
                                );
                              },
                            ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _totalPicked > 0 && !_saving ? _confirm : null,
                            child: _saving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    _totalPicked == 0
                                        ? 'Elige qué vas a comprar'
                                        : 'Agregar $_totalPicked a la lista',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _GroupChips extends StatelessWidget {
  final List<ShoppingGroup> groups;
  final String? selectedGroupId;
  final ValueChanged<String?> onSelect;
  final VoidCallback onCreate;

  const _GroupChips({
    required this.groups,
    required this.selectedGroupId,
    required this.onSelect,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip(context, label: 'Sin grupo', selected: selectedGroupId == null, onTap: () => onSelect(null)),
          for (final group in groups)
            _chip(
              context,
              label: group.name,
              selected: selectedGroupId == group.id,
              onTap: () => onSelect(group.id),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onCreate,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 16, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 4),
                      Text('Nuevo grupo',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? Theme.of(context).colorScheme.secondary : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NewEntryChip extends StatelessWidget {
  final _NewShoppingEntry entry;
  final VoidCallback onRemove;

  const _NewEntryChip({required this.entry, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: entry.category.bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(entry.category.icon, size: 16, color: entry.category.iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${entry.name} ×${entry.quantity}',
              style: TextStyle(fontWeight: FontWeight.w600, color: entry.category.labelColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 18, color: entry.category.labelColor),
          ),
        ],
      ),
    );
  }
}

class _InventoryPickRow extends StatelessWidget {
  final InventoryItem item;
  final int quantity;
  final ValueChanged<int> onChanged;

  const _InventoryPickRow({
    required this.item,
    required this.quantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = quantity > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? item.category.bgColor.withValues(alpha: 0.5) : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? item.category.iconColor.withValues(alpha: 0.4) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: item.category.bgColor,
            child: Icon(item.category.icon, color: item.category.iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    overflow: TextOverflow.ellipsis),
                Text(
                  'Tienes ${item.quantity}',
                  style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          _stepperButton(context, icon: Icons.remove, onTap: quantity > 0 ? () => onChanged(quantity - 1) : null),
          SizedBox(
            width: 28,
            child: Text('$quantity', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          _stepperButton(context, icon: Icons.add, onTap: () => onChanged(quantity + 1), filled: true),
        ],
      ),
    );
  }

  Widget _stepperButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback? onTap,
    bool filled = false,
  }) {
    final enabled = onTap != null;
    return Material(
      color: filled
          ? (enabled ? AppColors.primaryContainer : AppColors.surfaceContainer)
          : AppColors.surfaceContainerHigh,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 16,
            color: filled ? Colors.white : (enabled ? AppColors.onSurface : AppColors.outline),
          ),
        ),
      ),
    );
  }
}
