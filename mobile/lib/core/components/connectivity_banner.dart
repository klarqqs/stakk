import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../theme/tokens/app_colors.dart';

/// Shows a banner when device has no internet connectivity.
/// Place at top of app (e.g. above Scaffold body) so user knows why loading may fail.
class ConnectivityBanner extends StatefulWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _subscription = Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() => _isOnline = _hasConnection(result));
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> result) {
    if (mounted) {
      setState(() => _isOnline = _hasConnection(result));
    }
  }

  bool _hasConnection(List<ConnectivityResult> result) {
    if (result.isEmpty) return false;
    return result.any((r) => r != ConnectivityResult.none);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!_isOnline) _OfflineBanner(),
        Expanded(child: widget.child),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.errorBackground,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.wifi_off_rounded, size: 20, color: AppColors.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No internet connection',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
