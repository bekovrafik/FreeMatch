import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../providers/user_provider.dart';
import 'custom_toast.dart';

import '../constants/profile_options.dart';
import '../models/discovery_preferences.dart';

class DiscoverySettingsModal extends ConsumerStatefulWidget {
  const DiscoverySettingsModal({super.key});

  @override
  ConsumerState<DiscoverySettingsModal> createState() =>
      _DiscoverySettingsModalState();
}

class _DiscoverySettingsModalState
    extends ConsumerState<DiscoverySettingsModal> {
  late DiscoveryPreferences _tempForUI;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _tempForUI = ref.read(userProvider).preferences;
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // 1. Check permissions & get position
      final position = await _determinePosition();

      // 2. Reverse geocode
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.locality ?? place.subLocality ?? place.name;
        final state = place.administrativeArea; // e.g., CA, NY
        final country = place.country;

        String locationString = "Unknown";
        if (city != null && state != null) {
          locationString = "$city, $state";
        } else if (city != null && country != null) {
          locationString = "$city, $country";
        } else if (city != null) {
          locationString = city;
        }

        setState(() {
          _tempForUI = _tempForUI.copyWith(location: locationString);
        });
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
      if (mounted) {
        CustomToast.show(
          context,
          "Location Error: ${e.toString()}",
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Slate-900
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(top: BorderSide(color: Color(0xFF1E293B))), // Slate-800
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Discovery Settings",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.grey),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location
                  _buildSectionTitle("LOCATION"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _tempForUI.location.isEmpty
                                      ? "Anywhere"
                                      : _tempForUI.location,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _isLoadingLocation
                            ? null
                            : _getCurrentLocation,
                        icon: _isLoadingLocation
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.amber,
                                ),
                              )
                            : const Icon(
                                Icons.my_location,
                                color: Colors.amber,
                              ),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(12),
                          side: const BorderSide(color: Color(0xFF334155)),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      "Leave empty to search globally within distance.",
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Gender / Show Me
                  _buildSectionTitle("SHOW ME"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildGenderOption('MEN', "Men"),
                      const SizedBox(width: 8),
                      _buildGenderOption('WOMEN', "Women"),
                      const SizedBox(width: 8),
                      _buildGenderOption('EVERYONE', "Everyone"),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Distance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle("MAXIMUM DISTANCE"),
                      Text(
                        "${_tempForUI.distance.round()} km",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _tempForUI.distance,
                    min: 1,
                    max: 100,
                    activeColor: Colors.amber,
                    inactiveColor: const Color(0xFF1E293B),
                    onChanged: (val) {
                      setState(() {
                        _tempForUI = _tempForUI.copyWith(distance: val);
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Age Range
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle("AGE RANGE"),
                      Text(
                        "${_tempForUI.ageRange[0].round()} - ${_tempForUI.ageRange[1].round()}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: RangeValues(
                      _tempForUI.ageRange[0],
                      _tempForUI.ageRange[1],
                    ),
                    min: 18,
                    max: 100,
                    activeColor: Colors.amber,
                    inactiveColor: const Color(0xFF1E293B),
                    onChanged: (val) {
                      setState(() {
                        _tempForUI = _tempForUI.copyWith(
                          ageRange: [val.start, val.end],
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Looking For
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle("LOOKING FOR"),
                      if (_tempForUI.lookingFor.isNotEmpty)
                        GestureDetector(
                          onTap: () => setState(
                            () => _tempForUI = _tempForUI.copyWith(
                              lookingFor: [],
                            ),
                          ),
                          child: const Text(
                            "Clear All",
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kLookingForOptions.map((option) {
                      final isSelected = _tempForUI.lookingFor.contains(option);
                      return GestureDetector(
                        onTap: () {
                          final current = List<String>.from(
                            _tempForUI.lookingFor,
                          );
                          if (isSelected) {
                            current.remove(option);
                          } else {
                            current.add(option);
                          }
                          setState(() {
                            _tempForUI = _tempForUI.copyWith(
                              lookingFor: current,
                            );
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.amber
                                : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.amber
                                  : const Color(0xFF334155),
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.amber.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            option,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Interests
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle("INTERESTS"),
                      if (_tempForUI.interests.isNotEmpty)
                        GestureDetector(
                          onTap: () => setState(
                            () =>
                                _tempForUI = _tempForUI.copyWith(interests: []),
                          ),
                          child: const Text(
                            "Clear All",
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kInterestOptions.map((interest) {
                      final isSelected = _tempForUI.interests.contains(
                        interest,
                      );
                      return GestureDetector(
                        onTap: () {
                          final current = List<String>.from(
                            _tempForUI.interests,
                          );
                          if (isSelected) {
                            current.remove(interest);
                          } else {
                            current.add(interest);
                          }
                          setState(() {
                            _tempForUI = _tempForUI.copyWith(
                              interests: current,
                            );
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.amber
                                : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.amber
                                  : const Color(0xFF334155),
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.amber.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            interest,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ),

          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                ref.read(userProvider.notifier).updatePreferences(_tempForUI);
                Navigator.pop(context);
                CustomToast.show(context, "Filters Applied!");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Apply Filters",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              "FSA Ad sequencing rules apply regardless of filter settings.",
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.grey,
        fontWeight: FontWeight.bold,
        fontSize: 12, // text-xs
        letterSpacing: 1.5, // tracking-widest
      ),
    );
  }

  Widget _buildGenderOption(String value, String label) {
    final isSelected = _tempForUI.gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tempForUI = _tempForUI.copyWith(gender: value);
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.amber : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.amber : const Color(0xFF334155),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
