import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String _error = '';

  Future<void> _loginAdmin() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      final uid = cred.user!.uid;
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists || doc.data()?['userType'] != 'admin') {
        throw Exception("Not authorized as admin");
      }

      // Redirect based on department
      String dept = doc['department'];
      if (dept == 'ICT') {
        Navigator.pushNamed(context, '/ictAdminDashboard');
      } else if (dept == 'Commercial') {
        Navigator.pushNamed(context, '/commercialAdminDashboard');
      } else if (dept == 'Mechanical Engineering') {
        Navigator.pushNamed(context, '/mechAdminDashboard');
      } else if (dept == 'Transportation') {
        Navigator.pushNamed(context, '/transportAdminDashboard');
      } else {
        throw Exception("Unknown department");
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _email, decoration: const InputDecoration(labelText: "Email")),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 16),
            if (_error.isNotEmpty)
              Text(_error, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _isLoading ? null : _loginAdmin,
              child: _isLoading ? const CircularProgressIndicator() : const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
