import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mmb_app/component/appbar_widget.dart';
import 'package:mmb_app/component/custom_widget.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../../network/provider/ai_hub_provider.dart';
import '../../utils/theme/app.colors.dart';
import '../../utils/theme/app.fonts.dart';

class AiHubPage extends StatelessWidget {
  const AiHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AiHubProvider>(
      create: (_) => AiHubProvider(),
      child: const AiImageScreen(),
    );
  }
}

class AiImageScreen extends StatelessWidget {
  const AiImageScreen({super.key});

  static const Color accent = Color(0xFFF51F48);
  static const Color borderColor = Color(0xFFFFDFE6);

  @override
  Widget build(BuildContext context) {
    return Consumer<AiHubProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: CustomAppBar(title: "AI HUB", showRightIcon: false),
          body: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 280,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFE5E4FF),
                        Color(0xFFFFE8F0),
                        Color(0xFFFFF9FA),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  Expanded(
                    child: SafeArea(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _searchBar(),
                            const SizedBox(height: 10),
                            _generatorCard(context, provider),
                            const SizedBox(height: 12),
                            _credits(provider),
                            const SizedBox(height: 10),
                            _imageResult(provider),
                            if (provider.hasGeneratedImage) ...[
                              const SizedBox(height: 12),
                              _resultActions(context, provider),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _searchBar() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderColor),
      ),
      child: const Row(
        children: [
          Icon(Icons.search, color: Color(0xFFFFA69D)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Search templates, Brand Series...',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Colors.black38),
            ),
          ),
          Icon(Icons.mic_none, size: 19),
        ],
      ),
    );
  }

  Widget _generatorCard(BuildContext context, AiHubProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 15, 12, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEAE8FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child:Image.asset("assets/images/magic_media.png")
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: AppText(
                'AI Content Generator',
                style: TextStyle(
                  fontSize: AppFontSize.fontSize16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          AppText(
            'Create Images for Your\nBusiness with AI',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppFontSize.fontSize22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          AppText(
            'Generate captions, promotional copy, taglines, '
            'product descriptions and social content tailored '
            'to your business.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppFontSize.fontSize13,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: borderColor),
          const SizedBox(height: 4),
          AppText(
            'What would you like to create?',
            style: TextStyle(
              fontSize: AppFontSize.fontSize18,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 6),
          AppText(
            'Let AI generate logos, product images, captions, '
            'videos, and marketing content for your business.',
            style: TextStyle(
              fontSize: AppFontSize.fontSize14,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 9),
          ...provider.suggestions
              .take(2)
              .map(
                (suggestion) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: () {
                      provider.useImageSuggestion(suggestion);
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        suggestion,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 5),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              children: [
                TextField(
                  controller: provider.promptImageController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'Describe the image you want to create...',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.black26),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                const Divider(height: 1, color: borderColor),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _dropdown(
                          value: provider.selectedStyle,
                          items: provider.styles,
                          onChanged: provider.updateStyle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _dropdown(
                          value: provider.selectedRatio,
                          items: provider.ratios,
                          onChanged: provider.updateRatio,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 34,
                        width: 36,
                        child: ElevatedButton(
                          onPressed: provider.isGeneratingImage
                              ? null
                              : () => _generate(context, provider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          child: provider.isGeneratingImage
                              ? const Padding(
                                  padding: EdgeInsets.all(9),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.play_arrow_rounded, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(7),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 15),
          style: const TextStyle(fontSize: 10, color: Colors.black87),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Future<void> _generate(BuildContext context, AiHubProvider provider) async {
    final success = await provider.generateImage();

    if (!context.mounted) return;

    if (!success && provider.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
    }
  }

  Widget _credits(AiHubProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset("assets/images/magicpen.png",width: 18,height: 18,),
        const SizedBox(width: 6),
        Row(
          children: [
            AppText(
              '${provider.availableCredits} AI Credits Available  ',

              style: TextStyle(
                fontSize: AppFontSize.fontSize13,
                fontWeight: FontWeight.w400,
                color: AppColors.appBlack,
              ),
            ),
            AppText(
              '${provider.creditsPerImage} credits per image',
              style: TextStyle(
                fontSize: AppFontSize.fontSize13,
                fontWeight: FontWeight.w400,
                color: AppColors.appRed,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _imageResult(AiHubProvider provider) {
    final ratio = provider.selectedRatio == '16:9'
        ? 16 / 9
        : provider.selectedRatio == '9:16'
        ? 9 / 16
        : provider.selectedRatio == '4:3'
        ? 4 / 3
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(15),
      ),
      child: provider.isGeneratingImage
          ? const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator(color: accent)),
            )
          : provider.hasGeneratedImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: ratio,
                child: Image.network(
                  provider.generatedImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return const Center(
                      child: Icon(Icons.broken_image_outlined, size: 40),
                    );
                  },
                ),
              ),
            )
          : const SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Your generated image will appear here.',
                  style: TextStyle(fontSize: 11, color: Colors.black38),
                ),
              ),
            ),
    );
  }

  Widget _resultActions(BuildContext context, AiHubProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _tag(provider.selectedCategory),
            _tag(provider.selectedImageLanguage),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: provider.isGeneratingImage
                    ? null
                    : () => _generate(context, provider),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: const BorderSide(color: accent),
                  minimumSize: const Size(0, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: const Text(
                  'REGENERATE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: provider.hasGeneratedImage
                    ? () => _downloadImage(context, provider)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 45),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: const Text(
                  'DOWNLOAD',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDF1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10)),
    );
  }

  Future<void> _downloadImage(
    BuildContext context,
    AiHubProvider provider,
  ) async {
    final url = provider.generatedImageUrl;
    if (url == null || url.isEmpty) return;

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Image download failed');
      }

      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/ai_hub_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await file.writeAsBytes(response.bodyBytes);

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image saved: ${file.path}')));
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download failed. Check your internet connection.'),
        ),
      );
    }
  }

  Widget _bottomNavigation(BuildContext context, AiHubProvider provider) {
    const labels = ['CUSTOM', 'B SERIES', 'MY PAGE', 'NEAR ME', 'YOU'];

    const icons = [
      Icons.edit_note,
      Icons.inventory_2_outlined,
      Icons.person_outline,
      Icons.location_on_outlined,
      Icons.person,
    ];

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(4, 9, 4, 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(labels.length, (index) {
          final selected = provider.selectedBottomIndex == index;

          return InkWell(
            onTap: () => provider.selectBottomItem(index),
            child: SizedBox(
              width: 58,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icons[index],
                    size: 20,
                    color: selected ? accent : Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: selected ? accent : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
