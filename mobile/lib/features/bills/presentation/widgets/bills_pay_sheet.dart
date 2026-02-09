import 'package:flutter/material.dart';
import 'package:stakk_savings/core/components/buttons/primary_button.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/core/constants/app_constants.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/api/api_client.dart';
import 'package:stakk_savings/features/bills/domain/models/bill_models.dart';
import 'package:stakk_savings/features/bills/presentation/widgets/bills_pay_products_skeleton.dart';
import 'package:stakk_savings/core/utils/snackbar_utils.dart';
import 'package:stakk_savings/providers/auth_provider.dart';

/// Formats amount input with commas (e.g. 100000 → 100,000)
class _AmountInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final parts = newValue.text.replaceAll(',', '').split('.');
    final intPart = parts[0].replaceAll(RegExp(r'[^\d]'), '');
    final decRaw = parts.length > 1 ? parts[1].replaceAll(RegExp(r'[^\d]'), '') : '';
    final decPart = decRaw.length > 2 ? '.${decRaw.substring(0, 2)}' : (decRaw.isEmpty ? '' : '.$decRaw');
    if (intPart.isEmpty) return TextEditingValue(text: decPart.isEmpty ? '' : '0$decPart', selection: TextSelection.collapsed(offset: decPart.isEmpty ? 0 : decPart.length));
    final formatted = '${AppConstants.formatNgn(int.parse(intPart))}$decPart';
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

class BillsPaySheet extends StatefulWidget {
  final BillCategoryModel category;
  final BillProviderModel provider;
  final double balance;
  final double? presetAmount;
  final VoidCallback onClose;
  final VoidCallback onSuccess;

  const BillsPaySheet({
    super.key,
    required this.category,
    required this.provider,
    required this.balance,
    this.presetAmount,
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

  void _onAmountChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _amountController.addListener(_onAmountChanged);
    if (widget.presetAmount != null && widget.presetAmount! >= 1) {
      _amountController.text = AppConstants.formatNgn(widget.presetAmount!.round());
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
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
          // Airtime: auto-select first product (usually just 1)
          if (_isAirtime && products.isNotEmpty) {
            _selectedProduct = products.first;
          }
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
    if (code.contains('INT') || code.contains('INTERNET')) return 'Subscription ID';
    return 'Account Number';
  }

  bool get _isPhoneInput =>
      widget.category.code.toUpperCase().contains('AIRTIME') ||
      widget.category.code.toUpperCase().contains('MOBILEDATA');

  bool get _isAirtime => widget.category.code.toUpperCase().contains('AIRTIME');

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
    final raw = _amountController.text.trim().replaceAll(',', '');
    return double.tryParse(raw) ?? 0;
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
    final usdcNeeded = amount / AppConstants.ngnUsdRate;
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
        showTopSnackBar(context, 'Successfully paid ₦${amount.toStringAsFixed(0)} ${widget.provider.name}');
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
                        ? Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Verified',
                                style: AppTheme.body(fontSize: 13, color: const Color(0xFF059669), fontWeight: FontWeight.w600),
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(right: 4),
                                    child: _validating
                                ? const Center(
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 3),
                                    ),
                                  )
                                : TextButton(
                                    onPressed: _validate,
                                    style: TextButton.styleFrom(
                                      minimumSize: Size.zero,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text('Validate'),
                                  ),
                          ),
                  ),
                  inputFormatters: _isPhoneInput
                      ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)]
                      : null,
                ),
                if (_validatedName != null) ...[
                  const SizedBox(height: 8),
                  Text('✓ $_validatedName', style: AppTheme.body(fontSize: 13, color: const Color(0xFF059669))),
                ],
                const SizedBox(height: 16),
                if (_loadingProducts)
                  const BillsPayProductsSkeleton()
                else if (_products.isNotEmpty && !_isAirtime) ...[
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
                          _amountController.text = p.amount > 0 ? AppConstants.formatNgn(p.amount.round()) : '';
                        }),
                      )),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: _amountController,
                  readOnly: _selectedProduct != null && _selectedProduct!.amount > 0,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: (_isAirtime || _selectedProduct != null) ? 'Amount (NGN)' : 'Or enter amount (NGN)',
                    hintText: 'e.g. 500',
                    border: const OutlineInputBorder(),
                  ),
                  inputFormatters: [
                    _AmountInputFormatter(),
                  ],
                  onChanged: (_) => setState(() {
                    if (_selectedProduct != null && _selectedProduct!.amount > 0) _selectedProduct = null;
                  }),
                ),
                if (_amount >= 1) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: const Color(0xFF4F46E5)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '≈ \$${(_amount / AppConstants.ngnUsdRate).toStringAsFixed(2)} USDC will be deducted',
                            style: AppTheme.body(context: context, fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF4F46E5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: AppTheme.body(fontSize: 14, color: const Color(0xFFDC2626))),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Pay with USDC',
                    onPressed: _loading ? null : _pay,
                    isLoading: _loading,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final surface = isDark ? AppColors.surfaceVariantDarkMuted : AppColors.surfaceVariantLight;
    final surfaceSelected = isDark ? primary.withValues(alpha: 0.2) : primary.withValues(alpha: 0.08);
    final borderColor = isDark ? AppColors.borderDark.withValues(alpha: 0.4) : AppColors.borderLight;
    final borderSelected = primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? surfaceSelected : surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: selected ? borderSelected : borderColor,
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
                product.amount > 0 ? '₦${AppConstants.formatNgn(product.amount.round())}' : 'Custom',
                style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
