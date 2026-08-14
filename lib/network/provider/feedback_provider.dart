import 'package:flutter/material.dart';
import 'package:project_mmb/Repository/feedBack_Repository.dart';
import '../../model/feedback_model.dart';

class FeedbackProvider extends ChangeNotifier {
  /// Selected emoji index
  int _selectedEmoji = 0;
  int get selectedEmoji => _selectedEmoji;

  /// Feedback text controller
  final TextEditingController feedbackController = TextEditingController();

  /// Store submitted feedback
  final List<FeedbackModel> _feedbackList = [];
  List<FeedbackModel> get feedbackList => _feedbackList;

  bool _isVerifyLoading = false;
  bool get isVerifyLoading => _isVerifyLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Select Emoji
  void selectEmoji(int index) {
    _selectedEmoji = index;
    notifyListeners();
  }

  void submitFeedbackLocally() {
    if (feedbackController.text.trim().isEmpty) return;

    _feedbackList.add(
      FeedbackModel(
        rating: _selectedEmoji,
        feedback: feedbackController.text.trim(),
      ),
    );

    feedbackController.clear();
    _selectedEmoji = 3;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> submitFeedbackApi({
    required String appVersion,
    required String platform,
  }) async {
    if (feedbackController.text.trim().isEmpty) return null;

    _isVerifyLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await feedBackRepository.instance.feedBack(
        rating: _selectedEmoji + 1,
        message: feedbackController.text.trim(),
        appVersion: appVersion,
        platform: platform,
      );

      _isVerifyLoading = false;
      notifyListeners();

      return await result.when(
        success: (data) {
          feedbackController.clear();
          _selectedEmoji = 3;
          notifyListeners();
          return data;
        },
        failure: (error) {
          _errorMessage = error.message;
          notifyListeners();
          return null;
        },
      );
    } catch (e) {
      _isVerifyLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Clear Feedback
  void clearFeedback() {
    feedbackController.clear();
    _selectedEmoji = 3;
    notifyListeners();
  }

  @override
  void dispose() {
    feedbackController.dispose();
    super.dispose();
  }
}
