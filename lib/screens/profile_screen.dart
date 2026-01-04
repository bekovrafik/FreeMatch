import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/chat_service.dart';
import '../providers/user_provider.dart';
import '../widgets/verification_modal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/db_seeder.dart';

// Modular Widgets
import '../widgets/profile/header_section.dart';
import '../widgets/profile/stats_row.dart';
import '../widgets/profile/smart_tip_section.dart';
import '../widgets/profile/photos_grid_section.dart';
import '../widgets/profile/voice_intro_section.dart';
import '../widgets/profile/occupation_location_section.dart';
import '../widgets/profile/interest_picker_section.dart';
import '../widgets/profile/bio_section.dart';

import '../widgets/profile/birthday_gender_section.dart';
import '../widgets/profile/personal_details_section.dart';
import '../constants/profile_options.dart';
import '../widgets/custom_toast.dart';

// Mock User Data for Profile Screen (Self)

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _jobController;
  late TextEditingController _bioController;

  late TextEditingController _locationController; // Added controller
  // New Controllers
  late TextEditingController _heightController;
  late TextEditingController _speaksController;

  // New State Fields for Dropdowns
  String? _status;
  String? _orientation;
  String? _drinks;
  String? _smokes;
  String? _bodyType;
  String? _sign;
  String? _religion;
  String? _lookingFor;

  // Audio State
  late AudioRecorder _audioRecorder;
  late AudioPlayer _audioPlayer;
  String? _recordPath;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _hasPermission = false;

  // State
  bool _isLoading = true;
  bool _isSeeding = false;
  String _name = "";
  int _age = 18;
  String _job = "";
  String _location = "";
  String _bio = "";
  List<String> _interests = [];
  String? _voiceTitle; // New state for Title
  String _userId = "";
  List<String> _imageUrls = [];
  String? _pickedImageLocalPath;
  int _matchCount = 0;
  int _likeCount = 0;

  // New Fields
  int? _dob; // Timestamp

  String _gender = "WOMEN"; // Default

  @override
  void initState() {
    super.initState();
    // Initialize Audio
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();
    // Set Audio Context to ensure playback on speaker
    _audioPlayer.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playAndRecord,
          options: {
            AVAudioSessionOptions.defaultToSpeaker,
            AVAudioSessionOptions.allowBluetooth,
            AVAudioSessionOptions.allowAirPlay,
          },
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ),
    );
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) setState(() => _isPlaying = false);
    });
    _checkPermission();

    // Initialize all controllers here
    _nameController = TextEditingController();
    _jobController = TextEditingController();
    _bioController = TextEditingController();
    _locationController = TextEditingController();
    _heightController = TextEditingController();
    _speaksController = TextEditingController();

    // Load Profile Data
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUserProfile());
  }

  Future<void> _fetchStats() async {
    if (_userId.isEmpty) return;
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final chatService = ref.read(chatServiceProvider);

      final likes = await firestoreService.getLikesCount(_userId);
      final matches = await chatService.getMatchCount(_userId);

      if (mounted) {
        setState(() {
          _likeCount = likes;
          _matchCount = matches;
        });
      }
    } catch (e) {
      debugPrint("Error fetching stats: $e");
    }
  }

  Future<void> _loadUserProfile() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _userId = user.uid;
    final firestore = ref.read(firestoreServiceProvider);
    final profile = await firestore.getUserProfile(_userId);

    if (profile != null && mounted) {
      setState(() {
        _name = profile.name;
        _age = profile.age;
        _job = profile.profession;
        _location = profile.location;
        _bio = profile.bio;
        _interests = List.from(profile.interests);
        _recordPath = profile.voiceIntro;
        _voiceTitle = profile.voiceIntroTitle; // Load Title
        _imageUrls = List.from(profile.imageUrls);
        _dob = profile.dob;
        _gender = profile.gender;

        _status = profile.status;
        _orientation = profile.orientation;
        _drinks = profile.drinks;
        _smokes = profile.smokes;
        _bodyType = profile.bodyType;
        _sign = profile.sign;
        _religion = profile.religion;
        _lookingFor = profile.lookingFor;

        // Initialize controllers with fetched data
        _nameController.text = _name;
        _jobController.text = _job;
        _bioController.text = _bio;
        _locationController.text = _location;

        _heightController.text = profile.height ?? "";
        _speaksController.text = profile.speaks?.join(", ") ?? "";

        _isLoading = false;
      });

      // Fetch Stats
      _fetchStats();
    } else {
      // Default / New User fallback
      if (mounted) {
        setState(() {
          _name = user.displayName ?? "New User";
          _isLoading = false;
          // Initialize controllers with checked defaults
          _nameController.text = _name;
          _jobController.text = _job;
          _bioController.text = _bio;
          _locationController.text = _location;

          _heightController.text = "";
          _speaksController.text = "";
        });
      }
    }
  }

  Future<void> _saveUserProfile() async {
    // Determine the "final" values to save
    // If controllers were edited, use their text.
    // If not, fall back to existing state variables.
    // Sync state one last time before saving
    _name = _nameController.text;
    _job = _jobController.text;
    _bio = _bioController.text;
    _location = _locationController.text;

    // ... upload logic (omitted) ...
    if (_userId.isEmpty) return;

    // Upload Voice Intro if it's a local file
    String? finalVoiceUrl = _recordPath;
    if (_recordPath != null && !_recordPath!.startsWith('http')) {
      try {
        final storage = ref.read(storageServiceProvider);
        final file = File(_recordPath!);
        if (await file.exists()) {
          finalVoiceUrl = await storage.uploadVoiceIntro(file, _userId);
          // Update local state to point to URL now to prevent re-upload
          if (mounted) {
            setState(() {
              _recordPath = finalVoiceUrl;
            });
          }
        }
      } catch (e) {
        debugPrint("Error uploading voice intro: $e");
        // Maintain local path if upload fails, or handle error?
        // We'll proceed saving other fields for now.
      }
    }

    // Upload Profile Image if Changed
    if (_pickedImageLocalPath != null) {
      try {
        final storage = ref.read(storageServiceProvider);
        final file = File(_pickedImageLocalPath!);
        if (await file.exists()) {
          final imageUrl = await storage.uploadProfileImage(file, _userId);

          if (_imageUrls.isNotEmpty) {
            _imageUrls[0] = imageUrl; // Replace primary image
          } else {
            _imageUrls.add(imageUrl);
          }

          if (mounted) {
            setState(() {
              _pickedImageLocalPath = null; // Clear local path after upload
            });
          }
        }
      } catch (e) {
        debugPrint("Error uploading profile image: $e");
      }
    }

    final updates = {
      'name': _nameController.text,
      'profession': _jobController.text,
      'bio': _bioController.text,
      'location': _location,
      'interests': _interests,
      'voiceIntro': finalVoiceUrl,
      'voiceIntroTitle': _voiceTitle,
      'imageUrls': _imageUrls,
      'dob': _dob,
      'gender': _gender,
      'age': _age,
      'status': _status,
      'orientation': _orientation,
      'drinks': _drinks,
      'smokes': _smokes,
      'bodyType': _bodyType,
      'sign': _sign,
      'religion': _religion,
      'lookingFor': _lookingFor,
      'height': _heightController.text.isNotEmpty
          ? _heightController.text
          : null,
      'speaks': _speaksController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    };

    try {
      await ref
          .read(firestoreServiceProvider)
          .updateUserFields(_userId, updates);

      if (mounted) {
        CustomToast.show(context, "Profile Saved!");
        setState(() {
          _isEditing = false;
          // Update local View state strings from Controllers
          _name = _nameController.text;
          _job = _jobController.text;
          _bio = _bioController.text;
          _location = _locationController.text;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, "Error saving profile: $e", isError: true);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _pickedImageLocalPath = image.path;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _addPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        // Upload immediately
        final storage = ref.read(storageServiceProvider);
        final file = File(image.path);

        // Show loading if needed? For now we just wait.
        // Show loading if needed? For now we just wait.
        if (mounted) {
          CustomToast.show(context, "Uploading photo...");
        }

        final imageUrl = await storage.uploadProfileImage(file, _userId);

        if (mounted) {
          setState(() {
            _imageUrls.add(imageUrl);
          });
        }
      }
    } catch (e) {
      debugPrint("Error adding photo: $e");
      if (mounted) {
        CustomToast.show(context, "Failed to upload: $e", isError: true);
      }
    }
  }

  // --- Location Detection ---
  Future<void> _detectLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    setState(() => _isLoading = true);

    try {
      // 1. Check Service
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      // 2. Check Permissions
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      // 3. Get Position
      final position = await Geolocator.getCurrentPosition();

      // 4. Reverse Geocode
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // e.g. "San Francisco, United States"
        String detected = "${place.locality ?? ''}, ${place.country ?? ''}";
        // Clean up leading comma if locality is missing
        if (detected.startsWith(", ")) detected = detected.substring(2);

        setState(() {
          _location = detected;
          _locationController.text = detected;
        });

        if (mounted) {
          CustomToast.show(context, "Updated location to $detected");
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, "Error: $e", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dob != null
          ? DateTime.fromMillisecondsSinceEpoch(_dob!)
          : DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.amber,
              onPrimary: Colors.black,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dob = picked.millisecondsSinceEpoch;
        // Calculate Age
        final now = DateTime.now();
        int age = now.year - picked.year;
        if (now.month < picked.month ||
            (now.month == picked.month && now.day < picked.day)) {
          age--;
        }
        _age = age;
      });
    }
  }

  void _removePhoto(int index) {
    if (index >= 0 && index < _imageUrls.length) {
      setState(() {
        _imageUrls.removeAt(index);
      });
    }
  }

  void _toggleEdit() async {
    if (_isEditing) {
      // Trying to SAVE
      // Update local state temporarily to reflect potential new values in UI while saving
      setState(() {
        _name = _nameController.text;
        _job = _jobController.text;
        _bio = _bioController.text;
        _location = _locationController.text;
      });

      await _saveUserProfile();

      // _saveUserProfile handles setting _isEditing = false on success.
      // We don't need to do anything else here.
    } else {
      // Enter Edit Mode
      if (mounted) {
        setState(() {
          _isEditing = true;
        });
      }
    }
  }

  Future<void> _checkPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      setState(() => _hasPermission = true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jobController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _heightController.dispose();
    _speaksController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (!_hasPermission) {
        final status = await Permission.microphone.request();
        if (status != PermissionStatus.granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Microphone permission required')),
            );
          }
          return;
        }
        setState(() => _hasPermission = true);
      }

      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/voice_intro_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Config: Bitrate 128k, Sample Rate 44100
      const config = RecordConfig(encoder: AudioEncoder.aacLc);

      await _audioRecorder.start(config, path: path);
      setState(() {
        _isRecording = true;
        _recordPath = null;
      });
    } catch (e) {
      debugPrint("Error starting record: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        if (mounted) {
          // Ask for Title
          final TextEditingController titleController = TextEditingController();
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: const Text(
                "Name your sound",
                style: TextStyle(color: Colors.white),
              ),
              content: TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "e.g. My Intro",
                  hintStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Cancel recording logic if they cancel? Or just save without title?
                    // Let's assume title is optional but we default to something.
                    Navigator.pop(ctx);
                  },
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    "Save",
                    style: TextStyle(color: Colors.amber),
                  ),
                ),
              ],
            ),
          );

          setState(() {
            _isRecording = false;
            _recordPath = path;
            _voiceTitle = titleController.text.isNotEmpty
                ? titleController.text
                : "My Voice Intro";
          });
        }
      }
    } catch (e) {
      debugPrint("Error stopping record: $e");
    }
  }

  Future<void> _playRecording() async {
    if (_recordPath == null) return;
    try {
      if (_recordPath!.startsWith('http')) {
        await _audioPlayer.play(UrlSource(_recordPath!));
      } else {
        await _audioPlayer.play(DeviceFileSource(_recordPath!));
      }
      setState(() => _isPlaying = true);
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } catch (e) {
      debugPrint("Error pausing audio: $e");
    }
  }

  Future<void> _deleteRecording() async {
    // Typically you'd also delete the file from disk
    if (_recordPath != null) {
      final file = File(_recordPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }

    setState(() {
      _recordPath = null;
      _isPlaying = false;
    });
  }

  void _addInterest(String interest) {
    if (!_interests.contains(interest)) {
      setState(() {
        _interests.add(interest);
      });
    }
  }

  void _removeInterest(String interest) {
    setState(() {
      _interests.remove(interest);
    });
  }

  void _showInterestPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Add Interest",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: kInterestOptions
                        .map(
                          (s) => ActionChip(
                            label: Text(s),
                            backgroundColor: _interests.contains(s)
                                ? Colors.amber
                                : null,
                            onPressed: () {
                              _addInterest(s);
                              Navigator.pop(context);
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF020617),
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    final userState = ref.watch(userProvider);
    final isVerified = userState.isVerified;

    // Calculate Progress
    int score = 0;
    int total = 5;
    List<String> missing = [];

    if (_imageUrls.isNotEmpty) {
      score++;
    } else {
      missing.add("Add Photos");
    }
    if (_bio.isNotEmpty) {
      score++;
    } else {
      missing.add("Add Bio");
    }
    if (_recordPath != null) {
      score++;
    } else {
      missing.add("Add Voice Intro");
    }
    if (_interests.isNotEmpty) {
      score++;
    } else {
      missing.add("Add Interests");
    }
    if (_job.isNotEmpty || _location.isNotEmpty) {
      score++;
    } else {
      missing.add("Add Details");
    }

    double progress = score / total;
    String tip = missing.isNotEmpty ? missing.first : "";

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleEdit,
        backgroundColor: Colors.amber,
        child: Icon(_isEditing ? Icons.check : Icons.edit, color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileHeaderSection(
              name: _name,
              age: _age,
              isEditing: _isEditing,
              isVerified: isVerified,
              imageUrls: _imageUrls,
              pickedImageLocalPath: _pickedImageLocalPath,
              nameController: _nameController,
              onPickImage: _pickImage,
              onGetVerified: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => VerificationModal(
                    onVerified: () async {
                      ref.read(userProvider.notifier).setVerified(true);
                      // Persist to Firestore
                      if (_userId.isNotEmpty) {
                        await ref
                            .read(firestoreServiceProvider)
                            .updateUserFields(_userId, {'isVerified': true});
                      }
                    },
                  ),
                );
              },
            ),

            // Calculate Progress & Tip
            // Progress Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SmartTipSection(
                onFix: () {
                  _toggleEdit();
                },
                onSeed: _seedDatabase,
                isSeeding: _isSeeding,
                tip: tip,
                progress: progress,
              ),
            ),

            const SizedBox(height: 24),

            if (!_isEditing)
              ProfileStatsRow(
                matchCount: _matchCount,
                likeCount: _likeCount,
                completion: progress,
              ),

            if (_isEditing)
              BirthdayGenderSection(
                dob: _dob,
                age: _age,
                gender: _gender,
                onPickDate: _pickDate,
                onGenderChanged: (val) => setState(() => _gender = val),
              ),

            const SizedBox(height: 30),

            PhotosGridSection(
              imageUrls: _imageUrls,
              isEditing: _isEditing,
              onAdd: _addPhoto,
              onRemove: _removePhoto,
            ),

            VoiceIntroSection(
              isRecording: _isRecording,
              isPlaying: _isPlaying,
              recordPath: _recordPath,
              voiceTitle: _voiceTitle,
              onTapMic: () {
                if (_isRecording) {
                  _stopRecording();
                } else if (_recordPath != null) {
                  if (_isPlaying) {
                    _pauseRecording();
                  } else {
                    _playRecording();
                  }
                } else {
                  _startRecording();
                }
              },
              onDelete: _deleteRecording,
            ),

            const SizedBox(height: 30),

            OccupationLocationSection(
              isEditing: _isEditing,
              job: _job,
              location: _location,
              jobController: _jobController,
              locationController: _locationController,
              onDetectLocation: _detectLocation,
            ),

            const SizedBox(height: 30),

            InterestPickerSection(
              interests: _interests,
              isEditing: _isEditing,
              onAdd: _showInterestPicker,
              onRemove: _removeInterest,
            ),

            const SizedBox(height: 30),

            BioSection(
              isEditing: _isEditing,
              bio: _bio,
              bioController: _bioController,
            ),

            const SizedBox(height: 30),

            if (_isEditing ||
                _status != null ||
                _orientation != null ||
                _drinks != null ||
                _smokes != null ||
                _bodyType != null ||
                _sign != null ||
                _religion != null ||
                _heightController.text.isNotEmpty)
              PersonalDetailsSection(
                isEditing: _isEditing,
                status: _status,
                orientation: _orientation,
                drinks: _drinks,
                smokes: _smokes,
                bodyType: _bodyType,
                sign: _sign,
                religion: _religion,
                lookingFor: _lookingFor,
                heightController: _heightController,
                speaksController: _speaksController,
                onStatusChanged: (val) => setState(() => _status = val),
                onOrientationChanged: (val) =>
                    setState(() => _orientation = val),
                onDrinksChanged: (val) => setState(() => _drinks = val),
                onSmokesChanged: (val) => setState(() => _smokes = val),
                onBodyTypeChanged: (val) => setState(() => _bodyType = val),
                onSignChanged: (val) => setState(() => _sign = val),
                onReligionChanged: (val) => setState(() => _religion = val),
                onLookingForChanged: (val) => setState(() => _lookingFor = val),
              ),

            const SizedBox(height: 40),

            // Delete Custom Data Button removed (Production Cleanup)
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Future<void> _seedDatabase() async {
    setState(() => _isSeeding = true);
    try {
      await DbSeeder.seedProfilesChunked();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Success! Database seeded & Likes generated."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error seeding: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }
}
