import 'package:flutter/material.dart';
import 'dart:math' as math;

// --- 1. CONFIG & UTILS (COPY ĐỂ ĐỒNG BỘ GIAO DIỆN) ---
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

// --- 2. FORGOT PASSWORD SCREEN ---

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with TickerProviderStateMixin {
  final emailController = TextEditingController();
  
  // Animation & UI State
  late AnimationController _shakeController;
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
    _shakeController.dispose();
    super.dispose();
  }

  // Logic Ambient Light (Hiệu ứng ánh sáng)
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

  // Logic xử lý gửi link (Giả lập)
  void _handleSendLink() {
    if (emailController.text.isEmpty) {
      _shakeController.forward(from: 0.0); // Rung nếu trống
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập email'),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      // Logic gửi link gốc của bạn ở đây (hiện tại đang trống)
      // Thêm thông báo giả lập để test UI
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi liên kết khôi phục!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Xóa AppBar mặc định, dùng background xám
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                      // Icon Khóa
                      NeumorphicContainer(
                        width: 80, height: 80, isCircle: true,
                        child: const Icon(Icons.lock_reset, size: 40, color: Color(0xFF6c7293)),
                      ),
                      const SizedBox(height: 24),

                      // Tiêu đề
                      const Text(
                        'Quên mật khẩu?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Mô tả
                      const Text(
                        'Nhập email của bạn để nhận liên kết khôi phục mật khẩu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: AppColors.textLight, height: 1.5),
                      ),
                      const SizedBox(height: 32),
                      
                      // Input Email Style Neumorphism
                      _buildNeumorphicInput(
                        controller: emailController, 
                        label: 'Email', 
                        icon: Icons.email_outlined
                      ),
                      const SizedBox(height: 30),
                      
                      // Button Gửi
                      NeumorphicContainer(
                        width: double.infinity,
                        height: 56,
                        onTap: _handleSendLink,
                        child: const Center(
                          child: Text(
                            'GỬI LIÊN KẾT',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Button Quay lại
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_back, size: 16, color: AppColors.textLight),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              'Quay lại đăng nhập',
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

  // Helper cho Input
  Widget _buildNeumorphicInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return NeumorphicContainer(
      pressed: true, // Hiệu ứng lún
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textLight, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: TextField(
              controller: controller,
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
        ],
      ),
    );
  }
}