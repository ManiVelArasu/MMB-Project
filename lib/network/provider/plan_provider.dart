import 'package:flutter/cupertino.dart';

import '../../Api Model/payment_history.dart';
import '../../Api Model/plan_usage.dart';
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

  bool _isLoadingPaymentHistory = false;
  bool get isLoadingPaymentHistory => _isLoadingPaymentHistory;

  PaymentHistory? _paymentHistory;
  PaymentHistory? get paymentHistoryData => _paymentHistory;

  String? _paymentHistoryError;
  String? get paymentHistoryError => _paymentHistoryError;

  PlanUsage? _planUsageData;
  PlanUsage? get planUsageData => _planUsageData;

  bool _isLoadingPlanUsage = false;
  bool get isLoadingPlanUsage => _isLoadingPlanUsage;

  String? _planUsageError;
  String? get planUsageError => _planUsageError;

  bool _isCancellingPlan = false;
  bool get isCancellingPlan => _isCancellingPlan;

  String? _cancelPlanError;
  String? get cancelPlanError => _cancelPlanError;

  bool _isInvoiceLoading = false;

  String? _invoiceError;
  String? _invoiceHtml;

  bool get isInvoiceLoading => _isInvoiceLoading;
  String? get invoiceError => _invoiceError;
  String? get invoiceHtml => _invoiceHtml;

  bool _isReceiptLoading = false;

  String? _isReceiptError;
  String? _isReceiptHtml;

  bool get isReceiptLoading => _isReceiptLoading;
  String? get isReceiptError => _isReceiptError;
  String? get isReceiptHtml => _isReceiptHtml;

  Future<bool> getInvoice(String invoiceId) async {
    _isInvoiceLoading = true;
    _invoiceError = null;
    _invoiceHtml = null;

    notifyListeners();

    try {
      final result = await PlanRepository.instance.invoice(invoiceId);

      return result.when(
        success: (data) {
          _invoiceHtml = data?.toString();

          _isInvoiceLoading = false;
          notifyListeners();

          return _invoiceHtml != null && _invoiceHtml!.isNotEmpty;
        },
        failure: (error) {
          _invoiceError = error.message;

          _isInvoiceLoading = false;
          notifyListeners();

          return false;
        },
      );
    } catch (e) {
      _invoiceError = e.toString();

      _isInvoiceLoading = false;
      notifyListeners();

      debugPrint("❌ Invoice API Error: $e");

      return false;
    }
  }

  Future<bool> getReceipt(String invoiceId) async {
    _isReceiptLoading = true;
    _isReceiptError = null;
    _isReceiptHtml = null;

    notifyListeners();

    try {
      final result = await PlanRepository.instance.receipt(invoiceId);

      return await result.when(
        success: (data) {
          _isReceiptHtml = data?.toString();

          _isReceiptLoading = false;
          notifyListeners();

          return _isReceiptHtml != null && _isReceiptHtml!.isNotEmpty;
        },
        failure: (error) {
          _isReceiptError = error.message;

          _isReceiptLoading = false;
          notifyListeners();

          return false;
        },
      );
    } catch (e) {
      _isReceiptError = e.toString();

      _isReceiptLoading = false;
      notifyListeners();

      debugPrint("❌ Invoice API Error: $e");

      return false;
    }
  }

  Future<bool> cancelSubscription() async {
    if (_isCancellingPlan) return false;

    _isCancellingPlan = true;
    _cancelPlanError = null;
    notifyListeners();

    try {
      final result = await _repository.cancelPlan();

      if (result.isFailure) {
        _cancelPlanError =
            result.error?.message ?? "Unable to cancel subscription";

        debugPrint("❌ Cancel Plan Error: $_cancelPlanError");

        return false;
      }

      debugPrint("================================");
      debugPrint("✅ PLAN CANCELLED SUCCESSFULLY");
      debugPrint("${result.data}");
      debugPrint("================================");

      return true;
    } catch (e, stackTrace) {
      _cancelPlanError = e.toString();

      debugPrint("❌ Cancel Plan Exception: $e");
      debugPrintStack(stackTrace: stackTrace);

      return false;
    } finally {
      _isCancellingPlan = false;
      notifyListeners();
    }
  }

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
        _plansErrorMessage = result.error?.message ?? "Something went wrong";
      }
    } finally {
      _isLoadingPlans = false;
      notifyListeners();
    }
  }

  Future<void> fetchPlanUsage() async {
    _isLoadingPlanUsage = true;
    _planUsageError = null;
    notifyListeners();

    try {
      final result = await _repository.planUsage();

      if (result.isSuccess && result.data != null) {
        _planUsageData = result.data;

        debugPrint("========== PLAN USAGE ==========");

        final features = _planUsageData?.data?.features ?? [];

        for (final feature in features) {
          debugPrint(
            "Feature: ${feature.label} | "
            "Used: ${feature.used} | "
            "Limit: ${feature.effectiveLimit} | "
            "Remaining: ${feature.remaining}",
          );
        }

        debugPrint("================================");
      } else {
        _planUsageError = result.error?.message ?? "Unable to get plan usage";
      }
    } catch (e, stackTrace) {
      _planUsageError = e.toString();

      debugPrint("❌ Plan usage error: $e");
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isLoadingPlanUsage = false;
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
      debugPrint("💳 Plan Billing Option ID: $planBillingOptionId");

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

      final subscriptionId = data["subscription_id"]?.toString().trim();

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

  Future<bool> fetchPaymentHistory() async {
    _isLoadingPaymentHistory = true;
    _paymentHistoryError = null;
    notifyListeners();

    try {
      final result = await _repository.paymentHistory();

      if (result.isFailure) {
        _paymentHistoryError =
            result.error?.message ?? "Unable to get payment history";

        debugPrint("❌ Payment History Error: $_paymentHistoryError");

        return false;
      }

      final response = result.data;

      if (response == null) {
        _paymentHistoryError = "Payment history data not available";
        return false;
      }

      _paymentHistory = response;

      debugPrint("================================");
      debugPrint("💰 PAYMENT HISTORY");
      debugPrint("$_paymentHistory");
      debugPrint("================================");

      return true;
    } catch (e, stackTrace) {
      _paymentHistoryError = e.toString();

      debugPrint("❌ Payment History Exception: $e");
      debugPrintStack(stackTrace: stackTrace);

      return false;
    } finally {
      _isLoadingPaymentHistory = false;
      notifyListeners();
    }
  }

  // Add this inside PlanProvider class
  int? get activePlanIndex {
    final activeUid = activePlanUid;
    if (activeUid == null || activeUid.isEmpty || _plansData == null) {
      return null;
    }

    final plans = _plansData!.data;
    for (int i = 0; i < plans.length; i++) {
      if (plans[i].uid == activeUid) {
        return i;
      }
    }
    return null;
  }

  /// Returns the button text and state based on current active plan index
  PlanButtonState getPlanButtonState(
      Plan plan,
      int currentIndex,
      ) {
    final activeIndex = activePlanIndex;

    // ==========================================================
    // 1. NO ACTIVE PLAN
    // ==========================================================

    if (activeIndex == null) {
      return PlanButtonState(
        text: _getDefaultButtonText(currentIndex),
        isEnabled: true,
        isCurrentActive: false,
      );
    }

    // ==========================================================
    // 2. CURRENT PLAN
    // ==========================================================

    if (plan.uid == activePlanUid) {

      // --------------------------------------------------------
      // Current plan renewal cancelled
      // --------------------------------------------------------

      if (isRenewalCancelled) {
        return const PlanButtonState(
          text: "RENEW PLAN",
          isEnabled: true,
          isCurrentActive: false,
        );
      }

      // --------------------------------------------------------
      // Current plan is active + auto renew enabled
      // --------------------------------------------------------

      return const PlanButtonState(
        text: "ACTIVE PLAN",
        isEnabled: false,
        isCurrentActive: true,
      );
    }

    // ==========================================================
    // 3. LOWER PLAN -> DOWNGRADE
    // ==========================================================

    if (currentIndex < activeIndex) {
      return const PlanButtonState(
        text: "DOWNGRADE",
        isEnabled: true,
        isCurrentActive: false,
      );
    }

    // ==========================================================
    // 4. HIGHER PLAN -> UPGRADE
    // ==========================================================

    return const PlanButtonState(
      text: "UPGRADE",
      isEnabled: true,
      isCurrentActive: false,
    );
  }

  String _getDefaultButtonText(int index) {
    switch (index) {
      case 0:
        return " BASIC";
      case 1:
        return "PREMIUM";
      case 2:
        return "ELITE";
      default:
        return "PLAN";
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

    if (isRenewalCancelled) {
      return false;
    }

    return plan.uid == activeUid;
  }

  bool get isRenewalCancelled {
    final subscription = _subscriptionData?["subscription"];

    if (subscription is! Map) {
      return false;
    }

    final autoRenew = subscription["auto_renew"];

    final renewalCancelledAt =
    subscription["renewal_cancelled_at"];

    return autoRenew == false ||
        renewalCancelledAt != null;
  }
}

class CreatedSubscription {
  final String shortUrl;
  final String subscriptionId;

  CreatedSubscription({required this.shortUrl, required this.subscriptionId});
}

class PlanButtonState {
  final String text;
  final bool isEnabled;
  final bool isCurrentActive;

  const PlanButtonState({
    required this.text,
    required this.isEnabled,
    required this.isCurrentActive,
  });
}
