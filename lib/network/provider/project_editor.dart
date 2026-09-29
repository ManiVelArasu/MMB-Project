import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../Repository/project.dart';
import 'editor_provider.dart';

/// Connects EditorProvider changes to PATCH /project/{projectUid}.
///
/// EditorProvider already calls notifyListeners() for canvas/background/text/
/// image/shape changes. This listener therefore catches all those changes
/// without adding API calls to every individual editor action.
class ProjectEditorAutoSave extends ChangeNotifier {
  ProjectEditorAutoSave({
    required EditorProvider editorProvider,
    required String projectUid,
    this.projectName,
    this.debounceDuration = const Duration(milliseconds: 500),
  }) : _editorProvider = editorProvider,
       _projectUid = projectUid.trim() {
    _editorProvider.addListener(_onEditorChanged);
  }

  final EditorProvider _editorProvider;
  final String _projectUid;
  final String? projectName;
  final Duration debounceDuration;
  final ProjectRepository _repository = ProjectRepository.instance;

  Timer? _debounceTimer;
  bool _disposed = false;
  bool _saving = false;
  bool _pending = false;
  String? _lastSavedContent;
  String? _lastFailedContent;
  String? _errorMessage;
  String _status = 'saved';

  bool get isSaving => _saving;
  bool get hasPendingChanges => _pending;
  String get status => _status;
  String? get errorMessage => _errorMessage;

  void _onEditorChanged() {
    if (_disposed || _projectUid.isEmpty) return;

    // Ignore editor notifications while the initial template is being loaded.
    if (!_editorProvider.isTemplateLoaded) return;

    _pending = true;
    _errorMessage = null;
    _status = 'saving';
    notifyListeners();

    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () {
      _saveLatest();
    });
  }

  String _serialize() {
    return jsonEncode(_editorProvider.exportCurrentPageJson());
  }

  Future<void> _saveLatest() async {
    if (_disposed || _projectUid.isEmpty) return;
    if (_saving) return;
    if (!_pending) return;

    final content = _serialize();

    if (content == _lastSavedContent) {
      _pending = false;
      _status = 'saved';
      notifyListeners();
      return;
    }

    _saving = true;
    _status = 'saving';
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.updateProject(
        projectUid: _projectUid,
        content: content,
        name: projectName??'',
      );

      result.when(
        success: (_) {
          _lastSavedContent = content;
          _lastFailedContent = null;
          _pending = false;
          _errorMessage = null;
          _status = 'saved';
        },
        failure: (error) {
          _lastFailedContent = content;
          _errorMessage = error.message;
          _pending = true;
          _status = 'error';
        },
      );
    } catch (e, stackTrace) {
      debugPrint('Project auto-save failed: $e');
      debugPrint('$stackTrace');
      _lastFailedContent = content;
      _errorMessage = e.toString();
      _pending = true;
      _status = 'error';
    } finally {
      _saving = false;
      notifyListeners();

      // If another editor change happened while PATCH was in flight, save
      // the newest content after the same debounce interval. Never overlap
      // PATCH requests.
      if (!_disposed && _pending) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(debounceDuration, _saveLatest);
      }
    }
  }

  /// Call this before leaving the editor. It waits for the current debounce
  /// period and then waits for the PATCH request to finish.
  Future<void> flush() async {
    if (_disposed || _projectUid.isEmpty) return;

    _debounceTimer?.cancel();

    if (_pending && !_saving) {
      await _saveLatest();
    }

    // _saveLatest may have been followed by a change while the request was
    // running. Give that request a chance to finish, without overlapping.
    while (_saving) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    if (_pending && !_disposed) {
      await _saveLatest();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    _editorProvider.removeListener(_onEditorChanged);
    super.dispose();
  }
}
