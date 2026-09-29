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

  Future<void> fetchPlans() async {
    _isLoadingPlans = true;
    _plansErrorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.industry();

      if (result.isSuccess && result.data != null) {
        _plansData = result.data;
      } else {
        _plansErrorMessage = result.error?.message ?? "Something went wrong";
      }
    } finally {
      _isLoadingPlans = false;
      notifyListeners();
    }
  }

  Future<String?> fetchSubscription() async {
    _isLoadingPlans = true;
    _plansErrorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.subscription();

      if (result.isFailure) {
        _plansErrorMessage =
            result.error?.message ?? "Unable to start payment";
        return null;
      }

      final response = result.data;

      debugPrint("💳 SUBSCRIPTION RESPONSE: $response");

      if (response == null || response is! Map) {
        _plansErrorMessage = "Invalid subscription response";
        return null;
      }

      final data = response["data"];

      if (data is! Map) {
        _plansErrorMessage = "Invalid subscription data";
        return null;
      }

      final shortUrl = data["short_url"]?.toString().trim();

      if (shortUrl == null || shortUrl.isEmpty) {
        _plansErrorMessage = "Payment URL not available";
        return null;
      }

      debugPrint("✅ Razorpay URL: $shortUrl");

      return shortUrl;
    } catch (e) {
      _plansErrorMessage = e.toString();
      debugPrint("❌ Subscription error: $e");
      return null;
    } finally {
      _isLoadingPlans = false;
      notifyListeners();
    }
  }
}
