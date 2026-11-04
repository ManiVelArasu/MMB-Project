import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../component/custom_widget.dart';
import '../../../utils/theme/app.fonts.dart';
import '../../component/appbar_widget.dart';
import '../../network/provider/plan_provider.dart';
import 'invoice_screen.dart';

class PaymentDetailsScreen extends StatefulWidget {
  final String transactionId;
  final String status;
  final String paymentMethod;
  final String planName;
  final String dateTime;
  final String baseAmount;
  final String gstAmount;
  final String totalAmount;

  final String billedTo;
  final String email;
  final String gstin;

  const PaymentDetailsScreen({
    super.key,
    required this.transactionId,
    required this.status,
    required this.paymentMethod,
    required this.planName,
    required this.dateTime,
    required this.baseAmount,
    required this.gstAmount,
    required this.totalAmount,
    this.billedTo = '--',
    this.email = '--',
    this.gstin = '--',
  });

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  Future<void> _openInvoice({required bool isReceipt}) async {
    final provider = context.read<PlanProvider>();

    final success = isReceipt
        ? await provider.getReceipt(widget.transactionId)
        : await provider.getInvoice(widget.transactionId);

    if (!mounted) return;

    final html = isReceipt ? provider.isReceiptHtml : provider.invoiceHtml;

    if (success && html != null && html.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => InvoiceScreen(html: html)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isReceipt
                ? provider.isReceiptError ?? 'Unable to load receipt'
                : provider.invoiceError ?? 'Unable to load invoice',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanProvider>();

    final isLoading = provider.isInvoiceLoading || provider.isReceiptLoading;

    final status = widget.status.toUpperCase();
    final isSuccess = [
      'SUCCESS',
      'SUCCESSFUL',
      'COMPLETED',
      'PAID',
    ].contains(status);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: CustomAppBar(title: "Payment Details", showRightIcon: false),

      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 25.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TRANSACTION DETAILS CARD
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(18.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17.r),
                    border: Border.all(color: const Color(0xFFE7E0D7)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                'TRANSACTION STATUS',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: AppFontSize.fontSize12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 3.h),
                              AppText(
                                widget.paymentMethod,
                                style: TextStyle(
                                  color: Color(0xFF66615B),
                                  fontSize: AppFontSize.fontSize14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: isSuccess
                                  ? const Color(0xFFE1FAF3)
                                  : const Color(0xFFFFE5E7),
                              borderRadius: BorderRadius.circular(7.r),
                            ),
                            child: Text(
                              widget.status.toUpperCase(),
                              style: TextStyle(
                                color: isSuccess
                                    ? const Color(0xFF00A878)
                                    : Colors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 17.h),
                      Divider(color: Colors.grey.shade300),
                      SizedBox(height: 9.h),

                      _detailRow('Plan Purchased', widget.planName),
                      _detailRow('Transaction ID', widget.transactionId),
                      _detailRow('Date & Time', widget.dateTime),
                      _detailRow('Base Amount', widget.baseAmount),
                      _detailRow('GST (18%)', widget.gstAmount),

                      SizedBox(height: 7.h),
                      Divider(color: Colors.grey.shade300),
                      SizedBox(height: 9.h),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(
                            'Total Paid',
                            style: TextStyle(
                              color: Color(0xFF171A2B),
                              fontSize: AppFontSize.fontSize16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          AppText(
                            widget.totalAmount,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: AppFontSize.fontSize22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 19.h),

                // INVOICE AND RECEIPT BUTTONS
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46.h,
                        child: OutlinedButton(
                          onPressed: isLoading
                              ? null
                              : () => _openInvoice(isReceipt: false),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11.r),
                            ),
                          ),
                          child: const Text(
                            'INVOICE',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: SizedBox(
                        height: 46.h,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () => _openInvoice(isReceipt: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11.r),
                            ),
                          ),
                          child: const Text(
                            'RECEIPT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20.h),

                /*    const Text(
                  'BILLING DETAILS',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                SizedBox(height: 9.h),

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFFE7E0D7)),
                  ),
                  child: Column(
                    children: [
                      _detailRow('Billed To', widget.billedTo),
                      _detailRow('Email/Mobile', widget.email),
                      _detailRow('GSTIN', widget.gstin),
                    ],
                  ),
                ),*/
              ],
            ),
          ),

          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.12),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.red),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 7.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppText(
              title,
              style: TextStyle(
                color: Color(0xFF625D57),
                fontSize: AppFontSize.fontSize14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Flexible(
            child: AppText(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: Color(0xFF171A2B),
                fontSize: AppFontSize.fontSize14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
