import 'package:flutter/cupertino.dart';

import '../../Api Model/plans_type.dart';
import '../../Repository/plan_repository.dart';

class PlanProvider extends ChangeNotifier {
  final PlanRepository _repository = PlanRepository.instance;

  bool _isLoadingPlans = false;
  bool get isLoadingPlans => _isLoadingPlans;

  PlanResponse? _plansData;
  PlanResponse? get plansData => _plansData;

  String? _plansErrorMessage;
  String? get plansErrorMessage => _plansErrorMessage;

  bool _isCreatingSubscription = false;
  bool get isCreatingSubscription => _isCreatingSubscription;

  String? _subscriptionUrl;
  String? get subscriptionUrl => _subscriptionUrl;

  String? _subscriptionId;
  String? get subscriptionId => _subscriptionId;

  String? _userSubscriptionUid;
  String? get userSubscriptionUid => _userSubscriptionUid;

  String? _shortUrl;
  String? get shortUrl => _shortUrl;

  String? _subscriptionError;
  String? get subscriptionError => _subscriptionError;

  Map<String, dynamic>? _subscriptionData;
  Map<String, dynamic>? get subscriptionData => _subscriptionData;

  bool _isLoadingSubscription = false;
  bool get isLoadingSubscription => _isLoadingSubscription;
  Future<void> fetchPlans() async {
    _isLoadingPlans = true;
    _plansErrorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.industry();

      if (result.isSuccess && result.data != null) {
        _plansData = result.data;

        debugPrint("========== PLANS ==========");

        for (final plan in _plansData!.data) {
          debugPrint("PLAN ID: ${plan.id}");
          debugPrint("PLAN NAME: ${plan.name}");
          debugPrint(
            "BILLING OPTIONS COUNT: ${plan.planBillingOptions.length}",
          );

          for (final option in plan.planBillingOptions) {
            debugPrint(
              "➡️ Billing ID: ${option.id} | "
                  "Cycle: ${option.billingCycle} | "
                  "Price: ${option.price}",
            );
          }
        }

        debugPrint("===========================");
      } else {
        _plansErrorMessage =
            result.error?.message ?? "Something went wrong";
      }
    } finally {
      _isLoadingPlans = false;
      notifyListeners();
    }
  }

  Future<bool> fetchMySubscription() async {
    _isLoadingSubscription = true;
    _subscriptionError = null;
    notifyListeners();

    try {
      final result = await _repository.getMySubscription();

      if (result.isFailure) {
        _subscriptionError =
            result.error?.message ?? "Unable to get subscription";
        return false;
      }

      final response = result.data;

      debugPrint("================================");
      debugPrint("📦 MY SUBSCRIPTION");
      debugPrint("$response");
      debugPrint("================================");

      if (response is! Map<String, dynamic>) {
        _subscriptionError = "Invalid subscription response";
        return false;
      }

      final data = response["data"];

      if (data is! Map<String, dynamic>) {
        _subscriptionError = "Subscription data not available";
        return false;
      }

      _subscriptionData = data;

      final hasActiveSubscription = data["has_active_subscription"] == true;

      debugPrint("✅ Has active subscription: $hasActiveSubscription");

      return hasActiveSubscription;
    } catch (e, stackTrace) {
      _subscriptionError = e.toString();

      debugPrint("❌ Subscription exception: $e");
      debugPrintStack(stackTrace: stackTrace);

      return false;
    } finally {
      _isLoadingSubscription = false;
      notifyListeners();
    }
  }

  Future<CreatedSubscription?> createSubscription({
    required int planBillingOptionId,
  }) async {
    _isCreatingSubscription = true;
    _subscriptionError = null;
    notifyListeners();

    try {
      debugPrint(
        "💳 Plan Billing Option ID: $planBillingOptionId",
      );

      final result = await _repository.subscription(
        planBillingOptionId: planBillingOptionId,
      );

      if (result.isFailure) {
        _subscriptionError =
            result.error?.message ?? "Unable to create subscription";
        return null;
      }

      final response = result.data;

      debugPrint("================================");
      debugPrint("💳 CREATE SUBSCRIPTION RESPONSE");
      debugPrint("$response");
      debugPrint("================================");

      if (response is! Map<String, dynamic>) {
        _subscriptionError = "Invalid subscription response";
        return null;
      }

      final data = response["data"];

      if (data is! Map<String, dynamic>) {
        _subscriptionError = "Subscription data not available";
        return null;
      }

      final shortUrl = data["short_url"]?.toString().trim();

      final subscriptionId =
      data["subscription_id"]?.toString().trim();

      if (shortUrl == null || shortUrl.isEmpty) {
        _subscriptionError = "Payment URL not available";
        return null;
      }

      if (subscriptionId == null || subscriptionId.isEmpty) {
        _subscriptionError = "Subscription ID not available";
        return null;
      }

      _subscriptionUrl = shortUrl;
      _subscriptionId = subscriptionId;

      return CreatedSubscription(
        shortUrl: shortUrl,
        subscriptionId: subscriptionId,
      );
    } catch (e, stackTrace) {
      _subscriptionError = e.toString();

      debugPrint("❌ Create subscription error: $e");
      debugPrintStack(stackTrace: stackTrace);

      return null;
    } finally {
      _isCreatingSubscription = false;
      notifyListeners();
    }
  }

  String? get activePlanUid {
    final plan = _subscriptionData?["plan"];

    if (plan is Map) {
      return plan["uid"]?.toString();
    }

    return null;
  }

  String? get activePlanName {
    final plan = _subscriptionData?["plan"];

    if (plan is Map) {
      return plan["name"]?.toString();
    }

    return null;
  }

  bool isActivePlan(Plan plan) {
    final activeUid = activePlanUid;

    if (activeUid == null || activeUid.isEmpty) {
      return false;
    }

    return plan.uid == activeUid;
  }
}

class CreatedSubscription {
  final String shortUrl;
  final String subscriptionId;

  CreatedSubscription({required this.shortUrl, required this.subscriptionId});
}
