import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';

final profileSetupProvider =
    NotifierProvider<ProfileSetupNotifier, AsyncValue<void>>(() {
      return ProfileSetupNotifier();
    });

class ProfileSetupNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<void> submitProfile({
    required List<File?> photos,
    required UserProfile draftProfile,
  }) async {
    state = const AsyncLoading();
    try {
      // 1. Upload Photos
      List<String> imageUrls = [];
      for (var file in photos) {
        if (file != null) {
          final url = await ref
              .read(storageServiceProvider)
              .uploadProfileImage(file, draftProfile.id);
          imageUrls.add(url);
        }
      }

      // 2. Update Profile with Image URLs
      final finalProfile = draftProfile.copyWith(imageUrls: imageUrls);

      // 3. Save to Firestore
      await ref.read(firestoreServiceProvider).saveUserProfile(finalProfile);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
