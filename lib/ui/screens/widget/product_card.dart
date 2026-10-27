import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mmb_app/component/custom_widget.dart';
import 'package:mmb_app/utils/theme/app.colors.dart';

import '../../../Api Model/product_model.dart';
import '../../../utils/theme/app.fonts.dart';

class ProductCard extends StatelessWidget {
  final ProductListData item;
  final ValueChanged<bool>? onToggleActive;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProductCard({
    super.key,
    required this.item,
    this.onToggleActive,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = item.isActive == '1' || item.isActive == 'true';

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFDCDD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.image_outlined,
                size: 40,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppText(
                  item.name ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppFontSize.fontSize16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              AppText(
                '${item.unit ?? ''}kg',
                maxLines: 1,
                style: TextStyle(
                  fontSize: AppFontSize.fontSize16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AppText(
            item.description ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppFontSize.fontSize14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              AppText(
                '₹ ${item.offerPrice ?? '0'}',
                style: TextStyle(
                  fontSize: AppFontSize.fontSize16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              AppText(
                '₹ ${item.price ?? '0'}',
                style: TextStyle(
                  fontSize: AppFontSize.fontSize12,
                  decoration: TextDecoration.lineThrough,
                  fontWeight: FontWeight.w400,
                  color: AppColors.appRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  isActive ? 'AC' : 'IN',
                  style: TextStyle(
                    fontSize: AppFontSize.fontSize10,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.green : Colors.grey,
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.5,
                child: CupertinoSwitch(
                  value: isActive,
                  activeTrackColor: Colors.green,
                  onChanged: onToggleActive,
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: Colors.blue,
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
