import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/api/api_client.dart';
import 'package:stakk_savings/features/bills/domain/models/bill_models.dart';
import 'package:stakk_savings/providers/auth_provider.dart';

class BillsPaySheet extends StatefulWidget {
  final BillCategoryModel category;
  final BillProviderModel provider;
  final double balance;
  final VoidCallback onClose;
  final VoidCallback onSuccess;

  const BillsPaySheet({
    super.key,
    required this.category,
    required this.provider,
    required this.balance,
    required this.onClose,
    required this.onSuccess,
  });

  @override
  State<BillsPaySheet> createState() => _BillsPaySheetState();
}

class _BillsPaySheetState extends State<BillsPaySheet> {
  List<BillProductModel> _products = [];
  BillProductModel? _selectedProduct;
  final _customerController = TextEditingController();
  final _amountController = TextEditingController();
  bool _loadingProducts = true;
  bool _loading = false;
  bool _validating = false;
  String? _error;
  String? _validatedName;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _customerController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _loadingProducts = true);
    try {
      final products = await context.read<AuthProvider>().getBillProducts(widget.provider.billerCode);
      if (mounted) {
        setState(() {
          _products = products;
          _loadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _products = [];
          _loadingProducts = false;
        });
      }
    }
  }

  String get _labelName {
    final code = widget.category.code.toUpperCase();
    if (code.contains('AIRTIME') || code.contains('DATA') || code.contains('MOBILEDATA')) return 'Mobile Number';
    if (code.contains('CABLE') || code.contains('TV')) return 'Smart Card Number';
    if (code.contains('UTILITY') || code.contains('ELECTRIC')) return 'Meter Number';
    return 'Account Number';
  }

  bool get _isPhoneInput =>
      widget.category.code.toUpperCase().contains('AIRTIME') ||
      widget.category.code.toUpperCase().contains('MOBILEDATA');

  String get _itemCode {
    if (_selectedProduct != null && _selectedProduct!.productCode.isNotEmpty) {
      return _selectedProduct!.productCode;
    }
    final code = widget.category.code.toUpperCase();
    if (code.contains('AIRTIME')) return 'AT099';
    if (code.contains('MOBILEDATA')) return 'DT101';
    return 'AT099';
  }

  double get _amount {
    if (_selectedProduct != null && _selectedProduct!.amount > 0) return _selectedProduct!.amount;
    return double.tryParse(_amountController.text.trim()) ?? 0;
  }

  Future<void> _validate() async {
    final customer = _customerController.text.trim();
    if (customer.isEmpty) {
      setState(() => _error = 'Enter $_labelName');
      return;
    }
    setState(() {
      _validating = true;
      _error = null;
      _validatedName = null;
    });
    try {
      final validation = await context.read<AuthProvider>().validateBill(
            itemCode: _itemCode,
            code: widget.provider.billerCode,
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
        if (e.message == 'Session expired') {
          await context.read<AuthProvider>().handleSessionExpired(context);
        } else {
          setState(() {
            _error = e.message;
            _validating = false;
          });
        }
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
      setState(() => _error = 'Enter $_labelName');
      return;
    }
    final amount = _amount;
    if (amount < 1) {
      setState(() => _error = 'Enter valid amount (min ₦1)');
      return;
    }
    const ngnUsdRate = 1580.0;
    final usdcNeeded = amount / ngnUsdRate;
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
            billerCode: widget.provider.billerCode,
            itemCode: _itemCode,
          );
      if (mounted) {
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully paid ₦${amount.toStringAsFixed(0)} ${widget.provider.name}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        if (e.message == 'Session expired') {
          await context.read<AuthProvider>().handleSessionExpired(context);
        } else {
          setState(() {
            _error = e.message;
            _loading = false;
          });
        }
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.95,
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
                  '${widget.category.name} – ${widget.provider.name}',
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
                  keyboardType: _isPhoneInput ? TextInputType.phone : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: _labelName,
                    hintText: _isPhoneInput ? '08012345678' : 'Enter $_labelName',
                    border: const OutlineInputBorder(),
                    suffixIcon: _validatedName != null
                        ? Icon(Icons.check_circle, color: const Color(0xFF059669))
                        : null,
                  ),
                  inputFormatters: _isPhoneInput
                      ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)]
                      : null,
                ),
                if (_validatedName != null) ...[
                  const SizedBox(height: 8),
                  Text('✓ $_validatedName', style: AppTheme.body(fontSize: 13, color: const Color(0xFF059669))),
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
                if (_loadingProducts)
                  const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                else if (_products.isNotEmpty) ...[
                  Text(
                    'Select product',
                    style: AppTheme.header(context: context, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ..._products.map((p) => _ProductTile(
                        product: p,
                        selected: _selectedProduct?.id == p.id,
                        onTap: () => setState(() {
                          _selectedProduct = p;
                          _amountController.text = p.amount > 0 ? p.amount.toStringAsFixed(0) : '';
                        }),
                      )),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _products.isNotEmpty && _selectedProduct == null ? 'Or enter amount (NGN)' : 'Amount (NGN)',
                    hintText: 'e.g. 500',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() => _selectedProduct = null),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: AppTheme.body(fontSize: 14, color: const Color(0xFFDC2626))),
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

class _ProductTile extends StatelessWidget {
  final BillProductModel product;
  final bool selected;
  final VoidCallback onTap;

  const _ProductTile({required this.product, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEEF2FF) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? const Color(0xFF4F46E5) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: AppTheme.header(context: context, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                product.amount > 0 ? '₦${product.amount.toStringAsFixed(0)}' : 'Custom',
                style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
