import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int? _forceResendingToken;

  // 🔐 STUDENT REGISTRATION WITH EMAIL
  Future<User?> registerStudent({
    required String email,
    required String password,
    required String fullName,
    required int age,
    required String gender,
    required String course,
    required String department,
    required String level,
    required String enrollmentYear,
    required double feesPaid,
    required double balance,
    required String studentCategory,
  }) async {
    try {
      // Check for recent account creation attempts
      final creationTime = _auth.currentUser?.metadata.creationTime;
      if (creationTime != null && 
          DateTime.now().difference(creationTime).inMinutes.abs() < 5) {
        throw 'Please wait 5 minutes between registrations';
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;
      await _saveStudentData(
        uid: user.uid,
        email: email,
        fullName: fullName,
        age: age,
        gender: gender,
        course: course,
        department: department,
        level: level,
        enrollmentYear: enrollmentYear,
        feesPaid: feesPaid,
        balance: balance,
        studentCategory: studentCategory,
      );

      await user.sendEmailVerification();
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        throw 'Device temporarily blocked due to unusual activity. Try again later.';
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // 📱 PHONE VERIFICATION INITIATION (UPDATED FOR RELIABLE OTP)
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String, int?) onCodeSent,
    required Function(FirebaseAuthException) onVerificationFailed,
    required Function(PhoneAuthCredential) onVerificationCompleted,
    Function(String)? onCodeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    try {
      // Test numbers bypass (for development)
      const testNumbers = ['998268614', '887324797']; // Add your test numbers
      if (testNumbers.contains(phoneNumber)) {
        onCodeSent('test_verification_id', null);
        return;
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: '+265$phoneNumber',
        verificationCompleted: onVerificationCompleted,
        verificationFailed: (e) {
          // Enhanced error handling
          String message = 'Verification failed';
          if (e.code == 'invalid-phone-number') {
            message = 'Invalid phone number format';
          } else if (e.code == 'quota-exceeded') {
            message = 'SMS quota exceeded. Try again later.';
          }
          onVerificationFailed(FirebaseAuthException(
            code: e.code,
            message: message,
          ));
        },
        codeSent: (verificationId, forceResendingToken) {
          _forceResendingToken = forceResendingToken;
          onCodeSent(verificationId, forceResendingToken);
        },
        codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout ?? (verificationId) {},
        forceResendingToken: forceResendingToken ?? _forceResendingToken,
        timeout: const Duration(seconds: 120),
      );
    } catch (e) {
      onVerificationFailed(FirebaseAuthException(
        code: 'unknown-error',
        message: 'Failed to initiate phone verification',
      ));
    }
  }

  // 🔑 COMPLETE PHONE REGISTRATION
  Future<User?> completePhoneRegistration({
    required String verificationId,
    required String smsCode,
    required String password,
    required String fullName,
    required int age,
    required String gender,
    required String course,
    required String department,
    required String level,
    required String enrollmentYear,
    required double feesPaid,
    required double balance,
    required String studentCategory,
  }) async {
    try {
      // Test verification bypass
      if (verificationId == 'test_verification_id' && smsCode == '123456') {
        final fakeUser = await _auth.signInAnonymously();
        return fakeUser.user;
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      // Create backup email/password
      final email = '${user.uid}@nasawa.edu.mw';
      await user.updateEmail(email);
      await user.updatePassword(password);

      await _saveStudentData(
        uid: user.uid,
        phone: user.phoneNumber,
        email: email,
        fullName: fullName,
        age: age,
        gender: gender,
        course: course,
        department: department,
        level: level,
        enrollmentYear: enrollmentYear,
        feesPaid: feesPaid,
        balance: balance,
        studentCategory: studentCategory,
      );

      return user;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: e.code == 'invalid-verification-code' 
            ? 'Invalid OTP code' 
            : 'Registration failed',
      );
    }
  }

  // 👤 UNIVERSAL LOGIN (UPDATED FOR ADMIN ACCESS)
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    try {
      // Admin email pattern check
      final isAdminEmail = email.endsWith('@nasawa.edu.mw');
      
      // Special handling for admin emails
      if (isAdminEmail) {
        try {
          final userCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          return userCredential.user;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'user-not-found') {
            // Create admin account if not exists
            final userCredential = await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
            await _firestore.collection('users').doc(userCredential.user!.uid).set({
              'uid': userCredential.user!.uid,
              'email': email,
              'userType': 'admin',
              'createdAt': FieldValue.serverTimestamp(),
            });
            return userCredential.user;
          }
          rethrow;
        }
      }

      // Normal user login
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) return null;

      // Verify user exists in Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'User record not found in database',
        );
      }

      // Email verification check for students
      if (userDoc.data()?['userType'] != 'admin' && 
          !user.emailVerified && 
          user.email?.isNotEmpty == true) {
        await user.sendEmailVerification();
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Please verify your email first. A new link has been sent.',
        );
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: e.code == 'wrong-password'
            ? 'Invalid credentials'
            : e.message ?? 'Login failed',
      );
    }
  }

  // 🧑‍💼 ADMIN SPECIFIC METHODS
  Future<void> createAdminAccount({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'userType': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: e.code == 'email-already-in-use'
            ? 'Admin account already exists'
            : 'Failed to create admin account',
      );
    }
  }

  // 💾 SAVE STUDENT DATA (PRIVATE HELPER)
  Future<void> _saveStudentData({
    required String uid,
    String? email,
    String? phone,
    required String fullName,
    required int age,
    required String gender,
    required String course,
    required String department,
    required String level,
    required String enrollmentYear,
    required double feesPaid,
    required double balance,
    required String studentCategory,
  }) async {
    final studentData = {
      'uid': uid,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'fullName': fullName,
      'age': age,
      'gender': gender,
      'course': course,
      'department': department,
      'level': level,
      'enrollmentYear': enrollmentYear,
      'feesPaid': feesPaid,
      'balance': balance,
      'studentCategory': studentCategory,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'isPhoneVerified': phone != null,
    };

    await _firestore.collection('students').doc(uid).set(studentData);
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'userType': 'student',
      'department': department,
    });
  }

  // ✔️ Check if Student is Approved
  Future<bool> isStudentApproved(String uid) async {
    final doc = await _firestore.collection('students').doc(uid).get();
    return doc.exists && doc.data()?['status'] == 'approved';
  }

  // 🧑‍💼 Check if User is Admin
  Future<bool> isAdmin(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists && doc.data()?['userType'] == 'admin';
  }

  // 🔓 Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 👁️‍🗨️ Get Current User
  User? get currentUser => _auth.currentUser;

  // ✉️ Resend Email Verification
  Future<void> resendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    } else {
      throw 'No unverified email user found';
    }
  }

  // 🔄 Update User Password
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    } else {
      throw 'No authenticated user';
    }
  }

  // 🆔 Get User Role
  Future<String?> getUserRole(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['userType'];
  }
}