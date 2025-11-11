import 'package:flutter/foundation.dart';

class ErrorLogger {
  static final ErrorLogger _instance = ErrorLogger._internal();
  factory ErrorLogger() => _instance;
  ErrorLogger._internal();

  final List<ErrorLog> _errorLogs = [];
  static const int maxLogs = 20;

  void logError(dynamic error, StackTrace? stack, {String? context}) {
    final log = ErrorLog(
      timestamp: DateTime.now(),
      error: error.toString(),
      stackTrace: stack?.toString() ?? 'No stack trace',
      context: context,
    );

    _errorLogs.insert(0, log);

    // Keep only the most recent errors
    if (_errorLogs.length > maxLogs) {
      _errorLogs.removeRange(maxLogs, _errorLogs.length);
    }

    debugPrint('🔴 Error logged: $error');
  }

  List<ErrorLog> getRecentErrors() => List.unmodifiable(_errorLogs);

  String getFormattedErrors() {
    if (_errorLogs.isEmpty) {
      return 'No errors logged in this session.';
    }

    final buffer = StringBuffer();
    buffer.writeln('=== Recent Errors (${_errorLogs.length}) ===\n');

    for (var i = 0; i < _errorLogs.length; i++) {
      final log = _errorLogs[i];
      buffer.writeln('--- Error ${i + 1} ---');
      buffer.writeln('Time: ${log.timestamp}');
      if (log.context != null) {
        buffer.writeln('Context: ${log.context}');
      }
      buffer.writeln('Error: ${log.error}');
      buffer.writeln('Stack trace:');
      buffer.writeln(log.stackTrace);
      buffer.writeln();
    }

    return buffer.toString();
  }

  void clear() {
    _errorLogs.clear();
  }
}

class ErrorLog {
  final DateTime timestamp;
  final String error;
  final String stackTrace;
  final String? context;

  ErrorLog({
    required this.timestamp,
    required this.error,
    required this.stackTrace,
    this.context,
  });
}
