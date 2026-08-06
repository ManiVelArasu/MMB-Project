import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:project_mmb/component/custom_widget.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_widget.dart';
import '../../network/provider/faq_provider.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FaqProvider(),
      child: Consumer<FaqProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: Colors.white,

            appBar: const CustomAppBar(
              title: "FAQs",
              showRightIcon: false,
            ),

            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  const Center(
                    child: AppText(
                      "Got questions? We've got answers!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize:20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.faqList.length,
                    separatorBuilder: (_, _ ,) =>
                    const Divider(height: 30),
                    itemBuilder: (context, index) {
                      final faq = provider.faqList[index];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              provider.toggleExpansion(index);
                            },
                            child: Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    faq.question,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),

                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5E7EB),
                                    borderRadius:
                                    BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    faq.isExpanded
                                        ? Icons.remove
                                        : Icons.add,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (faq.isExpanded) ...[
                            const SizedBox(height: 18),

                            Text(
                              faq.answer,
                              style: const TextStyle(
                                fontSize: 17,
                                height: 1.6,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}