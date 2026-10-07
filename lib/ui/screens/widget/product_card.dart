import 'dart:io';
import 'package:flutter/material.dart';
import '../../../network/provider/my_product_provider.dart';

class ProductCard extends StatelessWidget {
  final ProductItem item;
  const ProductCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFEFEFEF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: item.image.isNotEmpty
                  ? Image.file(File(item.image), fit: BoxFit.cover)
                  : const Icon(Icons.image, color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 8, color: Colors.black54)),
                  const Spacer(),
                  Text("₹ ${item.offerPrice}",
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: item.isActive ? Colors.red : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(item.isActive ? "ACTIVE" : "INACTIVE",
                          style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      const Icon(Icons.edit_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 7),
                      const Icon(Icons.delete_outline, size: 14, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
