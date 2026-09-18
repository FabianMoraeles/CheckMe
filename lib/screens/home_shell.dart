import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'inventory_screen.dart';
import 'shopping_list_screen.dart';

class HomeShell extends StatefulWidget {
  final StorageService? storageService;

  const HomeShell({super.key, this.storageService});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _inventoryKey = GlobalKey<InventoryScreenState>();
  final _shoppingKey = GlobalKey<ShoppingListScreenState>();

  void _goToShoppingList() => _switchTo(1);

  /// Changes the visible tab and refreshes it, since both screens stay
  /// mounted inside the IndexedStack and can go stale after the other
  /// tab moves an item across lists.
  void _switchTo(int index) {
    setState(() => _index = index);
    if (index == 0) {
      _inventoryKey.currentState?.reload();
    } else {
      _shoppingKey.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInventory = _index == 0;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryContainer,
              child: const Icon(Icons.check_circle, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'CheckMe',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Beta',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Mi despensa y compras',
                  style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          InventoryScreen(
            key: _inventoryKey,
            onViewShoppingList: _goToShoppingList,
            storageService: widget.storageService,
          ),
          ShoppingListScreen(key: _shoppingKey, storageService: widget.storageService),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: SizedBox(
          height: 74,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _NavItem(
                        icon: Icons.inventory_2_outlined,
                        selectedIcon: Icons.inventory_2,
                        label: 'Inventario',
                        selected: isInventory,
                        onTap: () => _switchTo(0),
                      ),
                    ),
                    const SizedBox(width: 64),
                    Expanded(
                      child: _NavItem(
                        icon: Icons.shopping_cart_checkout_outlined,
                        selectedIcon: Icons.shopping_cart_checkout,
                        label: 'Lista de compras',
                        selected: !isInventory,
                        onTap: () => _switchTo(1),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -20,
                child: Material(
                  color: AppColors.primaryContainer,
                  shape: const CircleBorder(),
                  elevation: 6,
                  shadowColor: AppColors.primaryContainer.withValues(alpha: 0.5),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      if (isInventory) {
                        _inventoryKey.currentState?.addItem();
                      } else {
                        _shoppingKey.currentState?.addItem();
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Icon(Icons.add, color: Colors.white, size: 26),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Theme.of(context).colorScheme.primary : AppColors.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? selectedIcon : icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: selected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
