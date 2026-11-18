
import 'package:flutter/material.dart';

class CommonPlanUsageShimmer extends StatefulWidget {
  const CommonPlanUsageShimmer({super.key});

  @override
  State<CommonPlanUsageShimmer> createState() =>
      _CommonPlanUsageShimmerState();
}

class _CommonPlanUsageShimmerState
    extends State<CommonPlanUsageShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _shimmerBox({
    double height = 15,
    double width = double.infinity,
    double radius = 8,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1 + 2 * _controller.value, 0),
              end: Alignment(1 + 2 * _controller.value, 0),
              colors: const [
                Color(0xFFEAEAEA),
                Color(0xFFF8F8F8),
                Color(0xFFEAEAEA),
              ],
            ).createShader(bounds);
          },
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        );
      },
    );
  }

  Widget _normalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE6E1DC)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _shimmerBox(width: 130, height: 15),
              ),
              _shimmerBox(width: 65, height: 15),
            ],
          ),
          const SizedBox(height: 10),
          _shimmerBox(height: 4),
        ],
      ),
    );
  }

  Widget _aiCreditsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E1DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _shimmerBox(width: 100, height: 17),
              ),
              _shimmerBox(width: 110, height: 22),
            ],
          ),
          const SizedBox(height: 12),
          _shimmerBox(height: 4),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _shimmerBox(width: 90, height: 13),
              ),
              _shimmerBox(width: 70, height: 13),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: List.generate(
              3,
                  (index) => _shimmerBox(
                width: 95,
                height: 45,
                radius: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
      children: [
        _shimmerBox(width: 220, height: 12),
        const SizedBox(height: 14),

        _aiCreditsCard(),
        const SizedBox(height: 8),

        ...List.generate(
          5,
              (index) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _normalCard(),
          ),
        ),

        const SizedBox(height: 12),
        Center(
          child: _shimmerBox(width: 180, height: 13),
        ),

        const SizedBox(height: 28),

        _shimmerBox(height: 48, radius: 8),
      ],
    );
  }
}
