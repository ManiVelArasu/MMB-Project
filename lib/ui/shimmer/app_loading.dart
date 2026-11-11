import 'package:flutter/material.dart';

// ============================================================================
// Common loading widgets. Use these on every screen:
//
//   * First time the screen opens  -> shimmer (wave) placeholder
//   * Refresh / filter / upload    -> screen stays, normal loader on top
//
// Usage in a screen:
//
//   AppLoadingView(
//     isInitialLoading: provider.isInitialLoading,
//     isRefreshing: provider.isRefreshing,
//     skeleton: const AppShimmerGrid(),      // or AppShimmerList()
//     child: yourRealContent,
//   )
//
// Usage in a provider:
//
//   class MyProvider extends ChangeNotifier with LoadStateMixin {
//     Future<void> load({bool showOverlayLoader = true}) => runLoad(() async {
//       final res = await repo.call();
//       if (res.data == null) return false;
//       _data = res.data;
//       return true;
//     }, showOverlayLoader: showOverlayLoader);
//   }
// ============================================================================

/// State helper for providers: tells the screen whether this is the first load
/// (show shimmer) or a refresh (keep screen + show loader).
mixin LoadStateMixin on ChangeNotifier {
  bool isLoading = false;

  bool _hasLoadedOnce = false;
  bool _showOverlayLoader = true;
  bool _disposed = false;

  bool get hasLoadedOnce => _hasLoadedOnce;

  /// First load, nothing to show yet -> shimmer.
  bool get isInitialLoading => isLoading && !_hasLoadedOnce;

  /// Refresh / filter, data already on screen -> loader on top of the screen.
  /// Pull-to-refresh should call with `showOverlayLoader: false` because the
  /// RefreshIndicator already shows its own spinner.
  bool get isRefreshing => isLoading && _hasLoadedOnce && _showOverlayLoader;

  /// Runs [task]. Return true from it when data was loaded successfully.
  Future<void> runLoad(
      Future<bool> Function() task, {
        bool showOverlayLoader = true,
      }) async {
    _showOverlayLoader = showOverlayLoader;
    isLoading = true;
    notifyListeners();

    try {
      final loaded = await task();
      if (loaded) _hasLoadedOnce = true;
    } catch (e) {
      debugPrint('$runtimeType load error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // The user can leave the screen while a request is still running.
  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Shows [skeleton] on the first load, otherwise [child], with a normal loader
/// drawn on top of [child] while [isRefreshing] is true.
class AppLoadingView extends StatelessWidget {
  final bool isInitialLoading;
  final bool isRefreshing;
  final Widget skeleton;
  final Widget child;
  final bool? isDark;

  const AppLoadingView({
    super.key,
    required this.isInitialLoading,
    required this.isRefreshing,
    required this.skeleton,
    required this.child,
    this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (isInitialLoading) return skeleton;

    final dark = isDark ?? Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (isRefreshing)
          Positioned.fill(
            // Block taps until loading finishes.
            child: AbsorbPointer(
              child: Container(
                alignment: Alignment.center,
                color: (dark ? Colors.black : Colors.white).withValues(
                  alpha: 0.35,
                ),
                child: const CircularProgressIndicator(
                  color: Color(0xFFE53935),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Wave (shimmer) animation over its [child]. The child's shapes should be
/// opaque (see [ShimmerBox]); only their silhouette is used.
class AppShimmer extends StatefulWidget {
  final Widget child;
  final bool? isDark;
  final Duration period;

  const AppShimmer({
    super.key,
    required this.child,
    this.isDark,
    this.period = const Duration(milliseconds: 1400),
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark =
        widget.isDark ?? Theme.of(context).brightness == Brightness.dark;
    final base = dark ? const Color(0xFF2A2A2A) : const Color(0xFFE6E6E6);
    final highlight = dark ? const Color(0xFF3C3C3C) : const Color(0xFFF6F6F6);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: const Alignment(-1.0, -0.3),
                end: const Alignment(1.0, 0.3),
                colors: [base, highlight, base],
                stops: const [0.35, 0.5, 0.65],
                transform: _SlidingGradientTransform(
                  -1.0 + 2.0 * _controller.value,
                ),
              ).createShader(bounds);
            },
            child: child,
          );
        },
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

/// Opaque placeholder shape, to be used inside [AppShimmer].
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double radius;

  const ShimmerBox({super.key, this.width, this.height, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Shimmer placeholder for grid screens (template / download lists).
class AppShimmerGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsetsGeometry padding;
  final bool? isDark;

  const AppShimmerGrid({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.78,
    this.crossAxisSpacing = 12,
    this.mainAxisSpacing = 14,
    this.padding = const EdgeInsets.all(12),
    this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      isDark: isDark,
      child: GridView.builder(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        itemBuilder: (_, __) => const ShimmerBox(radius: 14),
      ),
    );
  }
}

/// Shimmer placeholder for list screens (thumbnail + two text lines).
class AppShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry padding;
  final bool? isDark;

  const AppShimmerList({
    super.key,
    this.itemCount = 8,
    this.itemHeight = 72,
    this.padding = const EdgeInsets.all(12),
    this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      isDark: isDark,
      child: ListView.separated(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => SizedBox(
          height: itemHeight,
          child: Row(
            children: [
              ShimmerBox(width: itemHeight, height: itemHeight, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(height: 14, radius: 6),
                    SizedBox(height: 10),
                    ShimmerBox(width: 120, height: 12, radius: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}