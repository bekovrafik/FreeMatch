import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storageServiceProvider = Provider((ref) => StorageService());

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadChatImage(File file, String chatId) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('chat_images/$chatId/$fileName');

    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;

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
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('profile_images/$userId/$fileName');

    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;

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
