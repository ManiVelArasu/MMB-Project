import 'package:flutter/cupertino.dart';

class AppText extends Text {
  const AppText(
      super.data, {
        super.key,
        super.overflow,
        super.maxLines,
        super.style,
        super.textAlign,
        this.fontfamily = 'Outfit',
        this.autoTr = true,
      });

  final bool autoTr;
  final String fontfamily;

  @override
  Widget build(BuildContext context) {
    return Text(
      data ?? '',
      style: (style ?? const TextStyle()).copyWith(
        fontFamily: fontfamily,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}