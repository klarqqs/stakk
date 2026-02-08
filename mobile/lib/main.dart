import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/auth_landing_screen.dart';
import 'screens/email_otp_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/check_email_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/verify_email_screen.dart';
import 'screens/complete_profile_screen.dart';
import 'screens/create_passcode_screen.dart';
import 'screens/reenter_passcode_screen.dart';
import 'screens/passcode_gate_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StakkApp());
}

class StakkApp extends StatelessWidget {
  const StakkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'Stakk',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthGate(),
          '/auth': (context) => const AuthScreen(),
          '/auth/email': (context) => const EmailOtpScreen(),
          '/auth/landing': (context) => const AuthLandingScreen(),
          '/auth/check-email': (context) => const CheckEmailScreen(),
          '/auth/login': (context) => const LoginScreen(),
          '/auth/signup': (context) => const SignupScreen(),
          '/auth/verify-email': (context) => const VerifyEmailScreen(),
          '/auth/complete-profile': (context) => const CompleteProfileScreen(),
          '/auth/create-passcode': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            return CreatePasscodeScreen(isFromSignup: args == true);
          },
          '/auth/reenter-passcode': (context) => const ReenterPasscodeScreen(),
          '/auth/passcode': (context) => const PasscodeGateScreen(),
          '/auth/forgot-password': (context) => const ForgotPasswordScreen(),
          '/auth/reset-password': (context) => const ResetPasswordScreen(),
          '/dashboard': (context) => const DashboardScreen(),
        },
        onUnknownRoute: (_) =>
            MaterialPageRoute(builder: (_) => const AuthGate()),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthGateResult>(
      future: _checkAuth(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: AppTheme.body(fontSize: 14, color: const Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          );
        }
        final result = snapshot.data ?? AuthGateResult(isAuth: false, hasPasscode: false);
        if (result.isAuth && result.hasPasscode) {
          return const PasscodeGateScreen();
        }
        if (result.isAuth) {
          return const DashboardScreen();
        }
        return const OnboardingScreen();
      },
    );
  }

  Future<AuthGateResult> _checkAuth(BuildContext context) async {
    final hasToken = await context.read<AuthProvider>().isAuthenticated();
    if (!hasToken) return AuthGateResult(isAuth: false, hasPasscode: false);
    const storage = FlutterSecureStorage();
    final passcode = await storage.read(key: 'passcode');
    return AuthGateResult(isAuth: true, hasPasscode: passcode != null && passcode.isNotEmpty);
  }
}

class AuthGateResult {
  final bool isAuth;
  final bool hasPasscode;

  AuthGateResult({required this.isAuth, required this.hasPasscode});
}
