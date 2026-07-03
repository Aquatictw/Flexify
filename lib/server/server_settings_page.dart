import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../database/database.dart';
import '../main.dart';
import '../settings/settings_state.dart';
import '../theme/tokens.dart';

class ServerSettingsPage extends StatefulWidget {
  const ServerSettingsPage({super.key});

  @override
  State<ServerSettingsPage> createState() => _ServerSettingsPageState();
}

class _ServerSettingsPageState extends State<ServerSettingsPage> {
  final _urlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _urlFocusNode = FocusNode();
  final _apiKeyFocusNode = FocusNode();

  bool _obscureApiKey = true;
  bool _isTesting = false;
  String? _testResult;
  bool? _testSuccess;
  String? _urlError;

  @override
  void initState() {
    super.initState();

    final settings = context.read<SettingsState>().value;
    _urlController.text = settings.serverUrl ?? '';
    _apiKeyController.text = settings.serverApiKey ?? '';

    _urlFocusNode.addListener(_onUrlFocusChange);
    _apiKeyFocusNode.addListener(_onApiKeyFocusChange);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _apiKeyController.dispose();
    _urlFocusNode.removeListener(_onUrlFocusChange);
    _apiKeyFocusNode.removeListener(_onApiKeyFocusChange);
    _urlFocusNode.dispose();
    _apiKeyFocusNode.dispose();
    super.dispose();
  }

  void _onUrlFocusChange() {
    if (!_urlFocusNode.hasFocus) {
      _saveUrl();
    }
  }

  void _onApiKeyFocusChange() {
    if (!_apiKeyFocusNode.hasFocus) {
      _saveApiKey();
    }
  }

  void _saveUrl() {
    var url = _urlController.text.trim();

    if (url.isNotEmpty &&
        !url.startsWith('http://') &&
        !url.startsWith('https://')) {
      setState(() {
        _urlError = 'URL must start with http:// or https://';
      });
      return;
    }

    setState(() {
      _urlError = null;
    });

    // Strip trailing slash
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    _urlController.text = url;

    db.settings.update().write(
          SettingsCompanion(
            serverUrl: Value(url.isEmpty ? null : url),
          ),
        );
  }

  void _saveApiKey() {
    final apiKey = _apiKeyController.text.trim();
    db.settings.update().write(
          SettingsCompanion(
            serverApiKey: Value(apiKey.isEmpty ? null : apiKey),
          ),
        );
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    final apiKey = _apiKeyController.text.trim();

    if (url.isEmpty || apiKey.isEmpty) return;

    setState(() {
      _isTesting = true;
      _testResult = null;
      _testSuccess = null;
    });

    try {
      // Step 1: Check server reachability via health endpoint
      final healthUri = Uri.parse('$url/api/health');
      final healthResponse = await http.get(healthUri).timeout(
            const Duration(seconds: 10),
          );

      if (healthResponse.statusCode != 200) {
        setState(() {
          _testResult = 'Server unreachable (status ${healthResponse.statusCode})';
          _testSuccess = false;
        });
        return;
      }

      // Step 2: Validate API key via authenticated endpoint
      final backupsUri = Uri.parse('$url/api/backups');
      final backupsResponse = await http.get(
        backupsUri,
        headers: {'Authorization': 'Bearer $apiKey'},
      ).timeout(const Duration(seconds: 10));

      if (backupsResponse.statusCode == 401 ||
          backupsResponse.statusCode == 403) {
        setState(() {
          _testResult = 'Invalid API key';
          _testSuccess = false;
        });
        return;
      }

      if (backupsResponse.statusCode == 200) {
        setState(() {
          _testResult = 'Connected successfully';
          _testSuccess = true;
        });
        return;
      }

      setState(() {
        _testResult =
            'Unexpected response (status ${backupsResponse.statusCode})';
        _testSuccess = false;
      });
    } on SocketException catch (e) {
      setState(() {
        _testResult = 'Server unreachable: ${e.message}';
        _testSuccess = false;
      });
    } on TimeoutException {
      setState(() {
        _testResult = 'Connection timed out';
        _testSuccess = false;
      });
    } catch (e) {
      setState(() {
        _testResult = 'Connection failed: $e';
        _testSuccess = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _urlController.text.trim();
    final apiKey = _apiKeyController.text.trim();
    final canTest = url.isNotEmpty && apiKey.isNotEmpty && !_isTesting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Server'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(space16),
        child: ListView(
          children: [
            TextFormField(
              controller: _urlController,
              focusNode: _urlFocusNode,
              decoration: InputDecoration(
                labelText: 'Server URL',
                hintText: 'https://myserver.com',
                errorText: _urlError,
              ),
              keyboardType: TextInputType.url,
              onFieldSubmitted: (_) => _saveUrl(),
            ),
            const SizedBox(height: space16),
            TextFormField(
              controller: _apiKeyController,
              focusNode: _apiKeyFocusNode,
              decoration: InputDecoration(
                labelText: 'API Key',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureApiKey
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureApiKey = !_obscureApiKey;
                    });
                  },
                ),
              ),
              obscureText: _obscureApiKey,
              onFieldSubmitted: (_) => _saveApiKey(),
            ),
            const SizedBox(height: space24),
            FilledButton.tonal(
              onPressed: canTest ? _testConnection : null,
              child: _isTesting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_find),
                        SizedBox(width: space8),
                        Text('Test Connection'),
                      ],
                    ),
            ),
            if (_testResult != null) ...[
              const SizedBox(height: space16),
              Builder(
                builder: (context) {
                  final statusColor = _testSuccess == true
                      ? context.jl.success
                      : context.jl.danger;
                  return Container(
                    padding: const EdgeInsets.all(space12),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: brSm,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _testSuccess == true
                              ? Icons.check_circle
                              : Icons.error,
                          color: statusColor,
                        ),
                        const SizedBox(width: space8),
                        Expanded(
                          child: Text(
                            _testResult!,
                            style: TextStyle(color: statusColor),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
