import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(radius: 50),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: 'John Doe',
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            // Add more profile fields
          ],
        ),
      ),
    );
  }
}