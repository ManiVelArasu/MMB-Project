import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class RazorpaySubscriptionScreen extends StatefulWidget {
  final String url;
  final String subscriptionId;

  const RazorpaySubscriptionScreen({
    super.key,
    required this.url,
    required this.subscriptionId,
  });

  @override
  State<RazorpaySubscriptionScreen> createState() =>
      _RazorpaySubscriptionScreenState();
}

class _RazorpaySubscriptionScreenState
    extends State<RazorpaySubscriptionScreen> {
  late final WebViewController _controller;

  bool isLoading = true;
  bool _paymentCompleted = false;
  bool _checkingPage = false;

  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();

    // Android WebView
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
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          // --------------------------------------------------
          // PROGRESS
          // --------------------------------------------------
          onProgress: (progress) {
            debugPrint(
              "Razorpay loading: $progress%",
            );
          },

          // --------------------------------------------------
          // PAGE STARTED
          // --------------------------------------------------
          onPageStarted: (url) {
            debugPrint(
              "🌐 Razorpay started: $url",
            );

            if (mounted) {
              setState(() {
                isLoading = true;
              });
            }

            _checkUrl(url);
          },

          // --------------------------------------------------
          // PAGE FINISHED
          // --------------------------------------------------
          onPageFinished: (url) {
            debugPrint(
              "✅ Razorpay finished: $url",
            );

            if (mounted) {
              setState(() {
                isLoading = false;
              });
            }

            _checkUrl(url);

            // IMPORTANT:
            // Razorpay success happens inside same URL.
            // So check the page text also.
            _startPageStatusChecking();
          },

          // --------------------------------------------------
          // URL CHANGE
          // --------------------------------------------------
          onUrlChange: (change) {
            final url = change.url ?? '';

            debugPrint(
              "🔗 Razorpay URL changed: $url",
            );

            _checkUrl(url);
          },

          // --------------------------------------------------
          // NAVIGATION
          // --------------------------------------------------
          onNavigationRequest: (request) {
            final url = request.url;

            debugPrint(
              "➡️ Razorpay navigation: $url",
            );

            _checkUrl(url);

            return NavigationDecision.navigate;
          },

          // --------------------------------------------------
          // RESOURCE ERROR
          // --------------------------------------------------
          onWebResourceError: (error) {
            debugPrint(
              "⚠️ Razorpay WebView Resource Error: "
                  "${error.description}",
            );

            debugPrint(
              "Main frame: ${error.isForMainFrame}",
            );

            // ERR_BLOCKED_BY_ORB is usually an internal
            // Razorpay resource error.
            //
            // Don't treat this as payment failure.
          },
        ),
      );

    _loadPayment();
  }

  // ==========================================================
  // LOAD RAZORPAY
  // ==========================================================

  Future<void> _loadPayment() async {
    final url = widget.url.trim();

    debugPrint(
      "================================",
    );
    debugPrint(
      "💳 RAZORPAY CHECKOUT",
    );
    debugPrint(
      "URL: $url",
    );
    debugPrint(
      "Subscription ID: ${widget.subscriptionId}",
    );
    debugPrint(
      "================================",
    );

    if (url.isEmpty) {
      debugPrint(
        "❌ Razorpay URL empty",
      );
      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != "https" &&
            uri.scheme != "http")) {
      debugPrint(
        "❌ Invalid Razorpay URL: $url",
      );
      return;
    }

    try {
      await _controller.loadRequest(uri);
    } catch (e) {
      debugPrint(
        "❌ Razorpay WebView load error: $e",
      );
    }
  }

  // ==========================================================
  // URL CHECK
  // ==========================================================

  void _checkUrl(String url) {
    if (_paymentCompleted) {
      return;
    }

    if (url.trim().isEmpty) {
      return;
    }

    final lowerUrl = url.toLowerCase();

    debugPrint(
      "🔍 Checking URL: $lowerUrl",
    );

    // URL success cases
    final urlSuccess =
        lowerUrl.contains("payment_success") ||
            lowerUrl.contains("payment-success") ||
            lowerUrl.contains("subscription_success") ||
            lowerUrl.contains("subscription-success") ||
            lowerUrl.contains("success=true") ||
            lowerUrl.contains("status=success") ||
            lowerUrl.contains("razorpay_payment_id");

    if (urlSuccess) {
      debugPrint(
        "================================",
      );
      debugPrint(
        "✅ SUCCESS DETECTED FROM URL",
      );
      debugPrint(
        "================================",
      );

      _goToSuccess();
    }
  }

  // ==========================================================
  // CHECK RAZORPAY PAGE CONTENT
  // ==========================================================

  void _startPageStatusChecking() {
    _statusTimer?.cancel();

    // Immediately check
    _checkRazorpayPage();

    // Continue checking because Razorpay can update
    // the page without changing the URL.
    _statusTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        if (!_paymentCompleted) {
          _checkRazorpayPage();
        }
      },
    );
  }

  // ==========================================================
  // READ RAZORPAY WEB PAGE TEXT
  // ==========================================================

  Future<void> _checkRazorpayPage() async {
    if (_paymentCompleted) {
      return;
    }

    if (_checkingPage) {
      return;
    }

    _checkingPage = true;

    try {
      final result = await _controller.runJavaScriptReturningResult(
        '''
        (function() {
          return document.body
            ? document.body.innerText
            : "";
        })();
        ''',
      );

      final pageText = result
          .toString()
          .toLowerCase();

      debugPrint(
        "📄 Razorpay page text:",
      );

      debugPrint(
        pageText.length > 1000
            ? pageText.substring(0, 1000)
            : pageText,
      );

      // ------------------------------------------------------
      // SUCCESS
      // ------------------------------------------------------

      final isSuccess =
          pageText.contains(
            "your subscription is active",
          ) ||
              pageText.contains(
                "subscription is active",
              ) ||
              pageText.contains(
                "subscription active",
              ) ||
              pageText.contains(
                "payment successful",
              ) ||
              pageText.contains(
                "payment successful",
              ) ||
              pageText.contains(
                "payment completed",
              );

      if (isSuccess) {
        debugPrint(
          "================================",
        );

        debugPrint(
          "🎉 RAZORPAY PAYMENT SUCCESS",
        );

        debugPrint(
          "🎉 SUBSCRIPTION ACTIVE",
        );

        debugPrint(
          "================================",
        );

        _goToSuccess();

        return;
      }

      // ------------------------------------------------------
      // FAILURE
      // ------------------------------------------------------

      final isFailure =
          pageText.contains(
            "payment failed",
          ) ||
              pageText.contains(
                "payment unsuccessful",
              ) ||
              pageText.contains(
                "payment cancelled",
              ) ||
              pageText.contains(
                "payment canceled",
              ) ||
              pageText.contains(
                "transaction failed",
              );

      if (isFailure) {
        debugPrint(
          "================================",
        );

        debugPrint(
          "❌ RAZORPAY PAYMENT FAILED",
        );

        debugPrint(
          "================================",
        );

        _goToFailure();

        return;
      }
    } catch (e) {
      debugPrint(
        "⚠️ Razorpay page status check error: $e",
      );
    } finally {
      _checkingPage = false;
    }
  }

  // ==========================================================
  // SUCCESS
  // ==========================================================

  void _goToSuccess() {
    if (_paymentCompleted) {
      return;
    }

    _paymentCompleted = true;

    _statusTimer?.cancel();

    if (!mounted) {
      return;
    }

    debugPrint(
      "🚀 Navigating to SubscriptionActivatedScreen",
    );

    Navigator.pushNamedAndRemoveUntil(
      context,
      "/SubscriptionActivatedScreen",
          (route) => false,
    );
  }

  // ==========================================================
  // FAILURE
  // ==========================================================

  void _goToFailure() {
    if (_paymentCompleted) {
      return;
    }

    _statusTimer?.cancel();

    if (!mounted) {
      return;
    }

    debugPrint(
      "❌ Navigating to payment failure",
    );

    // If you already have a failure route:
    //
    // Navigator.pushNamedAndRemoveUntil(
    //   context,
    //   "/PaymentFailedScreen",
    //   (route) => false,
    // );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Payment failed or was cancelled.",
        ),
      ),
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  // ==========================================================
  // UI
  // ==========================================================

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
            _statusTimer?.cancel();
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
        
            if (isLoading)
              Container(
                color: Colors.white.withOpacity(0.4),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
