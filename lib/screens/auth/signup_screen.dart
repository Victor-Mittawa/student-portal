import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:portal/services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _authService = AuthService();
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  // Controllers
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _feesPaidController = TextEditingController();
  final _balanceController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  // Verification
  String? _verificationMethod = 'email';
  String? _verificationId;
  int? _forceResendingToken;
  bool _isPhoneVerified = false;
  bool _isSendingOtp = false;
  int _otpResendTimeout = 0;
  Timer? _otpTimer;

  // Dropdown values
  String? _selectedCourse, _selectedDepartment, _selectedLevel, _selectedGender,
      _selectedEnrollmentYear, _selectedStudentCategory;

  bool _isLoading = false;
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _fullNameController.dispose();
    _ageController.dispose();
    _feesPaidController.dispose();
    _balanceController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _otpTimer?.cancel();
    super.dispose();
  }

  List<String> _years = List.generate(
    DateTime.now().year - 2021,
    (index) => '${2022 + index}',
  );

  List<DropdownMenuItem<String>> _getCoursesForDepartment(String? dept) {
    final deptCourses = {
      'Commercial': [
        'Administrative Studies',
        'Business Administrations',
        'Community Development',
        'Human Rights Management',
        'Public Health',
        'Procurement'
      ],
      'Information & Communication Technology': [
        'Information & Communication Technology'
      ],
      'Construction': ['Bricklaying', 'Carpentry & Joinery'],
      'Transportation': ['Automobile Mechanics', 'Motor Cycle Mechanics'],
      'Mechanical Engineering': ['General Fitting', 'Welding and Fabrication'],
    };
    
    return (deptCourses[dept] ?? []).map<DropdownMenuItem<String>>((course) {
      return DropdownMenuItem<String>(
        value: course,
        child: Text(
          course,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      );
    }).toList();
  }

  Future<void> _verifyPhoneNumber() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 9) return;

    setState(() => _isSendingOtp = true);

    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: phone,
        onCodeSent: (verificationId, forceResendingToken) {
          setState(() {
            _verificationId = verificationId;
            _forceResendingToken = forceResendingToken;
            _isSendingOtp = false;
            _startOtpTimer();
          });
          _showOtpDialog();
        },
        onVerificationFailed: (e) {
          setState(() => _isSendingOtp = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.message}')),
          );
        },
        onVerificationCompleted: (credential) async {
          await _auth.signInWithCredential(credential);
          setState(() => _isPhoneVerified = true);
        },
        forceResendingToken: _forceResendingToken,
      );
    } catch (e) {
      setState(() => _isSendingOtp = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP. Try again later.')),
      );
    }
  }

  void _startOtpTimer() {
    _otpTimer?.cancel();
    setState(() => _otpResendTimeout = 60);
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpResendTimeout > 0) {
        setState(() => _otpResendTimeout--);
      } else {
        timer.cancel();
      }
    });
  }

  void _showOtpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF203A43),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Enter OTP Code',
          style: GoogleFonts.poppins(
            color: Colors.tealAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'We sent a 6-digit code to +265${_phoneController.text.trim()}',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter 6-digit code',
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: _verifyOtp,
            child: Text(
              'Verify',
              style: GoogleFonts.poppins(
                color: Colors.tealAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-digit code')),
      );
      return;
    }

    try {
      final user = await _authService.completePhoneRegistration(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        gender: _selectedGender!,
        course: _selectedCourse!,
        department: _selectedDepartment!,
        level: _selectedLevel!,
        enrollmentYear: _selectedEnrollmentYear!,
        feesPaid: double.parse(_feesPaidController.text.replaceAll(',', '')),
        balance: double.parse(_balanceController.text.replaceAll(',', '')),
        studentCategory: _selectedStudentCategory!,
      );
      
      if (user != null) {
        setState(() => _isPhoneVerified = true);
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_verificationMethod == 'phone' && !_isPhoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify your phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user;
      if (_verificationMethod == 'email') {
        user = await _authService.registerStudent(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _fullNameController.text.trim(),
          age: int.parse(_ageController.text.trim()),
          gender: _selectedGender!,
          course: _selectedCourse!,
          department: _selectedDepartment!,
          level: _selectedLevel!,
          enrollmentYear: _selectedEnrollmentYear!,
          feesPaid: double.parse(_feesPaidController.text.replaceAll(',', '')),
          balance: double.parse(_balanceController.text.replaceAll(',', '')),
          studentCategory: _selectedStudentCategory!,
        );

        if (user != null) {
          _showVerificationDialog(
            'Verify Your Email',
            'We\'ve sent a verification link to ${_emailController.text.trim()}',
            Icons.mark_email_read,
          );
        }
      } else {
        user = await _authService.completePhoneRegistration(
          verificationId: _verificationId!,
          smsCode: _otpController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _fullNameController.text.trim(),
          age: int.parse(_ageController.text.trim()),
          gender: _selectedGender!,
          course: _selectedCourse!,
          department: _selectedDepartment!,
          level: _selectedLevel!,
          enrollmentYear: _selectedEnrollmentYear!,
          feesPaid: double.parse(_feesPaidController.text.replaceAll(',', '')),
          balance: double.parse(_balanceController.text.replaceAll(',', '')),
          studentCategory: _selectedStudentCategory!,
        );

        if (user != null) {
          _showVerificationDialog(
            'Registration Successful',
            'Your account has been created successfully',
            Icons.verified_user,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Registration failed';
      if (e.code == 'too-many-requests') {
        errorMessage = 'Too many attempts. Try again later.';
      } else if (e.code == 'invalid-verification-code') {
        errorMessage = 'Invalid OTP code';
      } else if (e.code == 'session-expired') {
        errorMessage = 'OTP session expired. Please request a new code.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showVerificationDialog(String title, String message, IconData icon) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF203A43),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.tealAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 60, color: Colors.tealAccent),
            const SizedBox(height: 20),
            Text(
              message,
              style: GoogleFonts.poppins(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: Text(
              'Continue to Login',
              style: GoogleFonts.poppins(
                color: Colors.tealAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d,]')),
        ],
        onChanged: (value) {
          final cursorPos = controller.selection.base.offset;
          final cleanValue = value.replaceAll(',', '');
          final formatted = NumberFormat('#,##0').format(int.tryParse(cleanValue) ?? 0);
          controller.value = controller.value.copyWith(
            text: formatted,
            selection: TextSelection.collapsed(
              offset: cursorPos + (formatted.length - value.length),
            ),
          );
        },
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: _inputDecoration(label),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Required';
          final amount = double.tryParse(value.replaceAll(',', ''));
          if (amount == null) return 'Invalid amount';
          return null;
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    bool isNumber = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscure && !_passwordVisible,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: _inputDecoration(label, suffixIcon: suffixIcon),
        validator: validator ??
            (value) => (value == null || value.isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: const Color(0xFF2C5364),
        decoration: _inputDecoration(hint),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              item,
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Required' : null,
        style: GoogleFonts.poppins(color: Colors.white),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.tealAccent),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.tealAccent),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            stops: [0.1, 0.5, 0.9],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - _opacityAnimation.value)),
                  child: child,
                ),
              );
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: GlassContainer(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Student Registration',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Verification Method Selector - UPDATED FOR BETTER VISIBILITY
                      Text(
                        'Verification Method',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Email'),
                              selected: _verificationMethod == 'email',
                              onSelected: (selected) => setState(() {
                                _verificationMethod = 'email';
                                _isPhoneVerified = false;
                              }),
                              selectedColor: Colors.tealAccent,
                              backgroundColor: _verificationMethod == 'phone' 
                                  ? Colors.grey[800]
                                  : null,
                              labelStyle: GoogleFonts.poppins(
                                color: _verificationMethod == 'email'
                                    ? Colors.black
                                    : _verificationMethod == 'phone' 
                                        ? Colors.tealAccent
                                        : Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Phone'),
                              selected: _verificationMethod == 'phone',
                              onSelected: (selected) => setState(() {
                                _verificationMethod = 'phone';
                              }),
                              selectedColor: Colors.tealAccent,
                              backgroundColor: _verificationMethod == 'email' 
                                  ? Colors.grey[800]
                                  : null,
                              labelStyle: GoogleFonts.poppins(
                                color: _verificationMethod == 'phone'
                                    ? Colors.black
                                    : _verificationMethod == 'email' 
                                        ? Colors.tealAccent
                                        : Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Email/Phone Field
                      if (_verificationMethod == 'email')
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Enter valid email';
                            }
                            return null;
                          },
                        )
                      else ...[
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number (e.g. 881234567)',
                          isNumber: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            if (value.length < 9) return 'Enter valid number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        if (!_isPhoneVerified)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.tealAccent[400],
                                foregroundColor: Colors.black, // Better contrast
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: (_isSendingOtp || _otpResendTimeout > 0)
                                  ? null
                                  : _verifyPhoneNumber,
                              child: _isSendingOtp
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.phone_android, size: 20),
                                        const SizedBox(width: 8),
                                        _otpResendTimeout > 0
                                            ? Text(
                                                'Resend OTP ($_otpResendTimeout)',
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              )
                                            : Text(
                                                'Send Verification Code',
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      ],
                                    ),
                            ),
                          ),
                        if (_isPhoneVerified)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified, color: Colors.green),
                                const SizedBox(width: 8),
                                Text(
                                  'Phone Verified',
                                  style: GoogleFonts.poppins(color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                      ],
                      const SizedBox(height: 16),

                      // Personal Info
                      _buildTextField(
                        controller: _fullNameController,
                        label: 'Full Name',
                      ),
                      _buildTextField(
                        controller: _ageController,
                        label: 'Age',
                        isNumber: true,
                      ),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        obscure: true,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: () => setState(
                              () => _passwordVisible = !_passwordVisible),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (value.length < 6) return 'Min 6 characters';
                          return null;
                        },
                      ),

                      // Academic Info
                      _buildDropdown(
                        hint: 'Gender',
                        value: _selectedGender,
                        items: ['Male', 'Female'],
                        onChanged: (val) => setState(() => _selectedGender = val),
                      ),
                      _buildDropdown(
                        hint: 'Year of Enrollment',
                        value: _selectedEnrollmentYear,
                        items: _years,
                        onChanged: (val) =>
                            setState(() => _selectedEnrollmentYear = val),
                      ),
                      _buildDropdown(
                        hint: 'Student Category',
                        value: _selectedStudentCategory,
                        items: [
                          'Boarding - Parallel',
                          'Boarding - Tevet',
                          'Day Scholar - Parallel',
                          'Day Scholar - Tevet'
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedStudentCategory = val),
                      ),
                      _buildDropdown(
                        hint: 'Department',
                        value: _selectedDepartment,
                        items: [
                          'Commercial',
                          'Construction',
                          'Information & Communication Technology',
                          'Mechanical Engineering',
                          'Transportation'
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedDepartment = val;
                            _selectedCourse = null;
                          });
                        },
                      ),
                      if (_selectedDepartment != null)
                        _buildDropdown(
                          hint: 'Course',
                          value: _selectedCourse,
                          items: _getCoursesForDepartment(_selectedDepartment)
                              .map((e) => e.value!)
                              .toList(),
                          onChanged: (val) => setState(() => _selectedCourse = val),
                        ),
                      _buildDropdown(
                        hint: 'Level',
                        value: _selectedLevel,
                        items: List.generate(6, (i) => '${i + 1}'),
                        onChanged: (val) => setState(() => _selectedLevel = val),
                      ),

                      // Financial Info
                      _buildNumberField(_feesPaidController, 'Fees Paid (MWK)'),
                      _buildNumberField(_balanceController, 'Balance (MWK)'),

                      // Submit Button
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent[400],
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            shadowColor: Colors.tealAccent.withOpacity(0.3),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Register Now',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Already have an account? Login',
                          style: GoogleFonts.poppins(
                            color: Colors.tealAccent[200],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              width: 1.5,
              color: Colors.white.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}