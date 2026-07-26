 import 'package:flutter/material.dart';

class ScaleSlider extends StatefulWidget {
  final double value; // current scale (0.5 to 3.0)
  final ValueChanged<double> onChanged;

  const ScaleSlider({
    required this.value,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  _ScaleSliderState createState() => _ScaleSliderState();
}

class _ScaleSliderState extends State<ScaleSlider> {
  double min = 0.5;  // 50%
  double max = 3.0;  // 300%

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Map scale value -> position
        final pos = ((widget.value - min) / (max - min)) * width;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: (d) {
            double newPos = d.localPosition.dx.clamp(0, width);
            double newVal = min + (newPos / width) * (max - min);
            widget.onChanged(newVal);
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              /// TICK MARKS
              CustomPaint(
                painter: _ScaleTickPainter(),
                size: Size(width, 30),
              ),

              /// BLUE MOVING BAR (center vertically)
              Positioned(
                left: pos - 2,
                top: 0,
                child: Container(
                  width: 4,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Color(0xff4ED8F2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScaleTickPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 3;

    int ticks = 25; // 25 ticks for scale (0.5 to 3.0)
    double spacing = size.width / ticks;

    double centerY = size.height / 2;

    for (int i = 0; i <= ticks; i++) {
      double x = i * spacing;

      // Draw tick centered vertically
      canvas.drawLine(
        Offset(x, centerY - 8),   // top
        Offset(x, centerY + 8),   // bottom
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}