import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PhotosGridSection extends StatelessWidget {
  final List<String> imageUrls;
  final bool isEditing;
  final VoidCallback onAdd;
  final Function(int) onRemove;

  const PhotosGridSection({
    super.key,
    required this.imageUrls,
    required this.isEditing,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.length <= 1 && !isEditing) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          "MY PHOTOS",
          action: isEditing
              ? TextButton(
                  onPressed: onAdd,
                  child: const Text(
                    "Add",
                    style: TextStyle(color: Colors.blue),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: isEditing && imageUrls.length <= 1
              ? GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: const Icon(Icons.add, color: Colors.grey),
                  ),
                )
              : GridView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: imageUrls.isNotEmpty ? imageUrls.length - 1 : 0,
                  itemBuilder: (context, index) {
                    final realIndex = index + 1;
                    final url = imageUrls[realIndex];
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: const Color(0xFF1E293B)),
                          ),
                        ),
                        if (isEditing)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => onRemove(realIndex),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
        ),
        const SizedBox(height: 30),
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
