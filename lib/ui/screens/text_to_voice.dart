import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../network/provider/ai_hub_provider.dart';

const Color _voiceRed = Color(0xFFF5222D);
const Color _voiceBorder = Color(0xFFFFDCDD);
const Color _voiceSoftRed = Color(0xFFFFF1F2);
const Color _voiceMuted = Color(0xFF777777);

class TextToVoiceScreen extends StatelessWidget {
  const TextToVoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AiHubProvider>(
      create: (_) => AiHubProvider(),
      child: const _TextToVoiceView(),
    );
  }
}

class _TextToVoiceView extends StatelessWidget {
  const _TextToVoiceView();

  @override
  Widget build(BuildContext context) {
    return Consumer<AiHubProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
              child: _circleIcon(
                icon: Icons.arrow_back,
                onTap: () => Navigator.maybePop(context),
              ),
            ),
            title: const Text(
              'Text to Voice',
              style: TextStyle(
                color: Colors.black,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _circleIcon(
                  icon: Icons.power_settings_new,
                  onTap: () => provider.stopVoice(),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(17, 18, 17, 24),
              children: [
                Row(
                  children: [
                     SizedBox(
                      width: 76,
                      height: 64,
                      child: Image.asset("assets/images/text_to_audio.png")
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Convert your content into natural-sounding voiceovers.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: Color(0xFF444444),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _voiceBorder),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: provider.textToVoiceController,
                        onChanged: provider.setVoiceText,
                        minLines: 4,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText:
                          'A premium coffee shop interior with warm lighting, modern furniture and a cup of cappuccino on the table',
                          hintStyle: TextStyle(
                            color: Color(0xFFC6C6C6),
                            height: 1.35,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Divider(color: _voiceBorder, height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _dropdown(
                              value: provider.voiceLanguage,
                              values: provider.voiceLanguages,
                              onChanged: provider.setVoiceLanguage,
                              width: 90,
                            ),
                            const SizedBox(width: 10),
                            _dropdown(
                              value: provider.voiceGender,
                              values: provider.voiceGenders,
                              onChanged: provider.setVoiceGender,
                              width: 75,
                            ),
                            const SizedBox(width: 10),
                            _dropdown(
                              value: provider.voiceStyle,
                              values: provider.voiceStyles,
                              onChanged: provider.setVoiceStyle,
                              width: 105,
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: provider.isConvertingVoice
                                  ? null
                                  : provider.generateVoice,
                              borderRadius: BorderRadius.circular(9),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFA5A9),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: provider.isConvertingVoice
                                    ? const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _voiceRed,
                                  ),
                                )
                                    : const Icon(
                                  Icons.play_arrow_rounded,
                                  color: _voiceRed,
                                  size: 27,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Icon(Icons.auto_awesome, color: _voiceRed, size: 16),
                    SizedBox(width: 10),
                    Text(
                      '20 AI Credits Available',
                      style: TextStyle(fontSize: 12),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '6 credits will be used',
                        style: TextStyle(
                          fontSize: 12,
                          color: _voiceRed,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (provider.voiceErrorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    provider.voiceErrorMessage!,
                    style: const TextStyle(color: _voiceRed, fontSize: 12),
                  ),
                ],
                if (provider.hasVoiceResult) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: _voiceBorder),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            color: _voiceSoftRed,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: provider.playVoice,
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFBDB5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    provider.isSpeakingVoice
                                        ? Icons.stop_rounded
                                        : Icons.play_arrow_rounded,
                                    color: const Color(0xFFED654F),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: LinearProgressIndicator(
                                    minHeight: 9,
                                    value: provider.isSpeakingVoice ? null : 1,
                                    backgroundColor: const Color(0xFFFFD6D8),
                                    color: _voiceRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            children: [
                              _tag(provider.voiceLanguage),
                              _tag(provider.voiceGender),
                              _tag(provider.voiceStyle),
                            ],
                          ),
                        ),
                        const SizedBox(height: 17),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: provider.isConvertingVoice
                                    ? null
                                    : provider.regenerateVoice,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _voiceRed,
                                  side: const BorderSide(color: _voiceRed),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                                ),
                                child: const Text(
                                  'REGENERATE',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  await provider.downloadVoice();
                                  if (context.mounted &&
                                      provider.voiceErrorMessage != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          provider.voiceErrorMessage!,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _voiceRed,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                                ),
                                child: const Text(
                                  'DOWNLOAD',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
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
        );
      },
    );
  }

  static Widget _circleIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: Color(0xFFFFE4E5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _voiceRed, size: 20),
      ),
    );
  }

  static Widget _dropdown({
    required String value,
    required List<String> values,
    required ValueChanged<String?> onChanged,
    required double width,
  }) {
    return Container(
      width: width,
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: values.contains(value) ? value : values.first,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 17),
          style: const TextStyle(color: Colors.black87, fontSize: 12),
          items: values
              .map((item) => DropdownMenuItem(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis),
          ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  static Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _voiceSoftRed,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11)),
    );
  }
}
