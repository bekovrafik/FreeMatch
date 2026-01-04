import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;

  final List<Map<String, dynamic>> _steps = [
    {
      "title": "Discover People",
      "desc": "Swipe right on profiles that catch your eye. It's that simple.",
      "icon": Icons.favorite,
      "color": Colors.pink,
    },
    {
      "title": "Stay Connected",
      "desc":
          "Match and chat instantly. No hidden fees for basic communication.",
      "icon": Icons.chat_bubble,
      "color": Colors.blue,
    },
    {
      "title": "Support Creators",
      "desc": "We keep it free by showing occasional sponsored content.",
      "icon": Icons.auto_awesome, // Sparkles equiv
      "color": Colors.amber,
    },
  ];

  void _next() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: List.generate(_steps.length, (index) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index <= _currentStep
                            ? Colors.white
                            : const Color(0xFF1E293B), // Slate-800
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const Spacer(),

            // Content (Animated Switcher for Transitions)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.2, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Column(
                key: ValueKey<int>(_currentStep),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (step["color"] as Color).withValues(alpha: 0.2),
                      boxShadow: [
                        BoxShadow(
                          color: (step["color"] as Color).withValues(alpha: 0.1),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      step["icon"] as IconData,
                      size: 64,
                      color: step["color"] as Color,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    step["title"] as String,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text(
                      step["desc"] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF94A3B8), // Slate-400
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B), // Slate-800
                    foregroundColor: Colors.white,
                    side: const BorderSide(
                      color: Color(0xFF334155),
                    ), // Slate-700
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentStep == _steps.length - 1
                            ? "Create Account"
                            : "Next",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
