import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChangeNumberBottomSheet extends StatefulWidget {
  final String currentMobileNumber;

  const ChangeNumberBottomSheet({super.key, required this.currentMobileNumber});

  @override
  State<ChangeNumberBottomSheet> createState() =>
      _ChangeNumberBottomSheetState();
}

class _ChangeNumberBottomSheetState extends State<ChangeNumberBottomSheet> {
  // ============================================================
  // STEPS
  // 0 = Current number
  // 1 = Current OTP
  // 2 = New number
  // 3 = New OTP
  // 4 = Success
  // ============================================================

  int _step = 0;

  bool isLoading = false;

  // ============================================================
  // CONTROLLERS
  // ============================================================

  late final TextEditingController currentMobileController;

  final TextEditingController newMobileController = TextEditingController();

  // ============================================================
  // CURRENT OTP
  // ============================================================

  final List<TextEditingController> currentOtpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> currentOtpFocusNodes = List.generate(
    6,
    (_) => FocusNode(),
  );

  // ============================================================
  // NEW OTP
  // ============================================================

  final List<TextEditingController> newOtpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> newOtpFocusNodes = List.generate(6, (_) => FocusNode());

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    currentMobileController = TextEditingController(
      text: widget.currentMobileNumber,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    currentMobileController.dispose();
    newMobileController.dispose();

    for (final controller in currentOtpControllers) {
      controller.dispose();
    }

    for (final focusNode in currentOtpFocusNodes) {
      focusNode.dispose();
    }

    for (final controller in newOtpControllers) {
      controller.dispose();
    }

    for (final focusNode in newOtpFocusNodes) {
      focusNode.dispose();
    }

    super.dispose();
  }

  // ============================================================
  // CURRENT OTP
  // ============================================================

  String get currentOtp {
    return currentOtpControllers.map((controller) => controller.text).join();
  }

  // ============================================================
  // NEW OTP
  // ============================================================

  String get newOtp {
    return newOtpControllers.map((controller) => controller.text).join();
  }

  // ============================================================
  // SEND CURRENT OTP
  // ============================================================

  Future<void> _sendCurrentOtp() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      // TODO:
      // உங்கள் current mobile OTP API இங்கே call செய்யவும்.

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      setState(() {
        _step = 1;
      });

      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;

        FocusScope.of(context).requestFocus(currentOtpFocusNodes.first);
      });
    } catch (e) {
      if (!mounted) return;

      _showError("Failed to send OTP");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // VERIFY CURRENT OTP
  // ============================================================

  Future<void> _verifyCurrentOtp() async {
    if (isLoading) return;

    if (currentOtp.length != 6) {
      _showError("Please enter 6 digit OTP");
      return;
    }

    debugPrint("CURRENT OTP: $currentOtp");

    setState(() {
      isLoading = true;
    });

    try {
      // TODO:
      // Current OTP verify API

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      setState(() {
        _step = 2;
      });
    } catch (e) {
      if (!mounted) return;

      _showError("Invalid OTP");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // SEND NEW NUMBER OTP
  // ============================================================

  Future<void> _sendNewOtp() async {
    if (isLoading) return;

    final newNumber = newMobileController.text.trim();

    if (newNumber.isEmpty) {
      _showError("Please enter new mobile number");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // TODO:
      // New mobile OTP API

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      setState(() {
        _step = 3;
      });

      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;

        FocusScope.of(context).requestFocus(newOtpFocusNodes.first);
      });
    } catch (e) {
      if (!mounted) return;

      _showError("Failed to send OTP");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // VERIFY NEW OTP
  // ============================================================

  Future<void> _verifyNewOtp() async {
    if (isLoading) return;

    if (newOtp.length != 6) {
      _showError("Please enter 6 digit OTP");
      return;
    }

    debugPrint("NEW OTP: $newOtp");

    setState(() {
      isLoading = true;
    });

    try {
      // TODO:
      // New number OTP verify API
      //
      // After successful verification,
      // update mobile number API call here.

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      setState(() {
        _step = 4;
      });
    } catch (e) {
      if (!mounted) return;

      _showError("Invalid OTP");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // RESEND CURRENT OTP
  // ============================================================

  Future<void> _resendCurrentOtp() async {
    debugPrint("Resend current OTP");

    // TODO:
    // Current number resend OTP API
  }

  // ============================================================
  // RESEND NEW OTP
  // ============================================================

  Future<void> _resendNewOtp() async {
    debugPrint("Resend new OTP");

    // TODO:
    // New number resend OTP API
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _buildStep(),
      ),
    );
  }

  // ============================================================
  // STEP
  // ============================================================

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildCurrentNumberStep();

      case 1:
        return _buildCurrentOtpStep();

      case 2:
        return _buildNewNumberStep();

      case 3:
        return _buildNewOtpStep();

      case 4:
        return _buildSuccessStep();

      default:
        return _buildCurrentNumberStep();
    }
  }

  // ============================================================
  // CURRENT NUMBER SCREEN
  // ============================================================

  Widget _buildCurrentNumberStep() {
    return _sheetContainer(
      key: const ValueKey("current_number"),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),

          SizedBox(height: 20.h),

          Text(
            "Verify your current mobile number",
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700),
          ),

          SizedBox(height: 5.h),

          Text(
            "For your security, we'll first verify your "
            "current mobile number before changing it.",
            style: TextStyle(
              fontSize: 8.5.sp,
              height: 1.4,
              color: const Color(0xFF777777),
            ),
          ),

          SizedBox(height: 16.h),

          _mobileField(controller: currentMobileController, enabled: false),

          SizedBox(height: 18.h),

          _redButton(text: "SEND OTP", onPressed: _sendCurrentOtp, width: 95.w),
        ],
      ),
    );
  }

  // ============================================================
  // CURRENT OTP SCREEN
  // ============================================================

  Widget _buildCurrentOtpStep() {
    return _sheetContainer(
      key: const ValueKey("current_otp"),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),

          SizedBox(height: 20.h),

          Text(
            "Verify your current mobile number",
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),

          SizedBox(height: 5.h),

          Text(
            "We've sent a 6-digit OTP to "
            "${widget.currentMobileNumber}.",
            style: TextStyle(fontSize: 8.5.sp, color: const Color(0xFF777777)),
          ),

          SizedBox(height: 20.h),

          _buildOtpBoxes(
            controllers: currentOtpControllers,
            focusNodes: currentOtpFocusNodes,
          ),

          SizedBox(height: 18.h),

          Center(
            child: GestureDetector(
              onTap: _resendCurrentOtp,
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "Haven't received the code? ",
                      style: TextStyle(
                        fontSize: 8.5.sp,
                        color: const Color(0xFF777777),
                      ),
                    ),
                    TextSpan(
                      text: "Resend OTP",
                      style: TextStyle(
                        fontSize: 8.5.sp,
                        color: const Color(0xFFFF1D25),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 18.h),

          Center(
            child: _redButton(
              text: "VERIFY",
              onPressed: _verifyCurrentOtp,
              width: 95.w,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NEW NUMBER SCREEN
  // ============================================================

  Widget _buildNewNumberStep() {
    return _sheetContainer(
      key: const ValueKey("new_number"),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),

          SizedBox(height: 20.h),

          Text(
            "Enter new mobile number",
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700),
          ),

          SizedBox(height: 5.h),

          Text(
            "Enter the mobile number you want to use "
            "for your MM8 account.",
            style: TextStyle(
              fontSize: 8.5.sp,
              height: 1.4,
              color: const Color(0xFF777777),
            ),
          ),

          SizedBox(height: 12.h),

          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F9EC),
              borderRadius: BorderRadius.circular(5.r),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 12.sp),
                SizedBox(width: 5.w),
                Text(
                  "Current mobile number verified",
                  style: TextStyle(
                    fontSize: 8.5.sp,
                    color: const Color(0xFF169B2E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 10.h),

          _mobileField(
            controller: newMobileController,
            enabled: true,
            hintText: "+91 98765 43210",
          ),

          SizedBox(height: 18.h),

          Center(
            child: _redButton(
              text: "SEND OTP",
              onPressed: _sendNewOtp,
              width: 95.w,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NEW OTP SCREEN
  // ============================================================

  Widget _buildNewOtpStep() {
    return _sheetContainer(
      key: const ValueKey("new_otp"),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),

          SizedBox(height: 20.h),

          Text(
            "Verify new mobile number",
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700),
          ),

          SizedBox(height: 5.h),

          Text(
            "We've sent a 6-digit OTP to "
            "${newMobileController.text}.",
            style: TextStyle(fontSize: 8.5.sp, color: const Color(0xFF777777)),
          ),

          SizedBox(height: 20.h),

          _buildOtpBoxes(
            controllers: newOtpControllers,
            focusNodes: newOtpFocusNodes,
          ),

          SizedBox(height: 18.h),

          Center(
            child: GestureDetector(
              onTap: _resendNewOtp,
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "Haven't received the code? ",
                      style: TextStyle(
                        fontSize: 8.5.sp,
                        color: const Color(0xFF777777),
                      ),
                    ),
                    TextSpan(
                      text: "Resend OTP",
                      style: TextStyle(
                        fontSize: 8.5.sp,
                        color: const Color(0xFFFF1D25),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 18.h),

          Center(
            child: _redButton(
              text: "VERIFY",
              onPressed: _verifyNewOtp,
              width: 95.w,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUCCESS SCREEN
  // ============================================================

  Widget _buildSuccessStep() {
    return _sheetContainer(
      key: const ValueKey("success"),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),

          SizedBox(height: 18.h),

          Container(
            width: 46.w,
            height: 46.w,
            decoration: const BoxDecoration(
              color: Color(0xFF18B53B),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: Colors.white, size: 28.sp),
          ),

          SizedBox(height: 14.h),

          Text(
            "Mobile Number Updated\nSuccessfully",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800),
          ),

          SizedBox(height: 10.h),

          Text(
            "Your MMB account is now linked to your new mobile number. Use this number the next time you sign in. Your business profile, templates, designs, downloads, AI credits and plan all stay exactly as they were.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8.5.sp,
              height: 1.45,
              color: const Color(0xFF777777),
            ),
          ),

          SizedBox(height: 20.h),

          _redButton(
            text: "CONTINUE TO MM8",
            onPressed: () {
              Navigator.pop(context, newMobileController.text.trim());
            },
            width: 150.w,
          ),
        ],
      ),
    );
  }

  Widget _sheetContainer({required Key key, required Widget child}) {
    return Container(
      key: key,
      width: double.infinity,

      padding: EdgeInsets.fromLTRB(14.w, 7.h, 14.w, 18.h),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12.r),
          topRight: Radius.circular(12.r),
        ),
      ),

      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 34.w,
                height: 3.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5D5D5),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),

            SizedBox(height: 6.h),

            child,
          ],
        ),
      ),
    );
  }
  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Column(
      children: [
        Center(
          child: Container(
            width: 32.w,
            height: 3.h,
            decoration: BoxDecoration(
              color: const Color(0xFFD0D0D0),
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        ),

        SizedBox(height: 6.h),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Change Mobile Number",
              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800),
            ),

            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: 20.w,
                height: 20.w,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE7E9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: const Color(0xFFFF1D25),
                  size: 12.sp,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // OTP BOXES
  // ============================================================

  Widget _buildOtpBoxes({
    required List<TextEditingController> controllers,
    required List<FocusNode> focusNodes,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 35.w,
          height: 35.h,
          child: TextField(
            controller: controllers[index],
            focusNode: focusNodes[index],

            keyboardType: TextInputType.number,

            textInputAction: index == 5
                ? TextInputAction.done
                : TextInputAction.next,

            maxLength: 1,

            textAlign: TextAlign.center,

            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),

            decoration: InputDecoration(
              counterText: "",

              filled: true,

              fillColor: const Color(0xFFF7F7F7),

              contentPadding: EdgeInsets.zero,

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5.r),
                borderSide: BorderSide.none,
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5.r),
                borderSide: BorderSide.none,
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5.r),
                borderSide: const BorderSide(
                  color: Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
            ),

            onChanged: (value) {
              // ==========================================
              // NEXT BOX
              // ==========================================

              if (value.isNotEmpty) {
                if (index < 5) {
                  FocusScope.of(context).requestFocus(focusNodes[index + 1]);
                } else {
                  focusNodes[index].unfocus();
                }
              }

              // ==========================================
              // PREVIOUS BOX
              // ==========================================

              if (value.isEmpty && index > 0) {
                FocusScope.of(context).requestFocus(focusNodes[index - 1]);
              }
            },
          ),
        );
      }),
    );
  }

  // ============================================================
  // MOBILE FIELD
  // ============================================================

  Widget _mobileField({
    required TextEditingController controller,
    required bool enabled,
    String? hintText,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.phone,

      style: TextStyle(fontSize: 10.sp, color: Colors.black),

      decoration: InputDecoration(
        hintText: hintText,

        hintStyle: TextStyle(fontSize: 10.sp, color: const Color(0xFF999999)),

        filled: true,

        fillColor: enabled ? Colors.white : const Color(0xFFFFE1E4),

        contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: const Color(0xFFE0E0E0)),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: const Color(0xFFE0E0E0)),
        ),

        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ============================================================
  // RED BUTTON
  // ============================================================

  Widget _redButton({
    required String text,
    required VoidCallback onPressed,
    required double width,
  }) {
    return SizedBox(
      width: width,
      height: 40.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,

        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF1D25),

          disabledBackgroundColor: const Color(0xFFFF1D25).withOpacity(0.6),

          elevation: 0,

          padding: EdgeInsets.zero,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7.r),
          ),
        ),

        child: isLoading
            ? SizedBox(
                width: 17.w,
                height: 17.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

// ================================================================
// SHOW DIALOG / BOTTOM SHEET
// ================================================================

Future<void> showChangeNumberBottomSheet(
  BuildContext context, {
  required String currentMobileNumber,
}) async {
  await showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    useSafeArea: true,
    builder: (context) {
      final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

      return AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: ChangeNumberBottomSheet(
          currentMobileNumber: currentMobileNumber,
        ),
      );
    },
  );
}
