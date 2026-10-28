import 'package:flutter/material.dart';
import 'package:mmb_app/component/custom_widget.dart';
import 'package:provider/provider.dart';



import '../../component/appbar_widget.dart';
import '../../network/provider/ai_hub_provider.dart';

const Color _red = Color(0xFFF5222D);
const Color _border = Color(0xFFFFDCDD);
const Color _softRed = Color(0xFFFFE8E8);
const Color _muted = Color(0xFF777777);

class GenerateImagesScreen extends StatelessWidget {
  const GenerateImagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // If AiHubProvider is already registered above this route, remove this
    // ChangeNotifierProvider wrapper and return const _GenerateImagesView().
    return ChangeNotifierProvider<AiHubProvider>(
      create: (_) => AiHubProvider(),
      child: const _GenerateImagesView(),
    );
  }
}

class _GenerateImagesView extends StatelessWidget {
  const _GenerateImagesView();

  static const _suggestions = [
    'Coffee shop interior',
    'Minimal product shot',
    'Festive flatlay',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AiHubProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: CustomAppBar(
            showRightIcon: true,
            rightImage: "assets/images/content.png",
            badgeCount: null,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F0FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Image.asset("assets/images/ai_image.png")
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: AppText(
                              'Describe what you need get unique images for posts & products.',
                              style: TextStyle(fontSize: 11, height: 1.35, color: Color(0xFF424242)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 27,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _suggestions.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) => InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => provider.useImageSuggestion(_suggestions[index]),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(color: _border),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: AppText(_suggestions[index], style: const TextStyle(fontSize: 9.5)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: _border),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: provider.promptImageController,
                              minLines: 4,
                              maxLines: 5,
                              onChanged: provider.updateImagePrompt,
                              decoration: const InputDecoration(
                                hintText: 'Describe the image you want to generate...',
                                hintStyle: TextStyle(fontSize: 11, color: Color(0xFFBDBDBD)),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 11, height: 1.35),
                            ),
                            const Divider(color: _border, height: 12),
                            Row(
                              children: [
                                _dropdown(
                                  value: provider.selectedStyle,
                                  items: provider.styles,
                                  onChanged: provider.updateStyle,
                                ),
                                const SizedBox(width: 8),
                                _dropdown(
                                  value: provider.selectedRatio,
                                  items: provider.ratios,
                                  onChanged: provider.updateRatio,
                                ),
                                const Spacer(),
                                InkWell(
                                  onTap: provider.isGeneratingImage
                                      ? null
                                      : () async {
                                    final ok = await provider.generateImage();
                                    if (!context.mounted) return;
                                    if (!ok && provider.errorMessage != null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(provider.errorMessage!)),
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(7),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: _red.withOpacity(.42),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: provider.isGeneratingImage
                                        ? const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: CircularProgressIndicator(strokeWidth: 2, color: _red),
                                    )
                                        : const Icon(Icons.play_arrow_rounded, color: _red, size: 23),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: _red, size: 14),
                          const SizedBox(width: 8),
                          AppText('${provider.creditsAvailable} AI Credits Available',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 5),
                          AppText('${provider.creditsUsed} credits will be used',
                              style: const TextStyle(fontSize: 10, color: _red)),
                        ],
                      ),
                      if (provider.errorMessage != null) ...[
                        const SizedBox(height: 8),
                        AppText(provider.errorMessage!, style: const TextStyle(color: _red, fontSize: 11)),
                      ],
                      if (provider.hasGeneratedImage) ...[
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: _border),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: AspectRatio(
                                  aspectRatio: _ratioValue(provider.selectedRatio),
                                  child: Image.network(
                                    provider.generatedImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.broken_image_outlined, size: 40, color: _muted),
                                    ),
                                    loadingBuilder: (context, child, progress) =>
                                    progress == null
                                        ? child
                                        : const Center(child: CircularProgressIndicator()),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _tag(provider.selectedCategory),
                                  const SizedBox(width: 6),
                                  _tag(provider.selectedImageLanguage),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: provider.isGeneratingImage
                                          ? null
                                          : () => provider.regenerateImage(),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _red,
                                        side: const BorderSide(color: _red),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const AppText('REGENERATE', style: TextStyle(fontSize: 10)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: AppText('Connect image download to your app.')),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _red,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const AppText('DOWNLOAD', style: TextStyle(fontSize: 10)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          _circleButton(Icons.arrow_back, () => Navigator.maybePop(context)),
          const SizedBox(width: 12),
          const Expanded(
            child: AppText('Generate Images', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          _circleButton(Icons.power_settings_new, () {}),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(color: _softRed, shape: BoxShape.circle),
        child: Icon(icon, color: _red, size: 15),
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          style: const TextStyle(fontSize: 10, color: Color(0xFF444444)),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: _softRed, borderRadius: BorderRadius.circular(12)),
      child: AppText(text, style: const TextStyle(fontSize: 9)),
    );
  }

  double _ratioValue(String ratio) {
    switch (ratio) {
      case '16:9':
        return 16 / 9;
      case '9:16':
        return 9 / 16;
      case '4:3':
        return 4 / 3;
      default:
        return 1;
    }
  }
}
