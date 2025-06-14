import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: 'MWK ',
    decimalDigits: 2,
  );
  
  double? feesPaid;
  double? balance;
  String fullName = "Student";
  String department = "";
  String course = "";
  String level = "";
  bool isLoading = true;
  bool isProfileComplete = false;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          feesPaid = (data['feesPaid'] ?? 0).toDouble();
          balance = (data['balance'] ?? 0).toDouble();
          fullName = data['fullName'] ?? "Student";
          department = data['department'] ?? "";
          course = data['course'] ?? "";
          level = data['level']?.toString() ?? "";
          isProfileComplete = data['status'] == 'approved';
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading student data: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2D3E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Confirm Logout',
            style: GoogleFonts.poppins(color: Colors.white)),
        content: Text('Are you sure you want to logout?',
            style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context, 
                  '/login', 
                  (route) => false
                );
              }
            },
            child: Text('Logout', 
                style: GoogleFonts.poppins(
                  color: Colors.red[400],
                  fontWeight: FontWeight.w600
                )),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1D2B),
      body: CustomScrollView(
        slivers: [
          // App Bar
SliverAppBar(
  expandedHeight: 120,
  floating: false,
  pinned: true,
  backgroundColor: const Color(0xFF1F1D2B),
  elevation: 0,
  title: Text('My dashboard',
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white, // Explicit white color
      )),
  actions: [
    IconButton(
      icon: const Icon(Icons.logout, 
          size: 22, 
          color: Colors.white), // Explicit white color
      onPressed: () => _confirmLogout(context),
    ),
  ],
  flexibleSpace: FlexibleSpaceBar(
    background: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A2D3E), Color(0xFF1F1D2B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    ),
  ),
),
          // Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Card
                      _buildProfileCard(),

                      const SizedBox(height: 20),

                      // Fees Card
                      _buildFeesCard(),

                      const SizedBox(height: 25),

                      // Quick Actions Title
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text('Quick Access',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            )),
                      ),

                      // Minimalist Quick Actions
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 4,
                        childAspectRatio: 0.8,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        children: [
                          _buildMinimalAction(Icons.grade, 'Results', Colors.amber[400]!),
                          _buildMinimalAction(Icons.assignment, 'Courses', Colors.blue[400]!),
                          _buildMinimalAction(Icons.schedule, 'Schedule', Colors.purple[400]!),
                          _buildMinimalAction(Icons.library_books, 'Materials', Colors.teal[400]!),
                          _buildMinimalAction(Icons.assessment, 'Progress', Colors.green[400]!),
                          _buildMinimalAction(Icons.payment, 'Payments', Colors.orange[400]!),
                          _buildMinimalAction(Icons.edit_document, 'Forms', Colors.pink[400]!),
                          _buildMinimalAction(Icons.help, 'Support', Colors.indigo[400]!),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // Status Indicator
                      if (!isProfileComplete)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: Colors.orange[300]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Your profile is pending approval',
                                  style: GoogleFonts.poppins(
                                    color: Colors.orange[300],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D3E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.blueAccent.withOpacity(0.8),
                  Colors.purpleAccent.withOpacity(0.8),
                ],
              ),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fullName,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    )),
                const SizedBox(height: 4),
                Text(
                  '$department • $course',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Level $level',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D3E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Fees Overview',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  )),
              const Icon(Icons.credit_card, color: Colors.white70, size: 22),
            ],
          ),
          const SizedBox(height: 16),
          _buildFeeItem('Paid', feesPaid, Colors.greenAccent),
          const SizedBox(height: 8),
          _buildFeeItem('Balance', balance, Colors.orangeAccent),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: balance != null && feesPaid != null && (feesPaid! + balance!) > 0
                ? feesPaid! / (feesPaid! + balance!)
                : 0,
            backgroundColor: Colors.white12,
            color: Colors.lightBlueAccent,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeItem(String label, double? amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white70,
            )),
        Text(_currencyFormat.format(amount),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            )),
      ],
    );
  }

  Widget _buildMinimalAction(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () => _showComingSoon(label),
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 58),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 17,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}