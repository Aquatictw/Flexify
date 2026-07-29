import 'dart:io';

class ServerConfig {
  final String apiKey;
  final String openRouterApiKey;
  final String chatModel;
  final int port;
  final String dataDir;
  final String knowledgeDir;
  final DateTime startTime;

  ServerConfig._({
    required this.apiKey,
    required this.openRouterApiKey,
    required this.chatModel,
    required this.port,
    required this.dataDir,
    required this.knowledgeDir,
    required this.startTime,
  });

  factory ServerConfig.fromEnvironment() {
    final apiKey = Platform.environment['JACKED_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('JACKED_API_KEY environment variable is required');
    }

    final openRouterApiKey = Platform.environment['OPENROUTER_API_KEY'];
    if (openRouterApiKey == null || openRouterApiKey.isEmpty) {
      throw Exception('OPENROUTER_API_KEY environment variable is required');
    }

    // The one env var that swaps the chat model — no code change needed.
    final chatModel = Platform.environment['CHAT_MODEL'];
    if (chatModel == null || chatModel.isEmpty) {
      throw Exception('CHAT_MODEL environment variable is required');
    }

    final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
    final dataDir = Platform.environment['DATA_DIR'] ?? '/data';
    final knowledgeDir =
        Platform.environment['KNOWLEDGE_DIR'] ?? '/data/knowledge';

    return ServerConfig._(
      apiKey: apiKey,
      openRouterApiKey: openRouterApiKey,
      chatModel: chatModel,
      port: port,
      dataDir: dataDir,
      knowledgeDir: knowledgeDir,
      startTime: DateTime.now(),
    );
  }
}
