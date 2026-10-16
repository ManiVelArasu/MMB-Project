import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mmb_app/component/appbar_widget.dart';
import 'package:mmb_app/component/custom_widget.dart';
import 'package:mmb_app/core/api/api_endpoints.dart';
import 'package:mmb_app/network/provider/business_provider.dart';
import 'package:mmb_app/ui/industry/edit_photo_screen.dart';
import 'package:mmb_app/utils/theme/app.fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class FromLibraryScreen extends StatefulWidget {
  const FromLibraryScreen({super.key});

  @override
  State<FromLibraryScreen> createState() => _FromLibraryScreenState();
}

class _FromLibraryScreenState extends State<FromLibraryScreen> {
  bool _isSelectingImage = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<BusinessProvider>().fetchLibraryImages('profile-pics');
    });
  }

  Future<File> _downloadLibraryImage(String imageUrl) async {
    final client = HttpClient();

    try {
      final request = await client.getUrl(Uri.parse(imageUrl));
      final response = await request.close();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Image download failed: ${response.statusCode}');
      }

      final bytes = await response.fold<List<int>>(
        <int>[],
        (previous, chunk) => previous..addAll(chunk),
      );

      if (bytes.isEmpty) {
        throw const HttpException('Downloaded image is empty');
      }

      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/library_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await file.writeAsBytes(bytes, flush: true);
      return file;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _onImageTap(Map<String, dynamic> image) async {
    if (_isSelectingImage) return;

    final provider = context.read<BusinessProvider>();

    final rawKey = image['s3_key'] ?? image['thumbnail_s3_key'];

    if (rawKey == null || rawKey.toString().trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Image URL not found')));
      return;
    }

    setState(() => _isSelectingImage = true);

    try {
      final imageKey = rawKey.toString().replaceFirst(RegExp(r'^/+'), '');

      final imageUrl = '${ApiEndpoints.cdnImageUrl}/$imageKey';

      final file = await _downloadLibraryImage(imageUrl);

      if (!mounted) return;

      // Same provider instance used by BusinessDetailsScreen.
      provider.setLibraryImage(file);

      // Close FromLibrary first, so the existing editor's
      // upload/background-removal flow returns to the previous screen.
      final navigator = Navigator.of(context, rootNavigator: true);

      navigator.pop();

      await Future.delayed(const Duration(milliseconds: 200));

      if (!navigator.mounted) return;

      navigator.push(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<BusinessProvider>.value(
            value: provider,
            child: const EditPhotoScreen(),
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Library image selection error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to open image: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSelectingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();

    return Scaffold(
      appBar: CustomAppBar( showRightIcon: false,showTitle: false,),
      body: Stack(
        children: [
          if (provider.isLoadingLibrary)
            const Center(child: CircularProgressIndicator())
          else if (provider.libraryError != null)
            Center(child: Text(provider.libraryError!))
          else if (provider.libraryImages.isEmpty)
            const Center(child: Text('No images found'))
          else
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 15, right: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      "MMB Library",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: AppFontSize.fontSize22,
                      ),
                    ),
                    SizedBox(height: 10),
                    AppText(
                      "Select your profile picture",
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: AppFontSize.fontSize18,
                      ),
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemCount: provider.libraryImages.length,
                        itemBuilder: (context, index) {
                          final image = provider.libraryImages[index];

                          final imageKey =
                              image['thumbnail_s3_key'] ?? image['s3_key'];

                          if (imageKey == null) {
                            return const Center(
                              child: Icon(Icons.broken_image),
                            );
                          }

                          final imageUrl =
                              '${ApiEndpoints.cdnImageUrl}/$imageKey';

                          return InkWell(
                            onTap: _isSelectingImage
                                ? null
                                : () => _onImageTap(image),
                            borderRadius: BorderRadius.circular(10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.broken_image),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_isSelectingImage)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
