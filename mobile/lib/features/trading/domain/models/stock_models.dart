/// Stock trading domain models
class Stock {
  final String symbol;
  final String name;
  final String? exchange;
  final String? type;
  final bool available;

  Stock({
    required this.symbol,
    required this.name,
    this.exchange,
    this.type,
    this.available = true,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      symbol: json['symbol'] as String? ?? json['ticker'] as String? ?? '',
      name: json['name'] as String? ?? '',
      exchange: json['exchange'] as String?,
      type: json['type'] as String?,
      available: json['available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'exchange': exchange,
      'type': type,
      'available': available,
    };
  }
}

class StockPrice {
  final String symbol;
  final double price;
  final double? change;
  final double? changePercent;
  final DateTime? timestamp;

  StockPrice({
    required this.symbol,
    required this.price,
    this.change,
    this.changePercent,
    this.timestamp,
  });

  factory StockPrice.fromJson(Map<String, dynamic> json) {
    return StockPrice(
      symbol: json['symbol'] as String? ?? json['ticker'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 
             (json['current_price'] as num?)?.toDouble() ?? 0.0,
      change: (json['change'] as num?)?.toDouble(),
      changePercent: (json['change_percent'] as num?)?.toDouble() ??
                     (json['changePercent'] as num?)?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
    );
  }
}

class StockHolding {
  final String symbol;
  final double shares;
  final double avgBuyPrice;
  final double currentPrice;
  final double totalValue;

  StockHolding({
    required this.symbol,
    required this.shares,
    required this.avgBuyPrice,
    required this.currentPrice,
    required this.totalValue,
  });

  factory StockHolding.fromJson(Map<String, dynamic> json) {
    final shares = (json['shares'] as num?)?.toDouble() ?? 0.0;
    final avgPrice = (json['avg_buy_price'] as num?)?.toDouble() ?? 0.0;
    final currentPrice = (json['current_price'] as num?)?.toDouble() ?? avgPrice;
    final totalValue = shares * currentPrice;

    return StockHolding(
      symbol: json['symbol'] as String? ?? json['ticker'] as String? ?? '',
      shares: shares,
      avgBuyPrice: avgPrice,
      currentPrice: currentPrice,
      totalValue: totalValue,
    );
  }
}

class StockPortfolio {
  final List<StockHolding> holdings;
  final double totalValue;
  final double? totalChange;
  final double? totalChangePercent;

  StockPortfolio({
    required this.holdings,
    required this.totalValue,
    this.totalChange,
    this.totalChangePercent,
  });

  factory StockPortfolio.fromJson(Map<String, dynamic> json) {
    final holdingsList = json['holdings'] as List<dynamic>? ?? [];
    final holdings = holdingsList
        .map((h) => StockHolding.fromJson(h as Map<String, dynamic>))
        .toList();

    return StockPortfolio(
      holdings: holdings,
      totalValue: (json['total_value'] as num?)?.toDouble() ?? 0.0,
      totalChange: (json['total_change'] as num?)?.toDouble(),
      totalChangePercent: (json['total_change_percent'] as num?)?.toDouble(),
    );
  }
}

class StockTrade {
  final String id;
  final String symbol;
  final String side; // 'buy' or 'sell'
  final double amountUSD;
  final double? shares;
  final double? price;
  final double? fee;
  final String status; // 'pending', 'completed', 'failed'
  final DateTime createdAt;
  final DateTime? completedAt;

  StockTrade({
    required this.id,
    required this.symbol,
    required this.side,
    required this.amountUSD,
    this.shares,
    this.price,
    this.fee,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  factory StockTrade.fromJson(Map<String, dynamic> json) {
    return StockTrade(
      id: json['id']?.toString() ?? json['dinari_order_id']?.toString() ?? '',
      symbol: json['symbol'] as String? ?? json['ticker'] as String? ?? '',
      side: json['side'] as String? ?? '',
      amountUSD: (json['amount_usd'] as num?)?.toDouble() ?? 0.0,
      shares: (json['shares'] as num?)?.toDouble(),
      price: (json['price'] as num?)?.toDouble(),
      fee: (json['fee'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
    );
  }
}

class StocksListResponse {
  final List<Stock> stocks;

  StocksListResponse({required this.stocks});

  factory StocksListResponse.fromJson(Map<String, dynamic> json) {
    final stocksList = json['stocks'] as List<dynamic>? ?? [];
    final stocks = stocksList
        .map((s) => Stock.fromJson(s as Map<String, dynamic>))
        .toList();

    return StocksListResponse(stocks: stocks);
  }
}
