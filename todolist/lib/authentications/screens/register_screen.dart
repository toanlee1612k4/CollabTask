import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/social_login_button.dart';
import '../widgets/primary_button.dart';
import 'login_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final fullNameController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Tạo tài khoản')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(controller: nameController, labelText: 'Tên tài khoản', icon: Icons.person),
              const SizedBox(height: 12),
              CustomTextField(controller: emailController, labelText: 'Email', icon: Icons.email),
              const SizedBox(height: 12),
              CustomTextField(controller: fullNameController, labelText: 'Họ và tên', icon: Icons.badge),
              const SizedBox(height: 12),
              CustomTextField(controller: phoneController, labelText: 'Số điện thoại', icon: Icons.phone),
              const SizedBox(height: 12),
              CustomTextField(controller: passwordController, labelText: 'Mật khẩu', icon: Icons.lock, obscureText: true),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'Đăng ký ngay',
                onPressed: () {},
              ),
              const SizedBox(height: 16),
              const Text('Hoặc đăng nhập bằng', textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SocialLoginButton(icon: Icons.g_mobiledata, label: 'Google'),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Bạn đã có tài khoản?'),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Đăng nhập ngay'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
