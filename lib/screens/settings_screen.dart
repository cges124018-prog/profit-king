import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'about_us_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 移除本地變數，直接存取 HomeScreen.isNotificationEnabled

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141A),
      appBar: AppBar(
        title: const Text('設定與資訊', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF12141A),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildSectionHeader('法律與政策'),
          _buildListTile(
            icon: Icons.privacy_tip_outlined,
            title: '隱私權政策',
            onTap: () async {
              final Uri url = Uri.parse('https://cges124018-prog.github.io/profit-king/privacy_policy.html');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          _buildListTile(
            icon: Icons.description_outlined,
            title: '使用者協議',
            onTap: () async {
              final Uri url = Uri.parse('https://cges124018-prog.github.io/profit-king/privacy_policy.html#terms');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          _buildListTile(
            icon: Icons.delete_outline,
            title: '要求刪除資料',
            onTap: () async {
              final Uri url = Uri.parse(
                  'mailto:profitleadertw@gmail.com?subject=${Uri.encodeComponent('【獲利王】要求刪除資料與相關設定')}&body=${Uri.encodeComponent('親愛的獲利王團隊，請幫我移除此應用程式中的個人化快取與相關參數數據，謝謝！')}');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('無法打開信箱，請至信箱手動寄信給 profitleadertw@gmail.com')),
                );
              }
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('關於我們'),
          _buildListTile(
            icon: Icons.info_outline,
            title: '關於我們',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutUsScreen()),
              );
            },
          ),
          _buildListTile(
            icon: Icons.email_outlined,
            title: '聯絡我們',
            subtitle: 'profitleadertw@gmail.com',
            onTap: () async {
              final Uri url = Uri.parse('mailto:profitleadertw@gmail.com');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          _buildListTile(
            icon: Icons.verified_user_outlined,
            title: '版本資訊',
            subtitle: 'Version 1.0.2',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('目前已是最新版本 !')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2233),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.white38)) : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}

