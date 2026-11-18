
import 'package:flutter/material.dart';

class CommonManagePlanShimmer extends StatefulWidget {
  const CommonManagePlanShimmer({super.key});

  @override
  State<CommonManagePlanShimmer> createState() =>
      _CommonManagePlanShimmerState();
}

class _CommonManagePlanShimmerState
    extends State<CommonManagePlanShimmer>
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

  Widget _box({
    double? width,
    double height = 14,
    double radius = 7,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.5 + value * 3, 0),
              end: Alignment(-0.5 + value * 3, 0),
              colors: const [
                Color(0xFFEAE7E7),
                Color(0xFFF9F6F6),
                Color(0xFFEAE7E7),
              ],
            ).createShader(bounds);
          },
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFFEAE7E7),
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        );
      },
    );
  }

  Widget _paymentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E2E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _box(width: 80, height: 22),
              _box(width: 18, height: 18, radius: 5),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _box(width: 140)),
              const SizedBox(width: 15),
              _box(width: 65, height: 20),
            ],
          ),
          const SizedBox(height: 10),
          _box(width: 150, height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // CURRENT PLAN TITLE
          _box(width: 105, height: 14),

          const SizedBox(height: 12),

          // CURRENT PLAN CARD
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E2E2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _box(width: 115, height: 21),
                    _box(width: 90, height: 21),
                  ],
                ),
                const SizedBox(height: 12),
                _box(width: 220),
                const SizedBox(height: 12),
                _box(width: double.infinity),
                const SizedBox(height: 8),
                _box(width: 180),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // PLAN USAGE / CHANGE PLAN BUTTONS
          Row(
            children: [
              Expanded(
                child: _box(height: 45, radius: 10),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _box(height: 45, radius: 10),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // PAYMENT HISTORY TITLE
          _box(width: 120, height: 14),

          const SizedBox(height: 12),

          // PAYMENT HISTORY CARDS
          _paymentCard(),
          const SizedBox(height: 8),
          _paymentCard(),
          const SizedBox(height: 8),
          _paymentCard(),
        ],
      ),
    );
  }
}
