import 'package:flutter/cupertino.dart';

class AppText extends Text {
  const AppText(
    super.data, {
    super.key,
    super.overflow,
    super.maxLines,
    super.style,
    super.textAlign,
    this.autoTr = true,
  });

  final bool autoTr;

  @override
  Widget build(BuildContext context) {
    return Text(
      data ?? '',
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
