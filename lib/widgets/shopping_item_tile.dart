import 'package:flutter/material.dart';

import '../models/item_category.dart';
import '../models/shopping_item.dart';
import '../theme/app_theme.dart';

class ShoppingItemTile extends StatelessWidget {
  final ShoppingItem item;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onAddToInventory;

  const ShoppingItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
    this.onAddToInventory,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onToggle(!item.checked),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Transform.scale(
                  scale: 1.3,
                  child: Checkbox(
                    value: item.checked,
                    onChanged: onToggle,
                    shape: const CircleBorder(),
                    activeColor: item.category.iconColor,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(item.category.icon, color: item.category.iconColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      decoration:
                          item.checked ? TextDecoration.lineThrough : null,
                      color: item.checked ? AppColors.outline : AppColors.onSurface,
                    ),
                  ),
                ),
                if (item.quantity > 1) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.checked
                          ? AppColors.surfaceContainerHigh
                          : item.category.bgColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '×${item.quantity}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: item.checked ? AppColors.outline : item.category.labelColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (item.checked && onAddToInventory != null)
                  IconButton(
                    tooltip: 'Agregar a mi inventario',
                    icon: const Icon(Icons.inventory_2_outlined),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: onAddToInventory,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
