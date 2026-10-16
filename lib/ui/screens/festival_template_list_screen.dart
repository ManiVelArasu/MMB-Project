import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/ui/screens/template_edit.dart';
import 'package:provider/provider.dart';

import '../../Api Model/special_days.dart';
import '../../component/appbar_widget.dart';
import '../../core/api/api_endpoints.dart';
import '../../network/provider/custom_theme_provider.dart';

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
        itemBuilder: (context, index) {
          final template = templates[index];

          final key = template.thumbnailS3Key?.trim() ?? '';

          final imageUrl = key.isEmpty
              ? ''
              : key.startsWith('http://') || key.startsWith('https://')
              ? key
              : '${ApiEndpoints.cdnImageUrl}/$key';

          return GestureDetector(
            onTap: () {
              final uid = template.uid?.trim() ?? '';

              if (uid.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Template UID not available')),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TemplateEditScreen(templateUid: uid),
                ),
              );
            },
            child: Container(
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
          );
        },
      ),
    );
  }
}
