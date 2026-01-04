import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _fadeInController;

  @override
  void initState() {
    super.initState();
    // Remove native splash immediately as we transition to this screen
    FlutterNativeSplash.remove();

    _setupAnimations();
  }

  void _setupAnimations() {
    // Floating animation for background blobs
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    // Pulse animation for the central heart background
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Fade in animation for content
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..forward();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    _fadeInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Colors from design
    const primary = Color(0xFFD10056);
    const secondary = Color(0xFF7A003C);
    const accent = Color(0xFFFF4D8C);
    const backgroundLight = Color(0xFFFFF0F5);
    const backgroundDark = Color(0xFF1A0510);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? backgroundDark : backgroundLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // --- Background Liquid Shapes ---
          Positioned(
            top: -80,
            left: -80,
            child: _AnimatedLiquidShape(
              controller: _floatController,
              color: isDark
                  ? primary.withValues(alpha: 0.2)
                  : accent.withValues(alpha: 0.4),
              size: 384, // w-96
              offset: const Offset(0, -20),
            ),
          ),
          Positioned(
            bottom: -40,
            right: -40,
            child: _AnimatedLiquidShape(
              controller: _floatController,
              color: isDark
                  ? secondary.withValues(alpha: 0.3)
                  : primary.withValues(alpha: 0.4),
              size: 320, // w-80
              offset: const Offset(0, -20),
              delay: const Duration(seconds: 3),
            ),
          ),

          // Center blurred glow
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [
                    isDark
                        ? primary.withValues(alpha: 0.1)
                        : accent.withValues(alpha: 0.2),
                    isDark
                        ? secondary.withValues(alpha: 0.1)
                        : primary.withValues(alpha: 0.1),
                  ],
                ),
              ),
            ).blurred(blur: 100),
          ),

          // --- Main Content ---
          Center(
            child: FadeTransition(
              opacity: _fadeInController,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 0.05),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _fadeInController,
                        curve: Curves.easeOut,
                      ),
                    ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Pulsing Heart Backgrounds
                    SizedBox(
                      width: 250,
                      height: 250,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _PulsingCircle(
                            controller: _pulseController,
                            size: 192, // w-48
                            color: primary.withValues(alpha: 0.1),
                          ),
                          _PulsingCircle(
                            controller: _pulseController,
                            size: 160, // w-40
                            color: primary.withValues(alpha: 0.2),
                            delay: const Duration(milliseconds: 75),
                          ),
                          // Heart Icon
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: SizedBox(
                              width: 128, // w-32
                              height: 128,
                              child: CustomPaint(painter: HeartPainter()),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title "FreeMatch"
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.outfit(
                          fontSize: 48, // text-5xl
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                        children: [
                          TextSpan(
                            text: 'Free',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.grey[900],
                            ),
                          ),
                          TextSpan(
                            text: 'Match',
                            style: TextStyle(
                              foreground: Paint()
                                ..shader =
                                    const LinearGradient(
                                      colors: [accent, primary],
                                    ).createShader(
                                      const Rect.fromLTWH(0, 0, 200, 70),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      "Find your perfect rhythm.",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[300] : Colors.grey[500],
                      ),
                    ),

                    const SizedBox(height: 64),

                    // Loading Bar
                    Container(
                      width: 200,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: const _LoadingIndicator(color: primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Footer
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeInController,
              child: Text(
                "CONNECT • DATE • LOVE",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Helper Widgets & Painters ---

class _AnimatedLiquidShape extends StatelessWidget {
  final AnimationController controller;
  final Color color;
  final double size;
  final Offset offset;
  final Duration delay;

  const _AnimatedLiquidShape({
    required this.controller,
    required this.color,
    required this.size,
    required this.offset,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Calculate delayed animation value
        double val = controller.value;
        if (delay != Duration.zero) {
          // Simple delay logic for loop
          // This is an approximation for the CSS delay in infinite loop
          // Ideally we'd use separate controllers, but this is fine for visual effect
          val = (controller.value + 0.5) % 1.0;
        }

        // CSS Float keyframes: 0% Y=0, 50% Y=-20, 100% Y=0
        // Sine wave is perfect for this
        final dy = math.sin(val * 2 * math.pi) * offset.dy;

        return Transform.translate(
          offset: Offset(0, dy),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ).blurred(blur: 80),
        );
      },
    );
  }
}

class _PulsingCircle extends StatelessWidget {
  final AnimationController controller;
  final double size;
  final Color color;
  final Duration delay;

  const _PulsingCircle({
    required this.controller,
    required this.size,
    required this.color,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // CSS Pulse: 0.5 scale up to 1? The CSS says 'pulse 3s ...'
        // Tailwind pulse is: opacity 1 -> .5 -> 1.
        // But the html has custom 'pulse-slow'.
        // Let's do a gentle scale/opacity pulse.

        double val = controller.value;
        // Introduce phase shift for delay
        if (delay != Duration.zero) {
          val = (val + 0.1) % 1.0;
        }

        final scale = 1.0 + (math.sin(val * 2 * math.pi) * 0.05); // +/- 5%
        final opacity = 0.8 + (math.sin(val * 2 * math.pi) * 0.2); // 0.6 to 1.0

        return Transform.scale(
          scale: scale,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: color.a * opacity),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class _LoadingIndicator extends StatefulWidget {
  final Color color;
  const _LoadingIndicator({required this.color});

  @override
  State<_LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<_LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1, milliseconds: 500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FractionallySizedBox(
          widthFactor: 0.3,
          alignment: Alignment(
            -1.0 + (_controller.value * 2.0),
            0.0,
          ), // Moves from left to right
          child: Container(
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      },
    );
  }
}

extension BlurExtension on Widget {
  Widget blurred({required double blur}) {
    // Only blur if we can (performance check?)
    // Actually BackDropFilter blurs what's BEHIND it.
    // To blur the container ITSELF (like CSS filter: blur), we need ImageFiltered.
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: this,
    );
  }
}

// Importing dart:ui for ImageFilter - REMOVED from here

class HeartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Scale to 100x100 coord system from SVG
    final scaleX = w / 100;
    final scaleY = h / 100;

    canvas.scale(scaleX, scaleY);

    // 1. Main Heart Gradient
    final path = Path();
    // SVG Path: M50 88.5C50 88.5 12.5 67.5 5 42.5C-2.5 17.5 22.5 5 42.5 17.5C47.5 20.6 50 25 50 25C50 25 52.5 20.6 57.5 17.5C77.5 5 102.5 17.5 95 42.5C87.5 67.5 50 88.5 50 88.5Z
    path.moveTo(50, 88.5);
    path.cubicTo(50, 88.5, 12.5, 67.5, 5, 42.5);
    path.cubicTo(-2.5, 17.5, 22.5, 5, 42.5, 17.5);
    path.cubicTo(47.5, 20.6, 50, 25, 50, 25);
    path.cubicTo(50, 25, 52.5, 20.6, 57.5, 17.5);
    path.cubicTo(77.5, 5, 102.5, 17.5, 95, 42.5);
    path.cubicTo(87.5, 67.5, 50, 88.5, 50, 88.5);
    path.close();

    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFF4D8C), Color(0xFF7A003C)],
      ).createShader(const Rect.fromLTWH(0, 0, 100, 100));

    // Shadow
    canvas.drawShadow(
      path.shift(const Offset(0, 4)),
      const Color(0xFF7A003C).withValues(alpha: 0.3),
      4,
      true,
    );

    canvas.drawPath(path, paint);

    // 2. Multiply Layer 1
    // M5 42.5C8 38 12 34 16 32C30 25 35 45 50 50C65 55 70 35 84 32C88 31.1 92 31.5 95 33C87.5 67.5 50 88.5 50 88.5C50 88.5 12.5 67.5 5 42.5Z
    final path2 = Path();
    path2.moveTo(5, 42.5);
    path2.cubicTo(8, 38, 12, 34, 16, 32);
    path2.cubicTo(30, 25, 35, 45, 50, 50);
    path2.cubicTo(65, 55, 70, 35, 84, 32);
    path2.cubicTo(88, 31.1, 92, 31.5, 95, 33);
    path2.cubicTo(87.5, 67.5, 50, 88.5, 50, 88.5);
    path2.cubicTo(50, 88.5, 12.5, 67.5, 5, 42.5);
    path2.close();

    final paint2 = Paint()
      ..color = const Color(0xFF99004C).withValues(alpha: 0.3)
      ..blendMode = BlendMode.multiply;

    canvas.drawPath(path2, paint2);

    // 3. Multiply Layer 2
    // M15 55C25 50 30 65 45 70C60 75 70 55 85 50C90 48.3 93.5 50 94.5 52C89 67 65 80 50 88.5C35 80 20 67 15 55Z
    final path3 = Path();
    path3.moveTo(15, 55);
    path3.cubicTo(25, 50, 30, 65, 45, 70);
    path3.cubicTo(60, 75, 70, 55, 85, 50);
    path3.cubicTo(90, 48.3, 93.5, 50, 94.5, 52);
    path3.cubicTo(89, 67, 65, 80, 50, 88.5);
    path3.cubicTo(35, 80, 20, 67, 15, 55);
    path3.close();

    final paint3 = Paint()
      ..color = const Color(0xFF59002C).withValues(alpha: 0.4)
      ..blendMode = BlendMode.multiply;

    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
