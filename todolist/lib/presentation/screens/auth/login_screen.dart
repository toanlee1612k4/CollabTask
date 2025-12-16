import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist/presentation/widgets/common/custom_text_field.dart';
import 'package:todolist/presentation/widgets/common/social_login_button.dart';
import 'package:todolist/presentation/widgets/common/primary_button.dart';
import 'package:todolist/presentation/screens/auth/register_screen.dart';
import 'package:todolist/presentation/screens/auth/forgot_password_screen.dart';
import 'package:todolist/data/services/api_client.dart';
import 'package:todolist/data/services/oauth_service.dart';
import 'package:todolist/main.dart' show AuthProvider;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final OAuthService _oauthService = OAuthService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    // Validate input
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập đầy đủ thông tin';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call API login - this saves token internally
      await apiClient.login(
        emailController.text.trim(),
        passwordController.text,
      );

      if (!mounted) return;

      // Update auth state
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.loadCurrentUser();

      // Navigate to dashboard
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Đăng nhập thất bại: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _oauthService.signInWithGoogle();
      
      if (!mounted) return;

      if (result['success']) {
        // Update auth state
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.loadCurrentUser();

        if (result['isNewUser']) {
          // Show welcome message for new users
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chào mừng bạn đến với CollabTask!')),
          );
        }

        // Navigate to dashboard
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        setState(() {
          _errorMessage = result['errorMessage'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleFacebookLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _oauthService.signInWithFacebook();
      
      if (!mounted) return;

      if (result['success']) {
        // Update auth state
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.loadCurrentUser();

        if (result['isNewUser']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chào mừng bạn đến với CollabTask!')),
          );
        }

        // Navigate to dashboard
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        setState(() {
          _errorMessage = result['errorMessage'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

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
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    PrimaryButton(
                      text: _isLoading ? 'Đang đăng nhập...' : 'Đăng nhập',
                      onPressed: _isLoading ? (){} : () {
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
                            onPressed: _isLoading ? null : _handleGoogleLogin,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SocialLoginButton(
                            icon: Icons.facebook,
                            label: 'Facebook',
                            onPressed: _isLoading ? null : _handleFacebookLogin,
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
