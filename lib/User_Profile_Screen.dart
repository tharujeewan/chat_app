// user_profile_screen.dart
import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  final String uid;

  const UserProfileScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Profile"),
      ),
      body: Center(
        child: Text(
            "User Profile of UID: $uid"), // Use UID to fetch and display profile info
      ),
    );
  }
}
