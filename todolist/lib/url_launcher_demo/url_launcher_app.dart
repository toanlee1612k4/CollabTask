import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:todolist/main.dart';

import 'package:todolist/url_launcher_demo/ widgets/launch_button.dart';

// --- URI Demo ---
final Uri _uriWeb = Uri.parse('https://flutter.dev'); // Dễ test hơn pub.dev
final Uri _uriCall = Uri.parse('tel:+058573792');
final Uri _uriEmail = Uri.parse(
  'mailto:support@example.com?subject=Báo cáo lỗi ứng dụng&body=Xin chào, tôi đã tìm thấy một lỗi...',
);
final Uri _uriSMS = Uri.parse('sms:+84901234567?body=Xin chào từ Flutter!');
final Uri _uriMap = Uri.parse('geo:0,0?q=Bitexco+Tower,+Ho+Chi+Minh+City');

class UrlLauncherDemoApp extends StatelessWidget {
  const UrlLauncherDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'URL Launcher Full Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const UrlLauncherHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class UrlLauncherHomePage extends StatelessWidget {
  const UrlLauncherHomePage({super.key});

  /// ✅ Hàm mở URL (chạy ổn trên emulator có Chrome)
  Future<void> _launchUrl(BuildContext context, Uri url) async {
    final bool canLaunch = await canLaunchUrl(url);

    if (canLaunch) {
      try {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication, // mở app ngoài (Chrome, Dialer,...)
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi mở URL: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thiết bị không hỗ trợ mở ${url.scheme}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('URL Launcher Demo'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LaunchButton(
                icon: Icons.public,
                label: '1️⃣ Mở Website (flutter.dev)',
                color: Colors.blue,
                onPressed: () => _launchUrl(context, _uriWeb),
              ),
              const SizedBox(height: 12),
              LaunchButton(
                icon: Icons.phone,
                label: '2️⃣ Gọi điện thoại',
                color: Colors.green,
                onPressed: () => _launchUrl(context, _uriCall),
              ),
              const SizedBox(height: 12),
              LaunchButton(
                icon: Icons.email,
                label: '3️⃣ Gửi Email (mẫu sẵn)',
                color: Colors.orange,
                onPressed: () => _launchUrl(context, _uriEmail),
              ),
              const SizedBox(height: 12),
              LaunchButton(
                icon: Icons.sms,
                label: '4️⃣ Gửi tin nhắn SMS',
                color: Colors.pink,
                onPressed: () => _launchUrl(context, _uriSMS),
              ),
              const SizedBox(height: 12),
              LaunchButton(
                icon: Icons.map,
                label: '5️⃣ Mở Bản đồ (Bitexco Tower)',
                color: Colors.purple,
                onPressed: () => _launchUrl(context, _uriMap),
              ),
          // 🌟 Thay nút quay lại bằng TopBar
              // 🌟 Nút quay lại màn hình chính (dưới dạng Topbar)
              const SizedBox(height: 24),
              Container(
                margin: const EdgeInsets.only(top: 16),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('DasgBoard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (
                            context) => const DashboardShell()),

                    );

                  }
              ),


              )]),
        ),
      ),
    );
  }
}
