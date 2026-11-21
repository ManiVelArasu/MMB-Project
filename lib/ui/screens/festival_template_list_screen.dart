import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/ui/screens/template_detail_screen.dart';
import 'package:mmb_app/ui/screens/template_edit.dart';
import 'package:mmb_app/ui/screens/widget/favorite_button.dart';
import 'package:mmb_app/ui/screens/widget/template_popup.dart';
import 'package:provider/provider.dart';

import '../../Api Model/special_days.dart';
import '../../component/appbar_widget.dart';
import '../../component/custom_widget.dart';
import '../../core/api/api_endpoints.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/favorite_provider.dart';
import '../../utils/theme/app.fonts.dart';

class SpecialDayTemplatesScreen extends StatelessWidget {
  final String specialDayName;
  final List<Template> templates;

  const SpecialDayTemplatesScreen({
    super.key,
    required this.specialDayName,
    required this.templates,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<CustomThemeProvider>().isDarkMode;

    return Scaffold(
      appBar: CustomAppBar(
        title: specialDayName,
        showTitle: true,
        showRightIcon: false,
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(12.r),
        itemCount: templates.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.70,
        ),
        itemBuilder: (context, index) =>
            _buildTemplateCard(context, templates[index], isDark),
      ),
    );
  }

  // =====================================================================
  // CARD
  // =====================================================================

  Widget _buildTemplateCard(
      BuildContext context,
      Template template,
      bool isDark,
      ) {
    final key = template.thumbnailS3Key?.trim() ?? '';
    final imageUrl = key.isEmpty
        ? ''
        : key.startsWith('http://') || key.startsWith('https://')
        ? key
        : '${ApiEndpoints.cdnImageUrl}/$key';

    final familyUid = template.familyUid?.trim() ?? '';

    return GestureDetector(
      onTap: () => _openDetail(context, template),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFEAEAEA),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl.isEmpty
                ? const Center(child: Icon(Icons.image_outlined))
                : CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
              const Center(child: CircularProgressIndicator()),
              errorWidget: (_, __, ___) => const Center(
                child: Icon(Icons.image_not_supported_rounded),
              ),
            ),
          ),

          // crown (left, locked only) + popup (always right)
          Positioned(
            top: 5.h,
            left: 5.w,
            right: 5.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (template.isLocked)
                  Image.asset(
                    'assets/images/crown.png',
                    width: 20.w,
                    height: 20.w,
                  )
                else
                  const SizedBox.shrink(),
                Selector<FavoriteProvider, bool>(
                  selector: (_, p) => p.isFavorite(familyUid),
                  builder: (_, isFav, __) => TemplateActionPopup(
                    isFavorite: true,
                    showDownload: false,
                    showDelete: false,
                    onCustomize: () => _customize(context, template),
                    onDownload: () async {},
                    onFavorite: () => toggleFavorite(context, familyUid),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Future<void> toggleFavorite(BuildContext context, String familyUid) async {
    if (familyUid.isEmpty) return;

    final ok = await context.read<FavoriteProvider>().toggle(familyUid);

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: AppText('Something went wrong. Try again.')),
      );
    }
  }
  // =====================================================================
  // ACTIONS
  // =====================================================================

  void _showUidMissing(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: AppText('Template UID not available')),
    );
  }

  /// Card tap -> Template Detail screen
  void _openDetail(BuildContext context, Template template) {
    final uid = template.uid?.toString().trim() ?? '';
    if (uid.isEmpty) {
      _showUidMissing(context);
      return;
    }

    int? categoryId;
    try {
      final dynamic raw = template.categoryId;
      categoryId = raw is int ? raw : int.tryParse('$raw');
    } catch (_) {
      categoryId = null;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TemplateDetailScreen(templateUid: uid, categoryId: categoryId),
      ),
    );
  }

  /// Popup "Customize" -> editor (premium templates show the upgrade dialog)
  void _customize(BuildContext context, Template template) {
    final templateUid = template.uid?.trim() ?? '';
    if (templateUid.isEmpty) {
      _showUidMissing(context);
      return;
    }

    if (template.isLocked) {
      _openDetail(context, template);
      return;
    }

    _openDetail(context, template);
  }

  // =====================================================================
  // PREMIUM DIALOG
  // =====================================================================

  void _showPremiumTemplateDialog(BuildContext context, dynamic template) {
    final String templateName = (template.name?.toString().isNotEmpty ?? false)
        ? template.name.toString()
        : 'This template';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: Icon(
                          Icons.local_offer_rounded,
                          color: Color(0xFFE91E63),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppText(
                          'Premium template',
                          style: TextStyle(
                            fontSize: AppFontSize.fontSize16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF202124),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AppText(
                      '"$templateName" is part of the premium\n'
                          'collection. Upgrade your plan to use it in your designs.',
                      style:  TextStyle(
                        fontSize: AppFontSize.fontSize14,
                        height: 1.45,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                ),
                Container(height: 1, color: const Color(0xFFE8E8E8)),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const AppText(
                          'Not now',
                          style: TextStyle(
                            color: Color(0xFF222222),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          Navigator.pushNamed(context, '/PlansAndPricingScreen');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF202020),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        child:  AppText(
                          'Upgrade to premium',
                          style: TextStyle(
                            fontSize: AppFontSize.fontSize13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}