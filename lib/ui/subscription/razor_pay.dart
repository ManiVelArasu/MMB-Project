import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class RazorpaySubscriptionScreen extends StatefulWidget {
  final String url;

  const RazorpaySubscriptionScreen({
    super.key,
    required this.url,
  });

  @override
  State<RazorpaySubscriptionScreen> createState() =>
      _RazorpaySubscriptionScreenState();
}

class _RazorpaySubscriptionScreenState
    extends State<RazorpaySubscriptionScreen> {

  late final WebViewController _controller;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Android WebView implementation
    if (WebViewPlatform.instance == null) {
      WebViewPlatform.instance = AndroidWebViewPlatform();
    }

    _controller = WebViewController()
      ..setJavaScriptMode(
        JavaScriptMode.unrestricted,
      )
      ..setBackgroundColor(
        Colors.white,
      )
      ..setNavigationDelegate(
        NavigationDelegate(

          onPageStarted: (url) {
            debugPrint("🌐 Razorpay started: $url");

            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },

          onPageFinished: (url) {
            debugPrint("✅ Razorpay loaded: $url");

            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },

          onNavigationRequest: (request) {
            debugPrint(
              "➡️ Razorpay navigation: ${request.url}",
            );

            return NavigationDecision.navigate;
          },

          onWebResourceError: (error) {
            debugPrint(
              "❌ Razorpay WebView error: "
                  "${error.description}",
            );
          },
        ),
      );

    _loadRazorpay();
  }

  Future<void> _loadRazorpay() async {
    final url = widget.url.trim();

    debugPrint("================================");
    debugPrint("💳 RAZORPAY");
    debugPrint("URL: $url");
    debugPrint("================================");

    if (url.isEmpty) {
      debugPrint("❌ Razorpay URL empty");
      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' &&
            uri.scheme != 'https')) {
      debugPrint("❌ Invalid Razorpay URL: $url");
      return;
    }

    await _controller.loadRequest(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          "Payment",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SafeArea(
        child: Stack(
          children: [
        
            WebViewWidget(
              controller: _controller,
            ),
        
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}