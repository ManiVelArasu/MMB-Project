import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../network/provider/business_provider.dart';
import '../../../network/provider/custom_theme_provider.dart';

class UpdateBusinessSheet extends StatefulWidget {
  const UpdateBusinessSheet({super.key});

  @override
  State<UpdateBusinessSheet> createState() => _UpdateBusinessSheetState();
}

class _UpdateBusinessSheetState extends State<UpdateBusinessSheet> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController contactController;

  int activeBottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<BusinessProvider>(context, listen: false);
    nameController = TextEditingController(text: provider.businessName.isEmpty ? "Steve & Sarah Cakes" : provider.businessName);
    phoneController = TextEditingController(text: provider.mobileNumber.isEmpty ? "+91 9876543210" : provider.mobileNumber);
    emailController = TextEditingController(text: provider.email.isEmpty ? "stevesarah@gmail.com" : provider.email);
    contactController = TextEditingController(text: provider.mobileNumber.isEmpty ? "+91 9876543210" : provider.mobileNumber);
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customColor = Provider.of<CustomThemeProvider>(context).colors;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12.h),
          Container(
            height: 5.h,
            width: 80.w,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          SizedBox(height: 12.h),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Update Business Info",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFECEE),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: const Color(0xFFE53935),
                      size: 18.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              children: [
                _buildOutlineInputField("Business Name", nameController),
                SizedBox(height: 12.h),
                _buildOutlineInputField("Phone Number", phoneController, keyboardType: TextInputType.phone),
                SizedBox(height: 12.h),
                _buildOutlineInputField("Email ID", emailController, keyboardType: TextInputType.emailAddress),
                SizedBox(height: 12.h),
                _buildOutlineInputField("Contact Number", contactController, keyboardType: TextInputType.phone),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: const BoxDecoration(
              color: Color(0xFF1E2B58),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      activeBottomNavIndex = 0;
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        color: activeBottomNavIndex == 0 ? const Color(0xFF4ED8F2) : Colors.white60,
                        size: 22.sp,
                      ),
                      Text(
                        "INFO",
                        style: TextStyle(
                          color: activeBottomNavIndex == 0 ? const Color(0xFF4ED8F2) : Colors.white60,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 24.w),

                // EDIT Navigation item
                InkWell(
                  onTap: () {
                    setState(() {
                      activeBottomNavIndex = 1;
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: activeBottomNavIndex == 1 ? const Color(0xFF4ED8F2) : Colors.white60,
                        size: 22.sp,
                      ),
                      Text(
                        "EDIT",
                        style: TextStyle(
                          color: activeBottomNavIndex == 1 ? const Color(0xFF4ED8F2) : Colors.white60,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ADD TO BUSINESS BUTTON
                ElevatedButton(
                  onPressed: () {
                    final provider = Provider.of<BusinessProvider>(context, listen: false);
                    provider.setBusinessName(nameController.text);
                    provider.setEmail(emailController.text);
                    provider.setMobileNumber(phoneController.text);

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935), // Red Button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                    elevation: 0,
                  ),
                  child: Text(
                    "Add to Business",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutlineInputField(
      String label,
      TextEditingController controller, {
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 2.h),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}