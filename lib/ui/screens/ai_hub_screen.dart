import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/component/appbar_widget.dart';
import 'package:mmb_app/component/bottom_navigation.dart';
import 'package:mmb_app/component/custom_searchbar.dart';
import 'package:mmb_app/component/custom_widget.dart';
import 'package:mmb_app/component/home_appbar.dart';
import 'package:mmb_app/utils/theme/app.colors.dart';
import 'package:mmb_app/utils/theme/app.fonts.dart';
import 'package:provider/provider.dart';

import '../../network/provider/ai_hub_provider.dart';

class AiHubScreen extends StatelessWidget {
  const AiHubScreen({super.key});

  static const Color _red = Color(0xFFF51F2B);
  static const Color _navy = Color(0xFF080808);
  static const Color _border = Color(0xFFFFE2E4);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AiHubProvider(),
      child: const _AiHubView(),
    );
  }
}

class _AiHubView extends StatelessWidget {
  const _AiHubView();

  static const Color _red = Color(0xFFF51F2B);
  static const Color _navy = Color(0xFF080808);
  static const Color _border = Color(0xFFFFE2E4);
  @override
  Widget build(BuildContext context) {
    return Consumer<AiHubProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: HomeCustomAppBar(
            showApiName: false,
            customName: 'AI HUB',
          ),
          body: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 300.h,
                child: Image.asset(
                  "assets/images/plan_gradient.png",
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomSearchBar(
                        hintText: "Search templates, Brand Series...",
                      ),
                      const SizedBox(height: 8),
                      _generatorCard(context, provider),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _generatorCard(BuildContext context, AiHubProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              alignment: Alignment.center,
              child: Image.asset("assets/images/translate.png"),
            ),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
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
          const SizedBox(height: 8),
          AppText(
            'Create Social Media Content\nin Seconds',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppFontSize.fontSize22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          AppText(
            'Generate captions, promotional copy, taglines,\nproduct descriptions and social content tailored to\nyour business.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppFontSize.fontSize13,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFFFECEC), height: 1),
          const SizedBox(height: 8),
          AppText(
            'What do you need?',
            style: TextStyle(
              fontSize: AppFontSize.fontSize18,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 5),
          ...provider.suggestions.map(
            (suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: InkWell(
                onTap: () => provider.selectSuggestion(suggestion),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: AppText(
                    suggestion,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppFontSize.fontSize13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF555555),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                TextField(
                  controller: provider.promptController,
                  minLines: 4,
                  maxLines: 6,
                  onChanged: (_) {},
                  decoration: InputDecoration(
                    hintText: 'Describe your idea, product, or campaign...',
                    hintStyle: TextStyle(
                      fontSize: AppFontSize.fontSize13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFBDBDBD),
                    ),
                    contentPadding: EdgeInsets.all(10),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(
                    fontSize: AppFontSize.fontSize13,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFFFEEEE)),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  child: Row(
                    children: [
                      _dropdown(
                        value: provider.tone,
                        items: const [
                          'Tone',
                          'Professional',
                          'Friendly',
                          'Funny',
                          'Promotional',
                        ],
                        onChanged: provider.setTone,
                      ),
                      const SizedBox(width: 6),
                      _dropdown(
                        value: provider.language,
                        items: const ['Language', 'English', 'Tamil', 'Hindi'],
                        onChanged: provider.setLanguage,
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: provider.isGenerating
                            ? null
                            : () async {
                                FocusScope.of(context).unfocus();
                                await provider.generateContent();
                              },
                        child: Container(
                          width: 27,
                          height: 25,
                          decoration: BoxDecoration(
                            color: _red.withOpacity(0.42),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: provider.isGenerating
                              ? const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _red,
                                  ),
                                )
                              : const Icon(
                                  Icons.play_arrow,
                                  color: _red,
                                  size: 20,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/images/magicpen.png",width: 18,height: 18,),
              const SizedBox(width: 6),
              AppText(
                '${provider.creditsAvailable} AI Credits Available',
                style: TextStyle(
                  fontSize: AppFontSize.fontSize13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.appBlack,
                ),
              ),
              const SizedBox(width: 5),
              AppText(
                '${provider.creditsUsed} credits will be used',
                style: TextStyle(
                  fontSize: AppFontSize.fontSize13,
                  fontWeight: FontWeight.w400,
                  color: _red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!provider.hasGeneratedContent)
            Container(
              height: 105,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Fill in the details and generate, your content will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, color: Color(0xFFBDBDBD)),
              ),
            )
          else
            _resultCard(context, provider),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      height: 27,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          iconSize: 13,
          style: TextStyle(
            fontSize: AppFontSize.fontSize13,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ),
    );
  }

  Widget _resultCard(BuildContext context, AiHubProvider provider) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              provider.generatedContent,
              style: const TextStyle(
                fontSize: 11,
                height: 1.4,
                color: Color(0xFF444444),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            children: [
              _tag(provider.tone == 'Tone' ? 'Promotional' : provider.tone),
              _tag(
                provider.language == 'Language' ? 'English' : provider.language,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: provider.regenerateContent,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _red,
                    side: const BorderSide(color: _red),
                    minimumSize: const Size(0, 37),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'REGENERATE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: provider.generatedContent),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Content copied')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 37),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'COPY',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(fontSize: 8)),
    );
  }

  Widget _bottomNavigation(AiHubProvider provider) {
    const labels = ['CUSTOM', 'B-SERIES', 'MY\nPAGE', 'NEAR ME', 'YOU'];
    const icons = [
      Icons.edit_note,
      Icons.dashboard,
      Icons.rocket_launch,
      Icons.storefront,
      Icons.person,
    ];

    return Container(
      height: 58,
      color: _navy,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(labels.length, (index) {
          final selected = provider.selectedBottomIndex == index;
          if (index == 2) {
            return GestureDetector(
              onTap: () => provider.selectBottomItem(index),
              child: Container(
                width: 57,
                height: 57,
                decoration: BoxDecoration(
                  color: _red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.rocket_launch, color: Colors.white, size: 17),
                    SizedBox(height: 1),
                    Text(
                      'MY\nPAGE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        height: 0.9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Expanded(
            child: InkWell(
              onTap: () => provider.selectBottomItem(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icons[index],
                    size: 17,
                    color: selected ? _red : Colors.white,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? _red : Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
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
