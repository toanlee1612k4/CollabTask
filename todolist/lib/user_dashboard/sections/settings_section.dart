import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    bool otpEnabled = true;
    bool notificationsEnabled = true;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          const Text('Cài đặt tài khoản',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Thông tin cá nhân
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Thông tin cá nhân'),
              subtitle: const Text('Xem và chỉnh sửa thông tin cá nhân của bạn'),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {},
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Đổi mật khẩu
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Đổi mật khẩu'),
              subtitle: const Text('Thay đổi mật khẩu đăng nhập'),
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 18),
                onPressed: () {},
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Bảo mật
          SwitchListTile(
            value: otpEnabled,
            onChanged: (_) {},
            title: const Text('Xác thực OTP'),
            subtitle: const Text('Bật / tắt xác thực hai lớp khi đăng nhập'),
          ),

          // Thông báo
          SwitchListTile(
            value: notificationsEnabled,
            onChanged: (_) {},
            title: const Text('Thông báo'),
            subtitle: const Text('Nhận thông báo về công việc và dự án mới'),
          ),
        ],
      ),
    );
  }
}
