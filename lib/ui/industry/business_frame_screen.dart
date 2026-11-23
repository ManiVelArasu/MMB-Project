import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
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
import '../../network/provider/common_provider.dart';
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

  // ---- Brand frame info (logo / mobile / website) ----
  bool _brandEnabled = true;
  File? _brandLogo;
  bool _brandSeeded = false;
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _websiteCtrl = TextEditingController();

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
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ------------------------------------------------------------
  // FRAME TAP -> frames/{id} API
  // ------------------------------------------------------------
  void _onFrameTap(int index, dynamic frame) {
    setState(() => selectedFrame = index);

    final uid = _pick(frame, [(f) => f.uid, (f) => f.id]);
    if (uid.isEmpty) return;

    // GET frames/{uid}; the preview switches to the image from the response.
    context.read<BusinessProfileProvider>().loadFrameDetail(uid);
  }

  String _cdn(String raw) {
    if (raw.isEmpty) return '';
    return raw.startsWith('http') ? raw : '${ApiEndpoints.cdnImageUrl}/$raw';
  }

  /// Image of the frames/{id} response. Keys are checked in this order,
  /// change the list if your API uses a different key.
  String _detailImageUrl(Map<String, dynamic> detail) {
    const keys = [
      'preview_s3_key',
      'image_s3_key',
      'frame_s3_key',
      's3_key',
      'thumbnail_s3_key',
      'image_url',
      'preview_url',
      'url',
      'image',
    ];
    final sources = <Map<String, dynamic>>[
      detail,
      if (detail['frame'] is Map) Map<String, dynamic>.from(detail['frame']),
    ];
    for (final source in sources) {
      for (final key in keys) {
        final v = source[key];
        if (v is String && v.trim().isNotEmpty) return _cdn(v.trim());
      }
    }
    return '';
  }

  /// Branded frame = needs logo / mobile / website. Detected from the
  /// frames/{id} response (flag or category containing "brand"), or from the
  /// selected category chip. Adjust here if your API marks it differently.
  bool _isBrandedFrame(
      BusinessProfileProvider p,
      Map<String, dynamic>? detail,
      ) {
    bool truthy(dynamic v) =>
        v == true || v == 1 || v?.toString().toLowerCase() == 'true';

    if (detail != null) {
      for (final key in const [
        'is_branded',
        'branded',
        'is_brand_frame',
        'brand_frame',
        'is_branding',
        'has_branding',
      ]) {
        if (truthy(detail[key])) return true;
      }
      final cat = detail['category'];
      final text = [
        cat is Map ? (cat['slug'] ?? cat['name']) : cat,
        detail['category_slug'],
        detail['category_name'],
      ].join(' ').toLowerCase();
      if (text.contains('brand')) return true;
    }
    return (p.selectedCategorySlug ?? '').toLowerCase().contains('brand');
  }

  /// Profile / business logo of the logged in user (from CommonProvider).
  /// Business account -> business logo, personal account -> profile photo.
  /// Field names are tried in order; add yours to the lists if needed.
  String _profileImageUrl() {
    final common = CommonProvider.instance;
    final isBusiness = common.accountType?.toLowerCase() == 'business';

    dynamic business;
    dynamic me;
    try {
      business = common.business;
    } catch (_) {}
    try {
      me = common.me?.data;
    } catch (_) {}

    final fromBusiness = _pick(business, [
          (b) => b.logoUrl,
          (b) => b.logo,
          (b) => b.logoS3Key,
          (b) => b.logoKey,
          (b) => b.businessLogo,
          (b) => b.profileImage,
    ]);
    final fromMe = _pick(me, [
          (m) => m.profileImageUrl,
          (m) => m.profileImage,
          (m) => m.profilePicture,
          (m) => m.profileImageS3Key,
          (m) => m.avatar,
          (m) => m.photo,
          (m) => m.imageS3Key,
    ]);

    final raw = isBusiness
        ? (fromBusiness.isNotEmpty ? fromBusiness : fromMe)
        : (fromMe.isNotEmpty ? fromMe : fromBusiness);
    return _cdn(raw);
  }

  /// Picked logo -> profile image -> profile icon (never the app logo).
  Widget _brandLogoWidget({double? height}) {
    if (_brandLogo != null) {
      return Image.file(_brandLogo!, height: height, fit: BoxFit.contain);
    }

    final url = _profileImageUrl();
    final icon = Icon(
      Icons.account_circle_rounded,
      size: height ?? 48.sp,
      color: Colors.grey.shade500,
    );
    if (url.isEmpty) return icon;

    return SizedBox(
      height: height,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          height: height,
          width: height,
          fit: BoxFit.cover,
          placeholder: (_, __) => icon,
          errorWidget: (_, __, ___) => icon,
        ),
      ),
    );
  }

  Future<void> _pickBrandLogo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    setState(() => _brandLogo = File(picked.path));
  }

  void _onUpdateBusinessDetails() {
    FocusScope.of(context).unfocus();
    // TODO: call your existing "update business details" API here with
    // _phoneCtrl.text, _websiteCtrl.text and _brandLogo.
    _toast('Business details updated');
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

        // frames/{id} response of the active frame (if already loaded)
        final activeUid = activeFrame == null
            ? ''
            : _pick(activeFrame, [(f) => f.uid, (f) => f.id]);
        final detail =
        (activeUid.isNotEmpty && frameProvider.frameDetailUid == activeUid)
            ? frameProvider.frameDetail
            : null;
        final detailUrl = detail == null ? '' : _detailImageUrl(detail);
        final previewUrl = detailUrl.isNotEmpty
            ? detailUrl
            : (activeFrame == null ? '' : _frameUrl(activeFrame));
        final isBranded =
            activeFrame != null && _isBrandedFrame(frameProvider, detail);

        if (!_brandSeeded) {
          _phoneCtrl.text = businessProvider.mobileNumber;
          _brandSeeded = true;
        }

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

                          // Brand frame header (Enable / Disable)
                          if (isBranded) ...[
                            _buildBrandHeader(),
                            SizedBox(height: 10.h),
                          ],

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

                                  // Image from frames/{id} over the photo
                                  if (activeFrame != null)
                                    Positioned.fill(
                                      child: _frameImageFromUrl(
                                        previewUrl,
                                        fit: BoxFit.fill,
                                      ),
                                    ),

                                  if (frameProvider.isFrameDetailLoading)
                                    const Positioned.fill(
                                      child: Center(
                                        child: SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    ),

                                  // Logo / mobile / website (branded frames)
                                  if (isBranded && _brandEnabled)
                                    ..._brandOverlay(),

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

                          if (isBranded) ...[
                            SizedBox(height: 14.h),
                            _buildBrandEditCard(),
                          ],

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
    return _frameImageFromUrl(_frameUrl(frame), fit: fit);
  }

  // ------------------------------------------------------------
  // BRAND FRAME (logo / mobile / website)
  // ------------------------------------------------------------

  Widget _buildBrandHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          AppText(
            'Selected Brand Frame',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          AppText(
            'Enable/Disable',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
          ),
          SizedBox(width: 6.w),
          Switch(
            value: _brandEnabled,
            activeTrackColor: const Color(0xFFE53935),
            thumbColor: const WidgetStatePropertyAll(Colors.white),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (v) => setState(() => _brandEnabled = v),
          ),
        ],
      ),
    );
  }

  List<Widget> _brandOverlay() {
    final phone = _phoneCtrl.text.trim();
    final site = _websiteCtrl.text.trim();

    return [
      // Logo - top right
      Positioned(
        top: 10.h,
        right: 10.w,
        child: _brandLogoWidget(height: 34.h),
      ),

      // Mobile number - bottom left
      if (phone.isNotEmpty)
        Positioned(
          left: 10.w,
          bottom: 10.h,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF2EAD33),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.phone, size: 12.sp, color: Colors.white),
              ),
              SizedBox(width: 4.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF2EAD33),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: AppText(
                  phone,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

      // Website - bottom right
      if (site.isNotEmpty)
        Positioned(
          right: 10.w,
          bottom: 10.h,
          child: Row(
            children: [
              Icon(Icons.language, size: 16.sp, color: const Color(0xFF1E3A8A)),
              SizedBox(width: 4.w),
              AppText(
                site,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
    ];
  }

  InputDecoration _brandFieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildBrandEditCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Edit Brand Frame Info',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12.h),

          // Logo: current logo  OR  upload
          Row(
            children: [
              Container(
                width: 80.w,
                height: 80.w,
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(child: _brandLogoWidget()),
              ),
              SizedBox(width: 14.w),
              AppText(
                'OR',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800),
              ),
              SizedBox(width: 14.w),
              InkWell(
                onTap: _pickBrandLogo,
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE3E3),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.upload_rounded,
                        color: const Color(0xFFE53935),
                        size: 22.sp,
                      ),
                      SizedBox(height: 6.h),
                      AppText(
                        'Upload logo',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            onChanged: (_) => setState(() {}),
            decoration: _brandFieldDecoration('Mobile Number'),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _websiteCtrl,
            keyboardType: TextInputType.url,
            onChanged: (_) => setState(() {}),
            decoration: _brandFieldDecoration('Website'),
          ),
          SizedBox(height: 14.h),

          ElevatedButton(
            onPressed: _onUpdateBusinessDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: AppText(
              'UPDATE BUSINESS DETAILS',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _frameImageFromUrl(String url, {BoxFit fit = BoxFit.cover}) {
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
          onTap: () => _onFrameTap(index, frame),
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