import 'package:flutter/material.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Courses')),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Course ${index + 1}'),
            subtitle: const Text('Computer Science'),
            trailing: const Icon(Icons.arrow_forward),
          );
        },
      ),
    );
  }
}