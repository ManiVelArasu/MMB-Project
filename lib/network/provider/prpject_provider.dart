import 'package:flutter/foundation.dart';

import '../../Repository/project.dart';

class ProjectProvider extends ChangeNotifier {
  ProjectProvider();

  final ProjectRepository repository = ProjectRepository.instance;

  // =========================================================
  // LOADING
  // =========================================================

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // =========================================================
  // PROJECT DATA
  // =========================================================

  int? _projectId;

  int? get projectId => _projectId;

  String? _projectUid;

  String? get projectUid => _projectUid;

  String? _projectName;

  String? get projectName => _projectName;

  String? _projectContent;

  String? get projectContent => _projectContent;

  // =========================================================
  // ERROR
  // =========================================================

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  // =========================================================
  // SIZE -> PROJECT NAME
  // =========================================================

  String getProjectNameFromSize(String size) {
    switch (size) {
      case "Post Square (1:1)":
        return "Post Square";

      case "Post Portrait (4:5)":
        return "Post Portrait";

      case "Story / Reel (9:16)":
        return "Story";

      case "Post Horizontal (16:9)":
        return "Post Horizontal";

      default:
        return "Post Square";
    }
  }

  // =========================================================
  // CREATE PROJECT
  // =========================================================

  Future<bool> createProject({String? name, String? content}) async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      // -------------------------------------------------------
      // NAME
      // -------------------------------------------------------

      final String finalName = name??'';

      // -------------------------------------------------------
      // CONTENT
      // -------------------------------------------------------

      final String finalContent = content?.trim().isNotEmpty == true
          ? content!.trim()
          : "{}";

      debugPrint("========================================");
      debugPrint("📁 CREATE PROJECT");
      debugPrint("Name    : $finalName");
      debugPrint("Content : $finalContent");
      debugPrint("========================================");

      // -------------------------------------------------------
      // API
      // -------------------------------------------------------

      final result = await repository.createProject(
        name: finalName,
        content: finalContent,
      );

      bool success = false;

      result.when(
        success: (data) {
          success = true;

          debugPrint("✅ PROJECT CREATE SUCCESS");

          debugPrint("Response: $data");

          // ---------------------------------------------------
          // RESPONSE
          //
          // {
          //   "success": true,
          //   "data": {
          //     "id": 53,
          //     "name": "Post Square",
          //     "content": "{}",
          //     "uid": "...",
          //     ...
          //   }
          // }
          // ---------------------------------------------------

          if (data is Map<String, dynamic>) {
            final projectData = data["data"];

            if (projectData is Map<String, dynamic>) {
              _projectId = int.tryParse(projectData["id"]?.toString() ?? "");

              _projectUid = projectData["uid"]?.toString();

              _projectName = projectData["name"]?.toString();

              _projectContent = projectData["content"]?.toString();

              debugPrint("Project ID      : $_projectId");

              debugPrint("Project UID     : $_projectUid");

              debugPrint("Project Name    : $_projectName");

              debugPrint("Project Content : $_projectContent");
            }
          }
        },
        failure: (error) {
          success = false;

          _errorMessage = error.message;

          debugPrint("❌ PROJECT CREATE FAILED");

          debugPrint("Error: ${error.message}");
        },
      );

      return success;
    } catch (e, stackTrace) {
      _errorMessage = e.toString();

      debugPrint("❌ PROJECT CREATE EXCEPTION");

      debugPrint("Error: $e");

      debugPrint(stackTrace.toString());

      return false;
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // =========================================================
  // CLEAR
  // =========================================================

  void clearProject() {
    _projectId = null;
    _projectUid = null;
    _projectName = null;
    _projectContent = null;
    _errorMessage = null;

    notifyListeners();
  }
}
