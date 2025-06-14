// lib/services/firestore_seeder.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreSeeder {
  static Future<void> seedFirestoreData() async {
    final firestore = FirebaseFirestore.instance;

    // Create test admin
    await firestore.collection('users').doc('admin_demo').set({
      'uid': 'admin_demo',
      'email': 'admin@example.com',
      'fullName': 'Demo Admin',
      'userType': 'admin',
    });

    // Create test student
    await firestore.collection('users').doc('student_demo').set({
      'uid': 'student_demo',
      'email': 'student@example.com',
      'fullName': 'Demo Student',
      'userType': 'student',
    });

    await firestore.collection('students').doc('student_demo').set({
      'uid': 'student_demo',
      'email': 'student@example.com',
      'fullName': 'Demo Student',
      'phoneNumber': '+1234567890',
      'registrationNumber': 'SP2025-D1',
      'gender': 'Male',
      'level': '100',
      'department': 'Computer Science',
      'username': 'demo_student',
      'userType': 'student',
    });

    // Payment document for demo student
    await firestore.collection('payments').add({
      'studentId': 'student_demo',
      'amount': 500.0,
      'paymentType': 'Tuition',
      'status': 'approved',
      'timestamp': FieldValue.serverTimestamp(),
    });

    print("✅ Demo data seeded successfully");
  }
}
