import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show consolidateHttpClientResponseBytes;
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/ui/screens/template_edit.dart';
import 'package:mmb_app/ui/screens/widget/template_popup.dart';
import 'package:mmb_app/utils/theme/app.colors.dart';
import 'package:mmb_app/widgets/button_widget.dart';
import 'package:provider/provider.dart';
import '../../Api Model/project_list.dart';
import '../../component/appbar_widget.dart';
import '../../component/custom_widget.dart';
import '../../core/api/api_endpoints.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/my_upload_provider.dart';
import '../../network/provider/prpject_provider.dart';
import '../../utils/theme/app.fonts.dart';
class _Palette {
  const _Palette(this.isDark);

  final bool isDark;

  Color get background =>
      isDark ? const Color(0xFF121212) : const Color(0xFFF7F7F7);
  Color get surface => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get border => isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200;
  Color get placeholder =>
      isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;
  Color get heading => isDark ? Colors.white : const Color(0xFF111827);
  Color get body => isDark ? Colors.white : Colors.black87;
  Color get subText => isDark ? Colors.white60 : Colors.black54;
  Color get icon => isDark ? Colors.white : Colors.black;
  Color get mutedIcon => isDark ? Colors.white38 : Colors.grey;
  Color get tabActive => isDark ? Colors.white : Colors.black;
  Color get tabInactive =>
      isDark ? const Color(0xFF6B6B6B) : const Color(0xFFC8C8C8);
  Color get shadow => Colors.black.withValues(alpha: isDark ? 0.35 : 0.05);
}

class MyDownloadScreen extends StatelessWidget {
  const MyDownloadScreen({super.key});

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
    final p = _Palette(isDark);

    return Scaffold(
      backgroundColor: p.background,

      appBar: CustomAppBar(title: 'My Download', showRightIcon: false),

      body: Consumer<UploadProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Images / Videos tabs
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
                    if (projectProvider.isLoadingPlans) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFED1C24),
                        ),
                      );
                    }

                    final downloadedProjects =
                        projectProvider.plansData?.data ?? [];
                    final uploadedImages = provider.uploads
                        .where((item) => !item.isVideo)
                        .toList();

                    final uploadedVideos = provider.uploads
                        .where((item) => item.isVideo)
                        .toList();

                    // IMAGES TAB
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
                            // Uploaded images
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

                                  return _buildDownloadedProjectCard(
                                    context,
                                    project,
                                    p,
                                    provider,
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    // VIDEOS TAB
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
              ),
            ],
          );
        },
      ),
    );
  }

  /// Shared "No Downloads Yet" state for the Images and Videos tabs.
  Widget _buildEmptyState(_Palette p) {
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

  /// Loader over the screen; the list stays visible behind it.
  NavigatorState _showLoader(BuildContext context, bool isDark) {
    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const CircularProgressIndicator(color: Color(0xFFED1C24)),
          ),
        ),
      ),
    );
    return navigator;
  }

  /// Downloads the project image from the CDN and saves it to the gallery.
  Future<void> _downloadProject(
      BuildContext context,
      ProjectListModel project,
      String imageUrl,
      ) async {
    final messenger = ScaffoldMessenger.of(context);

    if (imageUrl.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No image available to download')),
      );
      return;
    }

    final isDark = context.read<CustomThemeProvider>().isDarkMode;
    final navigator = _showLoader(context, isDark);
    File? tempFile;

    try {
      // Gallery permission
      if (!await Gal.hasAccess()) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          throw Exception('Storage permission denied');
        }
      }

      // Download bytes
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(imageUrl));
      final response = await request.close();

      if (response.statusCode != 200) {
        client.close();
        throw Exception('Download failed (${response.statusCode})');
      }

      final bytes = await consolidateHttpClientResponseBytes(response);
      client.close();

      final dir = await getTemporaryDirectory();
      final lower = imageUrl.toLowerCase();
      final ext = lower.contains('.png')
          ? 'png'
          : lower.contains('.webp')
          ? 'webp'
          : 'jpg';
      tempFile = File(
        '${dir.path}/${project.uid ?? DateTime.now().millisecondsSinceEpoch}.$ext',
      );
      await tempFile.writeAsBytes(bytes);

      await Gal.putImage(tempFile.path, album: 'MMB');

      messenger.showSnackBar(
        const SnackBar(content: Text('Image saved to gallery')),
      );
    } catch (e) {
      debugPrint('❌ Download error: $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to download image')),
      );
    } finally {
      navigator.pop(); // close loader
      try {
        await tempFile?.delete();
      } catch (_) {}
    }
  }

  Future<void> _confirmDeleteProject(
      BuildContext context,
      ProjectListModel project,
      ) async {
    final projectProvider = context.read<ProjectProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final isDark = context.read<CustomThemeProvider>().isDarkMode;
    final projectName = project.name?.trim().isNotEmpty == true
        ? project.name!.trim()
        : 'Untitled Project';

    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delete this design?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '\u201C$projectName\u201D will be removed from your downloads. '
                    'Files you already downloaded stay on your device.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: isDark ? Colors.white70 : const Color(0xFF444444),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black,
                      side: BorderSide(
                        color: isDark ? Colors.white : Colors.black,
                        width: 1.4,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFED1C24),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'DELETE',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    if (!context.mounted) return;
    final navigator = _showLoader(context, isDark);

    final ok = await projectProvider.deleteProject(project.uid);

    navigator.pop(); // close loader
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'Project deleted' : 'Failed to delete project'),
      ),
    );
  }

  /// Edit -> opens the saved project in the editor. The editor loads the
  /// project and calls the UPDATE project API as soon as it opens.
  void _openProjectInEditor(BuildContext context, ProjectListModel project) {
    final uid = project.uid?.trim() ?? '';
    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project UID not available')),
      );
      return;
    }

    String? content;
    int? templateId;
    try {
      final dynamic raw = (project as dynamic).content;
      if (raw != null) content = raw is String ? raw : jsonEncode(raw);
    } catch (_) {}
    try {
      final dynamic t = (project as dynamic).templateId;
      templateId = t is int ? t : int.tryParse('$t');
    } catch (_) {}

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TemplateEditScreen(
          projectUid: uid,
          projectName: project.name,
          projectContent: content,
          projectTemplateId: templateId,
        ),
      ),
    );
  }

  Widget _buildDownloadedProjectCard(
      BuildContext context,
      ProjectListModel project,
      _Palette p,
      UploadProvider provider,
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
                // Project Image
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

                // Three Dot Menu - Top Right
                Positioned(
                  top: 7.h,
                  right: 7.w,
                  child: TemplateActionPopup(
                    isFavorite: false,
                    onEdit: () => _openProjectInEditor(context, project),
                    onDownload: () => _downloadProject(context, project, imageUrl),
                    onDelete: () => _confirmDeleteProject(context, project),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: AppText(
              _getEditedTime(project.updatedAt?.toIso8601String()),
              maxLines: 1,
              style: TextStyle(
                fontSize: AppFontSize.fontSize13,
                fontWeight: FontWeight.w400,

                color: AppColors.appGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getEditedTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Edited recently';
    }

    final editedDate = DateTime.tryParse(dateString);

    if (editedDate == null) return 'Edited recently';

    final difference = DateTime.now().difference(editedDate);

    if (difference.inDays >= 365) {
      return 'Edited ${difference.inDays ~/ 365} year${difference.inDays ~/ 365 == 1 ? '' : 's'} ago';
    } else if (difference.inDays >= 30) {
      return 'Edited ${difference.inDays ~/ 30} month${difference.inDays ~/ 30 == 1 ? '' : 's'} ago';
    } else if (difference.inDays >= 1) {
      return 'Edited ${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours >= 1) {
      return 'Edited ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes >= 1) {
      return 'Edited ${difference.inMinutes} min ago';
    }

    return 'Edited just now';
  }

  Widget _buildMasonryGrid(
      BuildContext context,
      List<UploadItem> items,
      UploadProvider provider,
      _Palette p,
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
      _Palette p,
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

            // 3 Dot
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
                    //_downloadItem(context, item);
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
                        Text(
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
                        Text(
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

  Widget _tab(String title, UploadProvider provider, _Palette p) {
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

  void _showUploadMenu(
      BuildContext context,
      UploadItem item,
      UploadProvider provider,
      ) {
    final p = _Palette(context.read<CustomThemeProvider>().isDarkMode);

    showModalBottomSheet(
      context: context,
      backgroundColor: p.isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                leading: Icon(Icons.download, size: 22, color: p.icon),
                title: Text(
                  "DOWNLOAD",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.icon,
                  ),
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
                title: Text(
                  "DELETE",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.icon,
                  ),
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