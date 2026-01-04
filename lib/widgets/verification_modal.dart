import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_verification_service.dart';

class VerificationModal extends ConsumerStatefulWidget {
  final VoidCallback onVerified;

  const VerificationModal({super.key, required this.onVerified});

  @override
  ConsumerState<VerificationModal> createState() => _VerificationModalState();
}

class _VerificationModalState extends ConsumerState<VerificationModal> {
  int _step = 0;
  // 0: Intro
  // 1: Upload ID
  // 2: Gesture Guide
  // 3: Take Selfie
  // 4: Processing
  // 5: Success
  // 6: Failure

  File? _idImage;
  File? _selfieImage;
  String _failureReason = "";
  final ImagePicker _picker = ImagePicker();

  void _nextStep() {
    setState(() => _step++);
  }

  Future<void> _pickIdImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _idImage = File(image.path);
      });
      _nextStep();
    }
  }

  Future<void> _takeSelfie() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
    );
    if (image != null) {
      setState(() {
        _selfieImage = File(image.path);
        _step = 4; // Go to processing
      });
      _processVerification();
    }
  }

  Future<void> _processVerification() async {
    if (_idImage == null || _selfieImage == null) {
      setState(() {
        _failureReason = "Missing images.";
        _step = 6;
      });
      return;
    }

    final result = await ref
        .read(aiVerificationServiceProvider)
        .verifyIdentity(idImage: _idImage!, selfieImage: _selfieImage!);

    if (!mounted) return;

    final isMatch = result['isMatch'] == true;
    final isGesturing = result['isGesturing'] == true;

    if (isMatch && isGesturing) {
      setState(() {
        _step = 5; // Success
      });
    } else {
      setState(() {
        _failureReason = result['reason'] ?? "Verification failed.";
        if (!isMatch) _failureReason += "\n\nIdentity mismatch.";
        if (!isGesturing) _failureReason += "\n\nGesture not detected.";
        _step = 6; // Failure
      });
    }
  }

  void _finish() {
    widget.onVerified();
    Navigator.pop(context);
  }

  void _retry() {
    setState(() {
      _step = 0;
      _idImage = null;
      _selfieImage = null;
      _failureReason = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildStepContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildIntroStep();
      case 1:
        return _buildIdUploadStep();
      case 2:
        return _buildGestureStep();
      case 3:
        return _buildCameraStep();
      case 4:
        return _buildProcessingStep();
      case 5:
        return _buildSuccessStep();
      case 6:
        return _buildFailureStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildIntroStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.verified, size: 80, color: Colors.blue),
        const SizedBox(height: 24),
        const Text(
          "Get Verified",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "To get verified, we'll need two things:\n1. A photo of your ID/Passport\n2. A selfie doing a specific gesture.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 40),
        _buildButton("Start Verification", _nextStep),
      ],
    );
  }

  Widget _buildIdUploadStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.credit_card, size: 80, color: Colors.orange),
        const SizedBox(height: 24),
        const Text(
          "Upload ID",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Please upload a clear photo of your ID or Passport.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 40),
        _buildButton("Select ID Photo", _pickIdImage),
      ],
    );
  }

  Widget _buildGestureStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Copy this gesture",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Text("✌️", style: TextStyle(fontSize: 80)),
        ),
        const SizedBox(height: 40),
        const Text(
          "You must make the Peace Sign (V) with your hand in your selfie.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 40),
        _buildButton("I'm Ready", _nextStep),
      ],
    );
  }

  Widget _buildCameraStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.camera_front, size: 80, color: Colors.blue),
        const SizedBox(height: 24),
        const Text(
          "Take Selfie",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Make sure your face and the gesture are clearly visible.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 40),
        _buildButton("Open Camera", _takeSelfie),
      ],
    );
  }

  Widget _buildProcessingStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: Colors.blue),
        const SizedBox(height: 24),
        const Text(
          "Analyzing...",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Our AI is checking your ID and verifying your gesture.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, size: 80, color: Colors.green),
        const SizedBox(height: 24),
        const Text(
          "Verified!",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Identity confirmed. You've earned the Blue Badge.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 40),
        _buildButton("Awesome!", _finish),
      ],
    );
  }

  Widget _buildFailureStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 80, color: Colors.red),
        const SizedBox(height: 24),
        const Text(
          "Verification Failed",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Text(
            _failureReason,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent, fontSize: 14),
          ),
        ),
        const SizedBox(height: 40),
        _buildButton("Try Again", _retry),
      ],
    );
  }

  Widget _buildButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
