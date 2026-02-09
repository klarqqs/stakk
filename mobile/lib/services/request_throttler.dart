import 'dart:async';

/// Request throttler to prevent simultaneous API calls and rate limiting.
/// Spaces out requests to avoid hitting rate limits.
class RequestThrottler {
  static final RequestThrottler _instance = RequestThrottler._internal();
  factory RequestThrottler() => _instance;
  RequestThrottler._internal();

  final Map<String, DateTime> _lastRequestTime = {};
  final Map<String, Completer<void>> _pendingRequests = {};
  
  /// Minimum delay between requests of the same type (milliseconds)
  static const int _minDelayMs = 100; // 100ms between same-type requests
  
  /// Minimum delay between any requests (prevents bursts)
  static const int _globalDelayMs = 50; // 50ms between any requests
  
  DateTime? _lastGlobalRequest;

  /// Throttle a request - ensures minimum delay between requests
  /// Returns a Future that resolves when it's safe to make the request
  Future<void> throttle(String requestType) async {
    final now = DateTime.now();
    
    // Check global throttle (prevent any request bursts)
    if (_lastGlobalRequest != null) {
      final globalElapsed = now.difference(_lastGlobalRequest!);
      if (globalElapsed.inMilliseconds < _globalDelayMs) {
        await Future.delayed(Duration(milliseconds: _globalDelayMs - globalElapsed.inMilliseconds));
      }
    }
    
    // Check type-specific throttle
    if (_lastRequestTime.containsKey(requestType)) {
      final lastTime = _lastRequestTime[requestType]!;
      final elapsed = now.difference(lastTime);
      
      if (elapsed.inMilliseconds < _minDelayMs) {
        // Wait for minimum delay
        await Future.delayed(Duration(milliseconds: _minDelayMs - elapsed.inMilliseconds));
      }
    }
    
    // If there's a pending request of the same type, wait for it
    if (_pendingRequests.containsKey(requestType)) {
      await _pendingRequests[requestType]!.future;
    }
    
    // Update timestamps
    _lastRequestTime[requestType] = DateTime.now();
    _lastGlobalRequest = DateTime.now();
    
    // Create completer for this request
    final completer = Completer<void>();
    _pendingRequests[requestType] = completer;
    
    // Complete after a short delay to allow next request
    Future.delayed(const Duration(milliseconds: _minDelayMs), () {
      _pendingRequests.remove(requestType);
      completer.complete();
    });
  }

  /// Execute a throttled request
  Future<T> execute<T>(String requestType, Future<T> Function() request) async {
    await throttle(requestType);
    return await request();
  }
}
