import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../models/payment_model.dart';
import '../../theme/app_theme.dart';

class CustomerDynamicRevenueChart extends StatelessWidget {
  final List<EventModel> events;
  final List<PaymentModel> payments;

  const CustomerDynamicRevenueChart({
    super.key,
    required this.events,
    required this.payments,
  });

  @override
  Widget build(BuildContext context) {
    final List<double> monthlyValues = List.filled(12, 0.0);

    for (var event in events) {
      final String date = event.date.toLowerCase();
      if (date.contains('jan')) monthlyValues[0] += event.amountReceived;
      else if (date.contains('feb')) monthlyValues[1] += event.amountReceived;
      else if (date.contains('mar')) monthlyValues[2] += event.amountReceived;
      else if (date.contains('apr')) monthlyValues[3] += event.amountReceived;
      else if (date.contains('may')) monthlyValues[4] += event.amountReceived;
      else if (date.contains('jun')) monthlyValues[5] += event.amountReceived;
      else if (date.contains('jul')) monthlyValues[6] += event.amountReceived;
      else if (date.contains('aug')) monthlyValues[7] += event.amountReceived;
      else if (date.contains('sep')) monthlyValues[8] += event.amountReceived;
      else if (date.contains('oct')) monthlyValues[9] += event.amountReceived;
      else if (date.contains('nov')) monthlyValues[10] += event.amountReceived;
      else if (date.contains('dec')) monthlyValues[11] += event.amountReceived;
      else monthlyValues[8] += event.amountReceived;
    }

    double maxVal = monthlyValues.fold(0.0, (max, v) => v > max ? v : max);
    if (maxVal == 0) maxVal = 100000;

    int peakIndex = 0;
    double peakVal = monthlyValues[0];
    for (int i = 1; i < monthlyValues.length; i++) {
      if (monthlyValues[i] > peakVal) {
        peakVal = monthlyValues[i];
        peakIndex = i;
      }
    }

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
                'Customer Revenue Trend (Dynamic)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Peak: ₹${peakVal.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: _DynamicLineChartPainter(
                monthlyValues: monthlyValues,
                maxValue: maxVal,
                peakIndex: peakIndex,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DynamicLineChartPainter extends CustomPainter {
  final List<double> monthlyValues;
  final double maxValue;
  final int peakIndex;

  _DynamicLineChartPainter({
    required this.monthlyValues,
    required this.maxValue,
    required this.peakIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    final Paint gridPaint = Paint()
      ..color = const Color(0xFFF3F4F6)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      double y = height * (i / 4);
      canvas.drawLine(Offset(30, y), Offset(width, y), gridPaint);
    }

    final double chartLeft = 35.0;
    final double chartRight = width - 10;
    final double chartTop = 20.0;
    final double chartBottom = height - 25.0;
    final double dx = (chartRight - chartLeft) / (monthlyValues.length - 1);

    List<Offset> points = [];
    for (int i = 0; i < monthlyValues.length; i++) {
      double norm = (monthlyValues[i] / maxValue).clamp(0.05, 1.0);
      double x = chartLeft + (i * dx);
      double y = chartBottom - (norm * (chartBottom - chartTop));
      points.add(Offset(x, y));
    }

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

    final Path fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, chartBottom);
    fillPath.lineTo(points.first.dx, chartBottom);
    fillPath.close();

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.primary.withValues(alpha: 0.30),
          AppTheme.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTRB(chartLeft, chartTop, chartRight, chartBottom));

    canvas.drawPath(fillPath, fillPaint);

    final Paint linePaint = Paint()
      ..color = AppTheme.primaryDark
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, linePaint);

    final Paint pointPaint = Paint()..color = AppTheme.primaryDark;
    final Paint whitePaint = Paint()..color = Colors.white;

    for (int i = 0; i < points.length; i++) {
      if (i == peakIndex) continue;
      canvas.drawCircle(points[i], 3.5, pointPaint);
      canvas.drawCircle(points[i], 1.5, whitePaint);
    }

    final Offset highlightOffset = points[peakIndex];
    canvas.drawCircle(highlightOffset, 6, pointPaint);
    canvas.drawCircle(highlightOffset, 3, whitePaint);

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final String peakMonthName = months[peakIndex];
    final String labelText = '₹${monthlyValues[peakIndex].toStringAsFixed(0)}\n$peakMonthName 2026';

    final TextPainter tooltipPainter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    tooltipPainter.layout();

    final Rect tooltipBg = Rect.fromCenter(
      center: Offset(highlightOffset.dx.clamp(45.0, width - 45.0), highlightOffset.dy - 22),
      width: tooltipPainter.width + 12,
      height: tooltipPainter.height + 6,
    );
    final RRect tooltipRRect = RRect.fromRectAndRadius(tooltipBg, const Radius.circular(6));
    canvas.drawRRect(tooltipRRect, Paint()..color = const Color(0xFF1E293B));
    tooltipPainter.paint(
      canvas,
      Offset(tooltipBg.left + 6, tooltipBg.top + 3),
    );

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
