import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:mmb_app/component/custom_widget.dart';
import 'package:mmb_app/ui/screens/template_edit.dart';
import 'package:mmb_app/ui/screens/widget/favorite_button.dart';
import 'package:provider/provider.dart';

import '../../../Api Model/Template_model.dart';
import '../../../Api Model/template_version.dart' hide TemplateVersion;
import '../../../core/api/api_endpoints.dart';
import '../../../network/provider/custom_theme_provider.dart';
import '../../../network/provider/template_detail_provider.dart';
import '../../../utils/theme/app.colors.dart';
import '../../../utils/theme/app.fonts.dart';

const _kRed = Color(0xFFE53935);

Color _tint(bool isDark) =>
    isDark ? const Color(0xFF2A1A1C) : const Color(0xFFFFECEE);

String _imageUrl(String? key) {
  final k = key?.trim() ?? '';
  if (k.isEmpty) return '';
  return k.startsWith('http') ? k : '${ApiEndpoints.cdnImageUrl}/$k';
}

class _SizeOption {
  final String label;
  final int width;
  final int height;
  const _SizeOption(this.label, this.width, this.height);
  String get key => '${width}x$height';
}

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

String _ratioLabel(int w, int h) {
  final r = w / h;
  bool near(double v) => (r - v).abs() < 0.02;
  if (near(1.0)) return 'Square (1:1)';
  if (near(4 / 5)) return 'Portrait (4:5)';
  if (near(9 / 16)) return 'Story (9:16)';
  if (near(1.91)) return 'Landscape (1.91:1)';
  if (near(16 / 9)) return 'Landscape (16:9)';
  final g = _gcd(w, h);
  return '${w > h ? 'Landscape' : 'Portrait'} (${w ~/ g}:${h ~/ g})';
}

List<_SizeOption> _sizeOptionsFor(TemplateModel? t) {
  final list = <_SizeOption>[];
  if (t == null) return list;
  final seen = <String>{};

  void add(int? w, int? h, {bool first = false}) {
    if (w == null || h == null || w <= 0 || h <= 0) return;
    if (!seen.add('${w}x$h')) return;
    final opt = _SizeOption(_ratioLabel(w, h), w, h);
    first ? list.insert(0, opt) : list.add(opt);
  }

  for (final z in t.availableSizes) {
    add(z.width, z.height);
  }
  add(t.templateSize?.width, t.templateSize?.height, first: true);
  return list;
}

String _defaultKeyFor(TemplateModel? t) {
  final w = t?.templateSize?.width;
  final h = t?.templateSize?.height;
  if (w != null && h != null && w > 0 && h > 0) return '${w}x$h';
  final opts = _sizeOptionsFor(t);
  return opts.isNotEmpty ? opts.first.key : '';
}

({double width, double height}) _parseKey(String key) {
  final p = key.split('x');
  if (p.length == 2) {
    final w = double.tryParse(p[0]);
    final h = double.tryParse(p[1]);
    if (w != null && h != null && w > 0 && h > 0) {
      return (width: w, height: h);
    }
  }
  return (width: 1080, height: 1080);
}

List<String> _languagesOf(TemplateModel t) {
  final names = <String>[];
  for (final l in t.availableLanguages) {
    final n = (l.name ?? l.nativeName ?? '').trim();
    if (n.isNotEmpty && !names.contains(n)) names.add(n);
  }
  if (names.isEmpty) {
    final n = (t.language?.name ?? '').trim();
    if (n.isNotEmpty) names.add(n);
  }
  return names;
}

TemplateVersion? _versionFor(TemplateModel t, String? lang, String sizeKey) {
  final all = t.versions;
  if (all.isEmpty) return null;
  final byLang = lang == null
      ? all
      : all.where((v) => v.languageName == lang).toList();
  final pool = byLang.isNotEmpty ? byLang : all;
  for (final v in pool) {
    if ('${v.width}x${v.height}' == sizeKey) return v;
  }
  return pool.first;
}

class TemplateQuickViewSheet extends StatelessWidget {
  final String templateUid;
  final int? categoryId;

  const TemplateQuickViewSheet({
    super.key,
    required this.templateUid,
    this.categoryId,
  });

  static Future<void> show(
    BuildContext context, {
    required String templateUid,
    int? categoryId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TemplateQuickViewSheet(
        templateUid: templateUid,
        categoryId: categoryId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          TemplateDetailProvider()
            ..loadByTemplate(uid: templateUid, categoryId: categoryId),
      child: const _SheetBody(),
    );
  }
}

class _SheetBody extends StatefulWidget {
  const _SheetBody();

  @override
  State<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends State<_SheetBody> {
  /// Selected language chip (defaults to the template's own language).
  String? _lang;
  String? _forUid;

  TemplateVersion? _version(TemplateModel t, TemplateDetailProvider p) =>
      _versionFor(t, _lang, p.selectedResizeSize);

  /// Keeps the selected size valid for the current template.
  void _ensureValidSize(TemplateDetailProvider p) {
    final opts = _sizeOptionsFor(p.selectedTemplate);
    if (opts.isEmpty || opts.any((o) => o.key == p.selectedResizeSize)) return;
    final fallback = _defaultKeyFor(p.selectedTemplate);
    if (fallback.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => p.setResizeSize(fallback),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TemplateDetailProvider>();
    final isDark = context.watch<CustomThemeProvider>().isDarkMode;
    final t = p.selectedTemplate;

    // new template (first load / "More Like This" tap) -> reset language
    if (t != null && _forUid != t.uid) {
      _forUid = t.uid;
      final own = (t.language?.name ?? '').trim();
      _lang = own.isEmpty ? null : own;
    }

    _ensureValidSize(p);

    final loading = !p.hasLoaded || (p.isLoading && t == null);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      margin: EdgeInsets.only(bottom: 16.h),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                  if (loading)
                    SizedBox(
                      height: 260.h,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    )
                  else if (t == null)
                    SizedBox(
                      height: 200.h,
                      child: Center(
                        child: AppText(
                          'Template not available',
                          style: TextStyle(
                            fontSize: AppFontSize.fontSize14,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._content(context, p, t, isDark),
                ],
              ),
            ),

            // close (X)
            Positioned(
              top: 10.h,
              right: 12.w,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(
                    color: _tint(isDark),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 16.sp, color: _kRed),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // CONTENT
  // ------------------------------------------------------------------

  List<Widget> _content(
    BuildContext context,
    TemplateDetailProvider p,
    TemplateModel t,
    bool isDark,
  ) {
    final more = p.gridImageTemplates
        .where((e) => (e.uid ?? '') != (t.uid ?? ''))
        .toList();

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: _preview(p, t, isDark)),
          SizedBox(width: 14.w),
          Expanded(flex: 6, child: _info(p, t, isDark)),
        ],
      ),
      SizedBox(height: 16.h),
      _actionRow(context, p, t, isDark),
      if (t.isLocked ?? false) ...[
        SizedBox(height: 8.h),
        AppText(
          'This template is part of the premium collection.',
          style: TextStyle(
            fontSize: AppFontSize.fontSize12,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
      if (p.isLoading || more.isNotEmpty) ...[
        SizedBox(height: 24.h),
        AppText(
          'More Like This',
          style: TextStyle(
            fontSize: AppFontSize.fontSize15,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 12.h),
        if (p.isLoading)
          SizedBox(
            height: 150.h,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          _moreLikeThis(p, more, isDark),
      ],
    ];
  }

  // ------------------------------------------------------------------
  // PREVIEW  (follows the selected size's aspect ratio)
  // ------------------------------------------------------------------

  Widget _preview(TemplateDetailProvider p, TemplateModel t, bool isDark) {
    final url = _imageUrl(_version(t, p)?.thumbnailS3Key ?? t.thumbnailS3Key);
    final size = _parseKey(p.selectedResizeSize);
    final locked = t.isLocked ?? false;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: AspectRatio(
        aspectRatio: size.width / size.height,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            color: isDark ? Colors.black26 : Colors.white,
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 8),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              url.isEmpty
                  ? Icon(
                      Icons.image_outlined,
                      size: 36.sp,
                      color: Colors.grey.shade400,
                    )
                  : CachedNetworkImage(
                      key: ValueKey(url),
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (_, __, ___) => Icon(
                        Icons.image_not_supported_outlined,
                        size: 36.sp,
                        color: Colors.grey.shade400,
                      ),
                    ),
              if (locked)
                Positioned(
                  top: 6.h,
                  left: 6.w,
                  child: Image.asset(
                    'assets/images/crown.png',
                    width: 26.w,
                    height: 26.h,
                    fit: BoxFit.contain,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // INFO  (name · details · sizes · languages)
  // ------------------------------------------------------------------

  Widget _info(TemplateDetailProvider p, TemplateModel t, bool isDark) {
    final name = (t.name ?? '').toString().trim();
    final w = (t.templateSize?.width ?? 0).toInt();
    final h = (t.templateSize?.height ?? 0).toInt();

    var details = '';
    if (w > 0 && h > 0) {
      final orientation = _ratioLabel(w, h).split(' ').first;
      details = '$orientation · $w × $h';
    }

    final sizes = _sizeOptionsFor(t);
    final languages = _languagesOf(t);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (name.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(right: 32.w),
            child: AppText(
              name,
              style: TextStyle(
                fontSize: AppFontSize.fontSize18,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        if (details.isNotEmpty) ...[
          SizedBox(height: 2.h),
          AppText(
            details,
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
        if (sizes.isNotEmpty)
          _chipGroup(
            'Available Sizes',
            sizes
                .map(
                  (e) => _chip(
                    e.label,
                    isDark,
                    selected: p.selectedResizeSize == e.key,
                    onTap: () => p.setResizeSize(e.key),
                  ),
                )
                .toList(),
          ),
        if (languages.isNotEmpty)
          _chipGroup(
            'Available Language',
            languages
                .map(
                  (l) => _chip(
                    l,
                    isDark,
                    selected: _lang == l,
                    onTap: () => setState(() => _lang = l),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _chipGroup(String title, List<Widget> chips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 14.h),
        AppText(
          title,
          style: TextStyle(
            fontSize: AppFontSize.fontSize14,
            fontWeight: FontWeight.w400,
            color: AppColors.appGrey,
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(spacing: 8.w, runSpacing: 8.h, children: chips),
      ],
    );
  }

  Widget _chip(
    String label,
    bool isDark, {
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFECEE)
              : (isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected
                ? Colors.red
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          ),
        ),
        child: AppText(
          label,
          style: TextStyle(
            fontSize: AppFontSize.fontSize12,
            fontWeight: FontWeight.w500,
            color: selected
                ? Colors.red
                : (isDark ? Colors.white70 : AppColors.appGrey),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // ACTION ROW  (USE THIS TEMPLATE | download | heart)
  // ------------------------------------------------------------------

  Widget _actionRow(
    BuildContext context,
    TemplateDetailProvider p,
    TemplateModel t,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46.w,
            child: ElevatedButton(
              onPressed: () => _useTemplate(context, p, t),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: AppText(
                'USE THIS TEMPLATE',
                style: TextStyle(
                  fontSize: AppFontSize.fontSize14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        InkWell(
          onTap: () => _download(context, t, p),
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            width: 46.w,
            height: 46.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _tint(isDark),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: const Icon(
              Icons.file_download_outlined,
              color: _kRed,
              size: 22,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        FavoriteButton(
          key: ValueKey(t.uid),
          templateId: t.familyUid?.trim(),
          initialLikes: t.likesCount,
          isDark: isDark,
          size: 46.w,
          radius: 12.r,
        ),
      ],
    );
  }

  // Same as TemplateDetailScreen._openEditor
  void _useTemplate(
    BuildContext context,
    TemplateDetailProvider p,
    TemplateModel t,
  ) {
    // uid of the selected language version
    final uid = (_version(t, p)?.uid ?? t.uid)?.trim() ?? '';
    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: AppText('Template UID not available')),
      );
      return;
    }

    final sizeKey = p.selectedResizeSize;
    final size = _parseKey(sizeKey);
    final nav = Navigator.of(context);

    nav.pop(); // close sheet
    nav.push(
      MaterialPageRoute(
        builder: (_) => TemplateEditScreen(
          templateUid: uid,
          resizeSize: sizeKey,
          canvasWidth: size.width,
          canvasHeight: size.height,
        ),
      ),
    );
  }

  Future<void> _download(
    BuildContext context,
    TemplateModel t,
    TemplateDetailProvider p,
  ) async {
    final ver = _version(t, p);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final url = _imageUrl(ver?.thumbnailS3Key ?? t.thumbnailS3Key);
      if (url.isEmpty) throw Exception('Template image not available');

      messenger.showSnackBar(
        const SnackBar(content: Text('Downloading image...')),
      );

      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) throw Exception('Image download failed');

      await Gal.putImageBytes(
        res.bodyBytes,
        name: 'MMB_${ver?.uid ?? t.uid ?? 'template'}',
      );

      messenger.showSnackBar(
        const SnackBar(content: Text('Image saved to Gallery successfully!')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }

  // ------------------------------------------------------------------
  // MORE LIKE THIS  (tap = same as detail screen's _onTemplateTap)
  // ------------------------------------------------------------------

  Widget _moreLikeThis(
    TemplateDetailProvider p,
    List<TemplateModel> list,
    bool isDark,
  ) {
    return SizedBox(
      height: 150.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (_, i) {
          final item = list[i];
          final url = _imageUrl(item.thumbnailS3Key);
          return GestureDetector(
            onTap: () {
              final uid = item.uid?.trim() ?? '';
              if (uid.isEmpty) return;
              p.selectTemplate(uid);
              final key = _defaultKeyFor(item);
              if (key.isNotEmpty) p.setResizeSize(key);
            },
            child: AspectRatio(
              aspectRatio: 0.78,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  color: isDark
                      ? const Color(0xFF252525)
                      : Colors.grey.shade200,
                  border: Border.all(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),
                child: url.isEmpty
                    ? Icon(Icons.image_outlined, color: Colors.grey.shade400)
                    : CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey.shade400,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
