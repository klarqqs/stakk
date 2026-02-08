import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/api/api_client.dart' show ApiException, WalletBalance;
import 'package:stakk_savings/features/bills/domain/models/bill_models.dart';
import 'package:stakk_savings/features/bills/presentation/screens/bills_providers_screen.dart';
import 'package:stakk_savings/providers/auth_provider.dart';

class BillsCategoriesScreen extends StatefulWidget {
  const BillsCategoriesScreen({super.key});

  @override
  State<BillsCategoriesScreen> createState() => _BillsCategoriesScreenState();
}

class _BillsCategoriesScreenState extends State<BillsCategoriesScreen> {
  List<BillCategoryModel> _categories = [];
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
        auth.getBillTopCategories(),
        auth.getBalance(),
      ]);
      if (mounted) {
        setState(() {
          _categories = results[0] as List<BillCategoryModel>;
          _balance = results[1] as WalletBalance;
          _loading = false;
        });
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
          _error = 'Failed to load';
          _loading = false;
        });
      }
    }
  }

  IconData _categoryIcon(BillCategoryModel c) {
    final code = c.code.toUpperCase();
    if (code.contains('AIRTIME')) return Icons.phone_android;
    if (code.contains('MOBILEDATA') || code.contains('DATA')) return Icons.data_usage;
    if (code.contains('CABLE') || code.contains('TV')) return Icons.tv;
    if (code.contains('UTILITY') || code.contains('ELECTRIC')) return Icons.bolt;
    if (code.contains('BET') || code.contains('BETTING')) return Icons.sports_esports;
    return Icons.receipt_long;
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bills',
                        style: AppTheme.header(context: context, fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pay airtime, data, DSTV, electricity with USDC',
                        style: AppTheme.body(fontSize: 14, color: const Color(0xFF6B7280)),
                      ),
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
                              TextButton(onPressed: _load, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      ],
                      if (_error == null) ...[
                        const SizedBox(height: 24),
                        if (_categories.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'No bill categories available',
                              textAlign: TextAlign.center,
                              style: AppTheme.body(fontSize: 14, color: const Color(0xFF9CA3AF)),
                            ),
                          )
                        else
                          ..._categories.map((c) => _CategoryTile(
                                category: c,
                                icon: _categoryIcon(c),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (ctx) => BillsProvidersScreen(
                                      category: c,
                                      balance: _balance?.usdc ?? 0,
                                      onSuccess: () => _load(),
                                    ),
                                  ),
                                ),
                              )),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final BillCategoryModel category;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.icon,
    required this.onTap,
  });

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
                child: Icon(icon, color: const Color(0xFF4F46E5), size: 24),
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
                    if (category.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        category.description,
                        style: AppTheme.body(fontSize: 13, color: const Color(0xFF6B7280)),
                      ),
                    ],
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
