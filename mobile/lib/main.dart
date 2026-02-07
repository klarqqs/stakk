import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth_screen.dart';
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
    return FutureBuilder<bool>(
      future: context.read<AuthProvider>().isAuthenticated(),
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
        final isAuth = snapshot.data ?? false;
        return isAuth
            ? const DashboardScreen()
            : const AuthScreen();
      },
    );
  }
}
