import 'package:flutter/material.dart';

class InterestPickerSection extends StatelessWidget {
  final List<String> interests;
  final bool isEditing;
  final VoidCallback onAdd;
  final Function(String) onRemove;

  const InterestPickerSection({
    super.key,
    required this.interests,
    required this.isEditing,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          "INTERESTS",
          action: isEditing
              ? TextButton(
                  onPressed: onAdd,
                  child: const Text(
                    "Add",
                    style: TextStyle(color: Colors.blue),
                  ),
                )
              : Text(
                  "${interests.length}/10",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: interests
                .map(
                  (interest) => Chip(
                    label: Text(interest),
                    backgroundColor: const Color(0xFF1E293B),
                    labelStyle: const TextStyle(color: Colors.white),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    deleteIcon: isEditing
                        ? const Icon(Icons.close, size: 16, color: Colors.grey)
                        : null,
                    onDeleted: isEditing ? () => onRemove(interest) : null,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {Widget? action}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1.0,
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }
}
