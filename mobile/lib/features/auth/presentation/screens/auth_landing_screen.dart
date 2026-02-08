import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/providers/auth_provider.dart';
import 'package:stakk_savings/api/auth_service.dart';

class AuthLandingScreen extends StatelessWidget {
  const AuthLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(
                'Stakk',
                style: AppTheme.header(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Protect your savings from naira devaluation',
                style: AppTheme.body(
                    fontSize: 15, color: const Color(0xFF6B7280)),
              ),
              const SizedBox(height: 48),
              _GoogleSignInButton(),
              if (Platform.isIOS) ...[
                const SizedBox(height: 16),
                _AppleSignInButton(),
              ],
              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('or', style: TextStyle(color: Color(0xFF9CA3AF))),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/auth/check-email'),
                icon: const Icon(Icons.email_outlined, size: 20),
                label: const Text('Continue with Email'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/auth'),
                child: Text(
                  'Sign in with phone & password',
                  style: AppTheme.body(fontSize: 14, color: const Color(0xFF6B7280)),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Save in USDC • Secured by Stellar',
                textAlign: TextAlign.center,
                style: AppTheme.body(fontSize: 13, color: const Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatefulWidget {
  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email'],
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in failed')),
        );
        return;
      }

      await context.read<AuthProvider>().signInWithGoogle(idToken);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: _loading ? null : _signIn,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.g_mobiledata, size: 28),
                  SizedBox(width: 12),
                  Text('Continue with Google'),
                ],
              ),
      ),
    );
  }
}

class _AppleSignInButton extends StatefulWidget {
  @override
  State<_AppleSignInButton> createState() => _AppleSignInButtonState();
}

class _AppleSignInButtonState extends State<_AppleSignInButton> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      final cred = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = cred.identityToken;
      if (idToken == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Apple sign-in failed')),
        );
        return;
      }

      await context.read<AuthProvider>().signInWithApple(
        identityToken: idToken,
        email: cred.email,
        firstName: cred.givenName,
        lastName: cred.familyName,
      );
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code != AuthorizationErrorCode.canceled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Apple sign-in: ${e.message}')),
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Apple sign-in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: SignInWithAppleButton(
        onPressed: _loading ? () {} : () => _signIn(),
        style: SignInWithAppleButtonStyle.black,
      ),
    );
  }
}
