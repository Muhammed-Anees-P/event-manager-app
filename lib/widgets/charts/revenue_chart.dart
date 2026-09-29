import 'package:flutter/material.dart';

class RevenueChart extends StatelessWidget {
  const RevenueChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Revenue Overview',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Text(
                      'This Year',
                      style: TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                    ),
                    Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF4B5563)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: _LineChartPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // Grid lines
    final Paint gridPaint = Paint()
      ..color = const Color(0xFFF3F4F6)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      double y = height * (i / 4);
      canvas.drawLine(Offset(30, y), Offset(width, y), gridPaint);
    }

    // Points normalized (x: 0 to 11 for months, y: values)
    final List<double> values = [
      0.3, 0.45, 0.35, 0.55, 0.4, 0.6, 0.5, 0.9, 0.65, 0.7, 0.55, 0.8
    ];

    final double chartLeft = 35.0;
    final double chartRight = width - 10;
    final double chartTop = 15.0;
    final double chartBottom = height - 25.0;
    final double dx = (chartRight - chartLeft) / (values.length - 1);

    List<Offset> points = [];
    for (int i = 0; i < values.length; i++) {
      double x = chartLeft + (i * dx);
      double y = chartBottom - (values[i] * (chartBottom - chartTop));
      points.add(Offset(x, y));
    }

    // Path
    final Path path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final p1 = points[i - 1];
      final p2 = points[i];
      final controlPoint1 = Offset(p1.dx + dx / 2, p1.dy);
      final controlPoint2 = Offset(p2.dx - dx / 2, p2.dy);
      path.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        p2.dx, p2.dy,
      );
    }

    // Fill gradient below path
    final Path fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, chartBottom);
    fillPath.lineTo(points.first.dx, chartBottom);
    fillPath.close();

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF3B82F6).withValues(alpha: 0.25),
          const Color(0xFF3B82F6).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTRB(chartLeft, chartTop, chartRight, chartBottom));

    canvas.drawPath(fillPath, fillPaint);

    // Line Paint
    final Paint linePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, linePaint);

    // Points
    final Paint pointPaint = Paint()..color = const Color(0xFF2563EB);
    final Paint whitePaint = Paint()..color = Colors.white;

    for (int i = 0; i < points.length; i++) {
      if (i == 7) continue; // Highlighted separately
      canvas.drawCircle(points[i], 3.5, pointPaint);
      canvas.drawCircle(points[i], 1.5, whitePaint);
    }

    // Highlighted Point (Aug - Index 7)
    final Offset highlightOffset = points[7];
    canvas.drawCircle(highlightOffset, 6, pointPaint);
    canvas.drawCircle(highlightOffset, 3, whitePaint);

    // Tooltip for Aug: ₹4,20,000
    final TextPainter tooltipPainter = TextPainter(
      text: const TextSpan(
        text: '₹4,20,000\nAug 2026',
        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    tooltipPainter.layout();

    final Rect tooltipBg = Rect.fromCenter(
      center: Offset(highlightOffset.dx, highlightOffset.dy - 22),
      width: tooltipPainter.width + 12,
      height: tooltipPainter.height + 6,
    );
    final RRect tooltipRRect = RRect.fromRectAndRadius(tooltipBg, const Radius.circular(6));
    canvas.drawRRect(tooltipRRect, Paint()..color = const Color(0xFF1E293B));
    tooltipPainter.paint(
      canvas,
      Offset(tooltipBg.left + 6, tooltipBg.top + 3),
    );

    // X-Axis Labels (Jan..Dec)
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    for (int i = 0; i < months.length; i++) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: months[i],
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - (textPainter.width / 2), height - 15),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
