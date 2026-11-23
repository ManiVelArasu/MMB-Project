import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Network image that shows nothing while loading / on error.
/// Animated frames (gif / webp) animate automatically.
class FrameImage extends StatelessWidget {
  const FrameImage({super.key, required this.url, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const SizedBox.shrink();
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (_, __) => const SizedBox.shrink(),
      errorWidget: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}

/// Logo drawn inside the frame's logo slot (whole image, not cropped).
class FrameSlotLogo extends StatelessWidget {
  const FrameSlotLogo({super.key, required this.file, required this.url});

  final File? file;
  final String url;

  @override
  Widget build(BuildContext context) {
    final f = file;
    if (f != null) return Image.file(f, fit: BoxFit.contain);
    return FrameImage(url: url, fit: BoxFit.contain);
  }
}

/// Picked logo -> profile image -> profile icon (never the app logo).
class BrandAvatar extends StatelessWidget {
  const BrandAvatar({
    super.key,
    required this.file,
    required this.url,
    this.height,
  });

  final File? file;
  final String url;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final f = file;
    if (f != null) {
      return Image.file(f, height: height, fit: BoxFit.contain);
    }

    final icon = Icon(
      Icons.account_circle_rounded,
      size: height ?? 48.sp,
      color: Colors.grey.shade500,
    );
    if (url.isEmpty) return icon;

    return SizedBox(
      height: height,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          height: height,
          width: height,
          fit: BoxFit.cover,
          placeholder: (_, __) => icon,
          errorWidget: (_, __, ___) => icon,
        ),
      ),
    );
  }
}
