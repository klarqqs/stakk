import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/api/api_client.dart';
import 'package:stakk_savings/providers/auth_provider.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  List<BillCategory> _categories = [];
  bool _loading = true;
  String? _error;
  WalletBalance? _balance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final results = await Future.wait([
        auth.getBillCategories(),
        auth.getBalance(),
      ]);
      if (mounted) {
        setState(() {
          _categories = results[0] as List<BillCategory>;
          _balance = results[1] as WalletBalance;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load';
          _loading = false;
        });
      }
    }
  }

  void _openPaySheet(BillCategory category) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PayBillSheet(
        category: category,
        balance: _balance?.usdc ?? 0,
        onClose: () => Navigator.of(ctx).pop(),
        onSuccess: () {
          Navigator.of(ctx).pop();
          _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Bills',
                        style: AppTheme.header(context: context, fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pay airtime, data, DSTV, electricity with USDC',
                        style: AppTheme.body(fontSize: 14, color: const Color(0xFF6B7280)),
                      ),
                      if (_balance != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Available',
                                style: AppTheme.body(fontSize: 14, color: const Color(0xFF6B7280)),
                              ),
                              Text(
                                '\$${_balance!.usdc.toStringAsFixed(2)} USDC',
                                style: AppTheme.header(context: context, fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF4F46E5)),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: AppTheme.body(fontSize: 14, color: const Color(0xFFDC2626)),
                                ),
                              ),
                              TextButton(
                                onPressed: _load,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        'Select service',
                        style: AppTheme.header(context: context, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      if (_categories.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            'No bill services available',
                            textAlign: TextAlign.center,
                            style: AppTheme.body(fontSize: 14, color: const Color(0xFF9CA3AF)),
                          ),
                        )
                      else
                        ..._categories.map((c) => _BillTile(
                              category: c,
                              onTap: () => _openPaySheet(c),
                            )),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _BillTile extends StatelessWidget {
  final BillCategory category;
  final VoidCallback onTap;

  const _BillTile({required this.category, required this.onTap});

  IconData get _icon {
    if (category.isAirtime) return Icons.phone_android;
    if (category.billerName.toUpperCase().contains('DSTV') ||
        category.billerName.toUpperCase().contains('GOTV') ||
        category.billerName.toUpperCase().contains('STARTIMES')) {
      return Icons.tv;
    }
    if (category.billerName.toUpperCase().contains('PREPAID') ||
        category.billerName.toUpperCase().contains('POSTPAID') ||
        category.billerName.toUpperCase().contains('EKEDC') ||
        category.billerName.toUpperCase().contains('IKEDC') ||
        category.billerName.toUpperCase().contains('ELECTRICITY')) {
      return Icons.bolt;
    }
    return Icons.receipt_long;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon, color: const Color(0xFF4F46E5), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: AppTheme.header(context: context, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.billerName,
                      style: AppTheme.body(fontSize: 13, color: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayBillSheet extends StatefulWidget {
  final BillCategory category;
  final double balance;
  final VoidCallback onClose;
  final VoidCallback onSuccess;

  const _PayBillSheet({
    required this.category,
    required this.balance,
    required this.onClose,
    required this.onSuccess,
  });

  @override
  State<_PayBillSheet> createState() => _PayBillSheetState();
}

class _PayBillSheetState extends State<_PayBillSheet> {
  final _customerController = TextEditingController();
  final _amountController = TextEditingController();
  bool _loading = false;
  bool _validating = false;
  String? _error;
  String? _validatedName;

  @override
  void dispose() {
    _customerController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _validate() async {
    final customer = _customerController.text.trim();
    if (customer.isEmpty) {
      setState(() => _error = 'Enter ${widget.category.labelName}');
      return;
    }
    setState(() {
      _validating = true;
      _error = null;
      _validatedName = null;
    });
    try {
      final validation = await context.read<AuthProvider>().validateBill(
            itemCode: widget.category.itemCode,
            code: widget.category.billerCode,
            customer: customer,
          );
      if (mounted) {
        setState(() {
          _validatedName = validation.name;
          _validating = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _validating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Validation failed';
          _validating = false;
        });
      }
    }
  }

  Future<void> _pay() async {
    final customer = _customerController.text.trim();
    if (customer.isEmpty) {
      setState(() => _error = 'Enter ${widget.category.labelName}');
      return;
    }
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount < 1) {
      setState(() => _error = 'Enter valid amount (min ₦1)');
      return;
    }
    final usdcNeeded = amount / 1580;
    if (usdcNeeded > widget.balance) {
      setState(() => _error = 'Insufficient balance');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().payBill(
            customer: customer,
            amount: amount,
            type: widget.category.shortName,
          );
      if (mounted) {
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully paid ₦${amount.toStringAsFixed(0)} ${widget.category.name}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Payment failed';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = widget.category.labelName.toLowerCase().contains('mobile') ||
        widget.category.labelName.toLowerCase().contains('number') ||
        widget.category.isAirtime;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.category.name,
                  style: AppTheme.header(context: context, fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Balance: \$${widget.balance.toStringAsFixed(2)} USDC',
                  style: AppTheme.body(fontSize: 14, color: const Color(0xFF6B7280)),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _customerController,
                  keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: widget.category.labelName,
                    hintText: isPhone ? '08012345678' : 'Enter ${widget.category.labelName}',
                    border: const OutlineInputBorder(),
                    suffixIcon: _validatedName != null
                        ? Icon(Icons.check_circle, color: const Color(0xFF059669))
                        : null,
                  ),
                  inputFormatters: isPhone
                      ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)]
                      : null,
                ),
                if (_validatedName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '✓ $_validatedName',
                    style: AppTheme.body(fontSize: 13, color: const Color(0xFF059669)),
                  ),
                ],
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _validating ? null : _validate,
                  icon: _validating
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.verified_user_outlined, size: 18),
                  label: Text(_validating ? 'Validating...' : 'Validate'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount (NGN)',
                    hintText: 'e.g. 500',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: AppTheme.body(fontSize: 14, color: const Color(0xFFDC2626)),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _pay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                        : const Text('Pay with USDC'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
