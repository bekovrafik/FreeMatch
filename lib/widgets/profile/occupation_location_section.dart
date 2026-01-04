import 'package:flutter/material.dart';

class OccupationLocationSection extends StatelessWidget {
  final bool isEditing;
  final String job;
  final String location;
  final TextEditingController jobController;
  final TextEditingController locationController;
  final VoidCallback onDetectLocation;

  const OccupationLocationSection({
    super.key,
    required this.isEditing,
    required this.job,
    required this.location,
    required this.jobController,
    required this.locationController,
    required this.onDetectLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("OCCUPATION"),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.work_outline, color: Colors.amber, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: isEditing
                    ? TextField(
                        controller: jobController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Job Title",
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      )
                    : Text(
                        job,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        _buildSectionHeader("LOCATION"),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: isEditing
                    ? TextField(
                        controller: locationController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "City, Country",
                          hintStyle: const TextStyle(color: Colors.grey),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.my_location,
                              color: Colors.blue,
                            ),
                            onPressed: onDetectLocation,
                            tooltip: "Detect Location",
                          ),
                        ),
                      )
                    : Text(
                        location,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
