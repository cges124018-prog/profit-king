import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141A),
      appBar: AppBar(
        title: const Text('關於我們', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF12141A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // App Logo Preview in circle or rounded container
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D24),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text(
                'PR',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '獲利王 Profit Leader',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            
            _buildAboutCard(
              title: '我們的使命',
              content: '「獲利王」致力於為投資人提供最簡潔、數據最精準的台灣上市公司年度淨利觀測儀表板。\n\n每一年，台灣上市公司的淨利都非常驚人，我們希望以方便、即時的體驗，讓全民都有機會共享到台灣經濟發展的豐厚果實。\n\n⚠️ 免責聲明：\n淨利數據不代表未來獲利保證，亦不構成任何形式之買賣操作與投資建議。股市投資具備風險，用戶應進行審慎評估，並對其所有投資決策及產出之盈虧負擔全部責任。',
            ),
            
            const SizedBox(height: 16),
            _buildAboutCard(
              title: '三大核心優勢',
              content: '',
              isBulletList: true,
              bullets: [
                '🥇 視覺優先：拋棄繁雜的看盤數字，主打一目了然的排行榜對比。',
                '⚡ 極速體驗：雲端 Supabase 特快同步伺服器，最新財報秒速載入。',
                '📱 現代適應：完美支援 Android & iOS 邊緣安全圓角，體驗滑順。',
              ],
            ),
            const SizedBox(height: 40),
            const Divider(color: Colors.white12),
            const SizedBox(height: 16),
            const Text(
              '© 2026 獲利王 團隊 . All rights reserved.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard({
    required String title,
    required String content,
    bool isBulletList = false,
    List<String>? bullets,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFF3B30),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (!isBulletList)
            Text(
              content,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          if (isBulletList && bullets != null)
            ...bullets.map((bullet) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    bullet,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
