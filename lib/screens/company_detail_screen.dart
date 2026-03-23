import 'package:flutter/material.dart';
import '../models/company.dart';
import '../widgets/detail_chart.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class CompanyDetailScreen extends StatefulWidget {
  final CompanyData company;
  const CompanyDetailScreen({super.key, required this.company});

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {
  late Future<List<Map<String, dynamic>>> _etfHoldingsFuture;

  @override
  void initState() {
    super.initState();
    _etfHoldingsFuture = SupabaseService().fetchEtfHoldings(widget.company.symbol);
  }

  void _refreshData() {
    setState(() {
      _etfHoldingsFuture = SupabaseService().fetchEtfHoldings(widget.company.symbol);
    });
  }

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

  // 🟢 備份配息資料：若 TWSE 暫時斷線，熱門 ETF 仍能顯示基礎數據
  final Map<String, List<Map<String, String>>> _fallbackDividendData = {
    '0056': [
      {'ex_date': '2026/01/22', 'pay_date': '2026/02/11', 'dividend': '0.8660'},
    ],
    '00919': [
      {'ex_date': '2026/03/17', 'pay_date': '2026/04/14', 'dividend': '0.7800'},
    ],
  };

  // 🟢 民國年轉西元年配接器 (防證交所格式不齊)
  String _convertRocToAd(String rocStr) {
    try {
      if (!rocStr.contains('年')) return rocStr;
      final yearPart = rocStr.split('年')[0];
      final monthDayPart = rocStr.split('年')[1];
      final year = int.parse(yearPart) + 1911;
      return '$year/${monthDayPart.replaceAll('月', '/').replaceAll('日', '').trim()}';
    } catch (e) {
      return rocStr; // 解析失敗則保留原始字串
    }
  }

  // 🟢 自動從 證交所(TWSE) 爬取配息資料
  Future<List<Map<String, String>>> _fetchEtfDividend(String etfSymbol) async {
    List<Map<String, String>> list = [];
    try {
      final url = 'https://www.twse.com.tw/rwd/zh/ETF/etfDiv?response=json&stkNo=$etfSymbol&startDate=0940101';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'ok' && data['data'] != null) {
          final rows = data['data'] as List;
          for (var row in rows) {
            final rowList = row as List;
            if (rowList.length > 5) {
              final exDate = _convertRocToAd(rowList[2].toString()); // 除息交易日
              final payDate = _convertRocToAd(rowList[4].toString()); // 收益分配發放日
              final dividend = rowList[5].toString().trim();          // 收益分配金額
              
              if (exDate.isNotEmpty && payDate.isNotEmpty) {
                list.add({
                  'ex_date': exDate,
                  'pay_date': payDate,
                  'dividend': dividend,
                });
              }
            }
          }
        }
      }
    } catch (e) {
      // ignore: empty_catches
    }
    
    // 💡 容錯機制：如果爬網失敗/掛掉，就使用靜態備用資料
    if (list.isEmpty) {
       list = _fallbackDividendData[etfSymbol] ?? [];
    }
    return list;
  }

  // 🟢 備份成分股調整月份
  final Map<String, String> _etfRebalanceNote = {
    '0050': '每年之三月、六月、九月與十二月第三個星期五收盤生效。',
    '0052': '每年之三月、六月、九月與十二月第三個星期五收盤生效。',
    '0056': '每年 6、12 月',
    '00878': '每年 5、11 月',
    '00919': '每年 5、12 月定期審查',
    '00929': '每年 6 月底',
    '00940': '每年 5、11 月底',
    '006208': '每年之三月、六月、九月與十二月第三個星期五收盤生效。',
    '00881': '每年調整二次（四月、十月）',
    '00918': '每年 6、12 月',
    '009816': '每年調整四次(2、5、8、11月)',
    '00900': '每年4、7、12月',
    '00850': '每年 6、12 月'
  };

  void _showEtfDetailBottomSheet(String etfSymbol, String etfName, double shares) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final rebalanceMonth = _etfRebalanceNote[etfSymbol] ?? '官網定期檢視';
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFF161925),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // 頂部推拉條
              Container(
                width: 40, height: 5,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 20),
              
              // 1. 標題與基本資料
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(etfName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, overflow: TextOverflow.ellipsis)),
                        const SizedBox(height: 4),
                        Text('代號: $etfSymbol', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const Divider(color: Colors.white12, height: 24),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🌟 新增 A：調整日期說明小卡
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2132),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.2), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('成分股審核與調整月份', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 3),
                                  Text(rebalanceMonth, style: TextStyle(color: Colors.amber[300], fontSize: 14)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 3. 配息歷史清單
                      const Text('最新配息資訊', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      FutureBuilder<List<Map<String, String>>>(
                        future: _fetchEtfDividend(etfSymbol),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                          }
                          final list = snapshot.data ?? [];
                          if (list.isEmpty) {
                            final emptyText = (etfSymbol == '009816') ? '收益不分配(不配息)' : '尚無配息資訊';
                            return Text(emptyText, style: const TextStyle(color: Colors.white54));
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: list.length > 2 ? 2 : list.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final data = list[index];
                              final dividend = double.tryParse(data['dividend'] ?? '0') ?? 0.0;
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                   color: const Color(0xFF1B1E2D),
                                   borderRadius: BorderRadius.circular(10),
                                   border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                                ),
                                child: Column(
                                   children: [
                                      _buildDialogRow('除息日期', data['ex_date']!),
                                      const SizedBox(height: 6),
                                      _buildDialogRow('發放日期', data['pay_date']!),
                                      const SizedBox(height: 6),
                                      _buildDialogRow('現金股利', '${dividend.toStringAsFixed(4)} 元'),
                                   ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 4),

                      // 🌟 新增 B：橫向長條圖組件
                      const Text('成分股行業類別比重', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      FutureBuilder<Map<String, double>>(
                         future: SupabaseService().fetchEtfIndustryDistribution(etfSymbol),
                         builder: (context, snapshot) {
                           if (snapshot.connectionState == ConnectionState.waiting) {
                             return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
                           }
                           final dist = snapshot.data ?? {};
                           if (dist.isEmpty) return const Text('暫無產業數據', style: TextStyle(color: Colors.white54));

                           // 依佔比排序 
                           final sorted = dist.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
                           double totalSum = dist.values.fold(0.0, (a, b) => a + b);

                           if (totalSum == 0) totalSum = 100.0;

                           return Column(
                             children: sorted.map((entry) {
                               final double ratio = entry.value / totalSum;
                               final double percentage = entry.value;

                               if (percentage < 0.1) return const SizedBox.shrink();

                               return Padding(
                                 padding: const EdgeInsets.only(bottom: 14),
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Row(
                                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                       children: [
                                         Text(entry.key, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                         Text('${percentage.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold)),
                                       ],
                                     ),
                                     const SizedBox(height: 6),
                                     ClipRRect(
                                       borderRadius: BorderRadius.circular(4),
                                       child: LinearProgressIndicator(
                                         value: ratio.clamp(0.0, 1.0),
                                         backgroundColor: Colors.white.withValues(alpha: 0.05),
                                         valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                                         minHeight: 8,
                                       ),
                                     ),
                                   ],
                                 ),
                               );
                             }).toList(),
                           );
                         },
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final company = widget.company;
    final isPositive = company.yoyGrowth > 0;
    final yoyColor = isPositive ? const Color(0xFFFF3B30) : const Color(0xFF34C759);
    final growthSign = isPositive ? "+" : "";

    return Scaffold(
      backgroundColor: const Color(0xFF12141A),
      appBar: AppBar(
        title: Text('${company.name} (${company.symbol})'),
        backgroundColor: const Color(0xFF12141A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
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
                color: const Color(0xFF1A1D24),
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
                  if (company.yoyGrowth != 0.0) ...[
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
                ],
              ),
            ),
            // Detail Charts
            if (company.fiveYearNetIncome.isNotEmpty) ...[
              const SizedBox(height: 32),
              DetailChartWidget(
                title: '近五年淨利走勢',
                unit: '億元',
                data: company.fiveYearNetIncome.map((e) => e / 100).toList(),
                labels: company.fiveYearLabels,
              ),
            ],

            if (company.fiveYearEps.isNotEmpty) ...[
              const SizedBox(height: 24),
              DetailChartWidget(
                title: '近五年 EPS',
                unit: '元',
                data: company.fiveYearEps,
                labels: company.fiveYearLabels,
              ),
            ],

            if (company.fiveYearGrossMargin.isNotEmpty) ...[
              const SizedBox(height: 24),
              DetailChartWidget(
                title: '近五年毛利率',
                unit: '%',
                data: company.fiveYearGrossMargin.map((e) => e * 100).toList(),
                labels: company.fiveYearLabels,
              ),
            ],
               
            if (company.fiveYearNetIncome.isNotEmpty || 
                company.fiveYearEps.isNotEmpty || 
                company.fiveYearGrossMargin.isNotEmpty)
              const SizedBox(height: 24)
            else
              const SizedBox(height: 16), // 🟢 無圖表數據時收窄為微間距
            
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _etfHoldingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '持有 ${company.name} 的前五大 ETF',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '資料日期: 暫無',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2233),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('暫無 ETF 持股數據', style: TextStyle(color: Colors.white70)),
                        ),
                     ],
                  );
                }

                final rawItems = snapshot.data!;
                // 找到最合適的日期元件
                final dateItem = rawItems.firstWhere(
                  (item) => item['data_date'] != null && item['data_date'].toString().isNotEmpty,
                  orElse: () => <String, dynamic>{},
                );
                final String dataDate = dateItem['data_date']?.toString() ?? '即時';

                // 🌟 只保留張數大於 0 的項目
                final items = rawItems.where((item) => (item['shares'] as num?) != null && (item['shares'] as num) > 0).toList();

                if (items.isEmpty) {
                   return Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '持有 ${company.name} 的前五大 ETF',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '資料日期: $dataDate',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2233),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('暫無 ETF 持股數據', style: TextStyle(color: Colors.white70)),
                        ),
                     ],
                  );
                }



                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '持有 ${company.name} 的前十大 ETF',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '資料日期: $dataDate',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero, // 🟢 消除 ListView 默認產生的上下緩衝空隙
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final etfSymbol = item['etf_symbol']?.toString() ?? '';
                        final rawShares = (item['shares'] as num?)?.toDouble() ?? 0.0;
                        final sharesCount = (rawShares / 1000).toInt(); // 轉換為「張」（無條件捨去）
                        final rawWeight = (item['weight'] as num?)?.toDouble() ?? 0.0;
                        final etfName = item['etfs']?['name']?.toString() ?? item['etf_symbol']?.toString() ?? '未知 ETF';
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1D2D),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: InkWell(
                            onTap: () => _showEtfDetailBottomSheet(etfSymbol, etfName, rawShares),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: index == 0 
                                              ? const Color(0xFFFFD700) 
                                              : index == 1 
                                                  ? const Color(0xFFC0C0C0) 
                                                  : index == 2 
                                                      ? const Color(0xFFCD7F32) 
                                                      : Colors.white12,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color: index < 3 ? Colors.black : Colors.white70,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              etfName, 
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(etfSymbol, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${NumberFormat('#,###').format(sharesCount)} 張',
                                        style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        '佔基金淨資產之權重 ${rawWeight.toStringAsFixed(2)}%',
                                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                    },
                  ),
                  ],
                );
              },
            ),

            const SizedBox(height: 2),

            // 🌟 靜態/自動定審提醒看板
            Builder(
              builder: (context) {
                final currentMonth = DateTime.now().month;
                final Map<String, List<int>> rebalanceMonths = {
                  '0050': [3, 6, 9, 12],
                  '0052': [3, 6, 9, 12],
                  '0056': [6, 12],
                  '00878': [5, 11],
                  '00919': [5, 12],
                  '00929': [6],
                  '00940': [5, 11],
                  '006208': [3, 6, 9, 12],
                  '00881': [4, 10],
                  '00918': [6, 12],
                  '009816': [2, 5, 8, 11],
                  '00900': [4, 7, 12],
                  '00850': [6, 12],
                };

                final alertEtfs = rebalanceMonths.entries
                    .where((e) => e.value.contains(currentMonth))
                    .map((e) => e.key)
                    .toList();

                if (alertEtfs.isEmpty) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF23251B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '💡 $currentMonth月定審提醒：${alertEtfs.join('、')}',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '※ 免責聲明：本 App 提供之資訊僅供參考，不構成任何投資建議。投資人應獨立判斷、審視並評估投資風險，並自負盈虧。',
                style: TextStyle(color: Colors.white24, fontSize: 11, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
