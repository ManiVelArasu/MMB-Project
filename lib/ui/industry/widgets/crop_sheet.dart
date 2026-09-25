import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mmb_app/component/custom_widget.dart';
import 'package:provider/provider.dart';

import '../../../network/provider/business_provider.dart';

class UploadImageAfterCropSheet extends StatelessWidget {
  const UploadImageAfterCropSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 65,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                const AppText(
                  "Upload Image",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),

                const Spacer(),

                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 15),

            if (provider.selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  provider.selectedImage!,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 20),

            const AppText(
              "Remove Background?",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      // NO
                      Navigator.pop(context, false);
                    },
                    child: const AppText("NO"),
                  ),
                ),

                const SizedBox(width: 12),

                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      // YES
                      Navigator.pop(context, true);
                    },
                    child: const AppText("YES"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
