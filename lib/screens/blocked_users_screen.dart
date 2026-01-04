import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  // No mock data - default to empty until real blocking logic is connected fully
  final List<Map<String, String>> _blockedUsers = [];

  void _unblock(String id) {
    setState(() {
      _blockedUsers.removeWhere((user) => user['id'] == id);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("User unblocked.")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        title: const Text(
          "Blocked Users",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _blockedUsers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 60,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No blocked users",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: _blockedUsers.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: Color(0xFF1E293B)),
              itemBuilder: (context, index) {
                final user = _blockedUsers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(user['image']!),
                  ),
                  title: Text(
                    user['name']!,
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: TextButton(
                    onPressed: () => _unblock(user['id']!),
                    child: const Text(
                      "Unblock",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
