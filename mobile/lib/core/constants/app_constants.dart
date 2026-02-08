/// App-wide constants (matches backend where applicable)
class AppConstants {
  AppConstants._();

  /// NGN to USD rate for USDC display (matches backend NGN_USD_RATE)
  static const double ngnUsdRate = 1580;

  /// Format integer as NGN with commas (e.g. 15800 → "15,800")
  static String formatNgn(int n) =>
      n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}
