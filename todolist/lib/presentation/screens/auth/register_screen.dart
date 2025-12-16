import 'package:flutter/material.dart';
import 'package:todolist/presentation/widgets/common/custom_text_field.dart';
import 'package:todolist/presentation/widgets/common/social_login_button.dart';
import 'package:todolist/presentation/widgets/common/primary_button.dart';
import 'package:todolist/data/services/api_client.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    fullNameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Validate input
    if (emailController.text.trim().isEmpty) {
      _showError('Vui lòng nhập email');
      return;
    }
    if (fullNameController.text.trim().isEmpty) {
      _showError('Vui lòng nhập họ và tên');
      return;
    }
    if (passwordController.text.trim().isEmpty) {
      _showError('Vui lòng nhập mật khẩu');
      return;
    }
    if (passwordController.text.length < 6) {
      _showError('Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiClient = ApiClient();
      await apiClient.register(
        emailController.text.trim(),
        passwordController.text,
        fullNameController.text.trim(),
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký thành công! Vui lòng đăng nhập.'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to login
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showError('Đăng ký thất bại: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

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
                text: _isLoading ? 'Đang xử lý...' : 'Đăng ký ngay',
                onPressed: _isLoading ? () {} : _handleRegister,
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
                    onPressed: _isLoading
                        ? null
                        : () {
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
