import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DetailChartWidget extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final String title;
  final String unit;

  const DetailChartWidget({
    super.key,
    required this.data,
    required this.labels,
    required this.title,
    this.unit = '',
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();

    final maxVal = data.reduce((curr, next) => curr > next ? curr : next);
    final minVal = data.reduce((curr, next) => curr < next ? curr : next);
    // Add some padding to max and min
    final maxY = maxVal + (maxVal - minVal).abs() * 0.2;
    var minY = minVal - (maxVal - minVal).abs() * 0.2;
    if (minY < 0 && minVal >= 0) minY = 0; // Don't let 0 drop to negative if all positive

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < data.length; i++) {
        final val = data[i];
        barGroups.add(
            BarChartGroupData(
                x: i,
                barRods: [
                    BarChartRodData(
                        toY: val,
                        color: val >= 0 ? const Color(0xFFFF3B30) : const Color(0xFF34C759),
                        width: 22,
                        borderRadius: BorderRadius.circular(4),
                    ),
                ],
            ),
        );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2233),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  '($unit)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                minY: minY,
                barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                                NumberFormat("#,##0").format(rod.toY),
                                const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                ),
                            );
                        },
                    ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            labels[index],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            NumberFormat.compact().format(value),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.1),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 🟢 底部裝飾性成交量長條圖 (模擬 40 個點)
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              '成交量 (裝飾數據)',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
          SizedBox(
            height: 30,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(42, (idx) {
                // 模擬長短不一：透過固定數值生成或 idx 組合生成
                final heights = [
                  12.0, 8.0, 15.0, 22.0, 10.0, 5.0, 18.0, 25.0, 7.0, 14.0,
                  20.0, 11.0, 19.0, 6.0, 24.0, 16.0, 9.0, 13.0, 21.0, 11.0,
                  17.0, 5.0, 23.0, 10.0, 18.0, 14.0, 8.0, 25.0, 12.0, 6.0,
                  20.0, 15.0, 9.0, 23.0, 11.0, 17.0, 7.0, 13.0, 21.0, 10.0,
                  19.0, 14.0
                ];
                // 模擬紅綠交錯
                final isGreen = idx % 2 == 0 || idx % 3 == 0; 
                final color = isGreen ? const Color(0xFF34C759) : const Color(0xFFFF3B30);

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    height: heights[idx % heights.length],
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
