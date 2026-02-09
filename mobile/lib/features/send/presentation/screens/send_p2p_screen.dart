import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/api/api_client.dart';
import 'package:stakk_savings/core/components/buttons/primary_button.dart';
import 'package:stakk_savings/core/components/inputs/amount_input.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/core/utils/snackbar_utils.dart';
import 'package:stakk_savings/providers/auth_provider.dart';

class SendP2pScreen extends StatefulWidget {
  final double balance;
  final VoidCallback? onSuccess;

  const SendP2pScreen({super.key, required this.balance, this.onSuccess});

  @override
  State<SendP2pScreen> createState() => _SendP2pScreenState();
}

class _SendP2pScreenState extends State<SendP2pScreen> {
  final _receiverController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  P2pUser? _foundUser;
  bool _searching = false;
  bool _sending = false;
  String? _error;
  bool _success = false;
  String _successMessage = '';

  @override
  void dispose() {
    _receiverController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _receiverController.text.trim();
    if (query.length < 3) {
      setState(() {
        _error = 'Enter at least 3 characters';
        _foundUser = null;
      });
      return;
    }

    setState(() {
      _searching = true;
      _error = null;
      _foundUser = null;
    });

    try {
      final result = await context.read<AuthProvider>().p2pSearch(query);
      if (mounted) {
        setState(() {
          _foundUser = result.user;
          _searching = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _foundUser = null;
          _searching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Search failed';
          _searching = false;
        });
      }
    }
  }

  Future<void> _send() async {
    if (_foundUser == null) {
      setState(() => _error = 'Search for a user first');
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    if (amount > widget.balance) {
      setState(() => _error = 'Insufficient balance');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final receiver = _foundUser!.email ?? _foundUser!.phoneNumber;
      final result = await context.read<AuthProvider>().p2pSend(
        receiver: receiver,
        amount: amount,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _sending = false;
          _success = true;
          _successMessage = result.message;
        });
        widget.onSuccess?.call();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _sending = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Transfer failed';
          _sending = false;
        });
      }
    }
  }

  void _copyReceiver() {
    if (_foundUser != null) {
      final s = _foundUser!.email ?? _foundUser!.phoneNumber;
      Clipboard.setData(ClipboardData(text: s));
      showTopSnackBar(context, 'Copied to clipboard');
    }
  }

  Future<void> _pasteReceiver() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      _receiverController.text = data.text!;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final surface = isDark ? AppColors.surfaceVariantDarkMuted : Colors.white;
    final borderColor = isDark
        ? AppColors.borderDark.withValues(alpha: 0.4)
        : AppColors.borderLight.withValues(alpha: 0.6);

    if (_success) {
      return Scaffold(
        body: SafeArea(bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 80,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Sent Successfully!',
                  style: AppTheme.header(
                    context: context,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _successMessage,
                  textAlign: TextAlign.center,
                  style: AppTheme.body(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Done',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Send to Stakk User')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Balance card
            Text(
              'Balance: \$${widget.balance.toStringAsFixed(2)} USDC',
              style: AppTheme.body(
                fontSize: 14,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Phone or Email',
              style: AppTheme.body(
                context: context,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _receiverController,
                    keyboardType: TextInputType.emailAddress,
                    style: AppTheme.body(context: context, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'e.g. +2348012345678 or user@email.com',
                      hintStyle: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      filled: true,
                      fillColor: surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      suffixIcon: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _pasteReceiver,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.content_paste_outlined,
                              size: 18,
                              color: primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _searching ? null : _search,
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: _searching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Search'),
                ),
              ],
            ),
            if (_foundUser != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.successBackground,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        Icons.person,
                        color: AppColors.success,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _foundUser!.displayName,
                            style: AppTheme.body(
                              context: context,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _foundUser!.email ?? _foundUser!.phoneNumber,
                            style: AppTheme.body(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _copyReceiver,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.copy_outlined, size: 16, color: primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Amount (USDC)',
              style: AppTheme.body(
                context: context,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            AmountInput(
              controller: _amountController,
              currencyPrefix: '\$',
              hintText: '0.00',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              style: AppTheme.body(context: context, fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Note (optional)',
                hintText: "What's this for?",
                hintStyle: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                filled: true,
                fillColor: surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide(color: borderColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              maxLines: 2,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.error.withValues(alpha: 0.12)
                      : AppColors.errorBackground,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: AppTheme.body(
                          fontSize: 14,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Send',
                onPressed: (_foundUser == null || _sending) ? null : _send,
                isLoading: _sending,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
