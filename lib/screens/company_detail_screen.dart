import 'package:flutter/material.dart';
import '../models/company.dart';
import '../widgets/detail_chart.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';


class CompanyDetailScreen extends StatelessWidget {
  final CompanyData company;

  const CompanyDetailScreen({super.key, required this.company});

  String formatCurrency(double amount) {
    if (amount >= 1000000000000) {
      final trillion = (amount / 1000000000000).floor();
      final billion = ((amount % 1000000000000) / 100000000).floor();
      return "\$ $trillion兆$billion億元";
    } else if (amount >= 100000000) {
      final formatted = NumberFormat("#,##0.00").format(amount / 100000000);
      return "\$ $formatted 億";
    }
    return "\$ ${NumberFormat("#,##0").format(amount)}";
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = company.yoyGrowth > 0;
    final yoyColor = isPositive ? const Color(0xFFFF3B30) : const Color(0xFF34C759);
    final growthSign = isPositive ? "+" : "";

    return Scaffold(
      backgroundColor: const Color(0xFF0F121C), // Deep background
      appBar: AppBar(
        title: Text('${company.name} (${company.symbol})'),
         backgroundColor: const Color(0xFF0F121C),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Info Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E2233), Color(0xFF23283C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '累積淨利',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatCurrency(company.netIncome),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (company.note != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '*${company.note}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'YoY 增長',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: yoyColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: yoyColor, width: 1.5),
                        ),
                        child: Text(
                          '$growthSign${(company.yoyGrowth * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: yoyColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Detail Charts
            if (company.fiveYearNetIncome.isNotEmpty)
              DetailChartWidget(
                title: '近五年淨利走勢',
                unit: '億元',
                data: company.fiveYearNetIncome.map((e) => e / 100).toList(), // Assume mock data was roughly in Millions, maybe scale it appropriately. Wait, in mock data it's raw value? No, mock data eps is like 39.2, net income is 838498 (million NTD). Let's let the chart display it raw with M format. Wait, 838498 -> 838.498 B. Let's just pass data.
                labels: company.fiveYearLabels,
              ),

            const SizedBox(height: 24),
            if (company.fiveYearEps.isNotEmpty)
              DetailChartWidget(
                title: '近五年 EPS',
                unit: '元',
                data: company.fiveYearEps,
                labels: company.fiveYearLabels,
              ),

            const SizedBox(height: 24),
            if (company.fiveYearGrossMargin.isNotEmpty)
              DetailChartWidget(
                title: '近五年毛利率',
                unit: '%',
                data: company.fiveYearGrossMargin.map((e) => e * 100).toList(), // convert 0.53 to 53%
                labels: company.fiveYearLabels,
              ),
               
            const SizedBox(height: 24),
            
            // ETF Holdings Section
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                '持有本股的前十大 ETF',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            
            FutureBuilder<List<Map<String, dynamic>>>(
              future: SupabaseService().fetchEtfHoldings(company.symbol),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2233),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('暫無 ETF 持股數據', style: TextStyle(color: Colors.white70)),
                  );
                }

                final items = snapshot.data!;
                final etfNames = {
                  '0050': '元大台灣50',
                  '0056': '元大高股息',
                  '006208': '富邦台50',
                  '00878': '國泰永續高股息',
                  '00919': '群益台灣精選高息',
                  '00929': '復華台灣科技優息',
                  '00881': '國泰台灣5G+',
                  '00905': 'FT臺灣Smart',
                  '0052': '富邦科技',
                  '00692': '富邦公司治理',
                  '00850': '元大臺灣ESG永續',
                  '00922': '國泰台灣領袖50',
                  '00923': '群益台灣ESG低碳',
                };

                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2233),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(color: Colors.white12, height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final symbol = item['etf_symbol']?.toString() ?? '';
                      final shares = item['shares'] != null ? NumberFormat("#,##0").format(item['shares']) : '0';
                      final weight = item['weight'] != null ? '${(item['weight'] as num).toStringAsFixed(1)}%' : '-%';
                      final name = etfNames[symbol] ?? '外流通 ETF';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Text(symbol, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('$shares 張', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text('權重 $weight', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
