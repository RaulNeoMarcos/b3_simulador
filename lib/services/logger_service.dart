// lib/services/logger_service.dart

import 'package:intl/intl.dart';

enum LogLevel {
  debug(0),
  info(1),
  warning(2),
  error(3);

  final int value;
  const LogLevel(this.value);
}

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  bool _isDebugMode = true;
  final List<LogEntry> _history = [];
  static const int MAX_HISTORY = 1000;

  void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.debug, message, tag: tag, data: data);
  }

  void info(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.info, message, tag: tag, data: data);
  }

  void warning(
    String message, {
    String? tag,
    dynamic error, // 👈 ADICIONE ESTE PARÂMETRO
    StackTrace? stackTrace, // 👈 ADICIONE ESTE PARÂMETRO
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.warning,
      message,
      tag: tag,
      error: error, // 👈 PASSE O ERRO
      stackTrace: stackTrace, // 👈 PASSE O STACKTRACE
      data: data,
    );
  }

  void error(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  void _log(
    LogLevel level,
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    if (!_isDebugMode && level == LogLevel.debug) return;

    final timestamp = DateTime.now();
    final logEntry = LogEntry(
      timestamp: timestamp,
      level: level,
      tag: tag ?? 'APP',
      message: message,
      error: error?.toString(),
      stackTrace: stackTrace?.toString(),
      data: data,
    );

    // Adiciona ao histórico
    _history.add(logEntry);
    if (_history.length > MAX_HISTORY) {
      _history.removeAt(0);
    }

    // Formata a mensagem para console
    final emoji = _getEmoji(level);
    final timeStr = DateFormat('HH:mm:ss.SSS').format(timestamp);
    final tagStr = tag != null ? ' [$tag]' : '';

    if (error != null || stackTrace != null) {
      print('$emoji $timeStr$tagStr $message');
      if (error != null) print('   ⚠️ Erro: $error');
      if (stackTrace != null) print('   📚 Stack: $stackTrace');
    } else {
      print('$emoji $timeStr$tagStr $message');
    }

    if (data != null) {
      print('   📊 Dados: $data');
    }
  }

  String _getEmoji(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }

  List<LogEntry> getHistory({
    LogLevel? minLevel,
    String? tag,
    DateTime? from,
    DateTime? to,
  }) {
    return _history.where((entry) {
      if (minLevel != null && entry.level.value < minLevel.value) return false;
      if (tag != null && entry.tag != tag) return false;
      if (from != null && entry.timestamp.isBefore(from)) return false;
      if (to != null && entry.timestamp.isAfter(to)) return false;
      return true;
    }).toList();
  }

  void clearHistory() => _history.clear();

  void setDebugMode(bool enabled) => _isDebugMode = enabled;

  String exportLogs() {
    // Implementar exportação para arquivo
    final buffer = StringBuffer();
    for (var entry in _history) {
      buffer.writeln(entry.toString());
    }
    return buffer.toString();
  }
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final String? error;
  final String? stackTrace;
  final Map<String, dynamic>? data;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
    this.data,
  });

  @override
  String toString() {
    final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(timestamp);
    return '[$timeStr][${level.name}][$tag] $message${error != null ? '\nError: $error' : ''}';
  }
}
