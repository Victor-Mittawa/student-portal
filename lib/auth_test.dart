import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart'; // Your generated Firebase config

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TestAuthApp());
}

class TestAuthApp extends StatelessWidget {
  const TestAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth Test',
      home: const RegisterTestScreen(),
    );
  }
}

class RegisterTestScreen extends StatefulWidget {
  const RegisterTestScreen({super.key});

  @override
  State<RegisterTestScreen> createState() => _RegisterTestScreenState();
}

class _RegisterTestScreenState extends State<RegisterTestScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String _status = '';

  Future<void> _registerUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    setState(() {
      _status = 'Registering user...';
    });

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception(
                'Request timed out — check your network and Firebase config.'),
          );

      final user = userCredential.user;
      if (user != null) {
        await user.sendEmailVerification();
        setState(() {
          _status = 'User created! Verification email sent to $email';
        });
      } else {
        setState(() {
          _status = 'User creation failed without error.';
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _status = 'Firebase Auth Error: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Auth User Creation Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration:
                  const InputDecoration(labelText: 'Email', hintText: 'you@example.com'),
            ),
            TextField(
              controller: passwordController,
              decoration:
                  const InputDecoration(labelText: 'Password', hintText: 'Min 6 chars'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registerUser,
              child: const Text('Register'),
            ),
            const SizedBox(height: 20),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
