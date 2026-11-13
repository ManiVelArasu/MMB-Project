import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../Api Model/project_list.dart';
import '../../component/custom_widget.dart';
import '../../core/api/api_endpoints.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/my_upload_provider.dart';
import '../../network/provider/prpject_provider.dart';
import '../../utils/theme/app.colors.dart';
import '../../utils/theme/app.fonts.dart';
import '../../widgets/button_widget.dart';
import '../../widgets/color_widget.dart';
import '../industry/widgets/scaffold_widget.dart';
import '../shimmer/app_loading.dart';

class MyUploadsScreen extends StatelessWidget {
  const MyUploadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UploadProvider>(create: (_) => UploadProvider()),
        ChangeNotifierProvider<ProjectProvider>(
          create: (_) => ProjectProvider()..fetchProject(),
        ),
      ],
      child: const _MyUploadsView(),
    );
  }
}

class _MyUploadsView extends StatelessWidget {
  const _MyUploadsView();

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<CustomThemeProvider>().isDarkMode;
    final p = AppPalette(isDark);

    return CommonScaffold(
      isDarkMode: isDark,
      appBar: AppBar(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,

        leading: Padding(
          padding: const EdgeInsets.only(left: 10, top: 12, bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              color: p.backButtonBg,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.arrow_back,
                color: Color(0xFFED1C24),
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),

        titleSpacing: 6,

        title: AppText(
          "My Uploads",
          style: TextStyle(
            color: p.heading,
            fontSize: AppFontSize.fontSize22,
            fontWeight: FontWeight.w500,
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFED1C24),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                context.read<UploadProvider>().pickImage();
              },
              icon: Container(
                width: 15,
                height: 15,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  size: 11,
                  color: Color(0xFFED1C24),
                ),
              ),
              label: const AppText(
                "ADD NEW",
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),

      body: Consumer<UploadProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              Container(
                width: double.infinity,
                color: p.background,
                padding: const EdgeInsets.only(left: 10, top: 14, bottom: 10),
                child: Row(
                  children: [
                    _tab("Images", provider, p),
                    const SizedBox(width: 24),
                    _tab("Videos", provider, p),
                  ],
                ),
              ),

              Expanded(
                child: Consumer<ProjectProvider>(
                  builder: (context, projectProvider, child) {
                    return AppLoadingView(
                      isInitialLoading:
                      projectProvider.isLoadingPlans &&
                          projectProvider.plansData == null,
                      isRefreshing: provider.isUploading,
                      isDark: isDark,
                      skeleton: AppShimmerGrid(isDark: isDark),
                      child: Builder(
                        builder: (context) {
                          final downloadedProjects =
                              projectProvider.plansData?.data ?? [];
                          final uploadedImages = provider.uploads
                              .where((item) => !item.isVideo)
                              .toList();

                          final uploadedVideos = provider.uploads
                              .where((item) => item.isVideo)
                              .toList();

                          if (provider.selectedTab == "Images") {
                            if (uploadedImages.isEmpty &&
                                downloadedProjects.isEmpty) {
                              return _buildEmptyState(p);
                            }

                            return SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (uploadedImages.isNotEmpty) ...[
                                    Text(
                                      "My Uploads",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: p.heading,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _buildMasonryGrid(
                                      context,
                                      uploadedImages,
                                      provider,
                                      p,
                                    ),
                                  ],

                                  if (downloadedProjects.isNotEmpty) ...[
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                      const NeverScrollableScrollPhysics(),
                                      itemCount: downloadedProjects.length,
                                      gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 14,
                                        childAspectRatio: 0.78,
                                      ),
                                      itemBuilder: (context, index) {
                                        final project =
                                        downloadedProjects[index];

                                        return _buildDownloadedProjectCard(
                                          context,
                                          project,
                                          p,
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }

                          if (uploadedVideos.isEmpty) {
                            return _buildEmptyState(p);
                          }

                          return _buildMasonryGrid(
                            context,
                            uploadedVideos,
                            provider,
                            p,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Shared "No Downloads Yet" state for the Images and Videos tabs.
  Widget _buildEmptyState(AppPalette p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/no_downloads.png",
              width: 140,
              height: 140,
            ),
            AppText(
              'No Downloads Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: p.heading,
              ),
            ),

            const SizedBox(height: 8),

            AppText(
              'Your downloaded designs will appear here. '
                  'Create your first design and download it when it’s ready.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: p.subText),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Flexible(
                  child: ButtonWidget(
                    buttonPress: () {
                      // Explore Templates
                    },
                    title: "Explore Templates",
                    textColor: AppColors.appRed,
                    buttonColor: p.isDark
                        ? Colors.transparent
                        : AppColors.appWhite,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.appRed),
                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Flexible(
                  child: ButtonWidget(
                    buttonPress: () {
                      // Create a Design
                    },
                    title: "Create a Design",
                    textColor: AppColors.appWhite,
                    buttonColor: AppColors.appRed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadedProjectCard(
      BuildContext context,
      ProjectListModel project,
      AppPalette p,
      ) {
    final key = project.thumbnailS3Key?.trim() ?? '';

    final imageUrl = key.isEmpty
        ? ''
        : key.startsWith('http://') || key.startsWith('https://')
        ? key
        : '${ApiEndpoints.cdnImageUrl}/$key';

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(color: p.shadow, blurRadius: 7, offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: imageUrl.isEmpty
                      ? Container(
                    color: p.placeholder,
                    child: Icon(
                      Icons.image_outlined,
                      size: 40,
                      color: p.mutedIcon,
                    ),
                  )
                      : CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: p.placeholder,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: p.placeholder,
                      child: Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 35,
                          color: p.mutedIcon,
                        ),
                      ),
                    ),
                  ),
                ),


              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: AppText(
              project.name?.trim().isNotEmpty == true
                  ? project.name!
                  : 'Untitled Project',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppFontSize.fontSize14,
                fontWeight: FontWeight.w400,
                color: p.body,
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildMasonryGrid(
      BuildContext context,
      List<UploadItem> items,
      UploadProvider provider,
      AppPalette p,
      ) {
    final leftItems = <UploadItem>[];
    final rightItems = <UploadItem>[];

    for (int i = 0; i < items.length; i++) {
      if (i.isEven) {
        leftItems.add(items[i]);
      } else {
        rightItems.add(items[i]);
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: leftItems.map((item) {
                return _buildUploadItem(context, item, provider, p);
              }).toList(),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              children: rightItems.map((item) {
                return _buildUploadItem(context, item, provider, p);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadItem(
      BuildContext context,
      UploadItem item,
      UploadProvider provider,
      AppPalette p,
      ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            if (item.isVideo)
              Container(
                width: double.infinity,
                height: 180,
                color: p.isDark ? const Color(0xFF1E1E1E) : Colors.black,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 42,
                ),
              )
            else
              Image.file(
                File(item.path),
                width: double.infinity,
                fit: BoxFit.fitWidth,
              ),

            Positioned(
              top: 8,
              right: 8,
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                iconSize: 22,
                color: p.isDark ? const Color(0xFF242424) : Colors.white,
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                icon: Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    Icons.more_horiz,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onSelected: (value) {
                  if (value == "download") {
                  } else if (value == "delete") {
                    provider.deleteUpload(item.id);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: "download",
                    height: 38,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.file_download_outlined,
                          size: 17,
                          color: p.icon,
                        ),
                        const SizedBox(width: 8),
                        AppText(
                          "DOWNLOAD",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: p.icon,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: "delete",
                    height: 38,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline, size: 17, color: p.icon),
                        const SizedBox(width: 8),
                        AppText(
                          "DELETE",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: p.icon,
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
      ),
    );
  }

  Widget _tab(String title, UploadProvider provider, AppPalette p) {
    final selected = provider.selectedTab == title;

    return GestureDetector(
      onTap: () {
        provider.selectTab(title);
      },
      child: Container(
        padding: const EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? const Color(0xFFED1C24) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: AppText(
          title,
          style: TextStyle(
            fontSize: AppFontSize.fontSize14,
            fontWeight: FontWeight.w500,
            color: selected ? p.tabActive : p.tabInactive,
          ),
        ),
      ),
    );
  }

}
