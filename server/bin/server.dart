import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import 'package:jackedlog_server/config.dart';
import 'package:jackedlog_server/middleware/auth.dart';
import 'package:jackedlog_server/middleware/cors.dart';
import 'package:jackedlog_server/api/health_api.dart';
import 'package:jackedlog_server/api/backup_api.dart';
import 'package:jackedlog_server/api/chat_api.dart';
import 'package:jackedlog_server/api/manage_page.dart';
import 'package:jackedlog_server/api/dashboard_pages.dart';
import 'package:jackedlog_server/api/update_api.dart';
import 'package:jackedlog_server/services/backup_service.dart';
import 'package:jackedlog_server/services/dashboard_service.dart';
import 'package:jackedlog_server/services/knowledge_service.dart';
import 'package:jackedlog_server/version.dart';

void main() async {
  final config = ServerConfig.fromEnvironment();

  // Ensure data directory exists
  Directory(config.dataDir).createSync(recursive: true);

  // Initialize health API with server start time
  initHealthApi(config.startTime);

  // Initialize services
  final backupService = BackupService(config.dataDir);
  final dashboardService = DashboardService(config.dataDir);
  // Loaded once at boot: a missing/empty knowledge doc must fail startup, not
  // silently ship an empty system prompt.
  final knowledgeService = KnowledgeService.load(config.knowledgeDir);

  // Configure routes
  final router = Router();
  router.get('/api/health', healthHandler);
  router.post('/api/chat', (req) => chatHandler(req, config, knowledgeService));
  router.post('/api/backup', (req) => uploadBackupHandler(req, backupService));
  router.get('/api/backups', (req) => listBackupsHandler(req, backupService));
  router.get(
      '/api/backup/<filename>',
      (req, String filename) =>
          downloadBackupHandler(req, filename, backupService));
  router.delete(
      '/api/backup/<filename>',
      (req, String filename) =>
          deleteBackupHandler(req, filename, backupService));
  router.get(
      '/manage', (req) => managePageHandler(req, backupService, config.apiKey));
  router.get(
      '/dashboard',
      (req) => overviewPageHandler(
          req, dashboardService, backupService, config.apiKey));
  router.get(
      '/dashboard/exercises',
      (req) => exercisesPageHandler(
          req, dashboardService, backupService, config.apiKey));
  router.get(
      '/dashboard/exercise/<name>',
      (req, String name) => exerciseDetailHandler(
          req, name, dashboardService, backupService, config.apiKey));
  router.get(
      '/dashboard/history',
      (req) => historyPageHandler(
          req, dashboardService, backupService, config.apiKey));
  router.get(
      '/dashboard/workout/<id>',
      (req, String id) => workoutDetailHandler(
          req, id, dashboardService, backupService, config.apiKey));
  router.get(
      '/dashboard/blocks',
      (req) => blockHistoryPageHandler(
          req, dashboardService, backupService, config.apiKey));
  router.get(
      '/dashboard/bodyweight',
      (req) => bodyweightPageHandler(
          req, dashboardService, backupService, config.apiKey));
  router.get('/api/update/check', updateCheckHandler);
  router.post('/api/update/apply', updateApplyHandler);

  // Build middleware pipeline
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsMiddleware())
      .addMiddleware(authMiddleware(config.apiKey))
      .addHandler(router.call);

  // Start server
  final server = await io.serve(handler, '0.0.0.0', config.port);
  print('JackedLog Server v$serverVersion');
  print('Listening on port ${server.port}');
  print('Data directory: ${config.dataDir}');
  print('Chat model: ${config.chatModel}');
  print('Knowledge directory: ${config.knowledgeDir}');
  print('Knowledge prompt: ${knowledgeService.promptLength} chars');
}
