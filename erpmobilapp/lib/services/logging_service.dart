import 'package:erpmobilapp/models/log_entry.dart';
import 'package:hive/hive.dart';

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  static const String logsBox = 'logs';
  static List<LogEntry> _logs = [];

  factory LoggingService() {
    return _instance;
  }

  LoggingService._internal();

  static Future<void> initLogging() async {
    // Note: In a real app, register adapter in database_service.dart
    await Hive.openBox<LogEntry>(logsBox);
    _generateSampleLogs(); // Add sample logs for demonstration
  }

  static Future<void> logAction({
    required String userId,
    required String userName,
    required LogAction action,
    required LogEntityType entityType,
    required String entityId,
    required String description,
    Map<String, String>? changes,
  }) async {
    final logEntry = LogEntry(
      id: DateTime.now().millisecondsSinceEpoch,
      timestamp: DateTime.now(),
      userId: userId,
      userName: userName,
      action: action,
      entityType: entityType,
      entityId: entityId,
      description: description,
      changes: changes ?? {},
    );

    _logs.add(logEntry);
    
    // Limit logs to last 1000 entries
    if (_logs.length > 1000) {
      _logs.removeAt(0);
    }
  }

  static List<LogEntry> getLogs() {
    return List.from(_logs.reversed); // Most recent first
  }

  static List<LogEntry> getLogsByUser(String userId) {
    return _logs.where((log) => log.userId == userId).toList().reversed.toList();
  }

  static List<LogEntry> getLogsByEntityType(LogEntityType entityType) {
    return _logs.where((log) => log.entityType == entityType).toList().reversed.toList();
  }

  static List<LogEntry> getLogsByDateRange(DateTime startDate, DateTime endDate) {
    return _logs.where((log) => 
        log.timestamp.isAfter(startDate) && 
        log.timestamp.isBefore(endDate)
    ).toList().reversed.toList();
  }

  static void clearLogs() {
    _logs.clear();
  }

  // Generate sample logs for demonstration
  static void _generateSampleLogs() {
    if (_logs.isNotEmpty) return; // Don't generate if logs already exist

    final now = DateTime.now();
    final sampleLogs = [
      LogEntry(
        id: 1,
        timestamp: now.subtract(Duration(hours: 2)),
        userId: '1',
        userName: 'Admin User',
        action: LogAction.login,
        entityType: LogEntityType.user,
        entityId: '1',
        description: 'Kullanıcı sisteme giriş yaptı: Admin User',
        changes: {},
      ),
      LogEntry(
        id: 2,
        timestamp: now.subtract(Duration(hours: 1, minutes: 45)),
        userId: '1',
        userName: 'Admin User',
        action: LogAction.create,
        entityType: LogEntityType.customer,
        entityId: '1',
        description: 'Yeni müşteri eklendi: Acme Corporation',
        changes: {'name': 'Acme Corporation', 'country': 'Türkiye'},
      ),
      LogEntry(
        id: 3,
        timestamp: now.subtract(Duration(hours: 1, minutes: 30)),
        userId: '1',
        userName: 'Admin User',
        action: LogAction.create,
        entityType: LogEntityType.inventory,
        entityId: '1',
        description: 'Yeni envanter eklendi: Laptop Computer',
        changes: {'name': 'Laptop Computer', 'quantity': '10', 'price': '15000'},
      ),
      LogEntry(
        id: 4,
        timestamp: now.subtract(Duration(hours: 1, minutes: 15)),
        userId: '1',
        userName: 'Admin User',
        action: LogAction.create,
        entityType: LogEntityType.order,
        entityId: '1',
        description: 'Yeni sipariş oluşturuldu: Acme Corporation',
        changes: {'customer': 'Acme Corporation', 'amount': '25000'},
      ),
      LogEntry(
        id: 5,
        timestamp: now.subtract(Duration(hours: 1)),
        userId: '1',
        userName: 'Admin User',
        action: LogAction.update,
        entityType: LogEntityType.inventory,
        entityId: '1',
        description: 'Envanter güncellendi: Laptop Computer',
        changes: {'quantity': '8', 'status': 'Stokta'},
      ),
      LogEntry(
        id: 6,
        timestamp: now.subtract(Duration(minutes: 45)),
        userId: '2',
        userName: 'John Smith',
        action: LogAction.login,
        entityType: LogEntityType.user,
        entityId: '2',
        description: 'Kullanıcı sisteme giriş yaptı: John Smith',
        changes: {},
      ),
      LogEntry(
        id: 7,
        timestamp: now.subtract(Duration(minutes: 30)),
        userId: '2',
        userName: 'John Smith',
        action: LogAction.create,
        entityType: LogEntityType.employee,
        entityId: '3',
        description: 'Yeni çalışan eklendi: Jane Doe',
        changes: {'name': 'Jane Doe', 'department': 'İnsan Kaynakları', 'position': 'HR Specialist'},
      ),
      LogEntry(
        id: 8,
        timestamp: now.subtract(Duration(minutes: 15)),
        userId: '1',
        userName: 'Admin User',
        action: LogAction.update,
        entityType: LogEntityType.order,
        entityId: '1',
        description: 'Sipariş güncellendi: Acme Corporation',
        changes: {'status': 'processing', 'notes': 'Order confirmed by customer'},
      ),
      LogEntry(
        id: 9,
        timestamp: now.subtract(Duration(minutes: 10)),
        userId: '2',
        userName: 'John Smith',
        action: LogAction.update,
        entityType: LogEntityType.customer,
        entityId: '1',
        description: 'Müşteri bilgileri güncellendi: Acme Corporation',
        changes: {'phone': '+90 555 123 4567', 'address': 'İstanbul, Türkiye'},
      ),
      LogEntry(
        id: 10,
        timestamp: now.subtract(Duration(minutes: 5)),
        userId: '1',
        userName: 'Admin User',
        action: LogAction.create,
        entityType: LogEntityType.inventory,
        entityId: '2',
        description: 'Yeni envanter eklendi: Office Chair',
        changes: {'name': 'Office Chair', 'quantity': '25', 'price': '750'},
      ),
    ];

    _logs.addAll(sampleLogs);
  }
} 