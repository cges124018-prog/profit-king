class CompanyData {
  final int rank;
  final String symbol;
  final String name;
  final double netIncome; 
  final double yoyGrowth; 
  final List<double> recentQuartersNetIncome; 
  final String? note; 
  final String industry; // ADDED

  final List<double> fiveYearNetIncome;
  final List<double> fiveYearEps;
  final List<double> fiveYearGrossMargin;
  final List<String> fiveYearLabels;
  
  CompanyData({
    required this.rank,
    required this.symbol,
    required this.name,
    required this.netIncome,
    required this.yoyGrowth,
    required this.recentQuartersNetIncome,
    this.note,
    this.industry = '全產業',
    this.fiveYearNetIncome = const [],
    this.fiveYearEps = const [],
    this.fiveYearGrossMargin = const [],
    this.fiveYearLabels = const [],
  });
}
