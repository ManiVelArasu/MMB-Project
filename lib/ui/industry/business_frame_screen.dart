import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mmb_app/component/custom_widget.dart';
import 'package:mmb_app/ui/industry/widgets/Business_frame_bottom_sheet.dart';
import 'package:mmb_app/utils/theme/app.fonts.dart';
import '../../component/appbar_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/api/api_endpoints.dart';
import '../../network/provider/business_provider.dart';
import '../../network/provider/businessprofile_provider.dart';
import '../../network/provider/custom_theme_provider.dart';

class BusinessFramesScreen extends StatelessWidget {
  const BusinessFramesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Loads static frames on create; animated frames load on first tab tap.
    return ChangeNotifierProvider(
      create: (_) => BusinessProfileProvider(),
      child: const BusinessFramesView(),
    );
  }
}

class BusinessFramesView extends StatefulWidget {
  const BusinessFramesView({super.key});

  @override
  State<BusinessFramesView> createState() => _BusinessFramesViewState();
}

class _BusinessFramesViewState extends State<BusinessFramesView> {
  int selectedTab = 0;
  int selectedCategory = -1; // -1 = all
  int selectedFrame = 0;

  static const String _razorpayKey = 'rzp_test_TWag5Xvk4KWWgY';

  late final Razorpay _razorpay;
  Map<String, dynamic>? _pendingOrder;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onGetFrame(dynamic frame) async {
    final frameUid = _pick(frame, [(f) => f.uid, (f) => f.id]);
    if (frameUid.isEmpty) {
      _toast('Frame id not available');
      return;
    }

    final frameProvider = context.read<BusinessProfileProvider>();
    final business = context.read<BusinessProvider>();

    final order = await frameProvider.purchaseFrame(frameUid);
    if (!mounted) return;

    if (order == null) {
      _toast(frameProvider.purchaseError ?? 'Unable to start payment');
      return;
    }

    _pendingOrder = order;

    final amount = num.tryParse(order['amount'].toString()) ?? 0;

    try {
      _razorpay.open({
        'key': _razorpayKey,
        'order_id': order['order_id'],
        'name': 'Make My Brand',
        'description': 'Frame purchase',
        'prefill': {'contact': business.mobileNumber, 'email': business.email},
        'theme': {'color': '#E53935'},
      });
    } catch (e) {
      _toast('Unable to open payment: $e');
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse r) async {
    debugPrint(
      'Razorpay success: payment=${r.paymentId} '
      'order=${r.orderId} signature=${r.signature}',
    );

    final frameProvider = context.read<BusinessProfileProvider>();
    _pendingOrder = null;

    final ok = await frameProvider.verifyFramePayment(
      razorpayOrderId: r.orderId ?? '',
      razorpayPaymentId: r.paymentId ?? '',
      razorpaySignature: r.signature ?? '',
    );

    _toast(
      ok
          ? 'Payment successful'
          : frameProvider.purchaseError ?? 'Payment verification failed',
    );
  }

  void _onPaymentError(PaymentFailureResponse r) {
    debugPrint(
      'Razorpay error: code=${r.code} message=${r.message} '
      'error=${r.error}',
    );
    _toast(r.message ?? 'Payment failed');
    _pendingOrder = null;
  }

  void _onExternalWallet(ExternalWalletResponse r) {
    debugPrint('Razorpay external wallet: ${r.walletName}');
  }

  @override
  Widget build(BuildContext context) {
    final customColor = Provider.of<CustomThemeProvider>(context).colors;
    final theme = Theme.of(context).textTheme;

    return Consumer<BusinessProvider>(
      builder: (context, businessProvider, child) {
        final savedImageFile =
            businessProvider.selectedImage ?? businessProvider.originalImage;

        final frameProvider = context.watch<BusinessProfileProvider>();
        final frames = frameProvider.displayFrames;
        final activeFrame = frames.isEmpty
            ? null
            : frames[selectedFrame.clamp(0, frames.length - 1)];

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: const CustomAppBar(
            title: "Business Frames",
            showTitle: true,
            showRightIcon: false,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 12.h),

                          // 1. MAIN PREVIEW BANNER
                          Container(
                            height: 340.h,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: Stack(
                                children: [
                                  if (savedImageFile != null)
                                    Positioned.fill(
                                      child: Image.file(
                                        savedImageFile,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    )
                                  else
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.grey.shade100,
                                        child: Center(
                                          child: Icon(
                                            Icons.image_outlined,
                                            size: 48.sp,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ),
                                    ),

                                  // API frame (static / animated) over the photo
                                  if (activeFrame != null)
                                    Positioned.fill(
                                      child: _frameImage(
                                        activeFrame,
                                        fit: BoxFit.fill,
                                      ),
                                    ),

                                  // Default overlay only while no API frame
                                  if (activeFrame == null) ...[
                                    // 2. OVERLAY LOGO (Top Left)
                                    Positioned(
                                      top: 20.h,
                                      left: 16.w,
                                      child: Image.asset(
                                        "assets/images/abslogo.png",
                                        height: 40.h,
                                      ),
                                    ),

                                    // 3. BOTTOM CURVED INFO BANNER OVER IMAGE
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      left: 80.w,
                                      child: Container(
                                        height: 36.h,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12.w,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0066FF),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(20.r),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            // Phone Number
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.phone,
                                                  color: Colors.white,
                                                  size: 12.sp,
                                                ),
                                                SizedBox(width: 4.w),
                                                AppText(
                                                  businessProvider
                                                          .mobileNumber
                                                          .isEmpty
                                                      ? "+91 9876543210"
                                                      : businessProvider
                                                            .mobileNumber,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10.sp,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // Email Address
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.email,
                                                  color: Colors.white,
                                                  size: 12.sp,
                                                ),
                                                SizedBox(width: 4.w),
                                                AppText(
                                                  businessProvider.email.isEmpty
                                                      ? "sarahsteve@gmail.com"
                                                      : businessProvider.email,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10.sp,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 16.h),

                          Row(
                            children: [
                              Text(
                                activeFrame == null
                                    ? "Free"
                                    : _frameLabel(activeFrame),
                                style: theme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: AppFontSize.fontSize16,
                                  color: customColor.blackColor,
                                ),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => Padding(
                                      padding: EdgeInsets.only(
                                        bottom: MediaQuery.of(
                                          context,
                                        ).viewInsets.bottom,
                                      ),
                                      child: const UpdateBusinessSheet(),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                    vertical: 8.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFECEE),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: AppText(
                                    "EDIT",
                                    style: TextStyle(
                                      color: const Color(0xFFE53935),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              // UPDATE BUTTON
                              InkWell(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    "/CustomBottomNavScreen",
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                    vertical: 8.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: AppText(
                                    "UPDATE",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Already-owned frames (My Brand Frames) need no purchase.
                          if (activeFrame != null && selectedTab != 2) ...[
                            SizedBox(height: 14.h),
                            SizedBox(
                              width: double.infinity,
                              height: 46.h,
                              child: ElevatedButton(
                                onPressed: frameProvider.isPurchasing
                                    ? null
                                    : () => _onGetFrame(activeFrame),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE53935),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                child: frameProvider.isPurchasing
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : AppText(
                                        'GET FRAME',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                          SizedBox(height: 24.h),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildTabItem("Static Frames", index: 0),
                                SizedBox(width: 20.w),
                                _buildTabItem("Animated Frames", index: 1),
                                SizedBox(width: 20.w),
                                _buildTabItem("My Brand Frames", index: 2),
                              ],
                            ),
                          ),

                          SizedBox(height: 16.h),
                          // Categories from API (Branding / Promotional ...)
                          if (selectedTab != 2)
                            _buildCategoryWrap(frameProvider),

                          SizedBox(height: 20.h),

                          // 5. FRAMES FROM API (static / animated)
                          SizedBox(
                            height: 140.h,
                            child: _buildFramesList(
                              frameProvider,
                              frames,
                              savedImageFile,
                            ),
                          ),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // FRAMES (API)
  // ------------------------------------------------------------

  // Reads the first available field from the frame model, so a different
  // field name in FramesList does not break the build.
  String _pick(dynamic frame, List<dynamic Function(dynamic)> getters) {
    for (final get in getters) {
      try {
        final v = get(frame);
        if (v != null && v.toString().trim().isNotEmpty) {
          return v.toString().trim();
        }
      } catch (_) {}
    }
    return '';
  }

  String _frameUrl(dynamic frame) {
    final raw = _pick(frame, [
      (f) => f.previewS3Key,
      (f) => f.thumbnailS3Key,
      (f) => f.imageS3Key,
      (f) => f.s3Key,
      (f) => f.imageUrl,
      (f) => f.previewUrl,
      (f) => f.url,
    ]);
    if (raw.isEmpty) return '';
    return raw.startsWith('http') ? raw : '${ApiEndpoints.cdnImageUrl}/$raw';
  }

  String _frameLabel(dynamic frame) {
    final name = _pick(frame, [(f) => f.name, (f) => f.title]);
    return name.isEmpty ? 'Free' : name;
  }

  Widget _frameImage(dynamic frame, {BoxFit fit = BoxFit.cover}) {
    final url = _frameUrl(frame);
    if (url.isEmpty) return const SizedBox.shrink();
    // Animated frames (gif / webp) animate automatically.
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (_, __) => const SizedBox.shrink(),
      errorWidget: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  Widget _buildFramesList(
    BusinessProfileProvider frameProvider,
    List<dynamic> frames,
    dynamic savedImageFile,
  ) {
    if (frameProvider.isDisplayLoading && frames.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (frames.isEmpty) {
      final error = frameProvider.displayError;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              error ?? 'No frames available',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
            ),
            if (error != null)
              TextButton(
                onPressed: () => selectedTab == 2
                    ? frameProvider.loadMyFrames(forceRefresh: true)
                    : frameProvider.loadFrames(
                        selectedTab == 0 ? 'static' : 'animated',
                      ),
                child: const Text('Retry'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: frames.length,
      itemBuilder: (context, index) {
        final frame = frames[index];
        final isSelected = selectedFrame == index;

        return GestureDetector(
          onTap: () => setState(() => selectedFrame = index),
          child: Container(
            width: 110.w,
            margin: EdgeInsets.only(right: 12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFE53935)
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1.2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (savedImageFile != null)
                            Image.file(savedImageFile, fit: BoxFit.cover)
                          else
                            Container(color: Colors.grey.shade50),
                          _frameImage(frame, fit: BoxFit.fill),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 6.h),
                AppText(
                  _frameLabel(frame),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabItem(String title, {required int index}) {
    bool isSelected = selectedTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          selectedTab = index;
          selectedFrame = 0;
          selectedCategory = -1;
        });
        context.read<BusinessProfileProvider>().updateFrameTab(index);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.black : Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 4.h),
          if (isSelected)
            Container(
              height: 3.h,
              width: 60.w,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryWrap(BusinessProfileProvider frameProvider) {
    final categories = frameProvider.selectedFrameCategories;

    if (categories.isEmpty) {
      return frameProvider.isCategoriesLoading
          ? SizedBox(
              height: 40.h,
              child: const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : const SizedBox.shrink();
    }

    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: [
        for (var i = 0; i < categories.length; i++)
          _buildCategoryChip(
            _pick(categories[i], [
              (c) => c.name,
              (c) => c.title,
              (c) => c.label,
            ]),
            index: i,
            slug: _pick(categories[i], [
              (c) => c.slug,
              (c) => c.uid,
              (c) => c.id,
              (c) => c.name,
            ]),
          ),
      ],
    );
  }

  Widget _buildCategoryChip(
    String title, {
    required int index,
    required String slug,
  }) {
    bool isSelected = selectedCategory == index;
    return InkWell(
      onTap: () {
        // Tap again to clear the filter.
        final deselect = selectedCategory == index;
        setState(() {
          selectedCategory = deselect ? -1 : index;
          selectedFrame = 0;
        });
        context.read<BusinessProfileProvider>().selectFrameCategory(
          deselect ? null : slug,
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A4A4A) : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade400,
          ),
        ),
        child: AppText(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }
}
