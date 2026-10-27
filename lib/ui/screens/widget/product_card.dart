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
    final imageUrl = "item.image" ?? '';

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFDCDD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Product Image
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
          ),
          const SizedBox(height: 8),

          AppText(
            '${item.name ?? ''}, ${item.unit ?? ''}Kg',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppFontSize.fontSize14,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          AppText(
            item.description ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppFontSize.fontSize11,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 2,
            children: [
              AppText(
                '₹ ${item.offerPrice ?? item.price ?? '0'}',
                style: TextStyle(
                  fontSize: AppFontSize.fontSize14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              if (item.offerPrice != null && item.offerPrice != item.price)
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

          // Divider Line
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFFFDCDD)),
          const SizedBox(height: 4),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                isActive ? 'ACTIVE' : 'INACTIVE',
                style: TextStyle(
                  fontSize: AppFontSize.fontSize10,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),

              Transform.scale(
                scale: 0.45,
                child: CupertinoSwitch(
                  value: isActive,
                  activeTrackColor: Colors.green,
                  onChanged: onToggleActive,
                ),
              ),
              _buildActionButton(icon: Icons.edit_outlined, onPressed: onEdit),
              const SizedBox(width: 2),
              _buildActionButton(
                icon: Icons.delete_outline,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.image_outlined, size: 35, color: Colors.grey),
    );
  }

  Widget _buildActionButton({required IconData icon, VoidCallback? onPressed}) {
    return Material(
      color: const Color(0xFFEFEFEF),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(
            4,
          ), // பட்டன் பேடிங் குறைக்கப்பட்டுள்ள்ளது
          child: Icon(icon, size: 15, color: Colors.black87),
        ),
      ),
    );
  }
}
