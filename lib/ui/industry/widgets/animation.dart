import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Length of the exported MP4 / GIF.
const int kExportDurationMs = 6000;

/// When non-null the export renderer is driving time: every animated item
/// renders the frame for this timestamp (ms) instead of its own preview clock.
final ValueNotifier<double?> kExportClockMs = ValueNotifier<double?>(null);

/// Animation effects an editor item (text / image / shape) can have.
enum ItemAnimationType {
  none,
  move,
  fade,
  scale,
  zoom,
  wobble,
  flash,
  shake,
  spin,
}

/// Which part of the timeline the effect plays on.
enum ItemAnimationMode { both, entrance, exit }

/// Direction used by the Move animation.
enum ItemAnimDirection {
  left,
  right,
  top,
  bottom,
  topRight,
  topLeft,
  bottomLeft,
  bottomRight,
}

/// Axis used by Shake / Spin.
enum ItemAnimAxis { horizontal, vertical }

extension ItemAnimDirectionX on ItemAnimDirection {
  String get label => switch (this) {
    ItemAnimDirection.left => 'From Left',
    ItemAnimDirection.right => 'From Right',
    ItemAnimDirection.top => 'From Top',
    ItemAnimDirection.bottom => 'From Bottom',
    ItemAnimDirection.topRight => 'From Top Right',
    ItemAnimDirection.topLeft => 'From Top Left',
    ItemAnimDirection.bottomLeft => 'From Bottom Left',
    ItemAnimDirection.bottomRight => 'From Bottom Right',
  };

  IconData get icon => switch (this) {
    ItemAnimDirection.left => Icons.arrow_forward,
    ItemAnimDirection.right => Icons.arrow_back,
    ItemAnimDirection.top => Icons.arrow_downward,
    ItemAnimDirection.bottom => Icons.arrow_upward,
    ItemAnimDirection.topRight => Icons.south_west,
    ItemAnimDirection.topLeft => Icons.south_east,
    ItemAnimDirection.bottomLeft => Icons.north_east,
    ItemAnimDirection.bottomRight => Icons.north_west,
  };

  /// Unit vector the item starts from (relative to its rest position).
  Offset get startVector => switch (this) {
    ItemAnimDirection.left => const Offset(-1, 0),
    ItemAnimDirection.right => const Offset(1, 0),
    ItemAnimDirection.top => const Offset(0, -1),
    ItemAnimDirection.bottom => const Offset(0, 1),
    ItemAnimDirection.topRight => const Offset(0.75, -0.75),
    ItemAnimDirection.topLeft => const Offset(-0.75, -0.75),
    ItemAnimDirection.bottomLeft => const Offset(-0.75, 0.75),
    ItemAnimDirection.bottomRight => const Offset(0.75, 0.75),
  };
}

extension ItemAnimAxisX on ItemAnimAxis {
  String get label =>
      this == ItemAnimAxis.horizontal ? 'HORIZONTAL' : 'VERTICAL';
  IconData get icon =>
      this == ItemAnimAxis.horizontal ? Icons.swap_horiz : Icons.swap_vert;
}

extension ItemAnimationTypeX on ItemAnimationType {
  bool get hasDirection => this == ItemAnimationType.move;
  bool get hasAxis =>
      this == ItemAnimationType.shake || this == ItemAnimationType.spin;

  String get label => switch (this) {
    ItemAnimationType.none => 'None',
    ItemAnimationType.move => 'Move',
    ItemAnimationType.fade => 'Fade',
    ItemAnimationType.scale => 'Scale',
    ItemAnimationType.zoom => 'Zoom',
    ItemAnimationType.wobble => 'Wobble',
    ItemAnimationType.flash => 'Flash',
    ItemAnimationType.shake => 'Shake',
    ItemAnimationType.spin => 'Spin',
  };

  IconData get icon => switch (this) {
    ItemAnimationType.none => Icons.block,
    ItemAnimationType.move => Icons.east,
    ItemAnimationType.fade => Icons.opacity,
    ItemAnimationType.scale => Icons.aspect_ratio,
    ItemAnimationType.zoom => Icons.zoom_in,
    ItemAnimationType.wobble => Icons.screen_rotation,
    ItemAnimationType.flash => Icons.flash_on,
    ItemAnimationType.shake => Icons.vibration,
    ItemAnimationType.spin => Icons.threed_rotation,
  };
}

extension ItemAnimationModeX on ItemAnimationMode {
  String get label => switch (this) {
    ItemAnimationMode.both => 'BOTH',
    ItemAnimationMode.entrance => 'ENTRANCE',
    ItemAnimationMode.exit => 'EXIT',
  };
}

@immutable
class ItemAnimation {
  final ItemAnimationType type;
  final ItemAnimationMode mode;
  final ItemAnimDirection direction;
  final ItemAnimAxis axis;

  /// Start delay in seconds (0 - 2.9).
  final double delay;

  const ItemAnimation({
    this.type = ItemAnimationType.none,
    this.mode = ItemAnimationMode.both,
    this.direction = ItemAnimDirection.left,
    this.axis = ItemAnimAxis.horizontal,
    this.delay = 0.0,
  });

  static const ItemAnimation empty = ItemAnimation();

  bool get isNone => type == ItemAnimationType.none;

  ItemAnimation copyWith({
    ItemAnimationType? type,
    ItemAnimationMode? mode,
    ItemAnimDirection? direction,
    ItemAnimAxis? axis,
    double? delay,
  }) {
    return ItemAnimation(
      type: type ?? this.type,
      mode: mode ?? this.mode,
      direction: direction ?? this.direction,
      axis: axis ?? this.axis,
      delay: delay ?? this.delay,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'mode': mode.name,
    'direction': direction.name,
    'axis': axis.name,
    'delay': delay,
  };

  factory ItemAnimation.fromJson(dynamic json) {
    if (json is! Map) return ItemAnimation.empty;
    final typeName = json['type']?.toString();
    final modeName = json['mode']?.toString();
    return ItemAnimation(
      type: ItemAnimationType.values.firstWhere(
            (e) => e.name == typeName,
        orElse: () => ItemAnimationType.none,
      ),
      mode: ItemAnimationMode.values.firstWhere(
            (e) => e.name == modeName,
        orElse: () => ItemAnimationMode.both,
      ),
      direction: ItemAnimDirection.values.firstWhere(
            (e) => e.name == json['direction']?.toString(),
        orElse: () => ItemAnimDirection.left,
      ),
      axis: ItemAnimAxis.values.firstWhere(
            (e) => e.name == json['axis']?.toString(),
        orElse: () => ItemAnimAxis.horizontal,
      ),
      delay: ((json['delay'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 2.9),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ItemAnimation &&
              other.type == type &&
              other.mode == mode &&
              other.direction == direction &&
              other.axis == axis &&
              other.delay == delay;

  @override
  int get hashCode => Object.hash(type, mode, direction, axis, delay);
}

/// Preview timeline.
///
/// `progress` is 0 when the item is "hidden / at the start pose" and 1 when
/// the item is at rest (how it normally looks on the canvas).
///  * entrance: progress goes 0 -> 1
///  * exit:     progress goes 1 -> 0
class ItemAnimationTimeline {
  static const int _effectMs = 900;
  static const int _holdMs = 600;
  static const int _tailMs = 300;

  static int baseMs(ItemAnimationMode mode) => switch (mode) {
    ItemAnimationMode.both => _effectMs + _holdMs + _effectMs + _tailMs,
    ItemAnimationMode.entrance => _effectMs + _tailMs,
    ItemAnimationMode.exit => 400 + _effectMs + _tailMs,
  };

  /// Total preview length including the start delay (seconds).
  static int totalMs(ItemAnimationMode mode, [double delaySeconds = 0]) =>
      baseMs(mode) + (delaySeconds * 1000).round();

  /// Video / GIF timeline: entrance starts after the delay, the item rests,
  /// and the exit (if any) finishes exactly at the end of the clip.
  static ({double progress, bool entering}) atExport(
      ItemAnimationMode mode,
      double tMs,
      double delayMs, {
        int totalMs = kExportDurationMs,
      }) {
    double entrance(double ms) =>
        Curves.easeOutCubic.transform((ms / _effectMs).clamp(0.0, 1.0));
    double exit(double ms) =>
        1 - Curves.easeInCubic.transform((ms / _effectMs).clamp(0.0, 1.0));

    final hasEntrance = mode != ItemAnimationMode.exit;
    final hasExit = mode != ItemAnimationMode.entrance;
    final exitStart = (totalMs - _effectMs).toDouble();
    final entranceEnd = delayMs + (hasEntrance ? _effectMs : 0);

    if (hasExit && tMs >= exitStart && tMs >= entranceEnd) {
      return (progress: exit(tMs - exitStart), entering: false);
    }
    if (hasEntrance) {
      return (progress: entrance(tMs - delayMs), entering: true);
    }
    return (progress: 1.0, entering: false);
  }

  /// Returns the progress (0..1, may be eased) and whether we are entering.
  static ({double progress, bool entering}) at(
      ItemAnimationMode mode,
      double elapsedMs,
      ) {
    double entrance(double ms) =>
        Curves.easeOutCubic.transform((ms / _effectMs).clamp(0.0, 1.0));
    double exit(double ms) =>
        1 - Curves.easeInCubic.transform((ms / _effectMs).clamp(0.0, 1.0));

    switch (mode) {
      case ItemAnimationMode.entrance:
        return (progress: entrance(elapsedMs), entering: true);
      case ItemAnimationMode.exit:
        if (elapsedMs < 400) return (progress: 1.0, entering: false);
        return (progress: exit(elapsedMs - 400), entering: false);
      case ItemAnimationMode.both:
        if (elapsedMs < _effectMs) {
          return (progress: entrance(elapsedMs), entering: true);
        }
        if (elapsedMs < _effectMs + _holdMs) {
          return (progress: 1.0, entering: true);
        }
        return (progress: exit(elapsedMs - _effectMs - _holdMs), entering: false);
    }
  }
}

/// Builds the matrix + opacity for one effect at [p] (0 hidden -> 1 rest).
({Matrix4 matrix, double opacity}) itemAnimationFrame(
    ItemAnimationType type,
    double p,
    bool entering, {
      ItemAnimDirection direction = ItemAnimDirection.left,
      ItemAnimAxis axis = ItemAnimAxis.horizontal,
    }) {
  final m = Matrix4.identity();
  var opacity = 1.0;
  final pc = p.clamp(0.0, 1.0).toDouble();

  switch (type) {
    case ItemAnimationType.none:
      break;
    case ItemAnimationType.move:
      final v = direction.startVector;
      m.translate(v.dx * (1 - p) * 420.0, v.dy * (1 - p) * 420.0);
      opacity = pc;
      break;
    case ItemAnimationType.fade:
      opacity = pc;
      break;
    case ItemAnimationType.scale:
      final s = entering ? Curves.easeOutBack.transform(pc) : pc;
      final v = math.max(0.0001, s);
      m.scale(v, v, 1.0);
      opacity = math.min(1.0, pc * 2);
      break;
    case ItemAnimationType.zoom:
      final v = 1 + (1 - pc) * 1.2;
      m.scale(v, v, 1.0);
      opacity = pc;
      break;
    case ItemAnimationType.wobble:
      m.rotateZ(math.sin(pc * math.pi * 5) * (1 - pc) * 0.35);
      opacity = math.min(1.0, pc * 3);
      break;
    case ItemAnimationType.flash:
      opacity = (0.5 + 0.5 * math.cos(pc * 6 * math.pi)) * math.min(1.0, pc * 4);
      break;
    case ItemAnimationType.shake:
      final shake = math.sin(pc * math.pi * 12) * 28.0 * (1 - pc);
      if (axis == ItemAnimAxis.horizontal) {
        m.translate(shake, 0.0);
      } else {
        m.translate(0.0, shake);
      }
      opacity = math.min(1.0, pc * 3);
      break;
    case ItemAnimationType.spin:
      m.setEntry(3, 2, 0.0012);
      final turn = (1 - pc) * math.pi * 2;
      if (axis == ItemAnimAxis.horizontal) {
        m.rotateY(turn);
      } else {
        m.rotateX(turn);
      }
      final v = 0.5 + 0.5 * pc;
      m.scale(v, v, 1.0);
      opacity = pc;
      break;
  }
  return (matrix: m, opacity: opacity.clamp(0.0, 1.0).toDouble());
}

/// Wraps a canvas item. Whenever [previewTick] changes the selected effect is
/// played once (preview). At rest it renders the child unchanged.
///
/// The widget structure is intentionally identical while playing and at rest
/// so the child's state (images, videos...) is never rebuilt/reloaded.
class AnimatedItemShell extends StatefulWidget {
  final ItemAnimation animation;
  final int previewTick;

  /// Visual centre of the item, in the same coordinate space as the child.
  final Offset pivot;
  final Widget child;

  const AnimatedItemShell({
    super.key,
    required this.animation,
    required this.previewTick,
    required this.pivot,
    required this.child,
  });

  @override
  State<AnimatedItemShell> createState() => _AnimatedItemShellState();
}

class _AnimatedItemShellState extends State<AnimatedItemShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late int _lastTick = widget.previewTick;
  bool _playing = false;
  late ItemAnimation _playingAnimation = widget.animation;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _playing = false);
      }
    });
  }

  @override
  void didUpdateWidget(covariant AnimatedItemShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.previewTick != _lastTick) {
      _lastTick = widget.previewTick;
      _play();
    }
  }

  void _play() {
    if (widget.animation.isNone) return;
    _playingAnimation = widget.animation;
    _controller.duration = Duration(
      milliseconds: ItemAnimationTimeline.totalMs(
        _playingAnimation.mode,
        _playingAnimation.delay,
      ),
    );
    setState(() => _playing = true);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, kExportClockMs]),
      child: widget.child,
      builder: (context, child) {
        var p = 1.0;
        var entering = true;
        var type = ItemAnimationType.none;
        final exportMs = kExportClockMs.value;
        final anim = exportMs != null ? widget.animation : _playingAnimation;
        if (exportMs != null) {
          if (!widget.animation.isNone) {
            final f = ItemAnimationTimeline.atExport(
              widget.animation.mode,
              exportMs,
              widget.animation.delay * 1000,
            );
            p = f.progress;
            entering = f.entering;
            type = widget.animation.type;
          }
        } else if (_playing) {
          final total = ItemAnimationTimeline.totalMs(
            _playingAnimation.mode,
            _playingAnimation.delay,
          );
          final delayMs = _playingAnimation.delay * 1000;
          // During the delay the item stays in its start pose.
          final frame = ItemAnimationTimeline.at(
            _playingAnimation.mode,
            math.max(0.0, _controller.value * total - delayMs),
          );
          p = frame.progress;
          entering = frame.entering;
          type = _playingAnimation.type;
        }
        final frame = itemAnimationFrame(
          type,
          p,
          entering,
          direction: anim.direction,
          axis: anim.axis,
        );
        return Opacity(
          opacity: frame.opacity,
          child: Transform(
            transform: frame.matrix,
            origin: widget.pivot,
            child: child,
          ),
        );
      },
    );
  }
}