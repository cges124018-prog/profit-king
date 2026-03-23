import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/company.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  Future<List<CompanyData>> fetchTopCompanies({
    String year = '2025 年',
    String? industry,
  }) async {
    try {
      List<dynamic> combined = [];
      
      try {
        var query = supabase.from('companies_api').select().eq('year', year);
        if (industry != null) {
          query = query.eq('industry', industry);
        }
        final resApi = await query;
        combined.addAll(resApi as List);
      } catch (e) {
        // print('companies_api error: $e');
      }
      
      try {
        var manualQuery = supabase.from('companies_manual').select().eq('year', year);
        if (industry != null) {
          manualQuery = manualQuery.eq('industry', industry);
        }
        final resManual = await manualQuery;
        // Override with manual data
        for (var manualItem in resManual as List) {
          final existingIdx = combined.indexWhere((apiItem) => apiItem['symbol'] == manualItem['symbol']);
          if (existingIdx >= 0) {
            combined[existingIdx] = manualItem;
          } else {
            combined.add(manualItem);
          }
        }
      } catch (e) {
        // print('companies_manual error: $e');
      }

      // Sort by net_income descending
      combined.sort((a, b) {
        final aVal = (a['net_income'] as num?)?.toDouble() ?? 0.0;
        final bVal = (b['net_income'] as num?)?.toDouble() ?? 0.0;
        return bVal.compareTo(aVal);
      });

      // Assign rank dynamically
      for(int i=0; i<combined.length; i++) {
        combined[i]['rank'] = i + 1;
      }

      // Take top 5 for specific industries, else top 10
      final count = (industry != null && ['航運業', '電子零組件業', '其他電子業'].contains(industry)) ? 5 : 10;
      final topList = combined.take(count).toList();

      return topList.map((data) {
        // Map the JSON from Supabase to our CompanyData model
        return CompanyData(
          rank: data['rank'] ?? 0,
          symbol: data['symbol']?.toString() ?? '',
          name: data['name']?.toString() ?? '',
          netIncome: (data['net_income'] as num?)?.toDouble() ?? 0.0,
          yoyGrowth: (data['yoy_growth'] as num?)?.toDouble() ?? 0.0,
          note: data['note'] as String?,
          industry: data['industry'] as String? ?? '全產業',
          // Use null-aware operators to avoid throwing when a column is empty/null
          recentQuartersNetIncome: (data['recent_quarters'] as List?)
                  ?.map((e) => (e as num).toDouble())
                  .toList() ??
              [],
          // Defaulting others for now
          fiveYearNetIncome: [],
          fiveYearEps: [],
          fiveYearGrossMargin: [],
          fiveYearLabels: [],
        );
      }).toList();
    } catch (e) {
      // print('Error fetching companies from Supabase: $e');
      rethrow;
    }
  }

  Future<List<String>> fetchAvailableYears() async {
    try {
      // Fetch distinct years from both tables. 
      // Supabase has no raw DISTINCT for REST API without RPC, so we fetch all years, set, and sort.
      final resApi = await supabase.from('companies_api').select('year');
      final resManual = await supabase.from('companies_manual').select('year');

      final Set<String> years = {};

      for (var row in (resApi as List)) {
        if (row['year'] != null) years.add(row['year'].toString());
      }
      for (var row in (resManual as List)) {
        if (row['year'] != null) years.add(row['year'].toString());
      }

      // Default to ['2025 年'] if everything is completely empty for some reason
      if (years.isEmpty) {
        return ['2025 年'];
      }

      // Sort descending (2026, 2025...)
      final sortedYears = years.toList()..sort((a, b) => b.compareTo(a));
      return sortedYears;
    } catch (e) {
      // print('Error fetching years: $e');
      return ['2026 年', '2025 年']; // Fallback
    }
  }
  
  Future<List<Map<String, dynamic>>> fetchEtfHoldings(String stockSymbol) async {
    try {
      // 1. 先抓取雲端 etfs 名稱對照表
      final etfsRes = await supabase.from('etfs').select('symbol, name');
      final Map<String, String> etfNameMap = {};
      for (var row in (etfsRes as List)) {
        if (row['symbol'] != null) {
          final String sym = row['symbol'].toString().trim().toUpperCase();
          etfNameMap[sym] = row['name']?.toString() ?? '外流通 ETF';
        }
      }

      // 2. 抓取持股明細
      final response = await supabase
          .from('etf_holdings')
          .select('etf_symbol, shares, weight, data_date')
          .eq('stock_symbol', stockSymbol)
          .order('shares', ascending: false)
          .limit(30); // 🟢 放寬撈取額度，不怕重複佔位
          
      // 3. 在本地段主動合併與組裝對應格式 (並扣上防重複鎖)
      final Map<String, Map<String, dynamic>> dedupMap = {};
      
      for (var item in (response as List)) {
          final Map<String, dynamic> mutableItem = Map<String, dynamic>.from(item as Map);
          final String etfSymbol = (mutableItem['etf_symbol']?.toString() ?? '').trim().toUpperCase();
          
          mutableItem['etfs'] = {
             'name': etfNameMap[etfSymbol] ?? etfSymbol
          };
          
          if (!dedupMap.containsKey(etfSymbol)) {
              dedupMap[etfSymbol] = mutableItem;
          }
      }

       return dedupMap.values.take(10).toList(); // 🟢 放大過濾額度為前 10 筆明細
    } catch (e) {
      // 🚨 Debug 偵錯小幫手：將錯誤訊息直接傳回前端，排查為何變成空白！
      return [{
         'etf_symbol': 'DEBUG',
         'shares': 1000, 
         'weight': 0.0,
         'data_date': 'ERR',
         'etfs': { 'name': '載入發生故障: ${e.toString()}' }
      }];
    }
  }

  // 🟢 抓取特定 ETF 的成分股產業分佈，用於繪製產業佔比進度條
  Future<Map<String, double>> fetchEtfIndustryDistribution(String etfSymbol) async {
    try {
      // 1. 抓取成分股 (全量抓取)
      final etfRes = await supabase
          .from('etf_holdings')
          .select('stock_symbol, weight')
          .eq('etf_symbol', etfSymbol);
      
      final etfItems = etfRes as List;
      if (etfItems.isEmpty) return {};

      // 提取所有股號
      final List<String> symbols = etfItems
          .map((e) => e['stock_symbol']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();

      // 2. 批量查這些股號的產業 (從 api 表)
      final compRes = await supabase
          .from('companies_api')
          .select('symbol, industry')
          .inFilter('symbol', symbols);
          
      final compManualRes = await supabase
          .from('companies_manual')
          .select('symbol, industry')
          .inFilter('symbol', symbols);

      final Map<String, String> industryMap = {};
      
      for (var row in (compRes as List)) {
         final sym = row['symbol']?.toString() ?? '';
         final ind = row['industry']?.toString() ?? '其他';
         if (sym.isNotEmpty) industryMap[sym] = ind;
      }
      
      for (var row in (compManualRes as List)) {
         final sym = row['symbol']?.toString() ?? '';
         final ind = row['industry']?.toString() ?? '其他';
         if (sym.isNotEmpty) industryMap[sym] = ind;
      }

      // 3. 彙總計算
      final Map<String, double> distribution = {};
      double totalSum = 0.0;
      for (var item in etfItems) {
         final symbol = item['stock_symbol']?.toString() ?? '';
         final weight = (item['weight'] as num?)?.toDouble() ?? 0.0;
         final industry = industryMap[symbol] ?? '其他股'; 
         
         distribution[industry] = (distribution[industry] ?? 0.0) + weight;
         totalSum += weight;
      }
      
      // 平滑總計如果為 0 的除法保護
      if (totalSum == 0) totalSum = 100.0;

      return distribution;
    } catch (e) {
      return {};
    }
  }
}
