import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../network/provider/favorite_provider.dart';

/// Reusable heart button. Use it on any screen:
///
/// FavoriteButton(
///   templateId: template.familyUid,
///   initialFavourited: template.favourited,
///   initialLikes: template.likesCount,
///   isDark: isDark,
/// )
class FavoriteButton extends StatelessWidget {
  final String? templateId;
  final bool? initialFavourited;
  final int? initialLikes;
  final bool isDark;
  final double size;

  /// null -> circle, otherwise rounded square with this radius.
  final double? radius;

  const FavoriteButton({
    super.key,
    required this.templateId,
    required this.isDark,
    this.initialFavourited,
    this.initialLikes,
    this.size = 40,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final fav = context.read<FavoriteProvider>();
    fav.seed(
      templateId,
      favourited: initialFavourited,
      likesCount: initialLikes,
    );

    return Selector<FavoriteProvider, bool>(
      selector: (_, p) => p.isFavorite(templateId),
      builder: (_, isFav, __) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            final ok = await fav.toggle(templateId);
            if (!ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Something went wrong. Try again.')),
              );
            }
          },
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A1A1C) : const Color(0xFFFFECEE),
              shape: radius == null ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: radius == null ? null : BorderRadius.circular(radius!),
            ),
            child: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
              size: size * 0.5,
            ),
          ),
        );
      },
    );
  }
}