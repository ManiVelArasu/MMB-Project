import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../network/provider/plan_provider.dart';
import 'my_subscription.dart';

class SubscriptionActivatedScreen extends StatefulWidget {
  const SubscriptionActivatedScreen({super.key});

  @override
  State<SubscriptionActivatedScreen> createState() =>
      _SubscriptionActivatedScreenState();
}

class _SubscriptionActivatedScreenState
    extends State<SubscriptionActivatedScreen> {
  late final PlanProvider _provider;

  @override
  void initState() {
    super.initState();

    _provider = PlanProvider();

    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    final isActive = await _provider.fetchMySubscription();

    if (!mounted) return;

    debugPrint("📦 Subscription active: $isActive");
    debugPrint("📦 Subscription data: ${_provider.subscriptionData}");

    setState(() {});
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<PlanProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingSubscription) {
            return PopScope(
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) return;

                Navigator.pushNamedAndRemoveUntil(
                  context,
                  "/PlansAndPricingScreen",
                  (route) => false,
                );
              },
              child: const Scaffold(
                backgroundColor: Colors.white,
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          final data = provider.subscriptionData;

          final subscription = data?["subscription"] as Map<String, dynamic>?;

          final plan = data?["plan"] as Map<String, dynamic>?;

          final billing = data?["billing"] as Map<String, dynamic>?;

          final period = data?["period"] as Map<String, dynamic>?;

          final features = data?["features"] as List<dynamic>? ?? [];

          final planName = plan?["name"]?.toString() ?? "Premium Plan";

          return Scaffold(
            backgroundColor: Colors.white,

            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: const Text(
                "Subscription Activated",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  const Icon(Icons.celebration, size: 64, color: Colors.amber),

                  const SizedBox(height: 12),

                  const Text(
                    "SUBSCRIPTION ACTIVATED!",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "$planName is now active on your account.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------
                  // SUBSCRIPTION DETAILS
                  // ------------------------------------------

                  /*   Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "SUBSCRIPTION DETAILS",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),

                        const SizedBox(height: 14),

                        _detailRow(
                          "Plan",
                          planName,
                        ),

                        _detailRow(
                          "Amount Paid",
                          "$currency $amountPaid",
                        ),

                        _detailRow(
                          "Billing",
                          cycle,
                        ),

                        _detailRow(
                          "Payment Method",
                          paymentMethod.toUpperCase(),
                        ),

                        _detailRow(
                          "Start Date",
                          periodStart.isNotEmpty
                              ? periodStart
                              : _formatDate(startsAt),
                        ),

                        _detailRow(
                          "End Date",
                          periodEnd.isNotEmpty
                              ? periodEnd
                              : _formatDate(endsAt),
                        ),
                      ],
                    ),
                  ),*/
                  const SizedBox(height: 20),

                  // ------------------------------------------
                  // ACCESS LIST
                  // ------------------------------------------
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "YOU NOW HAVE ACCESS TO",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Expanded(
                            child: features.isEmpty
                                ? const Text(
                                    "No features available",
                                    style: TextStyle(color: Colors.grey),
                                  )
                                : ListView.separated(
                                    itemCount: features.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final feature = features[index];

                                      if (feature is! Map<String, dynamic>) {
                                        return const SizedBox();
                                      }

                                      final label =
                                          feature["label"]?.toString() ?? "";

                                      final enabled = feature["enabled"];

                                      final remaining = feature["remaining"];

                                      final limit = feature["limit"];

                                      return Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 20,
                                          ),

                                          const SizedBox(width: 10),

                                          Expanded(
                                            child: Text(
                                              label,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),

                                          if (remaining != null)
                                            Text(
                                              "$remaining",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red,
                                              ),
                                            ),

                                          if (enabled == true)
                                            const Icon(
                                              Icons.check,
                                              color: Colors.green,
                                              size: 18,
                                            ),

                                          if (limit != null &&
                                              remaining == null)
                                            Text(
                                              "$limit",
                                              style: const TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ------------------------------------------
                  // START EXPLORING
                  // ------------------------------------------
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final planProvider = context.read<PlanProvider>();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider.value(
                              value: planProvider,
                              child: const MySubscriptionScreen(),
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        "START EXPLORING",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black87),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, "/MySubscriptionScreen");
                      },
                      child: const Text(
                        "GO TO MY SUBSCRIPTION",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String value) {
    if (value.isEmpty) return "-";

    try {
      final date = DateTime.parse(value);

      return "${date.day.toString().padLeft(2, '0')}/"
          "${date.month.toString().padLeft(2, '0')}/"
          "${date.year}";
    } catch (_) {
      return value;
    }
  }
}
