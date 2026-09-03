import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NetworkAssetImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? errorWidget;
  final Widget? loadingWidget;

  const NetworkAssetImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorWidget,
    this.loadingWidget,
  });

  bool get _isSvg {
    final value = url?.toLowerCase().split('?').first ?? '';
    return value.endsWith('.svg');
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = url?.trim() ?? '';

    if (imageUrl.isEmpty) {
      return _errorWidget();
    }

    // SVG
    if (_isSvg) {
      return SvgPicture.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholderBuilder: (_) =>
        loadingWidget ?? _loadingWidget(),
      );
    }

    // PNG / JPG / JPEG / WEBP / GIF etc.
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return loadingWidget ?? _loadingWidget();
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Image load error: $imageUrl');
        debugPrint('$error');

        return _errorWidget();
      },
    );
  }

  Widget _loadingWidget() {
    return const Center(
      child: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
        ),
      ),
    );
  }

  Widget _errorWidget() {
    return errorWidget ??
        const Icon(
          Icons.category,
          size: 16,
          color: Colors.white,
        );
  }
}