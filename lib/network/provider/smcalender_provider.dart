import 'package:flutter/material.dart';

class CalendarItemModel {
  final String id;
  final String title;
  final String frequency;
  final String platformAndPosts;

  CalendarItemModel({
    required this.id,
    required this.title,
    required this.frequency,
    required this.platformAndPosts,
  });
}

class SmCalendarProvider extends ChangeNotifier {
  final List<CalendarItemModel> _calendars = [
    CalendarItemModel(
      id: "1",
      title: "August month Calendar",
      frequency: "3 posts per week",
      platformAndPosts: "Instagram / 12 posts",
    ),
    CalendarItemModel(
      id: "2",
      title: "September month Calendar",
      frequency: "3 posts per week",
      platformAndPosts: "Instagram, Facebook / 12 posts",
    ),
  ];

  List<CalendarItemModel> get calendars => _calendars;
}