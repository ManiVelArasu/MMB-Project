import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mmb_app/component/custom_widget.dart';
import 'package:mmb_app/utils/theme/app.colors.dart';

import '../../../Api Model/product_model.dart';
import '../../../utils/theme/app.fonts.dart';

class ProductCard extends StatelessWidget {
  final ProductListData item;

  const ProductCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
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
              AppText(
                '${item.unit}kg' ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
            style: TextStyle(
              fontSize: AppFontSize.fontSize14,
              fontWeight: FontWeight.w400,
            ),

            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
              AppText(
                '₹ ${item.price}',
                style: TextStyle(
                  fontSize: AppFontSize.fontSize12,
                  decoration: TextDecoration.lineThrough,
                  fontWeight: FontWeight.w400,
                  color: AppColors.appRed
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.isActive == '1' ? '🔴 ACTIVE' : 'INACTIVE',
            style: TextStyle(
              fontSize: AppFontSize.fontSize14,

              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
