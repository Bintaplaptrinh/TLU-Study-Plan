import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tlustudy_planner/services/log_service.dart';
import 'package:tlustudy_planner/i18n/tr_text.dart';
import 'package:tlustudy_planner/widgets/app_snackbar.dart';
import 'package:tlustudy_planner/services/auth_service.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final _logService = LogService();
  bool _autoScroll = true;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_autoScroll && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = _logService.getAllLogs();

    // Auto-scroll after build
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        title: const TrText('System Logs'),
        actions: [
          // Auto-scroll toggle
          IconButton(
            icon: Icon(
              _autoScroll
                  ? Icons.arrow_downward
                  : Icons.arrow_downward_outlined,
            ),
            tooltip: _autoScroll ? 'Auto-scroll ON' : 'Auto-scroll OFF',
            onPressed: () {
              setState(() {
                _autoScroll = !_autoScroll;
              });
            },
          ),
          // Copy logs
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy logs',
            onPressed: () {
              final logsText = _logService.exportLogs();
              Clipboard.setData(ClipboardData(text: logsText));
              showAppSnackBar(
                context,
                'Logs copied to clipboard',
                tone: SnackTone.success,
                duration: const Duration(seconds: 2),
              );
            },
          ),
          // Clear logs
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear logs',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const TrText('Clear logs?'),
                  content: const TrText('This will delete all log entries.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const TrText('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        _logService.clearLogs();
                        // Re-arm the detailed API probing so the next visit to
                        // Tiện ích reports every endpoint it tries again.
                        AuthService.resetProbeLogging();
                        setState(() {});
                        Navigator.pop(context);
                      },
                      child: const TrText('Clear'),
                    ),
                  ],
                ),
              );
            },
          ),
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: logs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  TrText(
                    'No logs yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Log count
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      TrText(
                        '${logs.length} log entries (max 500)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Logs list
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return _buildLogEntry(context, log);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLogEntry(BuildContext context, LogEntry log) {
    final color = _getLogColor(context, log.level);
    final timestamp =
        '${log.timestamp.hour.toString().padLeft(2, '0')}:'
        '${log.timestamp.minute.toString().padLeft(2, '0')}:'
        '${log.timestamp.second.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(_getLogIcon(log.level), size: 20, color: color),
        title: TrText(
          log.message,
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: TrText(
          timestamp,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  IconData _getLogIcon(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Icons.bug_report;
      case LogLevel.info:
        return Icons.info_outline;
      case LogLevel.warning:
        return Icons.warning_amber;
      case LogLevel.error:
        return Icons.error_outline;
      case LogLevel.success:
        return Icons.check_circle_outline;
    }
  }

  Color _getLogColor(BuildContext context, LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.success:
        return Colors.green;
    }
  }
}
