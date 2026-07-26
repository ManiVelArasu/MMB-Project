import 'package:flutter/material.dart';
import 'package:project_mmb/helper/shared_preference.dart';
import 'package:project_mmb/network/provider/custom_theme_provider.dart';
import 'package:project_mmb/widgets/custom_sized_box.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final customColor = Provider.of<CustomThemeProvider>(context).colors;
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  // PAGE 1
                  Column(
                    children: [
                      Image.asset("assets/images/onboarding1.png"),
                      const SizedBox(height: 30),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,

                            children: [
                              Text(
                                "Templates",
                                style: theme.headlineLarge!.copyWith(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: customColor.redColor,
                                ),
                              ),
                              Text(
                                " for ",
                                style: theme.headlineLarge!.copyWith(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "Success",
                            style: theme.headlineLarge!.copyWith(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          "Choose from thousands of professionally designed templates to create stunning visuals.",
                          textAlign: TextAlign.center,
                          style: theme.titleMedium!.copyWith(
                            color: customColor.textColor,
                            fontWeight: FontWeight.w400
                          ),
                        ),
                      ),
                    ],
                  ),

                  // PAGE 2
                  Column(
                    children: [
                      Image.asset("assets/images/onboarding2.png"),
                      const SizedBox(height: 30),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Magically ",
                            style: theme.headlineLarge!.copyWith(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,

                            children: [
                              Text(
                                "Edit",
                                style: theme.headlineLarge!.copyWith(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: customColor.redColor,
                                ),
                              ),
                              Text(
                                " Your Designs",
                                style: theme.headlineLarge!.copyWith(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: customColor.blackColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          "Editing social media designs is now effortless. Dive into thousands of images and elements.",
                          textAlign: TextAlign.center,
                          style: theme.titleMedium!.copyWith(
                            color: customColor.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // PAGE 3
                  Column(
                    children: [
                      Image.asset("assets/images/onboarding3.png"),
                      const SizedBox(height: 30),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,

                            children: [
                              Text(
                                "Unlock ",
                                style: theme.headlineLarge!.copyWith(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: customColor.blackColor,
                                ),
                              ),
                              Text(
                                "Social Media",
                                style: theme.headlineLarge!.copyWith(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: customColor.redColor,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "Superpowers",
                            style: theme.headlineLarge!.copyWith(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: theme.titleMedium!.copyWith(
                              color: customColor.textColor,
                            ),
                            children: [
                              TextSpan(
                                text:
                                    "Create and post directly to all your social media platforms, right from the ",
                                style: theme.titleMedium!.copyWith(
                                  color: customColor.textColor,
                                ),
                              ),
                              TextSpan(
                                text: "MMB editor",
                                style: theme.titleMedium!.copyWith(
                                  color: customColor.redColor,
                                  // Set red color
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: ". Complete control, effortlessly.",
                                style: theme.titleMedium!.copyWith(
                                  color: customColor.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // INDICATORS + BUTTON
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // LEFT SIDE (dummy spacing)
                const SizedBox(width: 52),

                // CENTER INDICATOR
                Row(
                  children: List.generate(
                    3,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 22 : 8,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? customColor.baseColor
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                ),

                // RIGHT BUTTON
                _currentPage == 2
                    ? Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: InkWell(
                    onTap: () async {

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('isOnboarded', true);
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, "/LoginScreen");
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: customColor.baseColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                )
                    : const CustomSizedBox(),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
