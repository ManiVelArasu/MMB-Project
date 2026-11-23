import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mmb_app/component/appbar_widget.dart';
import 'package:mmb_app/component/custom_widget.dart';
import 'package:mmb_app/network/provider/business_provider.dart';
import 'package:mmb_app/network/provider/businessprofile_provider.dart';
import 'package:mmb_app/network/provider/custom_theme_provider.dart';
import 'package:mmb_app/ui/industry/widgets/active_brand_frame.dart';
import 'package:mmb_app/ui/industry/widgets/brand_edit_sheet.dart';
import 'package:mmb_app/ui/industry/widgets/brand_form.dart';
import 'package:mmb_app/ui/industry/widgets/brand_profile_resolver.dart';
import 'package:mmb_app/ui/industry/widgets/frame_content.dart';
import 'package:mmb_app/ui/industry/widgets/frame_helpers.dart';
import 'package:mmb_app/ui/industry/widgets/frame_images.dart';
import 'package:mmb_app/ui/industry/widgets/frame_preview.dart';
import 'package:mmb_app/ui/industry/widgets/frame_selector_widgets.dart';
import 'package:mmb_app/utils/theme/app.fonts.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

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
  static const String _razorpayKey = 'rzp_test_TWag5Xvk4KWWgY';

  /// "My Brand Frames" tab (already purchased frames).
  static const int _myFramesTab = 2;

  int _selectedTab = 0;
  int _selectedCategory = -1; // -1 = all
  int _selectedFrame = 0;

  final BrandForm _form = BrandForm();
  late final Razorpay _razorpay;

  /// Last frame id for which frames/{id} was requested automatically.
  String _requestedUid = '';

  // ------------------------------------------------------------------
  // LIFECYCLE
  // ------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    // keep the Enable / Disable switch in sync with the applied frame
    _form.enabled = ActiveBrandFrame.instance.enabled;

    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _form.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  BrandProfileResolver _resolver() => BrandProfileResolver(
        profile: context.read<BusinessProfileProvider>(),
        business: context.read<BusinessProvider>(),
      );

  // ------------------------------------------------------------------
  // SELECTION (tab / category / frame)
  // ------------------------------------------------------------------

  void _onTabChanged(int index) {
    setState(() {
      _selectedTab = index;
      _selectedFrame = 0;
      _selectedCategory = -1;
    });
    context.read<BusinessProfileProvider>().updateFrameTab(index);
  }

  void _onCategoryTap(int index, String slug) {
    // tap the selected chip again to clear the filter
    final deselect = _selectedCategory == index;
    setState(() {
      _selectedCategory = deselect ? -1 : index;
      _selectedFrame = 0;
    });
    context.read<BusinessProfileProvider>().selectFrameCategory(
          deselect ? null : slug,
        );
  }

  void _onFrameTap(int index, dynamic frame) {
    setState(() => _selectedFrame = index);

    final uid = frameUid(frame);
    if (uid.isEmpty) return;

    // GET frames/{uid}; the preview switches to the image / content from
    // the response.
    context.read<BusinessProfileProvider>().loadFrameDetail(uid);
  }

  void _retryFrames() {
    final provider = context.read<BusinessProfileProvider>();
    if (_selectedTab == _myFramesTab) {
      provider.loadMyFrames(forceRefresh: true);
    } else {
      provider.loadFrames(_selectedTab == 0 ? 'static' : 'animated');
    }
  }

  /// First / selected frame (tab change, category change, first load):
  /// call frames/{id} automatically, no tap needed.
  void _loadDetailOnce(String uid, BusinessProfileProvider provider) {
    if (uid.isEmpty ||
        provider.frameDetailUid == uid ||
        _requestedUid == uid) {
      return;
    }
    _requestedUid = uid;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BusinessProfileProvider>().loadFrameDetail(uid);
    });
  }

  /// PURCHASED frame (My Brand Frames tab) -> shared with the template edit
  /// screen, which draws it as an overlay.
  void _shareWithTemplateEditor({
    required String uid,
    required String? contentJson,
    required String logoUrl,
  }) {
    final slots = _form.slotTexts;
    final logoFile = _form.logo;
    final enabled = _form.enabled;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ActiveBrandFrame.instance.update(
        uid: uid,
        contentJson: contentJson,
        enabled: enabled,
        slotTexts: slots,
        logoFile: logoFile,
        logoUrl: logoUrl,
      );
    });
  }

  // ------------------------------------------------------------------
  // BRAND INFO (logo / name / phone / email / website)
  // ------------------------------------------------------------------

  void _openEditSheet() {
    showBrandEditSheet(
      context,
      form: _form,
      logoPreview: () => BrandAvatar(file: _form.logo, url: _resolver().imageUrl),
      onPickLogo: _pickBrandLogo,
      onSave: _saveBusinessDetails,
      onChanged: () => setState(() {}),
    );
  }

  Future<void> _pickBrandLogo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    var file = File(picked.path);

    // "Remove Background?" -> REMOVE BG / KEEP IT ORIGINAL
    final removeBg = await showRemoveBackgroundDialog(context, file);
    if (!mounted) return;

    if (removeBg == true) {
      final result = await _removeBackground(file);
      if (!mounted) return;
      if (result != null) {
        file = result;
      } else {
        _toast('Unable to remove background, using original logo');
      }
    }

    setState(() {
      _form.logo = file;
      _form.logoChanged = true;
    });

    // presign -> upload -> confirm, right after the logo is final
    await _uploadPickedLogo(file);
  }

  /// TODO: plug in your remove-background API here (the one the web uses).
  /// Upload [input], download the transparent PNG, save it to a temp file and
  /// return that File. Return null on failure (the original logo is kept).
  Future<File?> _removeBackground(File input) async => null;

  Future<void> _uploadPickedLogo(File file) async {
    if (_form.isSaving) return;

    final profile = context.read<BusinessProfileProvider>();
    setState(() => _form.isSaving = true);

    final uploaded = await profile.uploadLogo(file);
    if (!mounted) return;

    setState(() {
      _form.isSaving = false;
      // uploaded -> the key is in the provider, no second upload needed.
      // failed   -> stays true, UPDATE BUSINESS DETAILS retries it.
      if (uploaded) _form.logoChanged = false;
    });

    _toast(
      uploaded
          ? 'Logo uploaded. Tap UPDATE BUSINESS DETAILS to save'
          : profile.updateError ?? 'Logo upload failed',
    );
  }

  /// UPDATE BUSINESS DETAILS: PUT /businesses/me (a logo uploaded earlier is
  /// sent by its key; a failed upload is retried here).
  Future<bool> _saveBusinessDetails() async {
    if (_form.isSaving) return false;

    FocusScope.of(context).unfocus();

    final name = _form.name.text.trim();
    final phone = _form.phone.text.trim();
    final email = _form.email.text.trim();

    final business = context.read<BusinessProvider>();
    final profile = context.read<BusinessProfileProvider>();

    // always https:// (typed with or without it)
    final website = profile.normalizeWebsite(_form.website.text);

    if (name.isEmpty) {
      _toast('Please enter name');
      return false;
    }
    if (phone.isEmpty) {
      _toast('Please enter contact number');
      return false;
    }

    // show the https:// value in the field / frame as well
    if (_form.website.text.trim() != website) {
      _form.website.text = website;
      _form.websiteTouched = true;
    }

    setState(() => _form.isSaving = true);

    final ok = await profile.saveProfile(
      name: name,
      phone: phone,
      website: website,
      email: email,
      // upload only when a new logo was picked
      newImage: _form.logoChanged ? _form.logo : null,
    );
    if (!mounted) return ok;

    setState(() => _form.isSaving = false);

    if (ok) {
      _form.logoChanged = false;

      // keep the local form provider in sync
      business
        ..setBusinessName(name)
        ..setEmail(email)
        ..setMobileNumber(phone);

      _toast('Business details updated');
    } else {
      _toast(profile.updateError ?? 'Unable to update business details');
    }
    return ok;
  }

  // ------------------------------------------------------------------
  // PAYMENT (Razorpay)
  // ------------------------------------------------------------------

  Future<void> _onGetFrame(dynamic frame) async {
    final uid = frameUid(frame);
    if (uid.isEmpty) {
      _toast('Frame id not available');
      return;
    }

    final profile = context.read<BusinessProfileProvider>();
    final business = context.read<BusinessProvider>();

    final order = await profile.purchaseFrame(uid);
    if (!mounted) return;

    if (order == null) {
      _toast(profile.purchaseError ?? 'Unable to start payment');
      return;
    }

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

    final profile = context.read<BusinessProfileProvider>();
    final ok = await profile.verifyFramePayment(
      razorpayOrderId: r.orderId ?? '',
      razorpayPaymentId: r.paymentId ?? '',
      razorpaySignature: r.signature ?? '',
    );

    _toast(
      ok
          ? 'Payment successful'
          : profile.purchaseError ?? 'Payment verification failed',
    );
  }

  void _onPaymentError(PaymentFailureResponse r) {
    debugPrint(
      'Razorpay error: code=${r.code} message=${r.message} error=${r.error}',
    );
    _toast(r.message ?? 'Payment failed');
  }

  void _onExternalWallet(ExternalWalletResponse r) {
    debugPrint('Razorpay external wallet: ${r.walletName}');
  }

  // ------------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Consumer<BusinessProvider>(
      builder: (context, business, _) {
        final profile = context.watch<BusinessProfileProvider>();

        // ---- selected frame + its frames/{id} response ----
        final frames = profile.displayFrames;
        final activeFrame = frames.isEmpty
            ? null
            : frames[_selectedFrame.clamp(0, frames.length - 1)];
        final activeUid = activeFrame == null ? '' : frameUid(activeFrame);
        final detail =
            (activeUid.isNotEmpty && profile.frameDetailUid == activeUid)
                ? profile.frameDetail
                : null;
        _loadDetailOnce(activeUid, profile);

        // ---- `content` (Fabric JSON): frames with "slot:*" objects are
        //      drawn from it, so the edited values appear inside the frame ----
        final contentJson = frameContentJson(detail);
        final parsed = FrameContent.parse(contentJson);
        final content = (parsed != null && parsed.hasSlots) ? parsed : null;

        // ---- profile values fill the fields until the user edits them ----
        final resolver = BrandProfileResolver(profile: profile, business: business);
        _form.syncFromProfile(resolver);
        final logoUrl = resolver.imageUrl;

        if (_selectedTab == _myFramesTab && content != null) {
          _shareWithTemplateEditor(
            uid: activeUid,
            contentJson: contentJson,
            logoUrl: logoUrl,
          );
        }

        final isBranded = activeFrame != null &&
            (content != null ||
                isBrandedFrame(
                  selectedCategorySlug: profile.selectedCategorySlug,
                  detail: detail,
                ));

        // preview height follows the frame's own aspect ratio
        final previewWidth = MediaQuery.of(context).size.width - 32.w;
        final previewHeight = content != null
            ? previewWidth * content.height / content.width
            : 340.h;

        final detailImage = detail == null ? '' : frameDetailImageUrl(detail);
        final previewImage = detailImage.isNotEmpty
            ? detailImage
            : (activeFrame == null ? '' : frameThumbUrl(activeFrame));

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: const CustomAppBar(
            title: "Business Frames",
            showTitle: true,
            showRightIcon: false,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 12.h),

                  if (isBranded) ...[
                    BrandHeaderBar(
                      enabled: _form.enabled,
                      onChanged: (v) => setState(() => _form.enabled = v),
                    ),
                    SizedBox(height: 10.h),
                  ],

                  FramePreview(
                    height: previewHeight,
                    hasFrame: activeFrame != null,
                    imageUrl: previewImage,
                    content: content,
                    isLoading: profile.isFrameDetailLoading,
                    showLegacyOverlay:
                        isBranded && _form.enabled && content == null,
                    form: _form,
                    logoUrl: logoUrl,
                    defaultPhone: business.mobileNumber,
                    defaultEmail: business.email,
                  ),
                  SizedBox(height: 16.h),

                  _buildTitleRow(activeFrame),

                  // Already-owned frames (My Brand Frames) need no purchase.
                  if (activeFrame != null && _selectedTab != _myFramesTab) ...[
                    SizedBox(height: 14.h),
                    _buildGetFrameButton(profile, activeFrame),
                  ],
                  SizedBox(height: 24.h),

                  FrameTabs(selected: _selectedTab, onChanged: _onTabChanged),
                  SizedBox(height: 16.h),

                  // Categories from API (Branding / Promotional ...)
                  if (_selectedTab != _myFramesTab)
                    FrameCategoryChips(
                      categories: profile.selectedFrameCategories,
                      isLoading: profile.isCategoriesLoading,
                      selectedIndex: _selectedCategory,
                      onTap: _onCategoryTap,
                    ),
                  SizedBox(height: 20.h),

                  SizedBox(
                    height: 140.h,
                    child: FramesStrip(
                      frames: frames,
                      selectedIndex: _selectedFrame,
                      isLoading: profile.isDisplayLoading,
                      error: profile.displayError,
                      onTap: _onFrameTap,
                      onRetry: _retryFrames,
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitleRow(dynamic activeFrame) {
    final colors = Provider.of<CustomThemeProvider>(context).colors;

    return Row(
      children: [
        Text(
          activeFrame == null ? "Free" : frameLabel(activeFrame),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: AppFontSize.fontSize16,
                color: colors.blackColor,
              ),
        ),
        const Spacer(),
        InkWell(
          onTap: _openEditSheet,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: kBrandRedTint,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: AppText(
              "EDIT",
              style: TextStyle(
                color: kBrandRed,
                fontWeight: FontWeight.w700,
                fontSize: 13.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGetFrameButton(
    BusinessProfileProvider profile,
    dynamic activeFrame,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 46.h,
      child: ElevatedButton(
        onPressed: profile.isPurchasing ? null : () => _onGetFrame(activeFrame),
        style: brandButtonStyle(radius: 12.r),
        child: profile.isPurchasing
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
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
