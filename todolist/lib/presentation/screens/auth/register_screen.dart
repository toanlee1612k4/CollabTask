import 'package:flutter/material.dart';
import 'package:todolist/data/services/api_client.dart';
import 'dart:math' as math;

// --- 1. CONFIG & UTILS (COPY TỪ LOGIN SCREEN) ---
// Giữ nguyên bộ màu và widget từ màn hình Login để đồng bộ giao diện
class AppColors {
  static const Color background = Color(0xFFe0e5ec);
  static const Color shadowDark = Color(0xFFbec3cf);
  static const Color shadowLight = Color(0xFFffffff);
  static const Color textDark = Color(0xFF3d4468);
  static const Color textLight = Color(0xFF9499b7);
  static const Color error = Color(0xFFff3b5c);
  static const Color success = Color(0xFF00c896);
}

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

// --- 2. REGISTER SCREEN ---

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  // Logic cũ: Các controller giữ nguyên
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;

  // Logic mới: Animation & UI State
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
    nameController.dispose();
    emailController.dispose();
    fullNameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    _shakeController.dispose(); // Dispose animation
    super.dispose();
  }

  // Logic cũ: Handle Register (Giữ nguyên logic gốc)
  Future<void> _handleRegister() async {
    // Validate input
    if (emailController.text.trim().isEmpty) {
      _triggerError('Vui lòng nhập email');
      return;
    }
    if (fullNameController.text.trim().isEmpty) {
      _triggerError('Vui lòng nhập họ và tên');
      return;
    }
    if (passwordController.text.trim().isEmpty) {
      _triggerError('Vui lòng nhập mật khẩu');
      return;
    }
    if (passwordController.text.length < 6) {
      _triggerError('Mật khẩu phải có ít nhất 6 ký tự');
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
          backgroundColor: AppColors.success, // Đổi màu cho hợp theme
        ),
      );

      // Navigate back to login
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _triggerError('Đăng ký thất bại: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Helper mới: Vừa hiện thông báo vừa rung màn hình
  void _triggerError(String message) {
    _shakeController.forward(from: 0.0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  // Logic Ambient Light
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: MouseRegion(
            onHover: _updateAmbientLight,
            onExit: _resetAmbientLight,
            child: ShakeWidget(
              controller: _shakeController,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: NeumorphicContainer(
                  key: _cardKey,
                  dynamicShadowOffset: _mousePos.distance > 0 ? _mousePos : null,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      const Text(
                        'Tạo tài khoản',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28, 
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Điền thông tin để bắt đầu',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: AppColors.textLight),
                      ),
                      const SizedBox(height: 30),

                      // Input Fields
                      _buildNeumorphicInput(
                        controller: nameController, 
                        label: 'Tên tài khoản', 
                        icon: Icons.person_outline
                      ),
                      const SizedBox(height: 20),
                      
                      _buildNeumorphicInput(
                        controller: emailController, 
                        label: 'Email', 
                        icon: Icons.email_outlined
                      ),
                      const SizedBox(height: 20),
                      
                      _buildNeumorphicInput(
                        controller: fullNameController, 
                        label: 'Họ và tên', 
                        icon: Icons.badge_outlined
                      ),
                      const SizedBox(height: 20),
                      
                      _buildNeumorphicInput(
                        controller: phoneController, 
                        label: 'Số điện thoại', 
                        icon: Icons.phone_outlined
                      ),
                      const SizedBox(height: 20),
                      
                      _buildNeumorphicInput(
                        controller: passwordController, 
                        label: 'Mật khẩu', 
                        icon: Icons.lock_outline,
                        isPassword: true
                      ),
                      const SizedBox(height: 30),

                      // Register Button
                      NeumorphicContainer(
                        width: double.infinity,
                        height: 56,
                        onTap: _isLoading ? null : _handleRegister,
                        child: Center(
                          child: _isLoading 
                            ? const SizedBox(
                                width: 24, height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textDark),
                              )
                            : const Text(
                                'ĐĂNG KÝ NGAY',
                                style: TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Text('Hoặc đăng nhập bằng', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textLight)),
                      const SizedBox(height: 16),
                      
                      // Social Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialBtn(Icons.g_mobiledata),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Bạn đã có tài khoản? ', style: TextStyle(color: AppColors.textLight)),
                          GestureDetector(
                            onTap: _isLoading ? null : () => Navigator.pop(context),
                            child: const Text(
                              'Đăng nhập ngay',
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper Widget cho Input
  Widget _buildNeumorphicInput({
    required TextEditingController controller,
    required String label,
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
                hintText: label,
                hintStyle: const TextStyle(color: Colors.transparent),
                labelText: label,
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

  Widget _buildSocialBtn(IconData icon) {
    return NeumorphicContainer(
      width: 50, height: 50,
      onTap: () {}, // Thêm logic social login nếu cần
      child: Icon(icon, color: const Color(0xFF6c7293)),
    );
  }
}