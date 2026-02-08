import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/constants/storage_keys.dart';

import 'features/auth/auth.dart';
import 'features/dashboard/presentation/screens/dashboard_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StakkApp());
}

class StakkApp extends StatelessWidget {
  const StakkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProvider, __) {
          return MaterialApp(
            title: 'Stakk',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
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
              '/dashboard': (context) => const DashboardShell(),
            },
            onUnknownRoute: (_) =>
                MaterialPageRoute(builder: (_) => const AuthGate()),
          );
        },
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
          return const DashboardShell();
        }
        return const OnboardingScreen();
      },
    );
  }

  Future<AuthGateResult> _checkAuth(BuildContext context) async {
    final hasToken = await context.read<AuthProvider>().isAuthenticated();
    if (!hasToken) return AuthGateResult(isAuth: false, hasPasscode: false);
    const storage = FlutterSecureStorage();
    final passcode = await storage.read(key: StorageKeys.passcode);
    return AuthGateResult(isAuth: true, hasPasscode: passcode != null && passcode.isNotEmpty);
  }
}

class AuthGateResult {
  final bool isAuth;
  final bool hasPasscode;

  AuthGateResult({required this.isAuth, required this.hasPasscode});
}
