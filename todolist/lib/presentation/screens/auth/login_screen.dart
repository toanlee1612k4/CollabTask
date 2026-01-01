import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todolist/presentation/screens/auth/register_screen.dart';
import 'package:todolist/presentation/screens/auth/forgot_password_screen.dart';
import 'package:todolist/data/services/oauth_service.dart';
import 'package:todolist/providers/auth_provider.dart';
import '../../layouts/app_layout.dart';
import 'dart:math' as math;

// --- 1. CONFIG & UTILS (GIỮ NGUYÊN) ---
class AppColors {
  static const Color background = Color(0xFFe0e5ec);
  static const Color shadowDark = Color(0xFFbec3cf);
  static const Color shadowLight = Color(0xFFffffff);
  static const Color textDark = Color(0xFF3d4468);
  static const Color textLight = Color(0xFF9499b7);
  static const Color error = Color(0xFFff3b5c);
  static const Color success = Color(0xFF00c896);
}

// Widget hiệu ứng rung
class ShakeWidget extends StatelessWidget {
  final Widget child;
  final AnimationController controller;

  const ShakeWidget({Key? key, required this.child, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final sineValue = math.sin(4 * math.pi * controller.value);
        return Transform.translate(
          offset: Offset(sineValue * 10, 0),
          child: child,
        );
      },
      child: child,
    );
  }
}

// Neumorphic Container
class NeumorphicContainer extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final bool pressed;
  final VoidCallback? onTap;
  final bool isCircle;
  final Offset? dynamicShadowOffset;

  const NeumorphicContainer({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.pressed = false,
    this.onTap,
    this.isCircle = false,
    this.dynamicShadowOffset,
  }) : super(key: key);

  @override
  State<NeumorphicContainer> createState() => _NeumorphicContainerState();
}

class _NeumorphicContainerState extends State<NeumorphicContainer> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    double offset = 8;
    double blur = 16;
    
    Offset darkOffset = widget.dynamicShadowOffset ?? Offset(offset, offset);
    Offset lightOffset = widget.dynamicShadowOffset != null 
        ? -widget.dynamicShadowOffset! 
        : Offset(-offset, -offset);

    if (widget.pressed) {
      darkOffset = const Offset(2, 2);
      lightOffset = const Offset(-2, -2);
      blur = 5;
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isHovering && widget.onTap != null ? 1.02 : 1.0),
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: AppColors.background,
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.isCircle ? null : BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: widget.pressed ? AppColors.shadowDark.withOpacity(0.5) : AppColors.shadowDark,
                offset: darkOffset,
                blurRadius: blur,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: widget.pressed ? AppColors.shadowLight : AppColors.shadowLight,
                offset: lightOffset,
                blurRadius: blur,
                spreadRadius: 1,
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// --- 2. LOGIN SCREEN ---

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with TickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final OAuthService _oauthService = OAuthService();
  
  late AnimationController _shakeController;
  bool _obscurePassword = true;
  Offset _mousePos = Offset.zero;
  final GlobalKey _cardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // --- Logic xử lý Login ---
  Future<void> _handleLogin() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _shakeController.forward(from: 0.0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin'), backgroundColor: AppColors.error),
      );
      return;
    }
    // Gọi login (Provider sẽ lo phần gọi API)
    await ref.read(authProvider.notifier).login(
      emailController.text.trim(),
      passwordController.text,
    );
  }

  // Giữ nguyên logic Social Login cũ của cậu
  Future<void> _handleGoogleLogin() async {
     // ... (Logic cũ giữ nguyên)
  }
  Future<void> _handleFacebookLogin() async {
     // ... (Logic cũ giữ nguyên)
  }

  void _updateAmbientLight(PointerEvent details) {
    final RenderBox? box = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      final size = box.size;
      final center = size.center(Offset.zero);
      final localPosition = details.localPosition;
      final dx = (localPosition.dx - center.dx) / (size.width / 2);
      final dy = (localPosition.dy - center.dy) / (size.height / 2);
      setState(() {
        _mousePos = Offset(dx * 20, dy * 20); 
      });
    }
  }

  void _resetAmbientLight(_) {
    setState(() => _mousePos = Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 CẬP NHẬT LOGIC LẮNG NGHE TRẠNG THÁI LOGIN TẠI ĐÂY 🔥
    ref.listen<AuthState>(authProvider, (previous, next) async {
      // 1. Nếu Đăng nhập thành công
      if (next.status == AuthStatus.authenticated) {
        if (mounted) {
          // Hiện thông báo thành công màu Xanh
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng nhập thành công! Đang chuyển trang...'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 1), // Hiện trong 1 giây
            ),
          );

          // Đợi 1 chút cho người dùng kịp đọc thông báo (tạo cảm giác mượt)
          await Future.delayed(const Duration(seconds: 1));

          // Chuyển sang Dashboard
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AppLayout(initialIndex: 0)),
            );
          }
        }
      } 
      // 2. Nếu Đăng nhập thất bại
      else if (next.status == AuthStatus.failure) {
        // Kích hoạt hiệu ứng Rung form
        _shakeController.forward(from: 0.0);
        
        if (mounted) {
          // Hiện thông báo lỗi (Lấy message từ server hoặc text mặc định)
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage ?? 'Đăng nhập thất bại. Vui lòng kiểm tra lại!'), 
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    // --- MAIN LAYOUT BUILDER ---
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 900;

          if (isDesktop) {
            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.all(60),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NeumorphicContainer(
                          width: 100, height: 100, isCircle: true,
                          child: const Icon(Icons.check_circle_outline, size: 50, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 40),
                        const Text(
                          "CollabTask",
                          style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: AppColors.textDark, height: 1.2),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Quản lý công việc và thời gian hiệu quả.",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Giải pháp tối ưu giúp bạn sắp xếp kế hoạch, theo dõi tiến độ và làm việc nhóm một cách mượt mà nhất.",
                          style: TextStyle(fontSize: 16, color: AppColors.textLight, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Center(
                    child: SingleChildScrollView(
                      child: _buildLoginForm(isLoading),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      "CollabTask",
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Quản lý công việc & thời gian",
                      style: TextStyle(fontSize: 14, color: AppColors.textLight),
                    ),
                    const SizedBox(height: 30),
                    _buildLoginForm(isLoading),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildLoginForm(bool isLoading) {
    return MouseRegion(
      onHover: _updateAmbientLight, 
      onExit: _resetAmbientLight,
      child: ShakeWidget(
        controller: _shakeController,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: NeumorphicContainer(
            key: _cardKey,
            dynamicShadowOffset: _mousePos.distance > 0 ? _mousePos : null,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NeumorphicContainer(
                  width: 80, height: 80, isCircle: true,
                  child: const Icon(Icons.person, size: 40, color: Color(0xFF6c7293)),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Chào mừng trở lại',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Đăng nhập để tiếp tục',
                  style: TextStyle(fontSize: 15, color: AppColors.textLight),
                ),
                const SizedBox(height: 32),

                _buildNeumorphicInput(
                  controller: emailController,
                  hint: 'Email',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 28),

                _buildNeumorphicInput(
                  controller: passwordController,
                  hint: 'Mật khẩu',
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                const SizedBox(height: 20),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ));
                    },
                    child: const Text(
                      'Quên mật khẩu?',
                      style: TextStyle(color: Color(0xFF6c7293), fontWeight: FontWeight.w500),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                NeumorphicContainer(
                  width: double.infinity,
                  height: 56,
                  onTap: isLoading ? null : _handleLogin,
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textDark),
                          )
                        : const Text(
                            'ĐĂNG NHẬP',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 30),
                const Text("Hoặc đăng nhập bằng", style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialBtn(Icons.g_mobiledata, isLoading ? null : _handleGoogleLogin),
                    const SizedBox(width: 20),
                    _buildSocialBtn(Icons.facebook, isLoading ? null : _handleFacebookLogin),
                  ],
                ),

                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Chưa có tài khoản? ", style: TextStyle(color: AppColors.textLight)),
                    GestureDetector(
                      onTap: () {
                        // Bỏ const ở đây nếu bị lỗi const
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => RegisterScreen(),
                        ));
                      },
                      child: const Text(
                        'Đăng ký ngay',
                        style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNeumorphicInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return NeumorphicContainer(
      pressed: true,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textLight, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword && _obscurePassword,
              style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.transparent), 
                labelText: hint, 
                labelStyle: const TextStyle(color: AppColors.textLight),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          if (isPassword)
            GestureDetector(
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textLight,
                size: 20,
              ),
            )
        ],
      ),
    );
  }

  Widget _buildSocialBtn(IconData icon, VoidCallback? onTap) {
    return NeumorphicContainer(
      width: 50, height: 50,
      onTap: onTap,
      child: Icon(icon, color: const Color(0xFF6c7293)),
    );
  }
}