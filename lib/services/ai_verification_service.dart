import 'dart:convert';
import 'dart:io';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiVerificationService {
  final GenerativeModel _model;

  AiVerificationService()
    : _model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-1.5-flash',
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

  Future<Map<String, dynamic>> verifyIdentity({
    required File idImage,
    required File selfieImage,
  }) async {
    try {
      final idBytes = await idImage.readAsBytes();
      final selfieBytes = await selfieImage.readAsBytes();

      // Determine MIME type roughly (default to jpeg as per API tolerance)
      const mimeType = 'image/jpeg';

      final prompt = Content.multi([
        TextPart(
          "You are an automated identity verification system. "
          "Strictly analyze these two images. "
          "Image 1 is an ID Document (Passport or ID Card). "
          "Image 2 is a Selfie of a user attempting to verify themselves. "
          "TASKS:\n"
          "1. Verify if the person in the ID photo MATCHES the person in the Selfie.\n"
          "2. Verify if the person in the Selfie is performing a 'Peace Sign' (V sign) hand gesture.\n\n"
          "Return a JSON object with this structure:\n"
          "{\n"
          " \"isMatch\": boolean,\n"
          " \"isGesturing\": boolean,\n"
          " \"confidence\": number (0.0 to 1.0),\n"
          " \"reason\": \"short explanation of the decision\"\n"
          "}",
        ),
        InlineDataPart(mimeType, idBytes),
        InlineDataPart(mimeType, selfieBytes),
      ]);

      final response = await _model.generateContent([prompt]);

      final text = response.text;
      if (text == null) {
        return {
          'isMatch': false,
          'isGesturing': false,
          'confidence': 0.0,
          'reason': "No response generated from AI.",
        };
      }

      // Clean (just in case model adds ticks despite JSON mode)
      final cleanJson = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      try {
        final Map<String, dynamic> data = jsonDecode(cleanJson);
        return data;
      } catch (e) {
        debugPrint("JSON Parse Error: $e. \nRaw Text: $text");
        return {
          'isMatch': false,
          'isGesturing': false,
          'confidence': 0.0,
          'reason': "Failed to parse AI response.",
        };
      }
    } catch (e) {
      debugPrint("AI Verification Error: $e");
      return {
        'isMatch': false,
        'isGesturing': false,
        'confidence': 0.0,
        'reason': "System Error: ${e.toString()}",
      };
    }
  }
}

final aiVerificationServiceProvider = Provider<AiVerificationService>((ref) {
  return AiVerificationService();
});
