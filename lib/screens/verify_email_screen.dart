import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../routes.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  late User _user;
  Timer? _checkTimer;
  bool _emailSent = false;
  bool _isChecking = false;
  bool _approvalPending = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;

    _sendVerificationEmail();
    _startChecking();
  }

  void _sendVerificationEmail() async {
    try {
      if (!_user.emailVerified && !_emailSent) {
        await _user.sendEmailVerification();
        setState(() => _emailSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending email: $e')),
      );
    }
  }

  void _startChecking() {
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkVerificationAndApproval());
  }

  Future<void> _checkVerificationAndApproval() async {
    if (_isChecking) return;
    _isChecking = true;

    await _user.reload();
    _user = FirebaseAuth.instance.currentUser!;

    if (_user.emailVerified) {
      final doc = await FirebaseFirestore.instance
          .collection('students')
          .doc(_user.uid)
          .get();

      if (doc.exists && doc.data()?['status'] == 'approved') {
        _checkTimer?.cancel();
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.studentHome);
        }
      } else {
        setState(() => _approvalPending = true);
      }
    }

    _isChecking = false;
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 24),
              const Text(
                'Please verify your email address by clicking the link we sent to your inbox.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _sendVerificationEmail,
                icon: const Icon(Icons.refresh),
                label: const Text('Resend Email'),
              ),
              const SizedBox(height: 20),
              if (_approvalPending)
                const Text(
                  'Email verified. Awaiting admin approval...',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                )
            ],
          ),
        ),
      ),
    );
  }
}
