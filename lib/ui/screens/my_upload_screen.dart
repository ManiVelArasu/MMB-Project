import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../network/provider/my_upload_provider.dart';

class MyUploadsScreen extends StatelessWidget {
  const MyUploadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UploadProvider(),
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
          padding: const EdgeInsets.only(
            left: 10,
            top: 10,
            bottom: 10,
          ),
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

        title: const Text(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize:
                MaterialTapTargetSize.shrinkWrap,
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
              label: const Text(
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
          final items = provider.uploads.where((item) {
            return provider.selectedTab == "Images"
                ? !item.isVideo
                : item.isVideo;
          }).toList();

          return Column(
            children: [
              // Tabs
              Container(
                width: double.infinity,
                color: const Color(0xFFF7F7F7),
                padding: const EdgeInsets.only(
                  left: 10,
                  top: 14,
                  bottom: 10,
                ),
                child: Row(
                  children: [
                    _tab("Images", provider),
                    const SizedBox(width: 24),
                    _tab("Videos", provider),
                  ],
                ),
              ),

              // Images
              Expanded(
                child: items.isEmpty
                    ? const Center(
                  child: Text(
                    "No uploads yet",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                )
                    : _buildMasonryGrid(
                  context,
                  items,
                  provider,
                ),
              ),
            ],
          );
        },
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
      padding: const EdgeInsets.fromLTRB(
        10,
        4,
        10,
        20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: leftItems.map((item) {
                return _buildUploadItem(
                  context,
                  item,
                  provider,
                );
              }).toList(),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              children: rightItems.map((item) {
                return _buildUploadItem(
                  context,
                  item,
                  provider,
                );
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
                        Text(
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
                        Text(
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

  Widget _tab(
      String title,
      UploadProvider provider,
      ) {
    final selected =
        provider.selectedTab == title;

    return GestureDetector(
      onTap: () {
        provider.selectTab(title);
      },
      child: Container(
        padding: const EdgeInsets.only(
          bottom: 5,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected
                  ? const Color(0xFFED1C24)
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected
                ? Colors.black
                : const Color(0xFFC8C8C8),
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(18),
        ),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),

              ListTile(
                leading: const Icon(
                  Icons.download,
                  size: 22,
                ),
                title: const Text(
                  "DOWNLOAD",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
                title: const Text(
                  "DELETE",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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