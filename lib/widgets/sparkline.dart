import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SparklineWidget extends StatelessWidget {
  final List<double> data;
  final Color color;

  const SparklineWidget({super.key, required this.data, this.color = Colors.green});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();

    final List<FlSpot> spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    return SizedBox(
      height: 40,
      width: 60,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.2),
              ),
            ),
          ],
          lineTouchData: LineTouchData(enabled: false), // Disable touch for sparkline
        ),
      ),
    );
  }
}
