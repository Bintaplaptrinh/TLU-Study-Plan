import 'dart:collection';

/// Service for capturing and displaying app logs
class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  // Store last 500 logs in memory
  final _logs = Queue<LogEntry>();
  static const int _maxLogs = 500;

  /// Add a log entry
  void log(String message, {LogLevel level = LogLevel.info}) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      message: message,
      level: level,
    );
    
    _logs.add(entry);
    
    // Keep only last 500 logs
    if (_logs.length > _maxLogs) {
      _logs.removeFirst();
    }
    
    // Still print to console for debugging
    print(_formatLogEntry(entry));
  }

  /// Get all logs
  List<LogEntry> getAllLogs() => _logs.toList();

  /// Clear all logs
  void clearLogs() {
    _logs.clear();
    log('Logs cleared', level: LogLevel.info);
  }

  /// Format log entry for display
  String _formatLogEntry(LogEntry entry) {
    final icon = _getLogIcon(entry.level);
    final timestamp = '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
        '${entry.timestamp.minute.toString().padLeft(2, '0')}:'
        '${entry.timestamp.second.toString().padLeft(2, '0')}';
    return '$icon [$timestamp] ${entry.message}';
  }

  String _getLogIcon(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.success:
        return '✅';
    }
  }

  /// Export logs as text
  String exportLogs() {
    final buffer = StringBuffer();
    buffer.writeln('=== TLU Study Planner Logs ===');
    buffer.writeln('Exported: ${DateTime.now()}');
    buffer.writeln('Total entries: ${_logs.length}');
    buffer.writeln('=' * 40);
    buffer.writeln();
    
    for (final entry in _logs) {
      buffer.writeln(_formatLogEntry(entry));
    }
    
    return buffer.toString();
  }
}

/// Log entry data class
class LogEntry {
  final DateTime timestamp;
  final String message;
  final LogLevel level;

  LogEntry({
    required this.timestamp,
    required this.message,
    required this.level,
  });
}

/// Log levels
enum LogLevel {
  debug,
  info,
  warning,
  error,
  success,
}
