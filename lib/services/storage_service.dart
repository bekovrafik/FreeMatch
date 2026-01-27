import 'dart:io';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

final storageServiceProvider = Provider((ref) => StorageService());

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Helper: Compress Image
  Future<File> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.absolute.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70, // 70% quality
        minWidth: 1024, // Resize to max 1024 width
        minHeight: 1024,
      );

      return result != null ? File(result.path) : file;
    } catch (e) {
      debugPrint("Error compressing image: $e");
      return file; // Return original if compression fails
    }
  }

  Future<String> uploadChatImage(File file, String chatId) async {
    final compressedFile = await _compressImage(file);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('chat_images/$chatId/$fileName');

    final uploadTask = ref.putFile(compressedFile);
    final snapshot = await uploadTask;

    // Cleanup temp file if different
    if (compressedFile.path != file.path) {
      compressedFile.delete().ignore();
    }

    return await snapshot.ref.getDownloadURL();
  }

  Future<String> uploadVoiceIntro(File file, String userId) async {
    final fileName = 'intro_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final ref = _storage.ref().child('voice_intros/$userId/$fileName');

    final metadata = SettableMetadata(contentType: 'audio/mp4');
    final uploadTask = ref.putFile(file, metadata);
    final snapshot = await uploadTask;

    return await snapshot.ref.getDownloadURL();
  }

  Future<String> uploadProfileImage(File file, String userId) async {
    final compressedFile = await _compressImage(file);
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('profile_images/$userId/$fileName');

    final uploadTask = ref.putFile(compressedFile);
    final snapshot = await uploadTask;

    // Cleanup temp file if different
    if (compressedFile.path != file.path) {
      compressedFile.delete().ignore();
    }

    return await snapshot.ref.getDownloadURL();
  }

  Future<String> uploadChatVoice(File file, String chatId) async {
    final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final ref = _storage.ref().child('chat_voice/$chatId/$fileName');

    final metadata = SettableMetadata(contentType: 'audio/mp4');
    final uploadTask = ref.putFile(file, metadata);
    final snapshot = await uploadTask;

    return await snapshot.ref.getDownloadURL();
  }
}
