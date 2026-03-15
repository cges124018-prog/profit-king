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
        print('companies_api error: $e');
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
        print('companies_manual error: $e');
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

      // Take top 10
      final top10 = combined.take(10).toList();

      return top10.map((data) {
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
      print('Error fetching companies from Supabase: $e');
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
      print('Error fetching years: $e');
      return ['2026 年', '2025 年']; // Fallback
    }
  }
  
  Future<List<Map<String, dynamic>>> fetchEtfHoldings(String stockSymbol) async {
    try {
      final response = await supabase
          .from('etf_holdings')
          .select('etf_symbol, shares, weight')
          .eq('stock_symbol', stockSymbol)
          .order('shares', ascending: false)
          .limit(10);
      return (response as List).map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error fetching ETF holdings: $e');
      return [];
    }
  }
}
