import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../widgets/company_card.dart';
import '../data/mock_data.dart';
import 'company_detail_screen.dart';
import 'settings_screen.dart'; // 🟢 引入設定頁面
import '../services/supabase_service.dart';
import '../models/company.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  // 🟢 靜態開關，供設定頁面一併操控
  static bool isNotificationEnabled = true;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<CompanyData>> _companiesFuture;
  late Future<List<String>> _yearsFuture;
  String _selectedYear = '2025 年';
  String _selectedIndustry = '全產業';

  // 🟢 宣告 Banner 廣告變數
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  // 🟢 宣告插頁廣告變數與計數器
  InterstitialAd? _interstitialAd;
  int _clickCount = 0;

  final List<String> _industries = [
    '全產業',
    '半導體業',
    '金融業',
    '電腦及週邊設備業',
    '航運業',
    '電子零組件業',
    '其他電子業'
  ];

  @override
  void initState() {
    super.initState();
    _companiesFuture = _supabaseService.fetchTopCompanies();
    _yearsFuture = _supabaseService.fetchAvailableYears();
  }

  @override
  void dispose() {
    _bannerAd?.dispose(); // 🟢 釋放廣告資源
    super.dispose();
  }

  bool _isAdInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isAdInitialized) {
      _loadBannerAd();
      _isAdInitialized = true;
    }
  }

  // 🟢 創建並載入「滿版自適應」廣告方法
  void _loadBannerAd() async {
    // 獲取目前螢幕寬度的自適應廣告大小
    final AnchoredAdaptiveBannerAdSize? size = 
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQuery.of(context).size.width.truncate(),
    );

    if (size == null) return;

    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-8735556969811073/8566599420', // 正式廣告單元 ID
      size: size, // 👈 換成滿版自適應 Size
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          // print('Ad fails to load: $error');
        },
      ),
    )..load();
    _loadInterstitialAd(); // 🟢 第一時間載入插頁廣告
  }

  // 🟢 載入插頁廣告方法
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-8735556969811073/9031336571', // 您的正式插頁廣告 ID
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null; // 失敗則重置
        },
      ),
    );
  }

  // 🟢 顯示插頁廣告方法（安全保障，看完後執行 onComplete）
  void _showInterstitialAd(VoidCallback onComplete) {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitialAd(); // 預載下一檔
          onComplete(); // 看完廣告立刻跳轉
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _loadInterstitialAd();
          onComplete(); // 失敗也跳轉，不阻礙
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null; // 展示後清空，避免重複觸發
    } else {
      onComplete(); // 暫無廣告時直接跳轉
    }
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
      backgroundColor: const Color(0xFF12141A),
      appBar: AppBar(
        title: const Text(
          '獲利王 Profit Leader',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: const Color(0xFF12141A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.settings), // 🟢 換成設定圖標
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
          const SizedBox(height: 12),
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
                    backgroundColor: const Color(0xFF1A1D24),
                    selectedColor: const Color(0xFF10B981).withValues(alpha: 0.15), // Green tinted
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF10B981) : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF10B981) : Colors.white24,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          if (['航運業', '電子零組件業', '其他電子業'].contains(_selectedIndustry))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                 children: [
                    const Icon(Icons.lightbulb_outline, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '此頁面只顯示獲利前五名公司',
                      style: TextStyle(color: Colors.amber.withValues(alpha: 0.8), fontSize: 11),
                    ),
                 ],
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
      bottomNavigationBar: _isAdLoaded && _bannerAd != null
          ? SafeArea(
              child: Container(
                color: const Color(0xFF0F121C),
                height: _bannerAd!.size.height.toDouble(),
                width: _bannerAd!.size.width.toDouble(),
                alignment: Alignment.center,
                child: AdWidget(ad: _bannerAd!),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildList(List<CompanyData> list) {
    return ListView.builder(
      itemCount: list.length + 1, // 🟢 增加 1 行給底部免責聲明使用
      itemBuilder: (context, index) {
        // 🟢 如果是最後一行，顯示免責聲明 Footer
        if (index == list.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              children: [
                const Divider(color: Colors.white10, thickness: 1),
                const SizedBox(height: 16),
                Text(
                  '💡 重要免責聲明與警語',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '本應用程式提供之淨利數據、ETF持有該股張數和持股權重及排行榜，均取自各投信官網及公開財報歷史數據整合運算，僅供個人化理財研究之參考。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '數據不代表未來獲利保證，亦不構成任何形式之買賣操作與投資建議。股市投資具備極大風險，用戶應進行審慎評估，並對其所有投資決策及產出之盈虧負擔全部責任。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '本軟體已盡力確保數據之正確性。惟對於可能發生的資料內容錯誤、更新延遲、系統連線中斷或故障，本團隊概不負擔任何形式之連帶擔保與損害賠償責任。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }

        return CompanyCard(
          company: list[index],
          onTap: () {
            _clickCount++;
            
            void navigateAction() {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CompanyDetailScreen(company: list[index]),
                ),
              );
            }

            // 每 3 次點選，觸發 1 次插頁廣告
            if (_clickCount % 3 == 0) {
              _showInterstitialAd(navigateAction);
            } else {
              navigateAction();
            }
          },
        );
      },
    );
  }
}
