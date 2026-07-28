import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';

import '../utils/theme/app.colors.dart';

class SvgLoaderWidget extends StatelessWidget {
  const SvgLoaderWidget({super.key, this.image, this.iconColor, this.fit=BoxFit.contain,});
  final String? image;
  final Color? iconColor;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      fit: fit,
      image ?? "AppAssets.personImg",
      colorFilter:iconColor!=null?
          ColorFilter.mode(iconColor ?? AppColors.primaryColor, BlendMode.srcIn):null,
    );
  }
}
