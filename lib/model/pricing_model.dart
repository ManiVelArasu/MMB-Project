import 'package:flutter/material.dart';

class PricingPlanModel {
  final String id;
  final String title;
  final String price;
  final String period;
  final String description;
  final Color cardBgColor;
  final Color buttonColor;
  final Color detailsTextColor;
  final Color borderColor;

  PricingPlanModel({
    required this.id,
    required this.title,
    required this.price,
    required this.period,
    required this.description,
    required this.cardBgColor,
    required this.buttonColor,
    required this.detailsTextColor,
    required this.borderColor,
  });
}

class PricingProvider extends ChangeNotifier {
  String _selectedPlanId = "";

  String get selectedPlanId => _selectedPlanId;

  // Plan Data List matching the design
  List<PricingPlanModel> get plans => [
    PricingPlanModel(
      id: "basic",
      title: "Basic",
      price: "₹250",
      period: "/month",
      description:
          "Our Basic plan is perfect for Personal/small businesses posting 2–3 times a week. Includes 500 AI credits.",
      cardBgColor: const Color(0xFFF9FDE8), // Soft Light Lime Green
      buttonColor: const Color(0xFF8DC63F), // Lime Green
      detailsTextColor: const Color(0xFF8DC63F),
      borderColor: const Color(0xFFE2F0B9),
    ),
    PricingPlanModel(
      id: "premium",
      title: "Premium",
      price: "₹499",
      period: "/month",
      description:
          "Our Premium plan is perfect for small/Medium businesses posting 3–4 times a week. Includes 1000 AI credits.",
      cardBgColor: const Color(0xFFFFF0F6), // Soft Light Pink
      buttonColor: const Color(0xFFF06292), // Bright Pink
      detailsTextColor: const Color(0xFFF06292),
      borderColor: const Color(0xFFFBCFE8),
    ),
    PricingPlanModel(
      id: "elite",
      title: "Elite",
      price: "₹999",
      period: "/month",
      description:
          "Our Elite plan is designed for growing businesses needing maximum coverage and priority AI credits.",
      cardBgColor: const Color(0xFFF3E8FF),
      buttonColor: const Color(0xFF9333EA),
      detailsTextColor: const Color(0xFF9333EA),
      borderColor: const Color(0xFFE9D5FF),
    ),
  ];

  void selectPlan(String planId) {
    _selectedPlanId = planId;
    notifyListeners();
  }
}
