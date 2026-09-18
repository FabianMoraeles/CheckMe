import 'package:flutter/material.dart';

import '../models/inventory_item.dart';
import '../models/item_category.dart';
import '../theme/app_theme.dart';

class InventoryItemCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;
  final VoidCallback onAddToShoppingList;

  const InventoryItemCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
    required this.onAddToShoppingList,
  });

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = item.quantity == 0;
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: item.category.bgColor,
                  child: Icon(item.category.icon, color: item.category.iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.category.bgColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.category.label,
                          style: TextStyle(
                            color: item.category.labelColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _RoundIconButton(
                  icon: Icons.remove,
                  enabled: !isOutOfStock,
                  onTap: onDecrement,
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    '${item.quantity}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: isOutOfStock ? AppColors.alert : AppColors.onSurface,
                    ),
                  ),
                ),
                _RoundIconButton(
                  icon: Icons.add,
                  enabled: true,
                  filled: true,
                  onTap: onIncrement,
                ),
              ],
            ),
            if (isOutOfStock) ...[
              const SizedBox(height: 10),
              Material(
                color: AppColors.alertContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onAddToShoppingList,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.alert),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Sin stock · Toca para agregar a la lista',
                            style: TextStyle(
                              color: AppColors.alert,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: AppColors.surfaceContainerLowest,
                          child: Icon(Icons.add_shopping_cart, size: 14, color: AppColors.alert),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final bool filled;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = filled
        ? AppColors.primaryContainer
        : (enabled ? AppColors.surfaceContainerHigh : AppColors.surfaceContainer);
    final iconColor = filled
        ? Colors.white
        : (enabled ? AppColors.onSurface : AppColors.outline);

    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 18, color: enabled || filled ? iconColor : iconColor.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}
