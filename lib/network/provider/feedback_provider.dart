import 'package:flutter/material.dart';
import '../../model/feedback_model.dart';

class FeedbackProvider extends ChangeNotifier {
  /// Selected emoji index
  int _selectedEmoji = 3;

  int get selectedEmoji => _selectedEmoji;

  /// Feedback text controller
  final TextEditingController feedbackController =
  TextEditingController();

  /// Store submitted feedback
  final List<FeedbackModel> _feedbackList = [];

  List<FeedbackModel> get feedbackList => _feedbackList;

  /// Select Emoji
  void selectEmoji(int index) {
    _selectedEmoji = index;
    notifyListeners();
  }

  /// Submit Feedback
  void submitFeedback() {
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