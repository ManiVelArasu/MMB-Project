import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../Repository/home_repository.dart';

/// App-wide favorite state, keyed by template `familyUid`.
/// Any screen can read / toggle it, so the heart stays in sync everywhere.
class FavoriteProvider extends ChangeNotifier {
  final Map<String, bool> _favourited = {};
  final Map<String, int> _likes = {};
  final Set<String> _busy = {};

  bool isFavorite(String? id) => _favourited[id] ?? false;
  int likesCount(String? id) => _likes[id] ?? 0;

  /// Stores a server value the first time an id is seen.
  /// Never overwrites a value the user has already toggled.
  void seed(String? id, {bool? favourited, int? likesCount}) {
    if (id == null || id.isEmpty) return;
    if (favourited != null) _favourited.putIfAbsent(id, () => favourited);
    if (likesCount != null) _likes.putIfAbsent(id, () => likesCount);
  }

  /// Optimistic toggle.
  /// Sends: favorite   -> favourited: true,  likes_count: 1
  ///        unfavorite -> favourited: false, likes_count: 0
  /// Returns false only when the API call failed (UI is reverted).
  Future<bool> toggle(String? id) async {
    if (id == null || id.isEmpty || _busy.contains(id)) {
      return false;
    }

    final prevFav = isFavorite(id);
    final prevLikes = likesCount(id);

    // Favorite true -> false
    // Favorite false -> true
    final newFav = !prevFav;

    // API count
    final int apiLikesCount = newFav ? 1 : 0;

    _busy.add(id);

    // Optimistic UI update
    _favourited[id] = newFav;
    _likes[id] = newFav
        ? prevLikes + 1
        : max(0, prevLikes - 1);

    notifyListeners();

    var success = false;

    try {
      final res = await HomeRepository.instance.favorite(
        id,
        favourited: newFav,
        likesCount: apiLikesCount,
      );

      success = res.isSuccess;

      if (success) {
        final body = _bodyOf(res);

        if (body != null) {
          if (body['favourited'] is bool) {
            _favourited[id] = body['favourited'] as bool;
          }

          if (body['likes_count'] is num) {
            _likes[id] =
                (body['likes_count'] as num).toInt();
          }
        }
      }
    } catch (e) {
      debugPrint('Favorite error: $e');
    }

    if (!success) {
      _favourited[id] = prevFav;
      _likes[id] = prevLikes;
    }

    _busy.remove(id);
    notifyListeners();

    return success;
  }

  /// Pulls the map out of the response, whether it is wrapped in
  /// `.data` / `data` or not.
  Map<String, dynamic>? _bodyOf(dynamic res) {
    dynamic d = res;
    try {
      d = res.data;
    } catch (_) {}
    if (d is Map && d['data'] is Map) d = d['data'];
    return d is Map ? Map<String, dynamic>.from(d) : null;
  }
}