import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/company.dart';



class CompanyCard extends StatelessWidget {
  final CompanyData company;
  final VoidCallback onTap;

  const CompanyCard({super.key, required this.company, required this.onTap});

  String formatCurrency(double amount) {
    if (amount >= 1000000000000) {
      // 兆元處理：例如 1兆7178億元
      final trillion = (amount / 1000000000000).floor();
      final billion = ((amount % 1000000000000) / 100000000).floor();
      return "\$ $trillion兆$billion億元";
    } else if (amount >= 100000000) {
      // 億元處理：保留小數不進位 (無條件捨去，避免進位小數自動進位)
      final value = (amount / 100000000 * 100).floorToDouble() / 100.0;
      final formatted = NumberFormat("#,##0.00").format(value);
      return "\$ $formatted 億";
    }
    return "\$ ${NumberFormat("#,##0").format(amount)}";
  }

  @override
  Widget build(BuildContext context) {
    // Colors
    final isTop3 = company.rank <= 3;
    final rankColor = isTop3 ? const Color(0xFFFFD700) : Colors.grey[400];
    final isPositive = company.yoyGrowth > 0;
    // Taiwan standard: Red is up (positive), Green is down (negative)
    final yoyColor = isPositive ? const Color(0xFFFF3B30) : const Color(0xFF34C759);
    final growthSign = isPositive ? "+" : "";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF1E2233), // Deep Navy Blue
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Rank
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  '${company.rank}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: rankColor,
                    shadows: isTop3
                        ? [
                            Shadow(
                                color: rankColor!.withValues(alpha: 0.5), blurRadius: 10)
                          ]
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name & Symbol
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      company.symbol,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // Net Income & YoY
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCurrency(company.netIncome),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (company.note != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '*${company.note}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                    if (company.yoyGrowth != 0.0) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: yoyColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$growthSign${(company.yoyGrowth * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: yoyColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
