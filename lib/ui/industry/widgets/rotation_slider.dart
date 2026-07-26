import 'package:flutter/material.dart';

class RotationSlider extends StatefulWidget {
  final double value; // current angle
  final ValueChanged<double> onChanged;

  const RotationSlider({
    required this.value,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  _RotationSliderState createState() => _RotationSliderState();
}

class _RotationSliderState extends State<RotationSlider>
    with SingleTickerProviderStateMixin {

  double min = -180;
  double max = 180;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Map angle -> position
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
                painter: _TickPainter(),
                size: Size(width, 30),
              ),

              /// BLUE MOVING BAR
              /// BLUE MOVING BAR (center vertically)
              Positioned(
                left: pos - 2,
                top: 0,   // <-- center by matching height
                child: Container(
                  width: 4,
                  height: 30,  // same height as tick canvas
                  decoration: BoxDecoration(
                    color: Color(0xff4ED8F2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),


              /// ANGLE LABEL
              // Positioned(
              //   bottom: 0,
              //   child: Text(
              //     "${widget.value.toStringAsFixed(1)}°",
              //     style: TextStyle(
              //       fontSize: 20,
              //       color: Color(0xff4ED8F2),
              //       fontWeight: FontWeight.bold,
              //     ),
              //   ),
              // ),
            ],
          ),
        );
      },
    );
  }
}

class _TickPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 3;

    int ticks = 36;
    double spacing = size.width / ticks;

    double centerY = size.height / 2;

    for (int i = 0; i <= ticks; i++) {
      double x = i * spacing;

      // draw tick centered vertically
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
