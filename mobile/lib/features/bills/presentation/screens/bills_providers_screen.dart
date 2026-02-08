import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/api/api_client.dart';
import 'package:stakk_savings/features/bills/domain/models/bill_models.dart';
import 'package:stakk_savings/features/bills/presentation/widgets/bills_pay_sheet.dart';
import 'package:stakk_savings/providers/auth_provider.dart';

class BillsProvidersScreen extends StatefulWidget {
  final BillCategoryModel category;
  final double balance;
  final VoidCallback onSuccess;

  const BillsProvidersScreen({
    super.key,
    required this.category,
    required this.balance,
    required this.onSuccess,
  });

  @override
  State<BillsProvidersScreen> createState() => _BillsProvidersScreenState();
}

class _BillsProvidersScreenState extends State<BillsProvidersScreen> {
  List<BillProviderModel> _providers = [];
  bool _loading = true;
  String? _error;

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
      final providers = await context.read<AuthProvider>().getBillProviders(widget.category.code);
      if (mounted) {
        setState(() {
          _providers = providers;
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
          _error = 'Failed to load providers';
          _loading = false;
        });
      }
    }
  }

  void _openPaySheet(BillProviderModel provider) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => BillsPaySheet(
        category: widget.category,
        provider: provider,
        balance: widget.balance,
        onClose: () => Navigator.of(ctx).pop(),
        onSuccess: () {
          Navigator.of(ctx).pop();
          widget.onSuccess();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category.name,
          style: AppTheme.header(context: context, fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
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
                        'Select provider',
                        style: AppTheme.header(context: context, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose your service provider',
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
                              Expanded(child: Text(_error!, style: AppTheme.body(fontSize: 14, color: const Color(0xFFDC2626)))),
                              TextButton(onPressed: _load, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      ],
                      if (_error == null) ...[
                        const SizedBox(height: 24),
                        if (_providers.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'No providers available',
                              textAlign: TextAlign.center,
                              style: AppTheme.body(fontSize: 14, color: const Color(0xFF9CA3AF)),
                            ),
                          )
                        else
                          ..._providers.map((p) => _ProviderTile(
                                provider: p,
                                onTap: () => _openPaySheet(p),
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

class _ProviderTile extends StatelessWidget {
  final BillProviderModel provider;
  final VoidCallback onTap;

  const _ProviderTile({required this.provider, required this.onTap});

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
                child: Icon(Icons.business, color: const Color(0xFF4F46E5), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  provider.name,
                  style: AppTheme.header(context: context, fontSize: 16, fontWeight: FontWeight.w600),
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
