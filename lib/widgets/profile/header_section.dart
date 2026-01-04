import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileHeaderSection extends StatelessWidget {
  final String name;
  final int age;
  final bool isEditing;
  final bool isVerified;
  final List<String> imageUrls;
  final String? pickedImageLocalPath;
  final TextEditingController nameController;
  final VoidCallback onPickImage;
  final VoidCallback onGetVerified;

  const ProfileHeaderSection({
    super.key,
    required this.name,
    required this.age,
    required this.isEditing,
    required this.isVerified,
    required this.imageUrls,
    required this.pickedImageLocalPath,
    required this.nameController,
    required this.onPickImage,
    required this.onGetVerified,
  });

  @override
  Widget build(BuildContext context) {
    const kDbImage =
        "https://images.unsplash.com/photo-1599566150163-29194dcaad36?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=80";

    return Stack(
      alignment: Alignment.center,
      children: [
        // Background Image
        GestureDetector(
          onTap: isEditing ? onPickImage : null,
          child: Stack(
            children: [
              Container(
                height: 480,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: pickedImageLocalPath != null
                        ? FileImage(File(pickedImageLocalPath!))
                              as ImageProvider
                        : (imageUrls.isNotEmpty
                              ? CachedNetworkImageProvider(imageUrls.first)
                              : const CachedNetworkImageProvider(kDbImage)),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF020617).withValues(alpha: 0.0),
                        const Color(0xFF020617),
                      ],
                      stops: const [0.6, 0.8, 1.0],
                    ),
                  ),
                ),
              ),
              if (isEditing)
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: const Center(
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Name & Verified Overlay
        Positioned(
          bottom: 40,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (isEditing)
                    Expanded(
                      child: TextField(
                        controller: nameController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Name",
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Text(
                      "$name, $age",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  if (isVerified && !isEditing)
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.verified, color: Colors.blue, size: 32),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              if (!isVerified)
                GestureDetector(
                  onTap: onGetVerified,
                  child: Row(
                    children: const [
                      Text(
                        "Get Verified",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.blue, size: 20),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
