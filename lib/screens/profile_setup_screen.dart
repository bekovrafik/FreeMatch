import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../models/user_profile.dart';
import '../widgets/custom_toast.dart';
import '../constants/profile_options.dart';
import 'home_screen.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Basic Info
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController =
      TextEditingController(); // Added Location
  DateTime? _dob;
  String _gender = 'WOMEN'; // Default

  // Step 1.5: Details
  String? _status = 'Single';
  String? _orientation = 'Straight';
  String? _drinks = 'Socially';
  String? _smokes = 'No';
  // New Dropdown State
  String? _bodyType;
  String? _sign;
  String? _religion;
  String? _lookingFor;
  final List<String> _selectedInterests = []; // Added Interests

  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _speaksController =
      TextEditingController(); // Comma separated

  // Step 2: Photos
  final List<File?> _photos = [null, null, null, null, null, null];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose(); // Dispose location
    _heightController.dispose();
    _speaksController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int index) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() {
        _photos[index] = File(image.path);
      });
    }
  }

  int get _age {
    if (_dob == null) return 18;
    final now = DateTime.now();
    int age = now.year - _dob!.year;
    if (now.month < _dob!.month ||
        (now.month == _dob!.month && now.day < _dob!.day)) {
      age--;
    }
    return age;
  }

  void _nextStep() async {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty) {
        CustomToast.show(context, "Please enter your name", isError: true);
        return;
      }
      if (_locationController.text.trim().isEmpty) {
        CustomToast.show(
          context,
          "Please enter your city/location",
          isError: true,
        );
        return;
      }
      if (_dob == null) {
        CustomToast.show(context, "Please enter your birthday", isError: true);
        return;
      }
      if (_age < 18) {
        CustomToast.show(
          context,
          "You must be 18+ to use FreeMatch",
          isError: true,
        );
        return;
      }
      setState(() => _currentStep++);
      setState(() => _currentStep++);
    } else if (_currentStep == 1) {
      // Details Step
      if (_selectedInterests.length < 3) {
        CustomToast.show(context, "Select at least 3 interests", isError: true);
        return;
      }
      setState(() => _currentStep++);
    } else if (_currentStep == 2) {
      if (_photos.where((p) => p != null).isEmpty) {
        CustomToast.show(
          context,
          "Please add at least one photo",
          isError: true,
        );
        return;
      }
      setState(() => _currentStep++);
    } else {
      // Final Step: Submit
      if (_bioController.text.trim().isEmpty) {
        CustomToast.show(context, "Please write a short bio", isError: true);
        return;
      }
      _submitProfile();
    }
  }

  Future<void> _submitProfile() async {
    setState(() => _isLoading = true);
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    try {
      // 1. Upload Photos
      List<String> imageUrls = [];
      for (var file in _photos) {
        if (file != null) {
          final url = await ref
              .read(storageServiceProvider)
              .uploadProfileImage(file, user.uid);
          imageUrls.add(url);
        }
      }

      // 2. Create Profile
      final profile = UserProfile(
        id: user.uid,
        name: _nameController.text.trim(),
        age: _age,
        dob: _dob!.millisecondsSinceEpoch,
        gender: _gender,
        bio: _bioController.text.trim(),
        imageUrls: imageUrls,
        location: _locationController.text.trim(), // Use input location
        profession: "",
        interests: _selectedInterests, // Use input interests
        distance: 0,
        lastActive: DateTime.now().millisecondsSinceEpoch,
        joinedDate: DateTime.now().millisecondsSinceEpoch,

        isVerified: false,
        status: _status,
        orientation: _orientation,
        drinks: _drinks,
        smokes: _smokes,
        bodyType: _bodyType,
        sign: _sign,
        religion: _religion,
        lookingFor: _lookingFor,
        height: _heightController.text,
        speaks: _speaksController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      );

      await ref.read(firestoreServiceProvider).saveUserProfile(profile);

      if (mounted) {
        CustomToast.show(context, "Profile Created!");
        // Navigate to Home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, "Error creating profile: $e", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        title: Text(
          _currentStep == 0
              ? "About You"
              : (_currentStep == 1
                    ? "Details"
                    : (_currentStep == 2 ? "Photos" : "Bio")),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  100,
                ), // Extra bottom padding for keyboard
                child: _buildCurrentStep(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          _currentStep == 3 ? "Complete Profile" : "Next",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    if (_currentStep == 0) {
      return Column(
        children: [
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Name",
              labelStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _locationController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Location (City, Country)",
              labelStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime(2000),
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
              );
              if (date != null) setState(() => _dob = date);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    _dob == null
                        ? "Select Birthday"
                        : "${_dob!.day}/${_dob!.month}/${_dob!.year} ($_age y.o)",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _gender,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E293B),
                items: ['WOMEN', 'MEN']
                    .map(
                      (g) => DropdownMenuItem(
                        value: g,
                        child: Text(
                          g,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _gender = val!),
              ),
            ),
          ),
        ],
      );
    } else if (_currentStep == 1) {
      return Column(
        children: [
          _buildDropdown("Status", _status, [
            "Single",
            "Available",
            "Seeing Someone",
          ], (val) => setState(() => _status = val)),
          const SizedBox(height: 16),
          _buildDropdown("Orientation", _orientation, [
            "Straight",
            "Gay",
            "Bisexual",
          ], (val) => setState(() => _orientation = val)),
          const SizedBox(height: 16),
          _buildDropdown("Drinks", _drinks, [
            "Never",
            "Sometimes",
            "If You Buy",
            "Socially",
            "Often",
          ], (val) => setState(() => _drinks = val)),
          const SizedBox(height: 16),
          _buildDropdown(
            "Looking For",
            _lookingFor,
            kLookingForOptions,
            (val) => setState(() => _lookingFor = val),
          ),
          const SizedBox(height: 16),
          _buildDropdown("Smokes", _smokes, [
            "No",
            "Sometimes",
            "Yes",
          ], (val) => setState(() => _smokes = val)),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          // Interests Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Interests (Select at least 3)",
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kInterestOptions.map((interest) {
                    final isSelected = _selectedInterests.contains(interest);
                    return FilterChip(
                      label: Text(interest),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            if (_selectedInterests.length < 10) {
                              _selectedInterests.add(interest);
                            }
                          } else {
                            _selectedInterests.remove(interest);
                          }
                        });
                      },
                      backgroundColor: const Color(0xFF0F172A),
                      selectedColor: Colors.amber,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                      ),
                      checkmarkColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? Colors.amber : Colors.grey[700]!,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField("Height (e.g. 170cm)", _heightController),
          const SizedBox(height: 16),
          _buildDropdown(
            "Religion",
            _religion,
            kReligionOptions,
            (val) => setState(() => _religion = val),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            "Sign (Zodiac)",
            _sign,
            kZodiacSigns,
            (val) => setState(() => _sign = val),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            "Body Type",
            _bodyType,
            kBodyTypeOptions,
            (val) => setState(() => _bodyType = val),
          ),
          const SizedBox(height: 16),
          _buildTextField("Speaks (comma separated)", _speaksController),
        ],
      );
    } else if (_currentStep == 2) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.8,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          final file = _photos[index];
          return GestureDetector(
            onTap: () => _pickImage(index),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[800]!),
                image: file != null
                    ? DecorationImage(image: FileImage(file), fit: BoxFit.cover)
                    : null,
              ),
              child: file == null
                  ? const Icon(Icons.add_a_photo, color: Colors.grey)
                  : null,
            ),
          );
        },
      );
    } else {
      return TextField(
        controller: _bioController,
        style: const TextStyle(color: Colors.white),
        maxLines: 5,
        maxLength: 200,
        decoration: InputDecoration(
          labelText: "Bio",
          hintText: "Tell us a bit about yourself...",
          labelStyle: TextStyle(color: Colors.grey[400]),
          hintStyle: TextStyle(color: Colors.grey[600]),
          filled: true,
          fillColor: const Color(0xFF1E293B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      );
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              items: items
                  .map(
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Text(
                        i,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
