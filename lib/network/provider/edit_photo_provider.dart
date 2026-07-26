import 'package:flutter/material.dart';

class EditPhotoProvider extends ChangeNotifier {
  // Search Controller
  final TextEditingController searchController = TextEditingController();

  // Business Details Controllers
  final TextEditingController businessNameController = TextEditingController(
    text: "Steve & Sarah Cakes",
  );
  final TextEditingController emailController = TextEditingController(
    text: "stevesarah@gmail.com",
  );
  final TextEditingController contactController = TextEditingController(
    text: "+91 98000 00001",
  );

  // More Business Info
  final TextEditingController altContactController = TextEditingController(
    text: "+91 98000 00001",
  );
  final TextEditingController websiteController = TextEditingController(
    text: "www.sarasteve.com",
  );

  // Social Controllers
  final TextEditingController facebookController = TextEditingController(
    text: "facebook.com",
  );
  final TextEditingController instagramController = TextEditingController(
    text: "instagram.com",
  );
  final TextEditingController twitterController = TextEditingController(
    text: "x.com",
  );
  final TextEditingController youtubeController = TextEditingController(
    text: "youtube.com",
  );
  final TextEditingController linkedinController = TextEditingController(
    text: "linkedin.com",
  );

  // Section Expand / Collapse States
  bool isMoreInfoExpanded = true;
  bool isSocialExpanded = true;

  void toggleMoreInfo() {
    isMoreInfoExpanded = !isMoreInfoExpanded;
    notifyListeners();
  }

  void toggleSocial() {
    isSocialExpanded = !isSocialExpanded;
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    businessNameController.dispose();
    emailController.dispose();
    contactController.dispose();
    altContactController.dispose();
    websiteController.dispose();
    facebookController.dispose();
    instagramController.dispose();
    twitterController.dispose();
    youtubeController.dispose();
    linkedinController.dispose();
    super.dispose();
  }
}
