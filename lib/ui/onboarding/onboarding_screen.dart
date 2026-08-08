import 'package:flutter/material.dart';
import 'package:project_mmb/component/custom_widget.dart';
import 'package:project_mmb/helper/shared_preference.dart';
import 'package:project_mmb/network/provider/custom_theme_provider.dart';
import 'package:project_mmb/utils/theme/app.fonts.dart';
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
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,

                                children: [
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: "Create",
                                          style: theme.headlineLarge!.copyWith(
                                            fontSize: AppFontSize.fontSize22,
                                            fontWeight: FontWeight.w900,
                                            color: customColor.blackColor,
                                          ),
                                        ),
                                        TextSpan(
                                          text: " Professional",
                                          style: theme.headlineLarge!.copyWith(
                                            fontSize: AppFontSize.fontSize22,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              AppText(
                                "Social Media Post",
                                style: TextStyle(
                                  fontSize: AppFontSize.fontSize22,
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
                          "Choose from thousands of ready-made templates designed for every business and every occasion.",
                          textAlign: TextAlign.center,
                          style: theme.titleMedium!.copyWith(
                            color: customColor.textColor,
                            fontWeight: FontWeight.w400,
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
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: "Create Faster with ",
                                  style: theme.headlineLarge!.copyWith(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: customColor.blackColor,
                                  ),
                                ),
                                TextSpan(
                                  text: "AI",
                                  style: theme.headlineLarge!.copyWith(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          "Generate images, captions, logos, product backgrounds, and more with powerful AI tools built for your business.",
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
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "Build Your ",
                                      style: theme.headlineLarge!.copyWith(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        color: customColor.blackColor,
                                      ),
                                    ),
                                    TextSpan(
                                      text: "Brand & Grow",
                                      style: theme.headlineLarge!.copyWith(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                                    "Customize, publish, and maintain a consistent brand across every social media platform with Make My Brand.",
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
                              Navigator.pushReplacementNamed(
                                context,
                                "/LoginScreen",
                              );
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
