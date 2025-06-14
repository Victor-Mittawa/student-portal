import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home/student_home.dart';
import '../screens/home/admin_home.dart';
import '../screens/home/profile_screen.dart';
import '../screens/dashboard/courses_screen.dart';
import '../screens/dashboard/payments_screen.dart';
import '../screens/payment_upload_screen.dart';
import '../screens/dashboard/upload_results_screen.dart';
import '../screens/auth/admin_signup_screen.dart';

class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';
  static const studentHome = '/student-home';
  static const adminHome = '/admin-home';
  static const adminSignup = '/admin-signup';
  static const profile = '/profile';
  static const courses = '/courses';
  static const payments = '/payments';
  static const uploadPayment = '/upload-payment';
  static const uploadResults = '/upload-results';

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashScreen(),
        login: (context) => const LoginScreen(),
        signup: (context) => const SignupScreen(),
        adminSignup: (context) => const AdminSignupScreen(),
        studentHome: (context) => const StudentHomeScreen(),
        profile: (context) => const ProfileScreen(),
        courses: (context) => const CoursesScreen(),
        payments: (context) => const PaymentsScreen(),
        uploadPayment: (context) => const PaymentUploadScreen(),
        // Note: adminHome and uploadResults are dynamic — handled below
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case adminHome:
        final args = settings.arguments as Map<String, dynamic>?;
        final department = args?['department'] ?? 'General';
        return MaterialPageRoute(
          builder: (_) => AdminHomeScreen(department: department),
        );

      case uploadResults:
        final args = settings.arguments as Map<String, dynamic>?;
        final department = args?['department'] ?? 'General';
        return MaterialPageRoute(
          builder: (_) => UploadResultsScreen(department: department),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('404 - Route not found'),
            ),
          ),
        );
    }
  }
}
