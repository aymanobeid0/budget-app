import 'package:flutter/material.dart';

/// How long a row takes to grow in or shrink out of a list.
const entryAnimationDuration = Duration(milliseconds: 220);

/// A column of keyed rows (Expenses, Income) where a row that joins after the
/// first build grows and fades in, and a row that leaves shrinks and fades
/// out. Rows already there on the first build show at once. With reduced
/// motion ([MediaQuery.disableAnimationsOf]) rows simply appear and vanish.
///
/// Every child needs a unique [Key]: that is how a row is followed between
/// builds.
class AnimatedEntries extends StatefulWidget {
  const AnimatedEntries({super.key, required this.children});

  final List<Widget> children;

  @override
  State<AnimatedEntries> createState() => _AnimatedEntriesState();
}

class _AnimatedEntriesState extends State<AnimatedEntries> {
  /// Keys present when the list first built, or added since. A child whose
  /// key is not in here is new and animates in.
  final Set<Key> _seen = {};

  /// Rows that have left the list and are animating out, with the last
  /// widget they were built from.
  final Map<Key, Widget> _leaving = {};

  /// The order rows were last shown in, leaving rows included.
  List<Widget> _shown = const [];

  @override
  void initState() {
    super.initState();
    _seen.addAll(widget.children.map((c) => c.key!));
    _shown = widget.children;
  }

  @override
  void didUpdateWidget(AnimatedEntries old) {
    super.didUpdateWidget(old);
    final current = {for (final c in widget.children) c.key!};
    _leaving.removeWhere((key, _) => current.contains(key));

    // Merge leaving rows back in after the row that preceded them.
    final merged = [...widget.children];
    Key? before;
    for (final row in _shown) {
      final key = row.key!;
      if (!current.contains(key)) {
        _leaving[key] = row;
        final at = before == null ? 0 : merged.indexWhere((c) => c.key == before) + 1;
        merged.insert(at, row);
      }
      before = key;
    }
    _shown = merged;
  }

  void _gone(Key key) {
    if (!mounted || _leaving.remove(key) == null) return;
    setState(() => _shown = _shown.where((c) => c.key != key).toList());
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced && _leaving.isNotEmpty) {
      _leaving.clear();
      _shown = widget.children;
    }
    final rows = <Widget>[];
    for (final child in _shown) {
      final key = child.key!;
      final isNew = _seen.add(key);
      rows.add(_EntryTransition(
        key: ValueKey<Key>(key),
        appear: isNew && !reduced,
        leaving: _leaving.containsKey(key),
        onGone: () => _gone(key),
        child: child,
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

class _EntryTransition extends StatefulWidget {
  const _EntryTransition({
    super.key,
    required this.appear,
    required this.leaving,
    required this.onGone,
    required this.child,
  });

  final bool appear;
  final bool leaving;
  final VoidCallback onGone;
  final Widget child;

  @override
  State<_EntryTransition> createState() => _EntryTransitionState();
}

class _EntryTransitionState extends State<_EntryTransition> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: entryAnimationDuration,
    value: widget.appear ? 0 : 1,
  );
  late final Animation<double> _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    if (widget.appear) _controller.forward();
    if (widget.leaving) _leave();
  }

  @override
  void didUpdateWidget(_EntryTransition old) {
    super.didUpdateWidget(old);
    if (widget.leaving && !old.leaving) _leave();
    if (!widget.leaving && old.leaving) _controller.forward();
  }

  void _leave() {
    _controller.reverse().then((_) {
      if (mounted && widget.leaving) widget.onGone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _curve,
      alignment: Alignment.topCenter,
      child: FadeTransition(opacity: _curve, child: widget.child),
    );
  }
}
