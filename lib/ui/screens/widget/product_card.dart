import 'dart:io';
import 'package:flutter/material.dart';
import '../../../network/provider/my_product_provider.dart';

class ProductCard extends StatelessWidget {
  final ProductItem item;

  const ProductCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE5E5E5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE
          SizedBox(
            height: 82,
            width: double.infinity,
            child: item.image.isNotEmpty
                ? Image.file(
              File(item.image),
              fit: BoxFit.cover,
            )
                : Container(
              color: const Color(0xFFEFEFEF),
              child: const Icon(
                Icons.image_outlined,
                color: Colors.grey,
              ),
            ),
          ),

          // CONTENT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                7,
                6,
                7,
                5,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    item.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 8.5,
                      color: Colors.black54,
                      height: 1.25,
                    ),
                  ),

                  const Spacer(),

                  Row(
                    children: [
                      Text(
                        "₹ ${item.offerPrice}",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      if (item.offerPrice != item.price) ...[
                        const SizedBox(width: 5),
                        Text(
                          "₹ ${item.price}",
                          style: const TextStyle(
                            fontSize: 7,
                            color: Color(0xFFED1C24),
                            decoration:
                            TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 5),

                  Container(
                    height: 25,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: item.isActive
                                ? const Color(0xFFED1C24)
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),

                        const SizedBox(width: 5),

                        Text(
                          item.isActive
                              ? "ACTIVE"
                              : "INACTIVE",
                          style: const TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const Spacer(),

                        _actionButton(
                          Icons.edit_outlined,
                              () {
                            // edit
                          },
                        ),

                        const SizedBox(width: 6),

                        _actionButton(
                          Icons.delete_outline,
                              () {
                            // delete
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
      IconData icon,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFEF),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 13,
          color: const Color(0xFF555555),
        ),
      ),
    );
  }
}