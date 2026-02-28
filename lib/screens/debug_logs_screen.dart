// lib/screens/debug_logs_screen.dart

import 'package:flutter/material.dart';
import 'package:b3_simulador/services/logger_service.dart';
import 'package:intl/intl.dart';

class DebugLogsScreen extends StatefulWidget {
  const DebugLogsScreen({Key? key}) : super(key: key);

  @override
  State<DebugLogsScreen> createState() => _DebugLogsScreenState();
}

class _DebugLogsScreenState extends State<DebugLogsScreen> {
  final LoggerService _logger = LoggerService();
  List<LogEntry> _logs = [];
  LogLevel? _filterLevel;
  String _searchTerm = '';
  bool _autoRefresh = true;

  @override
  void initState() {
    super.initState();
    _refreshLogs();
  }

  void _refreshLogs() {
    setState(() {
      _logs = _logger.getHistory(minLevel: _filterLevel);
      if (_searchTerm.isNotEmpty) {
        _logs = _logs
            .where(
              (log) =>
                  log.message.toLowerCase().contains(
                    _searchTerm.toLowerCase(),
                  ) ||
                  (log.error?.toLowerCase().contains(
                        _searchTerm.toLowerCase(),
                      ) ??
                      false),
            )
            .toList();
      }
    });
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Logs'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshLogs),
          IconButton(
            icon: Icon(_autoRefresh ? Icons.play_arrow : Icons.pause),
            onPressed: () {
              setState(() => _autoRefresh = !_autoRefresh);
            },
          ),
          PopupMenuButton<LogLevel?>(
            onSelected: (level) {
              setState(() {
                _filterLevel = level;
                _refreshLogs();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('Todos')),
              const PopupMenuItem(value: LogLevel.debug, child: Text('Debug')),
              const PopupMenuItem(value: LogLevel.info, child: Text('Info')),
              const PopupMenuItem(
                value: LogLevel.warning,
                child: Text('Warning'),
              ),
              const PopupMenuItem(value: LogLevel.error, child: Text('Error')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar nos logs...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                _searchTerm = value;
                _refreshLogs();
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      radius: 12,
                      backgroundColor: _getLevelColor(log.level),
                      child: Text(
                        log.level.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      log.message,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${DateFormat('dd/MM HH:mm:ss').format(log.timestamp)} • ${log.tag}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    children: [
                      if (log.error != null)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Erro:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                Text(log.error!),
                              ],
                            ),
                          ),
                        ),
                      if (log.stackTrace != null)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Stack Trace:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  log.stackTrace!,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (log.data != null)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dados:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                ...log.data!.entries
                                    .map((e) => Text('${e.key}: ${e.value}'))
                                    .toList(),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.clear_all),
        onPressed: () {
          _logger.clearHistory();
          _refreshLogs();
        },
      ),
    );
  }
}
