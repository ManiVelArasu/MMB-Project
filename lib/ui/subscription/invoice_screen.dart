
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class InvoiceScreen extends StatefulWidget {
  final String html;

  const InvoiceScreen({
    super.key,
    required this.html,
  });

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  InAppWebViewController? webViewController;

  bool isLoading = true;
  bool isDownloading = false;

  Future<void> downloadInvoice() async {
    if (webViewController == null || isLoading || isDownloading) {
      return;
    }

    try {
      setState(() {
        isDownloading = true;
      });

      // Open the native print interface.
      // Android: Android Print Manager.
      // iOS: iOS Print Interaction Controller.
      await webViewController!.printCurrentPage();
    } catch (e) {
      debugPrint('Invoice print error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to print invoice: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(24.r),
                child: Container(
                  height: 42.h,
                  width: 42.w,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A1A1C)
                        : const Color(0xFFFFECEE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFFE53935),
                    size: 20,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            const Expanded(
              child: Text(
                'Invoice',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed:
            (isLoading || isDownloading) ? null : downloadInvoice,
            tooltip: 'Download Invoice',
            icon: isDownloading
                ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Icon(
              Icons.download_rounded,
              color: Color(0xFFE53935),
              size: 24,
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              initialData: InAppWebViewInitialData(
                data: widget.html,
                mimeType: 'text/html',
                encoding: 'utf-8',
              ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                transparentBackground: false,
                supportZoom: true,
              ),
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onLoadStart: (controller, url) {
                if (mounted) {
                  setState(() {
                    isLoading = true;
                  });
                }
              },
              onLoadStop: (controller, url) async {
                if (mounted) {
                  setState(() {
                    isLoading = false;
                  });
                }
              },
              onReceivedError: (controller, request, error) {
                debugPrint('Invoice WebView error: ${error.description}');
              },
            ),

            if (isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
