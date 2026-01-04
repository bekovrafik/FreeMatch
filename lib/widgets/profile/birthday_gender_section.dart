import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BirthdayGenderSection extends StatelessWidget {
  final int? dob;
  final int age;
  final String gender;
  final VoidCallback onPickDate;
  final Function(String) onGenderChanged;

  const BirthdayGenderSection({
    super.key,
    required this.dob,
    required this.age,
    required this.gender,
    required this.onPickDate,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: InkWell(
            onTap: onPickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dob != null
                        ? "Birthday: ${DateFormat('MMM d, yyyy').format(DateTime.fromMillisecondsSinceEpoch(dob!))} (Age: $age)"
                        : "Select Birthday",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const Icon(Icons.calendar_today, color: Colors.amber),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text(
                "Gender: ",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text("Women"),
                selected: gender == "WOMEN",
                onSelected: (selected) => onGenderChanged("WOMEN"),
                selectedColor: Colors.amber,
                backgroundColor: const Color(0xFF1E293B),
                labelStyle: TextStyle(
                  color: gender == "WOMEN" ? Colors.black : Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text("Men"),
                selected: gender == "MEN",
                onSelected: (selected) => onGenderChanged("MEN"),
                selectedColor: Colors.amber,
                backgroundColor: const Color(0xFF1E293B),
                labelStyle: TextStyle(
                  color: gender == "MEN" ? Colors.black : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
