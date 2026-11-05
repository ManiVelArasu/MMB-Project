import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../Repository/search_repository.dart';

class SearchSuggestion {
  SearchSuggestion({
    required this.type,
    required this.label,
    required this.query,
  });

  final String type;
  final String label;
  final String query;

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    final label = json['label']?.toString() ?? '';
    return SearchSuggestion(
      type: json['type']?.toString() ?? '',
      label: label,
      query: json['query']?.toString() ?? label,
    );
  }
}

class SearchProvider extends ChangeNotifier {
  static const int pageSize = 30;
  static const int maxQueryLength = 100;

  final SearchProfileRepository _repository = SearchProfileRepository.instance;

  Timer? _debounce;
  bool _disposed = false;

  // ---------------- state ----------------
  List<SearchSuggestion> _suggestions = [];
  List<SearchSuggestion> get suggestions => _suggestions;

  List<Map<String, dynamic>> _results = [];
  List<Map<String, dynamic>> get results => _results;

  bool _isLoading = false; // first page
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _hasMore = false;
  bool get hasMore => _hasMore;

  bool _hasSearched = false;
  bool get hasSearched => _hasSearched;

  String? _error;
  String? get error => _error;

  String _activeQuery = '';
  String get activeQuery => _activeQuery;

  // Latest typed text, used to ignore stale suggestion responses.
  String _typed = '';

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }

  // ---------------- typing ----------------

  void onTextChanged(String text) {
    final q = text.trim();
    _typed = q;
    _debounce?.cancel();

    if (q.isEmpty) {
      clear();
      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 250),
      () => _loadSuggestions(q),
    );
  }

  Future<void> _loadSuggestions(String q) async {
    try {
      final result = await _repository.suggestions(q);

      // Stale response → ignore
      if (q != _typed) return;

      if (result.isSuccess && result.data is Map) {
        final data = (result.data as Map)['data'];
        _suggestions = data is List
            ? data
                  .whereType<Map>()
                  .map(
                    (e) =>
                        SearchSuggestion.fromJson(Map<String, dynamic>.from(e)),
                  )
                  .where((s) => s.label.isNotEmpty)
                  .toList()
            : [];
      } else {
        _suggestions = [];
      }
    } catch (e) {
      debugPrint('❌ Suggestions error: $e');
      if (q != _typed) return;
      _suggestions = [];
    }
    notifyListeners();
  }

  void clearSuggestions() {
    _debounce?.cancel();
    _suggestions = [];
    notifyListeners();
  }

  /// Clear Search: reset everything. No API call is made.
  /// _activeQuery is reset too, so any in-flight response is ignored.
  void clear() {
    _debounce?.cancel();
    _typed = '';
    _activeQuery = '';
    _suggestions = [];
    _results = [];
    _error = null;
    _hasSearched = false;
    _hasMore = false;
    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }

  // ---------------- search ----------------

  /// Enter / search button / suggestion tap.
  Future<void> search(String text) async {
    final q = text.trim();
    if (q.length < 2) return; // API needs 2–100 chars

    _debounce?.cancel();
    _typed = q;
    _activeQuery = q.length > maxQueryLength
        ? q.substring(0, maxQueryLength)
        : q;
    _suggestions = [];
    _hasSearched = true;
    _isLoading = true;
    _isLoadingMore = false;
    _hasMore = false;
    _error = null;
    _results = [];
    notifyListeners();

    final query = _activeQuery;

    try {
      final result = await _repository.search(
        query,
        limit: pageSize,
        offset: 0,
      );
      if (query != _activeQuery) return;

      if (result.isSuccess) {
        final page = _parseCards(result.data);
        _results = page;
        _hasMore = page.length >= pageSize;
      } else {
        _error = result.error?.message ?? 'Search failed';
      }
    } catch (e) {
      debugPrint('❌ Search error: $e');
      if (query != _activeQuery) return;
      _error = 'Search failed. Please try again.';
    } finally {
      if (query == _activeQuery) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore || _activeQuery.isEmpty) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    final query = _activeQuery;

    try {
      final result = await _repository.search(
        query,
        limit: pageSize,
        offset: _results.length,
      );
      if (query != _activeQuery) return;

      if (result.isSuccess) {
        final page = _parseCards(result.data);
        _results = [..._results, ...page];
        _hasMore = page.length >= pageSize;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('❌ Load more error: $e');
      _hasMore = false;
    } finally {
      if (query == _activeQuery) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  List<Map<String, dynamic>> _parseCards(dynamic json) {
    final data = json is Map ? json['data'] : json;
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
