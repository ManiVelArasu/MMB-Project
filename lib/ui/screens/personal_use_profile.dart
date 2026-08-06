import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../network/provider/businessprofile_provider.dart';

class PersonalProfileScreen extends StatelessWidget {
  const PersonalProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<BusinessProfileProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      body: SafeArea(

        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFEEF2), Color(0xFFE3F2FD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    // Profile/Business Logo Avatar
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.pink,
                      child: Text(
                        profileProvider.businessName.isNotEmpty
                            ? profileProvider.businessName[0].toUpperCase()
                            : "B",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Business Name & Category
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                profileProvider.businessName.isEmpty
                                    ? "Business Name"
                                    : profileProvider.businessName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.edit, size: 14, color: Colors.grey),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Text(
                                "Cake and Sweets",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  "PREMIUM",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Action Icons (Sparkle & Notification)
                    IconButton(
                      icon: const Icon(Icons.auto_awesome, color: Colors.redAccent),
                      onPressed: () {},
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications, color: Colors.red),
                          onPressed: () {},
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              "2",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 🚀 2. Banner Card: Start Your Business Journey
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Start Your Business Journey",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Create your business profile to unlock industry-specific templates and AI tools.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text(
                        "Set Up My Business →",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // 🚀 3. Two Grid Buttons: Personal Profile & My Downloads
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.badge, color: Colors.blue, size: 30),
                            SizedBox(height: 8),
                            Text(
                              "Personal Profile",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE7F6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.download, color: Colors.deepPurple, size: 30),
                            SizedBox(height: 8),
                            Text(
                              "My Downloads",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 🚀 4. Sections List (Help & Support, App Settings, About App)
              _buildSectionHeader("Help & Support"),
              _buildSettingsCard([
                _buildTile(Icons.chat_bubble_outline, "Help & Support", Colors.red, () {}),
                _buildTile(Icons.help_outline, "FAQs", Colors.red, () {}),
              ]),

              _buildSectionHeader("App Settings"),
              _buildSettingsCard([
                _buildDarkModeTile(),
                _buildTile(Icons.notifications_none, "Notifications", Colors.red, () {}),
              ]),

              _buildSectionHeader("About App"),
              _buildSettingsCard([
                _buildTile(Icons.feedback_outlined, "Feedback", Colors.red, () {}),
                _buildTile(Icons.privacy_tip_outlined, "Privacy Policy", Colors.red, () {}),
                _buildTile(Icons.description_outlined, "Terms & Conditions", Colors.red, () {}),
                _buildTile(Icons.assignment_return_outlined, "Refund Policy", Colors.red, () {}),
                _buildTile(Icons.share_outlined, "Follow Us", Colors.red, () {}),
                _buildTile(Icons.delete_outline, "Delete my Account", Colors.red, () {}),
              ]),

              // 🚀 5. Promotional Bottom Banner (Build Your Brand)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8EAF6), Color(0xFFD1C4E9)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Build Your Brand with\nBrand Series",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3F2B96),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Create consistent social media designs for your business, all in one place.",
                            style: TextStyle(fontSize: 10, color: Colors.black87),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {},
                            child: const Text(
                              "EXPLORE NOW",
                              style: TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.celebration, size: 60, color: Colors.deepPurple),
                  ],
                ),
              ),

              // 🚀 6. Logout & Version
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const Center(
                child: Text(
                  "App Version 1.2",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 4, spreadRadius: 1),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile(IconData icon, String title, Color iconColor, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildDarkModeTile() {
    return ListTile(
      leading: const Icon(Icons.dark_mode_outlined, color: Colors.red, size: 22),
      title: const Text("Dark Mode", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: Switch(
        value: false,
        activeColor: Colors.red,
        onChanged: (val) {},
      ),
    );
  }
}