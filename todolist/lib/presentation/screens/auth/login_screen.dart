import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todolist/presentation/widgets/common/custom_text_field.dart';
import 'package:todolist/presentation/widgets/common/social_login_button.dart';
import 'package:todolist/presentation/widgets/common/primary_button.dart';
import 'package:todolist/presentation/screens/auth/register_screen.dart';
import 'package:todolist/presentation/screens/auth/forgot_password_screen.dart';
import 'package:todolist/data/services/api_client.dart';
import 'package:todolist/data/services/oauth_service.dart';
import 'package:todolist/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final OAuthService _oauthService = OAuthService();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Validate input
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    // Use AuthProvider to login
    final authNotifier = ref.read(authProvider.notifier);
    final success = await authNotifier.login(
      emailController.text.trim(),
      passwordController.text,
    );

    if (!mounted) return;

    if (!success) {
      // Error message will be shown by listening to authProvider state
      final errorMessage = ref.read(authProvider).errorMessage;
      if (errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đăng nhập thất bại: $errorMessage')),
        );
      }
    }
    // Navigation will be handled automatically by SplashScreen's ref.listen
  }

  Future<void> _handleGoogleLogin() async {
    try {
      final result = await _oauthService.signInWithGoogle();
      
      if (!mounted) return;

      if (result['success']) {
        // Reload auth state after Google login
        final authNotifier = ref.read(authProvider.notifier);
        await authNotifier.login(
          result['email'] ?? '', 
          '', // Google login doesn't need password
        );

        if (result['isNewUser']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chào mừng bạn đến với CollabTask!')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['errorMessage'] ?? 'Đăng nhập thất bại')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  Future<void> _handleFacebookLogin() async {
    try {
      final result = await _oauthService.signInWithFacebook();
      
      if (!mounted) return;

      if (result['success']) {
        // Reload auth state after Facebook login
        final authNotifier = ref.read(authProvider.notifier);
        await authNotifier.login(
          result['email'] ?? '', 
          '', // Facebook login doesn't need password
        );

        if (result['isNewUser']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chào mừng bạn đến với CollabTask!')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['errorMessage'] ?? 'Đăng nhập thất bại')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state for loading status
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

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
                    if (authState.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          authState.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    PrimaryButton(
                      text: isLoading ? 'Đang đăng nhập...' : 'Đăng nhập',
                      onPressed: isLoading ? (){} : () {
                        _handleLogin();
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
                      children: [
                        Expanded(
                          child: SocialLoginButton(
                            icon: Icons.g_mobiledata,
                            label: 'Google',
                            onPressed: isLoading ? null : _handleGoogleLogin,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SocialLoginButton(
                            icon: Icons.facebook,
                            label: 'Facebook',
                            onPressed: isLoading ? null : _handleFacebookLogin,
                          ),
                        ),
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
