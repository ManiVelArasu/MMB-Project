import 'package:flutter/material.dart';
import '../../model/faq_model.dart';


class FaqProvider extends ChangeNotifier {
  final List<FaqModel> _faqList = [
    FaqModel(
      question: "How Make My Brand Helps Your Business?",
      answer:
      "1. Ready-Made Social Media Content: Access daily posts, festival templates, and trending designs.\n\n"
          "2. Brand Customization: Personalize every post with your logo, contact details, and brand identity.\n\n"
          "3. Social Media Management: Schedule content, track performance, and run effective ad campaigns.\n\n"
          "4. Business Growth Tools: Get a one-page website and essential branding materials.\n\n"
          "5. Community Marketplace: Connect with customers, collaborators, and influencers.\n\n"
          "6. Virtual Events & Gamification: Engage in online networking activities.\n\n"
          "7. Customer Support & Automation: Simplify operations with AI-driven tools.",
      isExpanded: true,
    ),

    FaqModel(
      question: "Why Facebook and Instagram ads important for your business?",
      answer:
      "Facebook and Instagram ads help you reach more customers, increase brand awareness, generate leads, and improve sales.",
    ),

    FaqModel(
      question: "How can I get access to ready-made social media content?",
      answer:
      "You can access daily social media templates through the Make My Brand application after logging in.",
    ),

    FaqModel(
      question: "What is the Community Marketplace?",
      answer:
      "Community Marketplace helps you connect with customers, business owners, and influencers.",
    ),
  ];

  List<FaqModel> get faqList => _faqList;

  void toggleExpansion(int index) {
    _faqList[index].isExpanded = !_faqList[index].isExpanded;
    notifyListeners();
  }
}