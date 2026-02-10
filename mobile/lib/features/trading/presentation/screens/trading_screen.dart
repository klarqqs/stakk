import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:stakk_savings/api/api_client.dart';
import 'package:stakk_savings/core/components/error_dialog.dart';
import 'package:stakk_savings/core/components/buttons/primary_button.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/core/utils/snackbar_utils.dart';
import 'package:stakk_savings/features/trading/domain/models/stock_models.dart';

class TradingScreen extends StatefulWidget {
  const TradingScreen({super.key});

  @override
  State<TradingScreen> createState() => _TradingScreenState();
}

class _TradingScreenState extends State<TradingScreen> {
  final _apiClient = ApiClient();
  final _searchController = TextEditingController();
  
  List<Stock> _allStocks = [];
  List<Stock> _filteredStocks = [];
  StockPortfolio? _portfolio;
  Stock? _selectedStock;
  String _buyAmount = '';
  bool _loadingStocks = true;
  bool _loadingPortfolio = true;
  bool _buying = false;

  static const _popularTickers = ['AAPL', 'TSLA', 'NVDA', 'GOOGL', 'MSFT', 'AMZN'];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredStocks = _allStocks;
      } else {
        _filteredStocks = _allStocks.where((stock) {
          return stock.symbol.toLowerCase().contains(query) ||
              stock.name.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadStocks(),
      _loadPortfolio(),
    ]);
  }

  Future<void> _loadStocks() async {
    try {
      setState(() => _loadingStocks = true);
      final stocks = await _apiClient.stocksGetAvailable();
      setState(() {
        _allStocks = stocks;
        _filteredStocks = stocks;
        _loadingStocks = false;
      });
    } catch (e) {
      setState(() => _loadingStocks = false);
      if (mounted) {
        ErrorDialog.show(context, message: 'Failed to load stocks: ${e.toString()}');
      }
    }
  }

  Future<void> _loadPortfolio() async {
    try {
      setState(() => _loadingPortfolio = true);
      final portfolio = await _apiClient.stocksGetPortfolio();
      setState(() {
        _portfolio = portfolio;
        _loadingPortfolio = false;
      });
    } catch (e) {
      setState(() => _loadingPortfolio = false);
      // Portfolio might be empty, don't show error
    }
  }

  Future<void> _buyStock() async {
    if (_selectedStock == null || _buyAmount.isEmpty) return;

    final amount = double.tryParse(_buyAmount);
    if (amount == null || amount <= 0) {
      TopSnackbar.error(context, 'Please enter a valid amount');
      return;
    }

    try {
      setState(() => _buying = true);
      await _apiClient.stocksBuy(
        ticker: _selectedStock!.symbol,
        amountUSD: amount,
      );

      if (mounted) {
        TopSnackbar.success(context, '✅ Successfully bought \$${amount.toStringAsFixed(2)} of ${_selectedStock!.symbol}!');
        Navigator.pop(context); // Close buy modal
        _selectedStock = null;
        _buyAmount = '';
        await _loadPortfolio();
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, message: 'Failed to buy stock: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _buying = false);
      }
    }
  }

  List<Stock> get _popularStocks {
    return _allStocks.where((s) => _popularTickers.contains(s.symbol)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildTradingContent(),
        if (_selectedStock != null) _buildBuyModal(),
      ],
    );
  }

  Widget _buildTradingContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.cardSurfaceDark : AppColors.cardSurfaceLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📈 Trade Stocks'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // Portfolio Summary
            if (_loadingPortfolio)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_portfolio != null && _portfolio!.totalValue > 0)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primaryDark,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Portfolio Value',
                        style: AppTheme.caption(
                          context: context,
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${_portfolio!.totalValue.toStringAsFixed(2)}',
                        style: AppTheme.title(
                          context: context,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.chartLine,
                            size: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_portfolio!.holdings.length} stocks owned',
                            style: AppTheme.caption(
                              context: context,
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // Your Holdings Section
            if (_portfolio != null && _portfolio!.holdings.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        '📊 Your Holdings',
                        style: AppTheme.title(
                          context: context,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

            if (_portfolio != null && _portfolio!.holdings.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final holding = _portfolio!.holdings[index];
                    final pnl = holding.totalValue - (holding.shares * holding.avgBuyPrice);
                    final pnlPercent = holding.avgBuyPrice > 0
                        ? ((holding.currentPrice - holding.avgBuyPrice) / holding.avgBuyPrice) * 100
                        : 0.0;
                    final isPositive = pnl >= 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Stock Symbol
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Center(
                              child: Text(
                                holding.symbol,
                                style: AppTheme.title(
                                  context: context,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Stock Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  holding.symbol,
                                  style: AppTheme.title(
                                    context: context,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${holding.shares.toStringAsFixed(4)} shares',
                                  style: AppTheme.caption(
                                    context: context,
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Value and P&L
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${holding.totalValue.toStringAsFixed(2)}',
                                style: AppTheme.title(
                                  context: context,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPositive ? Icons.trending_up : Icons.trending_down,
                                    size: 14,
                                    color: isPositive ? Colors.green : Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${isPositive ? '+' : ''}\$${pnl.toStringAsFixed(2)} (${isPositive ? '+' : ''}${pnlPercent.toStringAsFixed(2)}%)',
                                    style: AppTheme.caption(
                                      context: context,
                                      fontSize: 12,
                                      color: isPositive ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: _portfolio!.holdings.length,
                ),
              ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search stocks (e.g., AAPL, Tesla)',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Popular Stocks
            if (!_loadingStocks && _popularStocks.isNotEmpty && _searchController.text.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '🔥 Popular Stocks',
                    style: AppTheme.title(
                      context: context,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            if (!_loadingStocks && _popularStocks.isNotEmpty && _searchController.text.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final stock = _popularStocks[index];
                      return _StockCard(
                        stock: stock,
                        onTap: () => setState(() => _selectedStock = stock),
                      );
                    },
                    childCount: _popularStocks.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // All Stocks List
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _searchController.text.isEmpty
                      ? 'All Available Stocks'
                      : 'Results (${_filteredStocks.length})',
                  style: AppTheme.title(
                    context: context,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            if (_loadingStocks)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_filteredStocks.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    _searchController.text.isEmpty
                        ? 'No stocks available'
                        : 'No stocks found',
                    style: AppTheme.body(context: context),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final stock = _filteredStocks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _StockListItem(
                          stock: stock,
                          onTap: () => setState(() => _selectedStock = stock),
                        ),
                      );
                    },
                    childCount: _filteredStocks.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyModal() {
    return _BuyStockModal(
      stock: _selectedStock!,
      amount: _buyAmount,
      onAmountChanged: (value) => setState(() => _buyAmount = value),
      onBuy: _buyStock,
      onCancel: () => setState(() {
        _selectedStock = null;
        _buyAmount = '';
      }),
      buying: _buying,
    );
  }
}

class _StockCard extends StatelessWidget {
  final Stock stock;
  final VoidCallback onTap;

  const _StockCard({
    required this.stock,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.cardSurfaceDark : AppColors.cardSurfaceLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stock.symbol,
                style: AppTheme.title(
                  context: context,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stock.name,
                style: AppTheme.caption(
                  context: context,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockListItem extends StatelessWidget {
  final Stock stock;
  final VoidCallback onTap;

  const _StockListItem({
    required this.stock,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.cardSurfaceDark : AppColors.cardSurfaceLight;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: Colors.grey.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.symbol,
                      style: AppTheme.title(
                        context: context,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stock.name,
                      style: AppTheme.caption(
                        context: context,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (stock.exchange != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    stock.exchange!,
                    style: AppTheme.caption(
                      context: context,
                      fontSize: 11,
                    ),
                  ),
                ),
              FaIcon(
                FontAwesomeIcons.chevronRight,
                size: 14,
                color: primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuyStockModal extends StatelessWidget {
  final Stock stock;
  final String amount;
  final Function(String) onAmountChanged;
  final VoidCallback onBuy;
  final VoidCallback onCancel;
  final bool buying;

  const _BuyStockModal({
    required this.stock,
    required this.amount,
    required this.onAmountChanged,
    required this.onBuy,
    required this.onCancel,
    required this.buying,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.cardSurfaceDark : AppColors.cardSurfaceLight;

    return Material(
      color: Colors.black54,
      child: InkWell(
        onTap: onCancel,
        child: Container(
          color: Colors.black54,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {}, // Prevent tap from closing
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buy ${stock.symbol}',
                        style: AppTheme.title(
                          context: context,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stock.name,
                        style: AppTheme.body(context: context),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Amount (USDC)',
                        style: AppTheme.caption(
                          context: context,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: '10.00',
                          prefixText: '\$',
                          filled: true,
                          fillColor: isDark
                              ? Colors.grey[900]
                              : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: AppTheme.title(
                          context: context,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        onChanged: onAmountChanged,
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: buying
                            ? 'Processing...'
                            : amount.isEmpty 
                                ? 'Buy ${stock.symbol}'
                                : 'Buy \$$amount ${stock.symbol}',
                        onPressed: buying || amount.isEmpty ? null : onBuy,
                        isLoading: buying,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: buying ? null : onCancel,
                        child: Text(
                          'Cancel',
                          style: AppTheme.body(context: context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
