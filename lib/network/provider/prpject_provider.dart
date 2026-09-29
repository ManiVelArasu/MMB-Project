import 'package:flutter/foundation.dart' hide Uint8List;
import '../../Api Model/project_list.dart';
import '../../Repository/project.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../core/api/api_endpoints.dart';

class ProjectProvider extends ChangeNotifier {
  final ProjectRepository repository = ProjectRepository.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int? _projectId;
  int? get projectId => _projectId;

  String? _projectUid;
  String? get projectUid => _projectUid;

  String? _projectName;
  String? get projectName => _projectName;

  String? _lastSavedContent;
  String? get lastSavedContent => _lastSavedContent;
  bool _isExporting = false;
  String? _exportError;
  String? _exportUrl;
  String? _exportS3Key;

  bool get isExporting => _isExporting;

  String? get exportError => _exportError;

  String? get exportUrl => _exportUrl;

  String? get exportS3Key => _exportS3Key;

  bool _isLoadingPlans = false;
  bool get isLoadingPlans => _isLoadingPlans;

  ProjectList? _plansData;
  ProjectList? get plansData => _plansData;

  String? _thumbnailS3Key;
  String? get thumbnailS3Key => _thumbnailS3Key;

  Future<void> fetchProject() async {
    print('asdsadsadsad');
    _isLoadingPlans = true;
    _errorMessage = null;

    notifyListeners();

    try {
      debugPrint('========================================');
      debugPrint('📂 GET PROJECT LIST');
      debugPrint('Endpoint: ${ApiEndpoints.project}');
      debugPrint('========================================');

      final result = await repository.getProject();

      if (result.isSuccess && result.data != null) {
        _plansData = result.data;

        debugPrint('✅ PROJECT LIST SUCCESS');
        debugPrint('Project count: ${_plansData!.data.length}');

        for (final project in _plansData!.data) {
          debugPrint(
            'Project: uid=${project.uid}, '
                'name=${project.name}, '
                'thumbnail=${project.thumbnailS3Key}',
          );
        }
      } else {
        _errorMessage = result.error?.message ?? 'Unable to load projects';

        debugPrint('❌ PROJECT LIST FAILED');
        debugPrint(_errorMessage);
      }
    } catch (e, stackTrace) {
      _errorMessage = e.toString();

      debugPrint('❌ PROJECT LIST EXCEPTION: $e');
      debugPrint(stackTrace.toString());
    } finally {
      _isLoadingPlans = false;
      notifyListeners();
    }
  }

  Future<String?> exportProject({
    required String projectUid,
  }) async {
    if (projectUid.trim().isEmpty) {
      _exportError = 'Project UID not available';
      notifyListeners();
      return null;
    }

    _isExporting = true;
    _exportError = null;
    notifyListeners();

    try {
      debugPrint('================================');
      debugPrint('📥 PROJECT EXPORT');
      debugPrint('Project UID: $projectUid');
      debugPrint('Thumbnail S3 Key: $_thumbnailS3Key');
      debugPrint('================================');

      final result = await repository.exportProject(
        projectUid: projectUid,
        s3Key: _thumbnailS3Key??'',
      );

      if (result.isFailure) {
        _exportError =
            result.error?.message ?? 'Export failed';
        return null;
      }

      final response = result.data;

      debugPrint('📦 EXPORT RESPONSE: $response');

      if (response == null) {
        _exportError = 'Empty export response';
        return null;
      }

      final data = response['data'];

      if (data is! Map) {
        _exportError = 'Invalid export response';
        return null;
      }

      final returnedS3Key =
      data['s3_key']?.toString().trim();

      // Backend generated key
      if (returnedS3Key != null &&
          returnedS3Key.isNotEmpty &&
          returnedS3Key != 'null') {
        _thumbnailS3Key = returnedS3Key;

        final fileUrl =
            '${ApiEndpoints.cdnImageUrl}/${returnedS3Key.replaceFirst('/', '')}';

        debugPrint('✅ EXPORT S3 KEY: $returnedS3Key');
        debugPrint('✅ EXPORT URL: $fileUrl');

        return fileUrl;
      }

      // Backend says success but doesn't return s3_key.
      // Don't show "Thumbnail S3 key not available".
      if (data['status']?.toString() == 'success') {
        debugPrint(
          '✅ Export request succeeded, but backend did not return s3_key.',
        );

        return null;
      }

      _exportError = 'Export failed';
      return null;
    } catch (e, stackTrace) {
      _exportError = e.toString();

      debugPrint('❌ Export exception: $e');
      debugPrint(stackTrace.toString());

      return null;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }
  Future<bool> createProject({
    required String name,
    required String content,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.createProject(
        name: name,
        content: content,
      );

      var success = false;
      result.when(
        success: (data) {
          success = true;
          _readProjectData(data, fallbackName: name);
        },
        failure: (error) {
          _errorMessage = error.message;
        },
      );
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProject({
    required String content,
    String? name,
  }) async {
    final uid = _projectUid?.trim() ?? '';

    if (uid.isEmpty) {
      _errorMessage = 'Project UID not available';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.updateProject(
        projectUid: uid,
        name: (name ?? _projectName ?? 'Untitled design').trim(),
        content: content,
      );

      var success = false;

      result.when(
        success: (data) {
          success = true;

          debugPrint('================================');
          debugPrint('✅ PROJECT PATCH SUCCESS');
          debugPrint('PATCH RESPONSE: $data');
          debugPrint('================================');

          _lastSavedContent = content;

          // IMPORTANT
          _readProjectData(
            data,
            fallbackName: name,
          );

          debugPrint(
            '🖼️ SAVED THUMBNAIL KEY: $_thumbnailS3Key',
          );
        },
        failure: (error) {
          _errorMessage = error.message;

          debugPrint(
            '❌ PROJECT PATCH FAILED: ${error.message}',
          );
        },
      );

      return success;
    } catch (e, stackTrace) {
      _errorMessage = e.toString();

      debugPrint('❌ PATCH EXCEPTION: $e');
      debugPrint(stackTrace.toString());

      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void _readProjectData(
      dynamic response, {
        String? fallbackName,
      }) {
    try {
      if (response is! Map) {
        return;
      }

      final rawData = response['data'];

      final Map data;

      if (rawData is Map) {
        data = rawData;
      } else {
        data = response;
      }

      _projectUid =
          data['uid']?.toString() ?? _projectUid;

      _projectName =
          data['name']?.toString() ??
              fallbackName ??
              _projectName;

      final thumbnailKey =
      data['thumbnail_s3_key']?.toString().trim();

      if (thumbnailKey != null &&
          thumbnailKey.isNotEmpty &&
          thumbnailKey != 'null') {
        _thumbnailS3Key = thumbnailKey;

        debugPrint(
          '✅ THUMBNAIL S3 KEY UPDATED: $_thumbnailS3Key',
        );
      } else {
        debugPrint(
          '⚠️ PATCH response has no thumbnail_s3_key',
        );
      }

      final id = data['id'];

      _projectId = id is int
          ? id
          : int.tryParse(
        id?.toString() ?? '',
      );
    } catch (e) {
      debugPrint(
        '❌ _readProjectData error: $e',
      );

      _projectName ??= fallbackName;
    }
  }
}
