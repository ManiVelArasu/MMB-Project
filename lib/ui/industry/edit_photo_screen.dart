
import 'dart:io';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_mmb/ui/industry/widgets/rotation_slider.dart';
import 'package:project_mmb/ui/industry/widgets/scale_slider.dart';
import 'package:project_mmb/utils/constants.dart';
import 'package:project_mmb/widgets/custom_sized_box.dart';
import 'package:provider/provider.dart';
import 'package:project_mmb/network/provider/business_provider.dart';
import 'package:project_mmb/network/provider/custom_theme_provider.dart';
class EditPhotoScreen extends StatefulWidget {
  const EditPhotoScreen({super.key});

  @override
  State<EditPhotoScreen> createState() => _EditPhotoScreenState();
}

class _EditPhotoScreenState extends State<EditPhotoScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final customColor = Provider.of<CustomThemeProvider>(context).colors;
    final theme = Theme.of(context).textTheme;

    return Consumer<BusinessProvider>(
      builder: (context, businessProvider, child) {
        // Safety check
        if (businessProvider.selectedImage == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pop(context);
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: customColor.whiteColor,
          appBar: AppBar(
            backgroundColor: customColor.whiteColor,
            surfaceTintColor: customColor.whiteColor,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: SvgPicture.asset("assets/icons/back_icon.svg"),
            ),
            title: Text(
              "Edit Photo",
              style: theme.bodyMedium!.copyWith(
                color: customColor.blackColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // LIVE PREVIEW IMAGE
                Expanded(
                  child: Container(
                    color: Colors.grey[100],
                    child: Center(
                      child: _buildImagePreview(businessProvider),
                    ),
                  ),
                ),

                // TOOL-SPECIFIC CONTROLS
                _buildToolControls(businessProvider, customColor, theme),

                // BOTTOM TOOLBAR
                _buildBottomToolbar(
                  context,
                  businessProvider,
                  customColor,
                  theme,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePreview(BusinessProvider provider) {
    try {
      Widget imageWidget = ExtendedImage.file(
        provider.selectedImage!,
        fit: BoxFit.contain,
        mode: provider.selectedTool == "Crop"
            ? ExtendedImageMode.editor
            : ExtendedImageMode.gesture,
        extendedImageEditorKey: provider.editorKey,
        initEditorConfigHandler: (state) {
          return EditorConfig(
            maxScale: 8.0,
            cropRectPadding: const EdgeInsets.all(20.0),
            hitTestSize: 20.0,
            cropAspectRatio: provider.getAspectRatio(provider.selectedAspect),
            initCropRectType: provider.selectedAspect == "Original"
                ? InitCropRectType.imageRect
                : InitCropRectType.layoutRect,
          );
        },
        loadStateChanged: (state) {
          if (state.extendedImageLoadState == LoadState.failed) {
            return const Center(
              child: Text("Failed to load image"),
            );
          }
          return null;
        },
      );

      if (provider.selectedTool == "Scale") {
        imageWidget = Transform.scale(
          scale: provider.scaleValue,
          child: imageWidget,
        );
      }

      if (provider.selectedTool == "Rotate") {
        imageWidget = Transform.rotate(
          angle: provider.rotationAngle * (3.14159265359 / 180.0),
          child: imageWidget,
        );
      }

      return imageWidget;
    } catch (e) {
      debugPrint("Error building image preview: $e");
      return Center(
        child: Text("Error loading image: $e"),
      );
    }
  }

  Widget _buildToolControls(
      BusinessProvider provider,
      dynamic customColor,
      TextTheme theme,
      ) {
    switch (provider.selectedTool) {
      case "Crop":
        return _buildCropControls(provider, customColor, theme);
      case "Rotate":
        return _buildRotateControls(provider, customColor, theme);
      case "Scale":
        return _buildScaleControls(provider, customColor, theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCropControls(
      BusinessProvider provider,
      dynamic customColor,
      TextTheme theme,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: customColor.baseColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _aspectButton("Original", provider, customColor, theme),
            const SizedBox(width: 8),
            _aspectButton("Square", provider, customColor, theme),
            const SizedBox(width: 8),
            _aspectButton("3×2", provider, customColor, theme),
            const SizedBox(width: 8),
            _aspectButton("4×3", provider, customColor, theme),
            const SizedBox(width: 8),
            _aspectButton("16×9", provider, customColor, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildRotateControls(
      BusinessProvider provider,
      dynamic customColor,
      TextTheme theme,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: customColor.baseColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => provider.resetRotation(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.refresh,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                RotationSlider(
                  value: provider.rotationAngle,
                  onChanged: (v) => provider.setLiveRotationAngle(v),
                ),
                const SizedBox(height: 8),
                Text(
                  "${provider.rotationAngle.toStringAsFixed(1)}°",
                  style: theme.bodyMedium!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              double newAngle = provider.rotationAngle + 90;
              if (newAngle > 180) newAngle -= 360;
              provider.setLiveRotationAngle(newAngle);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.rotate_90_degrees_cw,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScaleControls(
      BusinessProvider provider,
      dynamic customColor,
      TextTheme theme,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: customColor.baseColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ScaleSlider(
                  value: provider.scaleValue,
                  onChanged: (value) => provider.setLiveScaleValue(value),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => provider.setLiveScaleValue(1.0),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  child: const Icon(
                    Icons.fit_screen,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "${(provider.scaleValue * 100).toStringAsFixed(0)}%",
            style: theme.bodySmall!.copyWith(
              color: const Color(0xff4ED8F2),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar(
      BuildContext context,
      BusinessProvider provider,
      dynamic customColor,
      TextTheme theme,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: customColor.whiteColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: _isProcessing ? null : () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: theme.bodyMedium!.copyWith(
                color: _isProcessing ? Colors.grey : customColor.redColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: customColor.blackColor,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Row(
              children: [
                _toolItem(
                  icon: "assets/icons/crop.svg",
                  label: "Crop",
                  isActive: provider.selectedTool == "Crop",
                  onTap: _isProcessing ? () {} : () => provider.setSelectedTool("Crop"),
                  theme: theme,
                ),
                const SizedBox(width: 24),
                _toolItem(
                  icon: "assets/icons/rotate.svg",
                  label: "Rotate",
                  isActive: provider.selectedTool == "Rotate",
                  onTap: _isProcessing ? () {} : () => provider.setSelectedTool("Rotate"),
                  theme: theme,
                ),
                const SizedBox(width: 24),
                _toolItem(
                  icon: "assets/icons/scale.svg",
                  label: "Scale",
                  isActive: provider.selectedTool == "Scale",
                  onTap: _isProcessing ? () {} : () => provider.setSelectedTool("Scale"),
                  theme: theme,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _isProcessing ? null : () => _handleApply(context, provider),
            child: _isProcessing
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Text(
              provider.hasChanges ? "Apply" : "Save",
              style: theme.bodyMedium!.copyWith(
                color: customColor.textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleApply(BuildContext context, BusinessProvider provider) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      if (provider.hasChanges) {
        switch (provider.selectedTool) {
          case "Crop":
            await provider.applyCrop();
            break;
          case "Rotate":
            await provider.applyRotate();
            break;
          case "Scale":
            await provider.applyScale();
            break;
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${provider.selectedTool} applied!"),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        if (context.mounted) {
          Navigator.pop(context);
          provider.bgRemoveSheet(context);
        }
      }
    } catch (e) {
      debugPrint("Error applying transformation: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Widget _toolItem({
    required String icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required TextTheme theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            icon,
            colorFilter: ColorFilter.mode(
              isActive ? Colors.blue : Colors.white,
              BlendMode.srcIn,
            ),
            width: 24,
            height: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.bodySmall!.copyWith(
              color: isActive ? Colors.blue : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _aspectButton(
      String text,
      BusinessProvider provider,
      dynamic customColor,
      TextTheme theme,
      ) {
    bool active = provider.selectedAspect == text;
    return GestureDetector(
      onTap: () => provider.setAspect(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: active ? const Color(0xff4ED8F2) : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(8),
          color: active ? const Color(0xff4ED8F2).withValues(alpha: 0.1) : null,
        ),
        child: Text(
          text,
          style: theme.bodySmall!.copyWith(
            color: active ? const Color(0xff4ED8F2) : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}