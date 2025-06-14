import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'routes.dart'; // ensure your route names are defined here

Future<void> handleLoginRedirection(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    // Should not happen, but fail-safe
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No user is currently signed in.')),
    );
    return;
  }

  try {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      throw Exception("User record not found in Firestore.");
    }

    final data = userDoc.data()!;
    final userType = data['userType'];
    final department = data['department'];

    if (userType == 'admin') {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.adminHome,
        arguments: {'department': department},
      );
    } else if (userType == 'student') {
      Navigator.pushReplacementNamed(context, AppRoutes.studentHome);
    } else {
      throw Exception("Unknown user type: $userType");
    }
  } catch (e) {
    print("Login redirection error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to fetch user type.')),
    );
  }
}
