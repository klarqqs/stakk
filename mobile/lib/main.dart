import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'api/api_client.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/constants/storage_keys.dart';
import 'core/utils/offline_handler.dart';
// import 'providers/auth_provider.dart';
// import 'services/fcm_service.dart';
import 'services/error_tracking_service.dart';
import 'services/analytics_service.dart';
import 'services/app_version_service.dart';
import 'features/auth/auth.dart';
import 'features/dashboard/presentation/screens/dashboard_shell.dart';

/// Top-level function for handling background messages (must be top-level).
/// This must be a top-level function, not a class method.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM: Background message received: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
  // Handle background message processing here if needed
  // Note: You can't use BuildContext here, so navigation must be handled
  // when the app comes to foreground
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize error tracking (wraps app in error boundary)
  await ErrorTrackingService().initialize();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize analytics
  await AnalyticsService().initialize();
  
  // Initialize app version service
  await AppVersionService().initialize();
  
  // Initialize offline handler
  await OfflineHandler().initialize();
  
  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Run app with error tracking
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
      child: Builder(
        builder: (ctx) {
          // Set up session expiry handler
          ApiClient.onSessionExpired = () {
            ErrorTrackingService().captureMessage(
              'Session expired - user logged out',
              context: {'screen': 'api_client'},
            );
            ctx.read<AuthProvider>().logout().then((_) {
              if (ctx.mounted) {
                Navigator.of(ctx).pushNamedAndRemoveUntil('/', (r) => false);
              }
            });
          };
          
          return Consumer<ThemeProvider>(
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
                  '/auth/email': (context) => const EmailOtpScreen(),
                  '/auth/check-email': (context) => const CheckEmailScreen(),
                  '/auth/login': (context) => const LoginScreen(),
                  '/auth/signup': (context) => const SignupScreen(),
                  '/auth/verify-email': (context) => const VerifyEmailScreen(),
                  '/auth/complete-profile': (context) => const CompleteProfileScreen(),
                  '/auth/create-passcode': (context) {
                    final args = ModalRoute.of(context)?.settings.arguments;
                    return CreatePasscodeScreen(isFromSignup: args == true);
                  },
                  '/auth/reenter-passcode': (context) {
                    final args = ModalRoute.of(context)?.settings.arguments;
                    return ReenterPasscodeScreen(expectedPasscode: args is String ? args : null);
                  },
                  '/auth/passcode': (context) => const PasscodeGateScreen(),
                  '/auth/forgot-password': (context) => const ForgotPasswordScreen(),
                  '/auth/reset-password': (context) => const ResetPasswordScreen(),
                  '/dashboard': (context) => const DashboardShell(),
                },
                onUnknownRoute: (_) =>
                    MaterialPageRoute(builder: (_) => const AuthGate()),
                // Global error handler
                builder: (context, child) {
                  return _ErrorBoundary(child: child ?? const SizedBox());
                },
              );
            },
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
    final auth = context.read<AuthProvider>();
    final hasToken = await auth.isAuthenticated();
    if (!hasToken) return AuthGateResult(isAuth: false, hasPasscode: false);
    await auth.loadUserIfAuthenticated();
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

/// Global error boundary widget
class _ErrorBoundary extends StatefulWidget {
  final Widget child;

  const _ErrorBoundary({required this.child});

  @override
  State<_ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<_ErrorBoundary> {
  @override
  void initState() {
    super.initState();
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      ErrorTrackingService().captureError(
        details.exception,
        stackTrace: details.stack,
        context: {
          'library': details.library,
          'context': details.context?.toString(),
        },
      );
      FlutterError.presentError(details);
    };
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
