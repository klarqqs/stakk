import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stakk_savings/core/utils/snackbar_utils.dart';
import 'package:stakk_savings/providers/auth_provider.dart';
import 'package:stakk_savings/features/wallet/presentation/screens/usdc_wallet_screen.dart';

class WalletAddressScreen extends StatelessWidget {
  const WalletAddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final stellarAddress = auth.user?.stellarAddress ?? '';
    final userFirstName = auth.user?.firstName ?? 'U';

    return Scaffold(
      backgroundColor: WalletColors.background,
      appBar: AppBar(
        title: const Text(
          'Your USDC Wallet Address',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: WalletColors.textPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const FaIcon(
            FontAwesomeIcons.chevronLeft,
            size: 20,
            color: WalletColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Warning Text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.triangleExclamation,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Send only USDC and tokens on Stellar Network to this address, otherwise you might lose your funds',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[300],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // QR Code with User Initial
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: WalletColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF2C2C2E),
                      width: 0.5,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      QrImageView(
                        data: stellarAddress,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: WalletColors.cardBackground,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: WalletColors.textPrimary,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: WalletColors.textPrimary,
                        ),
                      ),
                      // User Initial Circle Overlay
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: WalletColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            userFirstName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Scan QR Text
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.camera,
                      size: 16,
                      color: WalletColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Scan QR with camera to send USDC to your wallet',
                      style: TextStyle(
                        fontSize: 12,
                        color: WalletColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Divider
              Container(
                height: 0.5,
                color: const Color(0xFF2C2C2E),
              ),

              const SizedBox(height: 32),

              // Your USDC Address Label
              Text(
                'Your USDC Address:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: WalletColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Address Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: WalletColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2C2C2E),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  stellarAddress,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: WalletColors.textPrimary,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 24),

              // Copy Address Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: stellarAddress));
                    HapticFeedback.mediumImpact();
                    showTopSnackBar(context, 'Address copied!');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WalletColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Copy Address',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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
