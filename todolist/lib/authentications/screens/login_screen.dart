import 'package:flutter/material.dart';
import 'package:todolist/Group_Management/group_management_screen.dart';
import 'package:todolist/url_launcher_demo/url_launcher_app.dart';
import 'package:todolist/user_dashboard/screens/user_dashboard_screen.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/social_login_button.dart';
import '../widgets/primary_button.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../../Project_Dashboard/screens/project_dashboard.dart';
import '../../Group_Management/group_management_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 600;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 400 : double.infinity),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Đăng nhập',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: emailController,
                      labelText: 'Nhập tài khoản (Email hoặc SĐT)',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: passwordController,
                      labelText: 'Nhập mật khẩu',
                      icon: Icons.lock,
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ));
                        },
                        child: const Text('Quên mật khẩu?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    PrimaryButton(
                      text: 'Đăng nhập',
                      onPressed: () {
                        // TODO: Thêm xử lý đăng nhập thật ở đây
                        // Tạm thời bỏ qua xử lý xác thực, chỉ test chuyển màn hình
                        Navigator.push(
                          context,
                         //MaterialPageRoute(builder: (_) => const UserDashboardScreen()),
                          MaterialPageRoute(builder: (_) => const UrlLauncherDemoApp()),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Hoặc đăng nhập bằng',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SocialLoginButton(icon: Icons.g_mobiledata, label: 'Google'),
                        SizedBox(width: 12),
                        SocialLoginButton(icon: Icons.facebook, label: 'Facebook'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Bạn chưa có tài khoản?'),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ));
                          },
                          child: const Text('Đăng ký ngay'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
