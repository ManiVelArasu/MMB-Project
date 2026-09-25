import 'package:flutter/material.dart';

class ChangePlanScreen extends StatefulWidget {
  final bool openCancelSheet;

  const ChangePlanScreen({
    super.key,
    this.openCancelSheet = false,
  });

  @override
  State<ChangePlanScreen> createState() =>
      _ChangePlanScreenState();
}

class _ChangePlanScreenState extends State<ChangePlanScreen> {
  bool _cancelSheetOpened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_cancelSheetOpened) return;

    if (widget.openCancelSheet) {
      _cancelSheetOpened = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _showCancelRenewalBottomSheet();
      });
    }
  }
  void _showCancelRenewalBottomSheet() {
    String selectedReason = "I found a better app";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom:
                  MediaQuery.of(context)
                      .viewInsets
                      .bottom +
                      12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    // ================================
                    // HANDLE
                    // ================================

                    Center(
                      child: Container(
                        width: 45,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius:
                          BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ================================
                    // TITLE
                    // ================================

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "What's making you cancel?",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF171A2B),
                            ),
                          ),
                        ),

                        GestureDetector(
                          onTap: () {
                            Navigator.pop(
                              sheetContext,
                            );
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration:
                            const BoxDecoration(
                              color: Color(0xFFFFE5E7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      "Before you go, let us know why. It helps us improve\n"
                          "Make My Brand for everyone.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ================================
                    // REASONS
                    // ================================

                    _reasonItem(
                      title: "I found a better app",
                      selected:
                      selectedReason ==
                          "I found a better app",
                      onTap: () {
                        setSheetState(() {
                          selectedReason =
                          "I found a better app";
                        });
                      },
                    ),

                    _reasonItem(
                      title:
                      "Too expensive for what I use",
                      selected:
                      selectedReason ==
                          "Too expensive for what I use",
                      onTap: () {
                        setSheetState(() {
                          selectedReason =
                          "Too expensive for what I use";
                        });
                      },
                    ),

                    _reasonItem(
                      title:
                      "Missing a feature I need",
                      selected:
                      selectedReason ==
                          "Missing a feature I need",
                      onTap: () {
                        setSheetState(() {
                          selectedReason =
                          "Missing a feature I need";
                        });
                      },
                    ),

                    _reasonItem(
                      title: "I don't use it enough",
                      selected:
                      selectedReason ==
                          "I don't use it enough",
                      onTap: () {
                        setSheetState(() {
                          selectedReason =
                          "I don't use it enough";
                        });
                      },
                    ),

                    _reasonItem(
                      title: "Technical issues",
                      selected:
                      selectedReason ==
                          "Technical issues",
                      onTap: () {
                        setSheetState(() {
                          selectedReason =
                          "Technical issues";
                        });
                      },
                    ),

                    _reasonItem(
                      title: "Other",
                      selected:
                      selectedReason == "Other",
                      onTap: () {
                        setSheetState(() {
                          selectedReason = "Other";
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // ================================
                    // INPUT
                    // ================================

                    Container(
                      width: double.infinity,
                      height: 55,
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius:
                        BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      child: const Text(
                        "Add your valid inputs",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ================================
                    // BUTTONS
                    // ================================

                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(
                                  sheetContext,
                                );
                              },
                              style:
                              OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Colors.red,
                                ),
                                shape:
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(
                                    10,
                                  ),
                                ),
                              ),
                              child: const Text(
                                "BACK",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight:
                                  FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                debugPrint(
                                  "Cancel reason: $selectedReason",
                                );
                                Navigator.pop(sheetContext);

                                Navigator.pushNamed(
                                  context,
                                  "/ConfirmCancellationScreen",
                                );
                              },
                              style:
                              ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                elevation: 0,
                                shape:
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(
                                    10,
                                  ),
                                ),
                              ),
                              child: const Text(
                                "CONTINUE",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                  FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _reasonItem({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 6,
        ),
        child: Row(
          children: [
            Container(
              width: 19,
              height: 19,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? Colors.red
                      : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? Center(
                child: Container(
                  width: 9,
                  height: 9,
                  decoration:
                  const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                ),
              )
                  : null,
            ),

            const SizedBox(width: 10),

            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF555555),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ============================================================
    // உங்கள் OLD ChangePlanScreen DESIGN
    // இங்கே எந்த மாற்றமும் வேண்டாம்
    // ============================================================

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.red,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Change Plan",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Text(
              "CURRENT PLAN",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Premium",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "All basic brand generation tools",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    "₹499/mo",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "UPGRADE TO",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius:
                BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFD8B4FE),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "Elite",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "₹999/mo",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "• 3,000 AI Credits + Business Listing",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "Prorated difference",
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        "₹500",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 20),

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "Charged today",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "₹500",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    "/UsageScreen",
                  );
                },
                child: const Text(
                  "PAY DIFFERENCE & UPGRADE",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),

            const Center(
              child: Text(
                "Downgrades take effect from your next billing cycle "
                    "instead of charging you today.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}