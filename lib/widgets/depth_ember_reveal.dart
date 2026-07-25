import 'package:flutter/material.dart';

/// Depth + ember reveal tab transition (replaces the old swipe TabBarView).
///
/// On tab switch the incoming page zooms up from behind (scale + blur clearing)
/// while a bottom-up clip wipe reveals it, led by a glowing "ember" edge that
/// sweeps up the viewport. The outgoing page grows slightly and recedes/fades.
/// Individual blocks can cascade in via [RevealBlock] — see below.
///
/// The ember colour tracks the app theme ([ColorScheme.primary]).
///
/// Port of `.prototypes/10-depth-ember-reveal.html`.

// Entrance/reveal ease. Milder than the prototype's quint-like curve so the
// scan line's sweep spends real time on screen and the per-block cascade
// reads as a sequence instead of one burst.
const _curveIn = Cubic(0.33, 1, 0.68, 1);
// cubic-bezier(0.4, 0, 1, 1) — the exit ease.
const _curveOut = Cubic(0.4, 0, 1, 1);

const _inDuration = Duration(milliseconds: 520);
const _outDuration = Duration(milliseconds: 215);

/// Hosts the tab pages and plays the depth+ember reveal when [controller]'s
/// index changes. A page is created on its first visit and kept alive from
/// then on (state preserved, like an IndexedStack); never-visited tabs are not
/// inflated at all, so their streams/timers/media never start. Only the active
/// and the outgoing page are painted.
class DepthEmberTabView extends StatefulWidget {
  const DepthEmberTabView({
    required this.controller,
    required this.children,
    super.key,
  });

  final TabController controller;
  final List<Widget> children;

  @override
  State<DepthEmberTabView> createState() => _DepthEmberTabViewState();
}

class _DepthEmberTabViewState extends State<DepthEmberTabView>
    with TickerProviderStateMixin {
  late final AnimationController _in =
      AnimationController(vsync: this, duration: _inDuration);
  late final AnimationController _out =
      AnimationController(vsync: this, duration: _outDuration);

  int _index = 0;
  int? _leaving;

  /// Indices visited at least once. A page enters the tree on first visit and
  /// never leaves it, so its wrapper subtree stays shape-stable afterwards.
  final _visited = <int>{};

  @override
  void initState() {
    super.initState();
    _index = widget.controller.index;
    _visited.add(_index);
    // Start revealed: the first tab is active but never gets a _onTab forward,
    // so at value 0 its RevealBlocks would hold everything at opacity 0 until
    // the first tab switch. Later switches re-run forward(from: 0) as normal.
    _in.value = 1;
    widget.controller.addListener(_onTab);
    _in.addStatusListener(_onInStatus);
  }

  @override
  void didUpdateWidget(DepthEmberTabView old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onTab);
      widget.controller.addListener(_onTab);
      _index = widget.controller.index;
      _leaving = null;
      // Tab set changed: indices now mean different pages.
      _visited
        ..clear()
        ..add(_index);
    }
  }

  void _onTab() {
    final next = widget.controller.index;
    if (next == _index) return;
    setState(() {
      _leaving = _index;
      _index = next;
      _visited.add(next);
    });
    _in.forward(from: 0);
    _out.forward(from: 0);
  }

  void _onInStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed && _leaving != null) {
      setState(() => _leaving = null);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTab);
    _in.dispose();
    _out.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final ember = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: Listenable.merge([_in, _out]),
      builder: (context, _) {
        final pageP = _curveIn.transform(_in.value); // eased reveal front
        return Stack(
          fit: StackFit.expand,
          children: [
            for (var i = 0; i < widget.children.length; i++)
              _layer(i, pageP, reduceMotion),
            if (!reduceMotion && _in.isAnimating) _emberEdge(pageP, ember),
          ],
        );
      },
    );
  }

  Widget _layer(int i, double pageP, bool reduceMotion) {
    // Never visited: hold the Stack slot but don't inflate the page. Nothing
    // in it has run initState, so no streams, timers or media are alive.
    if (!_visited.contains(i)) return const SizedBox.shrink();

    final active = i == _index;
    final leaving = i == _leaving;
    final visible = active || leaving;
    final animating = !reduceMotion && _in.isAnimating;

    // Effect values; neutral (opacity 1, no clip, scale 1) when idle so the
    // wrapper tree below never changes shape. Swapping wrappers in/out at
    // animation start/end re-inflates the whole page subtree (state loss,
    // blank flicker) — keep the structure constant, vary only the values.
    var opacity = 1.0;
    var scale = 1.0;
    var clip = 1.0;
    if (animating && active) {
      // Zoom up from behind: scale 0.88→1, clip wipe bottom-up. Opacity ramps
      // to 1 by 55% of the timeline (matches the prototype).
      // ponytail: dropped the per-frame ImageFilter.blur — a full-viewport
      // gaussian + saveLayer every frame dropped frames on-device. Scale +
      // clip + opacity read the same. Re-add a blur only if profiling says it's
      // worth the raster cost.
      // Page-level zoom kept subtle so the per-block cascade carries the
      // depth effect instead of being swallowed by a whole-page scale.
      opacity = (_in.value / 0.55).clamp(0.0, 1.0);
      scale = 0.96 + 0.04 * pageP;
      clip = pageP;
    } else if (animating && leaving) {
      // Grow slightly and recede/fade into the background.
      final outP = _curveOut.transform(_out.value);
      opacity = 1 - outP;
      scale = 1 + 0.1 * outP;
    }

    // Active page drives the live entrance so its RevealBlocks cascade; every
    // other page is inert (entrance held complete) so blocks sit at rest.
    return RepaintBoundary(
      child: Opacity(
        opacity: opacity,
        child: ClipRect(
          clipper: _BottomUpReveal(clip),
          child: Transform.scale(
            scale: scale,
            child: TickerMode(
              enabled: visible,
              child: Offstage(
                offstage: !visible,
                child: DepthRevealScope(
                  entrance: active ? _in : const AlwaysStoppedAnimation(1),
                  reduceMotion: reduceMotion,
                  child: widget.children[i],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emberEdge(double pageP, Color ember) {
    final t = _in.value;
    // Fade in by 8%, hold, fade out over the last 28% (emberEdgeMove).
    final double opacity = t < 0.08
        ? t / 0.08
        : t > 0.72
            ? ((1 - t) / 0.28).clamp(0.0, 1.0)
            : 1.0;
    return IgnorePointer(
      child: Align(
        alignment: Alignment(0, 1 - 2 * pageP), // rides the reveal front
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ember.withValues(alpha: 0),
                  ember,
                  Color.lerp(ember, Colors.white, 0.6)!,
                  ember,
                  ember.withValues(alpha: 0),
                ],
                stops: const [0, 0.15, 0.5, 0.85, 1],
              ),
              boxShadow: [
                BoxShadow(
                  color: ember.withValues(alpha: 0.85),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: ember.withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: 6,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Clips its child to reveal from the bottom up. [progress] 0 → nothing,
/// 1 → fully visible.
class _BottomUpReveal extends CustomClipper<Rect> {
  const _BottomUpReveal(this.progress);
  final double progress;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(
        0,
        size.height * (1 - progress),
        size.width,
        size.height * progress,
      );

  @override
  bool shouldReclip(_BottomUpReveal old) => old.progress != progress;
}

/// Exposes the current page-entrance animation to descendant [RevealBlock]s.
class DepthRevealScope extends InheritedWidget {
  const DepthRevealScope({
    required this.entrance,
    required this.reduceMotion,
    required super.child,
    super.key,
  });

  final Animation<double> entrance;
  final bool reduceMotion;

  static DepthRevealScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DepthRevealScope>();

  @override
  bool updateShouldNotify(DepthRevealScope old) =>
      entrance != old.entrance || reduceMotion != old.reduceMotion;
}

/// Wrap a top-level block (card, row, section) so it cascades in when its page
/// becomes active: a zoom + rise timed to the bottom-up scan line passing the
/// block's on-screen position. Outside a [DepthRevealScope], or under reduced
/// motion, it just renders the child unchanged.
///
/// [index] is unused (the cascade is position-synced now); kept so existing
/// call sites don't churn.
class RevealBlock extends StatelessWidget {
  const RevealBlock({required this.child, this.index = 0, super.key});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = DepthRevealScope.maybeOf(context);
    if (scope == null || scope.reduceMotion) return child;

    return AnimatedBuilder(
      animation: scope.entrance,
      child: child,
      builder: (context, child) {
        // No early-return at v >= 1: swapping the tree shape re-inflates the
        // child (state loss/flicker). At v = 1 the values below are neutral.
        final v = scope.entrance.value;
        var w = 1.0;
        if (v < 1) {
          // Sync each block's pop to the bottom-up scan line: start when the
          // reveal front (same eased progress the ember rides) crosses the
          // block's on-screen position, then play out over a short window.
          final eased = _curveIn.transform(v);
          final box = context.findRenderObject() as RenderBox?;
          if (box != null && box.attached && box.hasSize) {
            final h = MediaQuery.sizeOf(context).height;
            final y = box.localToGlobal(Offset.zero).dy + box.size.height / 2;
            // Progress value at which the line reaches this block; clamped so
            // every block still finishes by the end of the entrance.
            final hit = (1 - y / h).clamp(0.0, 0.72);
            w = ((eased - hit) / 0.28).clamp(0.0, 1.0);
          } else {
            w = eased;
          }
        }
        final eased = _curveIn.transform(w);
        return Opacity(
          opacity: (w / 0.45).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 32 * (1 - eased)),
            child: Transform.scale(scale: 0.78 + 0.22 * eased, child: child),
          ),
        );
      },
    );
  }
}
