import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache service for storing API responses locally to improve UX
/// Shows cached data immediately while fresh data loads in background
class CacheService {
  static const String _prefix = 'stakk_cache_';
  static const String _timestampPrefix = 'stakk_cache_ts_';
  
  // Cache TTL (Time To Live) in seconds
  static const int _balanceTtl = 30; // 30 seconds - balance changes frequently
  static const int _transactionsTtl = 60; // 1 minute
  static const int _billsTtl = 300; // 5 minutes - bills categories don't change often
  static const int _goalsTtl = 120; // 2 minutes
  static const int _locksTtl = 120; // 2 minutes
  static const int _p2pHistoryTtl = 60; // 1 minute
  static const int _notificationsTtl = 30; // 30 seconds
  static const int _blendEarningsTtl = 60; // 1 minute
  static const int _blendApyTtl = 300; // 5 minutes - APY doesn't change often
  
  /// Cache keys
  static const String _keyBalance = 'balance';
  static const String _keyTransactions = 'transactions';
  static const String _keyBillCategories = 'bill_categories';
  static const String _keyBillProviders = 'bill_providers';
  static const String _keyGoals = 'goals';
  static const String _keyLocks = 'locks';
  static const String _keyP2pHistory = 'p2p_history';
  static const String _keyNotifications = 'notifications';
  static const String _keyBlendEarnings = 'blend_earnings';
  static const String _keyBlendApy = 'blend_apy';
  
  /// Get TTL for a cache key
  static int _getTtl(String key) {
    switch (key) {
      case _keyBalance:
        return _balanceTtl;
      case _keyTransactions:
        return _transactionsTtl;
      case _keyBillCategories:
      case _keyBillProviders:
        return _billsTtl;
      case _keyGoals:
        return _goalsTtl;
      case _keyLocks:
        return _locksTtl;
      case _keyP2pHistory:
        return _p2pHistoryTtl;
      case _keyNotifications:
        return _notificationsTtl;
      case _keyBlendEarnings:
        return _blendEarningsTtl;
      case _keyBlendApy:
        return _blendApyTtl;
      default:
        return 60; // Default 1 minute
    }
  }
  
  /// Check if cached data is still valid
  Future<bool> _isValid(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final timestampKey = _timestampPrefix + key;
    final timestamp = prefs.getInt(timestampKey);
    
    if (timestamp == null) return false;
    
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final ttl = _getTtl(key);
    return (now - timestamp) < ttl;
  }
  
  /// Save data to cache
  Future<void> set(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _prefix + key;
      final timestampKey = _timestampPrefix + key;
      
      final jsonString = jsonEncode(data);
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      await prefs.setString(cacheKey, jsonString);
      await prefs.setInt(timestampKey, timestamp);
    } catch (e) {
      // Silently fail - caching is not critical
      print('CacheService: Failed to cache $key: $e');
    }
  }
  
  /// Get cached data if valid, otherwise return null
  Future<T?> get<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    try {
      if (!await _isValid(key)) {
        return null;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _prefix + key;
      final jsonString = prefs.getString(cacheKey);
      
      if (jsonString == null) return null;
      
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return fromJson(json);
    } catch (e) {
      print('CacheService: Failed to get cached $key: $e');
      return null;
    }
  }
  
  /// Get cached list data if valid, otherwise return null
  Future<List<T>?> getList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      if (!await _isValid(key)) {
        return null;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _prefix + key;
      final jsonString = prefs.getString(cacheKey);
      
      if (jsonString == null) return null;
      
      final json = jsonDecode(jsonString);
      if (json is List) {
        return json.map((item) => fromJson(item as Map<String, dynamic>)).toList();
      }
      return null;
    } catch (e) {
      print('CacheService: Failed to get cached list $key: $e');
      return null;
    }
  }
  
  /// Get cached int if valid, otherwise return null
  Future<int?> getInt(String key) async {
    try {
      if (!await _isValid(key)) {
        return null;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _prefix + key;
      final jsonString = prefs.getString(cacheKey);
      
      if (jsonString == null) return null;
      
      return int.tryParse(jsonString);
    } catch (e) {
      print('CacheService: Failed to get cached int $key: $e');
      return null;
    }
  }
  
  /// Clear specific cache entry
  Future<void> clear(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _prefix + key;
      final timestampKey = _timestampPrefix + key;
      
      await prefs.remove(cacheKey);
      await prefs.remove(timestampKey);
    } catch (e) {
      print('CacheService: Failed to clear $key: $e');
    }
  }
  
  /// Clear all cache
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_prefix) || key.startsWith(_timestampPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('CacheService: Failed to clear all cache: $e');
    }
  }
  
  // Convenience methods for specific data types
  
  Future<void> setBalance(Map<String, dynamic> data) => set(_keyBalance, data);
  Future<Map<String, dynamic>?> getBalance() => get(_keyBalance, (json) => json);
  
  Future<void> setTransactions(List<Map<String, dynamic>> data) => set(_keyTransactions, data);
  Future<List<Map<String, dynamic>>?> getTransactions() => getList(_keyTransactions, (json) => json);
  
  Future<void> setBillCategories(List<Map<String, dynamic>> data) => set(_keyBillCategories, data);
  Future<List<Map<String, dynamic>>?> getBillCategories() => getList(_keyBillCategories, (json) => json);
  
  Future<void> setBillProviders(String categoryCode, List<Map<String, dynamic>> data) {
    return set('${_keyBillProviders}_$categoryCode', data);
  }
  Future<List<Map<String, dynamic>>?> getBillProviders(String categoryCode) {
    return getList('${_keyBillProviders}_$categoryCode', (json) => json);
  }
  
  Future<void> setGoals(List<Map<String, dynamic>> data) => set(_keyGoals, data);
  Future<List<Map<String, dynamic>>?> getGoals() => getList(_keyGoals, (json) => json);
  
  Future<void> setLocks(List<Map<String, dynamic>> data) => set(_keyLocks, data);
  Future<List<Map<String, dynamic>>?> getLocks() => getList(_keyLocks, (json) => json);
  
  Future<void> setP2pHistory(List<Map<String, dynamic>> data) => set(_keyP2pHistory, data);
  Future<List<Map<String, dynamic>>?> getP2pHistory() => getList(_keyP2pHistory, (json) => json);
  
  Future<void> setNotifications(int count) => set(_keyNotifications, count.toString());
  Future<int?> getNotifications() => getInt(_keyNotifications);
  
  Future<void> setBlendEarnings(Map<String, dynamic> data) => set(_keyBlendEarnings, data);
  Future<Map<String, dynamic>?> getBlendEarnings() => get(_keyBlendEarnings, (json) => json);
  
  Future<void> setBlendApy(Map<String, dynamic> data) => set(_keyBlendApy, data);
  Future<Map<String, dynamic>?> getBlendApy() => get(_keyBlendApy, (json) => json);
}
