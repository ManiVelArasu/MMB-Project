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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Uploads",
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 9),
              ),
              onPressed: () {
                context.read<UploadProvider>().pickImage();
              },
              icon: const Icon(Icons.add, size: 14),
              label: const Text("ADD NEW", style: TextStyle(fontSize: 9)),
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

          return Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _tab("Images", provider),
                    const SizedBox(width: 18),
                    _tab("Videos", provider),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: items.isEmpty
                      ? const Center(
                    child: Text(
                      "No uploads yet",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                      : GridView.builder(
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 5,
                      childAspectRatio: .85,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return GestureDetector(
                        onLongPress: () => _showMenu(context, item, provider),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: item.isVideo
                              ? Container(
                            color: Colors.black,
                            child: const Icon(
                              Icons.play_circle_outline,
                              color: Colors.white,
                              size: 28,
                            ),
                          )
                              : Image.file(
                            File(item.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tab(String title, UploadProvider provider) {
    final selected = provider.selectedTab == title;
    return GestureDetector(
      onTap: () => provider.selectTab(title),
      child: Container(
        padding: const EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? Colors.red : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.red : Colors.grey,
          ),
        ),
      ),
    );
  }

  void _showMenu(
      BuildContext context,
      UploadItem item,
      UploadProvider provider,
      ) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text("DOWNLOAD"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text("DELETE"),
              onTap: () {
                provider.deleteUpload(item.id);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
