import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Api Model/project_list.dart';
import '../../component/custom_widget.dart';
import '../../core/api/api_endpoints.dart';
import '../../network/provider/my_upload_provider.dart';
import '../../network/provider/prpject_provider.dart';
import '../../utils/theme/app.colors.dart';
import '../../widgets/button_widget.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 60,

        leading: Padding(
          padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFFE5E7),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.arrow_back,
                color: Color(0xFFED1C24),
                size: 20,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),

        titleSpacing: 8,

        title: const AppText(
          "My Uploads",
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w700,
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
              // Images / Videos tabs
              Container(
                width: double.infinity,
                color: const Color(0xFFF7F7F7),
                padding: const EdgeInsets.only(left: 10, top: 14, bottom: 10),
                child: Row(
                  children: [
                    _tab("Images", provider),
                    const SizedBox(width: 24),
                    _tab("Videos", provider),
                  ],
                ),
              ),

              Expanded(
                child: Consumer<ProjectProvider>(
                  builder: (context, projectProvider, child) {
                    if (projectProvider.isLoadingPlans) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFED1C24),
                        ),
                      );
                    }
                    final uploadedImages = provider.uploads
                        .where((item) => !item.isVideo)
                        .toList();

                    final uploadedVideos = provider.uploads
                        .where((item) => item.isVideo)
                        .toList();

                    final downloadedProjects =
                        projectProvider.plansData?.data ?? [];

                    // IMAGES TAB
                    if (provider.selectedTab == "Images") {
                      if (uploadedImages.isEmpty &&
                          downloadedProjects.isEmpty) {
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
                                const AppText(
                                  'No Downloads Yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                const AppText(
                                  'Your downloaded designs will appear here. '
                                  'Create your first design and download it when it’s ready.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
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
                                        buttonColor: AppColors.appWhite,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: AppColors.appRed,
                                          ),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(15),
                                          ),
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

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Uploaded images
                            if (uploadedImages.isNotEmpty) ...[
                              const AppText(
                                "My Uploads",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildMasonryGrid(
                                context,
                                uploadedImages,
                                provider,
                              ),
                            ],

                            // Downloaded projects
                            if (downloadedProjects.isNotEmpty) ...[
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: downloadedProjects.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 14,
                                      childAspectRatio: 0.78,
                                    ),
                                itemBuilder: (context, index) {
                                  final project = downloadedProjects[index];

                                  return _buildDownloadedProjectCard(project);
                                },
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    // VIDEOS TAB
                    if (uploadedVideos.isEmpty) {
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
                              const AppText(
                                'No Downloads Yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 8),

                              const AppText(
                                'Your downloaded designs will appear here. '
                                'Create your first design and download it when it’s ready.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
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
                                      buttonColor: AppColors.appWhite,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: AppColors.appRed,
                                        ),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(15),
                                        ),
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

                    return _buildMasonryGrid(context, uploadedVideos, provider);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDownloadedProjectCard(ProjectListModel project) {
    final key = project.thumbnailS3Key?.trim() ?? '';

    final imageUrl = key.isEmpty
        ? ''
        : key.startsWith('http://') || key.startsWith('https://')
        ? key
        : '${ApiEndpoints.cdnImageUrl}/$key';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: imageUrl.isEmpty
                  ? Container(
                      color: Colors.grey.shade100,
                      child: const Icon(
                        Icons.image_outlined,
                        size: 40,
                        color: Colors.grey,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 35,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: AppText(
              project.name?.trim().isNotEmpty == true
                  ? project.name!
                  : 'Untitled Project',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
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
                return _buildUploadItem(context, item, provider);
              }).toList(),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              children: rightItems.map((item) {
                return _buildUploadItem(context, item, provider);
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
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Image
            if (item.isVideo)
              Container(
                width: double.infinity,
                height: 180,
                color: Colors.black,
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

            // 3 Dot
            Positioned(
              top: 8,
              right: 8,
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                iconSize: 22,
                color: Colors.white,
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
                    //_downloadItem(context, item);
                  } else if (value == "delete") {
                    provider.deleteUpload(item.id);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: "download",
                    height: 38,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.file_download_outlined,
                          size: 17,
                          color: Colors.black,
                        ),
                        SizedBox(width: 8),
                        AppText(
                          "DOWNLOAD",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: "delete",
                    height: 38,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 17,
                          color: Colors.black,
                        ),
                        SizedBox(width: 8),
                        AppText(
                          "DELETE",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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

  Widget _tab(String title, UploadProvider provider) {
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
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.black : const Color(0xFFC8C8C8),
          ),
        ),
      ),
    );
  }

  void _showUploadMenu(
    BuildContext context,
    UploadItem item,
    UploadProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),

              ListTile(
                leading: const Icon(Icons.download, size: 22),
                title: const AppText(
                  "DOWNLOAD",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 22,
                ),
                title: const AppText(
                  "DELETE",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  provider.deleteUpload(item.id);
                  Navigator.pop(context);
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
