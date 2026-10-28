import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../network/provider/ai_hub_provider.dart';

const Color _red = Color(0xFFF5222D);
const Color _border = Color(0xFFFFDCDD);
const Color _softRed = Color(0xFFFFE8E8);
const Color _muted = Color(0xFF777777);


class ContentGeneratorScreen extends StatelessWidget {
  const ContentGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ContentGeneratorView();
  }
}

class ContentGeneratorView extends StatelessWidget {

  const ContentGeneratorView({super.key});

  @override
  Widget build(BuildContext context) {

    return ChangeNotifierProvider<AiHubProvider>(
      create: (_) => AiHubProvider(),
      child: const _ContentGeneratorBody(),
    );
  }
}

class _ContentGeneratorBody extends StatelessWidget {

  const _ContentGeneratorBody({super.key});

  @override
  Widget build(BuildContext context) {

    return Consumer<AiHubProvider>(
      builder: (context, provider, child) {
        // உங்கள் existing Content Generator UI-ஐ இங்கே வைக்கவும்.
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                _header(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
                    children: [
                      const SizedBox(height: 20),
                      _intro(),
                      const SizedBox(height: 18),
                      const Text(
                        'What do you need?',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: provider.suggestions.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final suggestion = provider.suggestions[index];
                            return InkWell(
                              onTap: () =>
                                  provider.selectSuggestion(suggestion),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                alignment: Alignment.center,
                                padding:
                                const EdgeInsets.symmetric(horizontal: 13),
                                decoration: BoxDecoration(
                                  border: Border.all(color: _border),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Text(
                                  suggestion,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF555555),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 13),
                      _promptBox(context, provider),
                      const SizedBox(height: 12),
                      const Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 10.5,
                            height: 1.5,
                            color: Color(0xFF777777),
                          ),
                          children: [
                            TextSpan(
                              text: 'AI can make mistakes, please check for accuracy. See ',
                            ),
                            TextSpan(
                              text: 'terms',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            TextSpan(text: ' or\nshare '),
                            TextSpan(
                              text: 'feedback',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: _red, size: 15),
                          const SizedBox(width: 9),
                          Text(
                            '${provider.creditsAvailable} AI Credits Available',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${provider.creditsUsed} credits will be used',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: _red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (provider.errorMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          provider.errorMessage!,
                          style: const TextStyle(
                            color: _red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (provider.isGenerating) ...[
                        const SizedBox(height: 16),
                        const Center(
                          child: CircularProgressIndicator(
                            color: _red,
                            strokeWidth: 2.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            'Generating your content...',
                            style: TextStyle(color: _muted, fontSize: 12),
                          ),
                        ),
                      ],
                      if (provider.hasGeneratedContent) ...[
                        const SizedBox(height: 20),
                        _resultCard(context, provider),
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
}



Widget _header(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
    child: Row(
      children: [
        _circleButton(
          icon: Icons.arrow_back,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'Content Generator',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
      Image.asset("assets/images/content.png",height:35,width:35,)
      ],
    ),
  );
}

Widget _circleButton({
  required IconData icon,
  required VoidCallback onTap,
}) {
  return Material(
    color: _softRed,
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, color: _red, size: 19),
      ),
    ),
  );
}

Widget _intro() {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          color: const Color(0xFFF4E7FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child:Image.asset("assets/images/caption.png"),
      ),
      const SizedBox(width: 14),
      const Expanded(
        child: Text(
          'Generate captions, promotional copy, taglines, product descriptions and social content tailored to your business.',
          style: TextStyle(
            color: Color(0xFF444444),
            fontSize: 11.5,
            height: 1.45,
          ),
        ),
      ),
    ],
  );
}

Widget _promptBox(BuildContext context, AiHubProvider provider) {
  return Container(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 9),
    decoration: BoxDecoration(
      border: Border.all(color: _border),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      children: [
        TextField(
          controller: provider.promptController,
          onChanged: provider.setPrompt,
          minLines: 4,
          maxLines: 5,
          textInputAction: TextInputAction.newline,
          style: const TextStyle(
            fontSize: 12,
            height: 1.35,
            color: Color(0xFF333333),
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText:
            'A premium coffee shop interior with warm lighting, modern furniture and a cup of cappuccino on the table',
            hintStyle: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: Color(0xFFBDBDBD),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const Divider(color: Color(0xFFFFE6E6), height: 12),
        Row(
          children: [
            _dropdown(
              context,
              label: provider.tone,
              options: const [
                'Promotional',
                'Professional',
                'Friendly',
                'Funny',
                'Luxury',
                'Casual',
              ],
              onSelected: provider.setTone,
            ),
            const SizedBox(width: 9),
            _dropdown(
              context,
              label: provider.language,
              options: const ['English', 'Tamil', 'Hindi', 'Malayalam'],
              onSelected: provider.setLanguage,
            ),
            const Spacer(),
            Material(
              color: const Color(0xFFFFA0A5),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: provider.isGenerating
                    ? null
                    : () async {
                  FocusScope.of(context).unfocus();
                  await provider.generateContent();
                },
                child: SizedBox(
                  width: 27,
                  height: 27,
                  child: provider.isGenerating
                      ? const Padding(
                    padding: EdgeInsets.all(6),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _red,
                    ),
                  )
                      : const Icon(
                    Icons.play_arrow_rounded,
                    color: _red,
                    size: 23,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _dropdown(
    BuildContext context, {
      required String label,
      required List<String> options,
      required ValueChanged<String> onSelected,
    }) {
  return PopupMenuButton<String>(
    onSelected: onSelected,
    color: Colors.white,
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    itemBuilder: (context) => options
        .map(
          (option) => PopupMenuItem<String>(
        value: option,
        child: Text(option, style: const TextStyle(fontSize: 12)),
      ),
    )
        .toList(),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF444444)),
          ),
          const SizedBox(width: 7),
          const Icon(Icons.keyboard_arrow_down,
              size: 16, color: Color(0xFF555555)),
        ],
      ),
    ),
  );
}

Widget _resultCard(BuildContext context, AiHubProvider provider) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _border),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3F4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            provider.generatedContent,
            style: const TextStyle(
              color: Color(0xFF4A4A4A),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _tag(provider.tone == 'Tone' ? 'Promotional' : provider.tone),
            _tag(provider.language == 'Language'
                ? 'English'
                : provider.language),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _outlineButton(
                label: 'REGENERATE',
                onTap: provider.isGenerating
                    ? null
                    : () => provider.regenerateContent(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _outlineButton(
                label: 'EDIT',
                onTap: () => _editContent(context, provider),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _solidButton(
                label: 'COPY',
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: provider.generatedContent),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Content copied'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _tag(String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE9EA),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 10, color: Color(0xFF333333)),
    ),
  );
}

Widget _outlineButton({
  required String label,
  required VoidCallback? onTap,
}) {
  return SizedBox(
    height: 34,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: _red,
        side: const BorderSide(color: _red),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

Widget _solidButton({
  required String label,
  required VoidCallback onTap,
}) {
  return SizedBox(
    height: 34,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: _red,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

Future<void> _editContent(
    BuildContext context,
    AiHubProvider provider,
    ) async {
  final controller = TextEditingController(text: provider.generatedContent);

  final updated = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Edit content'),
      content: TextField(
        controller: controller,
        minLines: 4,
        maxLines: 8,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Edit your content',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, controller.text),
          child: const Text('SAVE'),
        ),
      ],
    ),
  );

  if (updated != null) {
    provider.updateGeneratedContent(updated);
  }
  controller.dispose();
}

