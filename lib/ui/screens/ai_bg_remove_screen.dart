import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mmb_app/component/custom_widget.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_widget.dart';
import '../../component/custom_searchbar.dart';
import '../../component/home_appbar.dart';
import '../../network/provider/ai_hub_provider.dart';
import '../../utils/theme/app.colors.dart';
import '../../utils/theme/app.fonts.dart';

class AiRemoveBgPage extends StatelessWidget {
  const AiRemoveBgPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AiHubProvider>(
      create: (_) => AiHubProvider(),
      child: const AiRemoveBgScreen(),
    );
  }
}

class AiRemoveBgScreen extends StatelessWidget {
  const AiRemoveBgScreen({super.key});

  static const Color accent = Color(0xFFF51F25);
  static const Color borderColor = Color(0xFFFFDFE6);

  @override
  Widget build(BuildContext context) {
    return Consumer<AiHubProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: HomeCustomAppBar(showApiName: false, customName: 'AI HUB'),
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
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 20),
                            _uploadHeader(),
                            const SizedBox(height: 20),
                            _description(),
                            const SizedBox(height: 18),
                            _uploadArea(context, provider),
                            const SizedBox(height: 16),
                            _removeButton(provider),
                            const SizedBox(height: 12),
                            _credits(provider),
                            if (provider.bgErrorMessage != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                provider.bgErrorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: accent,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            _resultArea(provider),
                            if (provider.removedBgImage != null) ...[
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () {
                                  provider.downloadRemovedBackground();
                                },
                                icon: const Icon(Icons.download),
                                label: const Text('DOWNLOAD IMAGE'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accent,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(46),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _uploadHeader() {
    return Column(
      children: [
        Container(
          height: 90,
          width: 90,
          child: Image.asset('assets/images/bg_remover.png'),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: AppText(
            'Background Remover',
            style: TextStyle(
              fontSize: AppFontSize.fontSize16,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
            ),
          ),
        ),
        const SizedBox(height: 12),
        AppText(
          'Remove Image Backgrounds\nInstantly',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppFontSize.fontSize22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        AppText(
          'Upload a product or portrait image and remove '
          'the background automatically.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppFontSize.fontSize13,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _description() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: borderColor),
        const SizedBox(height: 16),
        AppText(
          'What would you like to create?',
          style: TextStyle(
            fontSize: AppFontSize.fontSize18,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 10),
        AppText(
          'Let AI generate logos, product images, captions, '
          'videos, and marketing content for your business.',
          style: TextStyle(
            fontSize: AppFontSize.fontSize14,
            fontWeight: FontWeight.w400,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _uploadArea(BuildContext context, AiHubProvider provider) {
    final image = provider.selectedBgImage;

    return InkWell(
      onTap: () => _showImagePicker(context, provider),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 170,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(14),
        ),
        child: image != null
            ? Stack(
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        image,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      onPressed: provider.clearBackgroundImage,
                      icon: const Icon(Icons.close, color: accent),
                    ),
                  ),
                ],
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    color: Color(0xFFFFA1AC),
                    size: 30,
                  ),
                  SizedBox(height: 10),
                  AppText(
                    'Drag & drop your image',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 6),
                  AppText(
                    'or click to Upload Image · JPG,\n'
                    'PNG, WEBP up to 10MB',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black38,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showImagePicker(BuildContext context, AiHubProvider provider) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const AppText('Choose from gallery'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  provider.pickBackgroundImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const AppText('Take a photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  provider.pickBackgroundImage(source: ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _removeButton(AiHubProvider provider) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: provider.isRemovingBackground
            ? null
            : provider.removeImageBackground,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          disabledBackgroundColor: Colors.red.shade200,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: provider.isRemovingBackground
            ? const SizedBox(
                height: 21,
                width: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const AppText(
                'REMOVE BACKGROUND',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }

  Widget _credits(AiHubProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset("assets/images/magicpen.png", width: 18, height: 18),

          const SizedBox(width: 7),
          Flexible(
            child: AppText(
              '${provider.availableCredits} AI Credits Available',
              style: TextStyle(
                fontSize: AppFontSize.fontSize13,
                fontWeight: FontWeight.w400,
                color: AppColors.appBlack,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: AppText(
              '${provider.creditsPerImage} credits will be used',
              style: TextStyle(
                fontSize: AppFontSize.fontSize13,
                fontWeight: FontWeight.w400,
                color: AppColors.appRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultArea(AiHubProvider provider) {
    final File? result = provider.removedBgImage;

    return Container(
      height: 230,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: result != null
          ? Image.file(result, fit: BoxFit.contain)
          : const Center(
              child: AppText(
                'Background removed image will appear here',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black38, fontSize: 11),
              ),
            ),
    );
  }
}
