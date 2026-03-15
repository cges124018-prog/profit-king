import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../widgets/company_card.dart';
import 'company_detail_screen.dart';
import '../services/supabase_service.dart';
import '../models/company.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<CompanyData>> _companiesFuture;
  late Future<List<String>> _yearsFuture;
  String _selectedYear = '2025 年';
  String _selectedIndustry = '全產業';

  final List<String> _industries = [
    '全產業',
    '半導體業',
    '金融業',
    '電腦及週邊設備業',
    '航運業',
    '電子零組件業'
  ];

  @override
  void initState() {
    super.initState();
    _companiesFuture = _supabaseService.fetchTopCompanies();
    _yearsFuture = _supabaseService.fetchAvailableYears();
  }

  void _refreshData() {
    setState(() {
      _companiesFuture = _supabaseService.fetchTopCompanies(
        year: _selectedYear,
        industry: _selectedIndustry == '全產業' ? null : _selectedIndustry,
      );
      _yearsFuture = _supabaseService.fetchAvailableYears();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F121C),
      appBar: AppBar(
        title: const Text(
          '獲利王 Leaderboard',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: const Color(0xFF0F121C),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('篩選功能開發中...')),
              );
            },
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FutureBuilder<List<String>>(
                  future: _yearsFuture,
                  builder: (context, snapshot) {
                    List<String> years = snapshot.data ?? [_selectedYear];
                    if (years.isEmpty) years = [_selectedYear];

                    return PopupMenuButton<String>(
                      color: const Color(0xFF23283C),
                      onSelected: (String value) {
                        setState(() {
                          _selectedYear = value;
                          _refreshData();
                        });
                      },
                      itemBuilder: (BuildContext context) {
                        return years.map((yearStr) {
                          return PopupMenuItem<String>(
                            value: yearStr,
                            child: Text(yearStr, style: const TextStyle(color: Colors.white)),
                          );
                        }).toList();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2233),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                            const SizedBox(width: 6),
                            Text(
                              _selectedYear,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white70),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Text(
                  '更新: 雲端即時同步',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Industry Filter Chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _industries.length,
              itemBuilder: (context, index) {
                final industry = _industries[index];
                final isSelected = industry == _selectedIndustry;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(industry),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedIndustry = industry;
                          _companiesFuture = _supabaseService.fetchTopCompanies(
                            year: _selectedYear,
                            industry: _selectedIndustry == '全產業' ? null : _selectedIndustry,
                          );
                        });
                      }
                    },
                    backgroundColor: const Color(0xFF1E2233),
                    selectedColor: const Color(0xFFFF3B30).withOpacity(0.2), // Apple Red tinted
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFFFF3B30) : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFFF3B30) : Colors.white24,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<CompanyData>>(
              future: _companiesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  // Fallback to mock data if error occurs
                  return _buildList(mockCompanies);
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('暫無資料'));
                }

                return _buildList(snapshot.data!);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<CompanyData> list) {
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        return CompanyCard(
          company: list[index],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CompanyDetailScreen(company: list[index]),
              ),
            );
          },
        );
      },
    );
  }
}
