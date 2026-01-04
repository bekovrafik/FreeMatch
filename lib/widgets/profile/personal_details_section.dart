import 'package:flutter/material.dart';
import '../../constants/profile_options.dart';

class PersonalDetailsSection extends StatelessWidget {
  final bool isEditing;
  final String? status;
  final String? orientation;
  final String? drinks;
  final String? smokes;
  final String? bodyType;
  final String? sign;
  final String? religion;
  final String? lookingFor;

  final TextEditingController heightController;
  final TextEditingController speaksController;

  final Function(String?) onStatusChanged;
  final Function(String?) onOrientationChanged;
  final Function(String?) onDrinksChanged;
  final Function(String?) onSmokesChanged;
  final Function(String?) onBodyTypeChanged;
  final Function(String?) onSignChanged;
  final Function(String?) onReligionChanged;
  final Function(String?) onLookingForChanged;

  const PersonalDetailsSection({
    super.key,
    required this.isEditing,
    this.status,
    this.orientation,
    this.drinks,
    this.smokes,
    this.bodyType,
    this.sign,
    this.religion,
    this.lookingFor,
    required this.heightController,
    required this.speaksController,
    required this.onStatusChanged,
    required this.onOrientationChanged,
    required this.onDrinksChanged,
    required this.onSmokesChanged,
    required this.onBodyTypeChanged,
    required this.onSignChanged,
    required this.onReligionChanged,
    required this.onLookingForChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!isEditing) {
      // View Mode - Modern Chip Layout
      final fields = [
        if (lookingFor != null)
          _buildDetailChip("Looking For", lookingFor!, Icons.search_rounded),
        if (status != null)
          _buildDetailChip("Status", status!, Icons.favorite_border_rounded),
        if (orientation != null)
          _buildDetailChip(
            "Orientation",
            orientation!,
            Icons.diversity_3_rounded,
          ),
        if (heightController.text.isNotEmpty)
          _buildDetailChip(
            "Height",
            "${heightController.text} cm",
            Icons.height_rounded,
          ),
        if (bodyType != null)
          _buildDetailChip(
            "Body Type",
            bodyType!,
            Icons.accessibility_new_rounded,
          ),
        if (sign != null)
          _buildDetailChip("Sign", sign!, Icons.auto_awesome_rounded),
        if (religion != null)
          _buildDetailChip(
            "Religion",
            religion!,
            Icons.self_improvement_rounded,
          ),
        if (drinks != null)
          _buildDetailChip("Drinks", drinks!, Icons.local_bar_rounded),
        if (smokes != null)
          _buildDetailChip("Smokes", smokes!, Icons.smoking_rooms_rounded),
        if (speaksController.text.isNotEmpty)
          _buildDetailChip(
            "Speaks",
            speaksController.text,
            Icons.translate_rounded,
          ),
      ];

      if (fields.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "PERSONAL DETAILS",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 10, children: fields),
          ],
        ),
      );
    }

    // Edit Mode
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "EDIT DETAILS",
            style: TextStyle(
              color: Colors.amber,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildDropdown("Status", status, kStatusOptions, onStatusChanged),
          const SizedBox(height: 12),
          _buildDropdown(
            "Orientation",
            orientation,
            kOrientationOptions,
            onOrientationChanged,
          ),
          const SizedBox(height: 12),
          _buildDropdown("Drinks", drinks, kDrinksOptions, onDrinksChanged),
          const SizedBox(height: 12),
          _buildDropdown("Smokes", smokes, kSmokesOptions, onSmokesChanged),
          const SizedBox(height: 12),
          _buildTextField("Height (cm)", heightController),
          const SizedBox(height: 12),
          _buildDropdown(
            "Body Type",
            bodyType,
            kBodyTypeOptions,
            onBodyTypeChanged,
          ),
          const SizedBox(height: 12),
          _buildDropdown("Sign", sign, kZodiacSigns, onSignChanged),
          const SizedBox(height: 12),
          _buildDropdown(
            "Religion",
            religion,
            kReligionOptions,
            onReligionChanged,
          ),
          const SizedBox(height: 12),
          _buildDropdown(
            "Looking For",
            lookingFor,
            kLookingForOptions,
            onLookingForChanged,
          ),
          const SizedBox(height: 12),
          _buildTextField("Speaks (comma separated)", speaksController),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
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
        borderRadius: BorderRadius.circular(16),
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
              value: (value != null && items.contains(value)) ? value : null,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.grey,
              ),
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
