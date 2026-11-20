import 'dart:async';

import 'package:flutter/material.dart';

import '../../Api Model/key_words_model.dart';
import '../../Repository/business_profile_repository.dart';
import '../../Repository/search_repository.dart';
import 'common_provider.dart';

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

/// One entry of a filter dropdown. [value] is what goes into the API.
class SearchFilterOption {
  const SearchFilterOption({
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final String? value;
  final String? trailing;
}

class SearchProvider extends ChangeNotifier {
  SearchProvider({String initialQuery = ''}) {
    controller = TextEditingController(text: initialQuery);
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );

    _firstLoad = initialQuery.trim().length >= 2;

    scrollController.addListener(_onScroll);
    _loadKeywords();

    final initial = initialQuery.trim();
    if (initial.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_disposed) return;
        if (initial.length >= 2) {
          search(initial);
        } else {
          onTextChanged(initial);
        }
      });
    }
  }

  static const int pageSize = 30;
  static const int maxQueryLength = 100;

  final SearchProfileRepository _repository =
      SearchProfileRepository.instance;

  late final TextEditingController controller;
  final FocusNode focusNode = FocusNode();
  final ScrollController scrollController = ScrollController();

  Timer? _debounce;
  bool _disposed = false;
  bool _firstLoad = false;
  int _requestSeq = 0;

  List<SearchSuggestion> _suggestions = [];
  List<SearchSuggestion> get suggestions => _suggestions;

  List<Map<String, dynamic>> _results = [];
  List<Map<String, dynamic>> get results => _results;

  bool _isLoading = false;
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

  String _typed = '';

  bool get isWaitingForFirstResult =>
      _firstLoad && !_hasSearched && _error == null;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    controller.dispose();
    focusNode.dispose();
    scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // FILTERS  ->  templates?q=..&tags=..&template_type=..&language=..&size=..
  // ---------------------------------------------------------------------

  static const List<SearchFilterOption> postTypeOptions = [
    SearchFilterOption(label: 'Images', value: 'image'),
    SearchFilterOption(label: 'Videos', value: 'video'),
  ];

  static const List<SearchFilterOption> languageOptions = [
    SearchFilterOption(label: 'English', value: 'en'),
    SearchFilterOption(label: 'Hindi', value: 'hi', trailing: 'हिन्दी'),
    SearchFilterOption(label: 'Malayalam', value: 'ml', trailing: 'മലയാളം'),
  ];

  // Only 'youtube-thumbnail' is a confirmed slug; check the others against
  // the backend (or load this list from your sizes API).
  static const List<SearchFilterOption> sizeOptions = [
    SearchFilterOption(
      label: 'Instagram Post Portrait',
      value: 'instagram-post-portrait',
      trailing: '1080 × 1350',
    ),
    SearchFilterOption(
      label: 'Instagram Story',
      value: 'instagram-story',
      trailing: '1080 × 1920',
    ),
    SearchFilterOption(
      label: 'YouTube Shorts Thumbnail',
      value: 'youtube-shorts-thumbnail',
      trailing: '1080 × 1920',
    ),
    SearchFilterOption(
      label: 'YouTube Thumbnail',
      value: 'youtube-thumbnail',
      trailing: '1280 × 720',
    ),
  ];

  List<SearchFilterOption> _tagOptions = [];
  List<SearchFilterOption> get tagOptions => _tagOptions;

  String? _tag;
  static const String defaultTemplateType = 'image';
  String? _templateType = defaultTemplateType;
  String? _language;
  String? _size;

  String? get tag => _tag;
  String? get templateType => _templateType;
  String? get language => _language;
  String? get size => _size;

  /// IMAGE is the default post type, so it does not count as a filter.
  bool get hasActiveFilters =>
      _tag != null ||
          _templateType != defaultTemplateType ||
          _language != null ||
          _size != null;

  void setTag(String? value) {
    if (_tag == value) return;
    _applyFilter(() => _tag = value);
  }

  void setTemplateType(String? value) {
    if (_templateType == value) return;
    _applyFilter(() => _templateType = value);
  }

  void setLanguage(String? value) {
    if (_language == value) return;
    _applyFilter(() => _language = value);
  }

  void setSize(String? value) {
    if (_size == value) return;
    _applyFilter(() => _size = value);
  }

  void clearFilters() {
    if (!hasActiveFilters) return;
    _applyFilter(() {
      _tag = null;
      _templateType = defaultTemplateType;
      _language = null;
      _size = null;
    });
  }

  /// A filter change re-runs the current search from page 1.
  void _applyFilter(VoidCallback change) {
    change();
    notifyListeners();
    if (_activeQuery.isNotEmpty) search(_activeQuery);
  }

  /// Same keywords API the business profile uses (business accounts only).
  Future<void> _loadKeywords() async {
    try {
      final common = CommonProvider.instance;
      if (common.accountType?.toLowerCase() != 'business') return;

      final categorySlug =
          common.business?.businessCategory?.parent?.slug ?? '';
      if (categorySlug.isEmpty) return;

      final result = await BusinessProfileRepository.instance
          .industryKeyWords(categorySlug);
      if (_disposed) return;

      final KeyWordsModel? data = result.data;
      if (data == null) return;

      _tagOptions = data.data
          .map(
            (k) => SearchFilterOption(
          label: '${k.name}'.trim(),
          value: '${k.slug}'.trim(),
        ),
      )
          .where(
            (o) =>
        o.label.isNotEmpty &&
            o.label != 'null' &&
            (o.value ?? '').isNotEmpty &&
            o.value != 'null',
      )
          .toList();
      notifyListeners();
    } catch (error) {
      debugPrint('Search keywords error: $error');
    }
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;

    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 300) {
      loadMore();
    }
  }

  void onTextChanged(String text) {
    final query = text.trim();
    _firstLoad = false;
    _typed = query;
    _debounce?.cancel();

    if (query.isEmpty) {
      clear();
      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 250),
          () => _loadSuggestions(query),
    );
  }

  Future<void> _loadSuggestions(String query) async {
    try {
      final result = await _repository.suggestions(query);

      if (_disposed || query != _typed) return;

      if (result.isSuccess && result.data is Map) {
        final data = (result.data as Map)['data'];
        _suggestions = data is List
            ? data
            .whereType<Map>()
            .map(
              (item) => SearchSuggestion.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
            .where((item) => item.label.isNotEmpty)
            .toList()
            : [];
      } else {
        _suggestions = [];
      }
    } catch (error) {
      debugPrint('Suggestions error: $error');
      if (_disposed || query != _typed) return;
      _suggestions = [];
    }

    notifyListeners();
  }

  void clearSuggestions() {
    _debounce?.cancel();
    _suggestions = [];
    notifyListeners();
  }

  void clearSearch() {
    controller.clear();
    focusNode.requestFocus();
    clear();
  }

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
    _firstLoad = false;
    notifyListeners();
  }

  void pickSuggestion(SearchSuggestion suggestion) {
    controller.text = suggestion.query;
    controller.selection = TextSelection.collapsed(
      offset: suggestion.query.length,
    );
    submit(suggestion.query);
  }

  void submit(String text) {
    final query = text.trim();
    if (query.length < 2) return;
    focusNode.unfocus();
    search(query);
  }

  void retry() {
    if (_activeQuery.isNotEmpty) {
      search(_activeQuery);
    }
  }

  Future<void> search(String text) async {
    final queryText = text.trim();
    if (queryText.length < 2) return;

    _debounce?.cancel();
    _typed = queryText;
    _activeQuery = queryText.length > maxQueryLength
        ? queryText.substring(0, maxQueryLength)
        : queryText;

    _suggestions = [];
    _hasSearched = true;
    _isLoading = true;
    _isLoadingMore = false;
    _hasMore = false;
    _error = null;
    _results = [];
    _firstLoad = false;
    final requestId = ++_requestSeq;
    notifyListeners();

    final query = _activeQuery;

    try {
      final result = await _repository.search(
        query,
        limit: pageSize,
        offset: 0,
        tags: _tag,
        templateType: _templateType,
        language: _language,
        size: _size,
      );

      if (_disposed || requestId != _requestSeq) return;

      if (result.isSuccess) {
        final page = _parseCards(result.data);
        _results = page;
        _hasMore = page.length >= pageSize;
      } else {
        _error = result.error?.message ?? 'Search failed';
      }
    } catch (error) {
      debugPrint('Search error: $error');
      if (_disposed || requestId != _requestSeq) return;
      _error = 'Search failed. Please try again.';
    } finally {
      if (!_disposed && requestId == _requestSeq) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_isLoading ||
        _isLoadingMore ||
        !_hasMore ||
        _activeQuery.isEmpty) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    final query = _activeQuery;
    final requestId = _requestSeq;

    try {
      final result = await _repository.search(
        query,
        limit: pageSize,
        offset: _results.length,
        tags: _tag,
        templateType: _templateType,
        language: _language,
        size: _size,
      );

      if (_disposed || requestId != _requestSeq) return;

      if (result.isSuccess) {
        final page = _parseCards(result.data);
        _results = [..._results, ...page];
        _hasMore = page.length >= pageSize;
      } else {
        _hasMore = false;
      }
    } catch (error) {
      debugPrint('Load more error: $error');
      if (_disposed || requestId != _requestSeq) return;
      _hasMore = false;
    } finally {
      if (!_disposed && requestId == _requestSeq) {
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
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}