import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/core/components/error_dialog.dart';
import 'package:stakk_savings/core/utils/snackbar_utils.dart';
import 'package:stakk_savings/providers/auth_provider.dart';
import 'package:stakk_savings/features/wallet/presentation/screens/usdc_wallet_screen.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _transfer() async {
    final address = _addressController.text.trim();
    final amount = double.tryParse(_amountController.text);

    if (address.isEmpty) {
      showTopSnackBar(context, 'Enter wallet address');
      return;
    }

    if (amount == null || amount <= 0) {
      showTopSnackBar(context, 'Enter valid amount');
      return;
    }

    // Validate Stellar address format (starts with G and is 56 chars)
    if (!address.startsWith('G') || address.length != 56) {
      showTopSnackBar(context, 'Invalid Stellar wallet address');
      return;
    }

    setState(() => _loading = true);

    try {
      final auth = context.read<AuthProvider>();
      final balance = await auth.getBalance();

      if (balance.usdc < amount) {
        if (mounted) {
          showTopSnackBar(context, 'Insufficient balance');
          setState(() => _loading = false);
        }
        return;
      }

      // TODO: Implement actual transfer API call
      // await auth.transferUSDC(address, amount);

      if (mounted) {
        HapticFeedback.mediumImpact();
        showTopSnackBar(context, 'Transfer successful');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, message: 'Transfer failed: ${e.toString()}');
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WalletColors.background,
      appBar: AppBar(
        title: const Text(
          'Transfer USDC',
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
              Text(
                'Recipient wallet address',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: WalletColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _addressController,
                style: const TextStyle(
                  fontSize: 16,
                  color: WalletColors.textPrimary,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: 'G...',
                  hintStyle: const TextStyle(
                    color: WalletColors.textSecondary,
                  ),
                  prefixIcon: const FaIcon(
                    FontAwesomeIcons.wallet,
                    color: WalletColors.textSecondary,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: WalletColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2C2C2E),
                      width: 0.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2C2C2E),
                      width: 0.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: WalletColors.primary,
                      width: 1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Amount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: WalletColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                  fontSize: 16,
                  color: WalletColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: const TextStyle(
                    color: WalletColors.textSecondary,
                  ),
                  prefixIcon: const FaIcon(
                    FontAwesomeIcons.dollarSign,
                    color: WalletColors.textSecondary,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: WalletColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2C2C2E),
                      width: 0.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2C2C2E),
                      width: 0.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: WalletColors.primary,
                      width: 1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _transfer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WalletColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: WalletColors.textSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Send USDC',
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
