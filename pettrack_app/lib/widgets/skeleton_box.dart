import 'package:flutter/material.dart';

/// A soft, shimmering placeholder block used while content loads.
///
/// Skeletons feel calmer than spinners and signal "the shape of what is
/// coming" — part of the PetTrack polish vocabulary.
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius radius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = const BorderRadius.all(Radius.circular(8)),
  });

  /// A card-sized placeholder matching a typical list/grid tile.
  const SkeletonBox.tile({super.key, this.height = 120})
      : width = double.infinity,
        radius = const BorderRadius.all(Radius.circular(12));

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlight = Theme.of(context).colorScheme.surfaceContainerHigh;

    return FadeTransition(
      opacity: Tween<double>(begin: 0.55, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: widget.radius,
        ),
        child: ClipRRect(
          borderRadius: widget.radius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [base, highlight, base],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Grid of skeleton tiles, sized like the replay grid.
class SkeletonGrid extends StatelessWidget {
  final int count;
  final double childAspectRatio;
  final int crossAxisCount;

  const SkeletonGrid({
    super.key,
    this.count = 6,
    this.childAspectRatio = 16 / 9,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: count,
      itemBuilder: (context, index) =>
          SkeletonBox.tile(height: 120),
    );
  }
}
