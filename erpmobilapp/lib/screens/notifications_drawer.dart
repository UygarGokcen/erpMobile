import 'package:flutter/material.dart';
import 'package:erpmobilapp/models/employee.dart';
import 'package:erpmobilapp/models/notification.dart' as NotificationModel;
import 'package:erpmobilapp/services/database_service.dart';
import 'package:erpmobilapp/services/notification_service.dart';

class NotificationsDrawer extends StatefulWidget {
  final Employee currentUser;

  NotificationsDrawer({required this.currentUser});

  @override
  _NotificationsDrawerState createState() => _NotificationsDrawerState();
}

class _NotificationsDrawerState extends State<NotificationsDrawer> {
  List<NotificationModel.Notification> notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() async {
    try {
      final loadedNotifications = DatabaseService.getAllNotifications();
      
      // If no notifications exist, add realistic sample ones
      if (loadedNotifications.isEmpty) {
        await NotificationService.initializeWithSampleData();
        final newNotifications = DatabaseService.getAllNotifications();
        setState(() {
          notifications = newNotifications;
        });
      } else {
        setState(() {
          notifications = loadedNotifications;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      // Fallback to basic sample notifications
      await _addBasicSampleNotifications();
    }
  }

  Future<void> _addBasicSampleNotifications() async {
    final sampleNotifications = [
      NotificationModel.Notification(
        id: 1,
        type: NotificationModel.NotificationType.loginSuccess,
        message: 'Hoş geldiniz ${widget.currentUser.name}! Sisteme başarıyla giriş yaptınız.',
        timestamp: DateTime.now().subtract(Duration(minutes: 5)),
        userId: widget.currentUser.id.toString(),
      ),
      NotificationModel.Notification(
        id: 2,
        type: NotificationModel.NotificationType.productCompleted,
        message: 'Laptop Computer ürünü başarıyla tamamlandı ve stokta mevcut.',
        timestamp: DateTime.now().subtract(Duration(hours: 1)),
        userId: widget.currentUser.id.toString(),
      ),
      NotificationModel.Notification(
        id: 3,
        type: NotificationModel.NotificationType.paymentReceived,
        message: 'Tech Solutions Ltd. müşterisinden ₺15,000.00 ödeme alındı.',
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
        userId: widget.currentUser.id.toString(),
      ),
      NotificationModel.Notification(
        id: 4,
        type: NotificationModel.NotificationType.orderCompleted,
        message: 'Sipariş #ORD-001 (Global Industries) başarıyla tamamlandı.',
        timestamp: DateTime.now().subtract(Duration(hours: 3)),
        userId: widget.currentUser.id.toString(),
      ),
      NotificationModel.Notification(
        id: 5,
        type: NotificationModel.NotificationType.lowStock,
        message: 'Kritik stok seviyesi: Office Chair (Kalan: 3 adet)',
        timestamp: DateTime.now().subtract(Duration(hours: 4)),
        userId: widget.currentUser.id.toString(),
      ),
    ];

    for (var notification in sampleNotifications) {
      try {
        await DatabaseService.addNotification(notification);
      } catch (e) {
        print('Error adding sample notification: $e');
      }
    }

    // Reload notifications after adding samples
    setState(() {
      notifications = sampleNotifications;
    });
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else {
      return '${difference.inDays} gün önce';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF013220), Color(0xFF013220).withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.notifications,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Bildirimler',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${notifications.where((n) => !n.isRead).length} okunmamış',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          if (notifications.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Henüz bildirim yok',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.all(8),
                itemCount: notifications.length,
                separatorBuilder: (context, index) => Divider(height: 1),
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    elevation: notification.isRead ? 1 : 3,
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getNotificationColor(notification.type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getNotificationIcon(notification.type),
                          color: _getNotificationColor(notification.type),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        notification.message,
                        style: TextStyle(
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        _formatTime(notification.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      trailing: notification.isRead 
                        ? null 
                        : Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Color(0xFF013220),
                              shape: BoxShape.circle,
                            ),
                          ),
                      onTap: () {
                        setState(() {
                          notification.isRead = true;
                        });
                        // Handle notification tap - navigate to relevant screen
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Bildirim okundu: ${notification.message}'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          
          // Bottom action buttons - kullanıcının overflow hatası için Flexible kullan
          if (notifications.isNotEmpty)
            Flexible(
              flex: 0,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: Icon(Icons.mark_email_read, size: 16),
                            label: Text('Tümünü Okundu İşaretle', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              setState(() {
                                for (var notification in notifications) {
                                  notification.isRead = true;
                                }
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size(0, 32),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: Icon(Icons.clear_all, size: 16),
                            label: Text('Temizle', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              setState(() {
                                notifications.clear();
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size(0, 32),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(NotificationModel.NotificationType type) {
    switch (type) {
      case NotificationModel.NotificationType.orderStatus:
        return Icons.shopping_cart;
      case NotificationModel.NotificationType.inventoryChange:
        return Icons.inventory;
      case NotificationModel.NotificationType.message:
        return Icons.message;
      case NotificationModel.NotificationType.loginSuccess:
        return Icons.login;
      case NotificationModel.NotificationType.productCompleted:
        return Icons.check_circle;
      case NotificationModel.NotificationType.customerAdded:
        return Icons.person_add;
      case NotificationModel.NotificationType.employeeAdded:
        return Icons.group_add;
      case NotificationModel.NotificationType.paymentReceived:
        return Icons.payment;
      case NotificationModel.NotificationType.lowStock:
        return Icons.warning;
      case NotificationModel.NotificationType.orderCompleted:
        return Icons.task_alt;
      case NotificationModel.NotificationType.taskAssigned:
        return Icons.assignment;
      case NotificationModel.NotificationType.systemUpdate:
        return Icons.system_update;
    }
  }

  Color _getNotificationColor(NotificationModel.NotificationType type) {
    switch (type) {
      case NotificationModel.NotificationType.orderStatus:
        return Colors.blue;
      case NotificationModel.NotificationType.inventoryChange:
        return Colors.orange;
      case NotificationModel.NotificationType.message:
        return Colors.green;
      case NotificationModel.NotificationType.loginSuccess:
        return Colors.green;
      case NotificationModel.NotificationType.productCompleted:
        return Colors.green;
      case NotificationModel.NotificationType.customerAdded:
        return Colors.blue;
      case NotificationModel.NotificationType.employeeAdded:
        return Colors.purple;
      case NotificationModel.NotificationType.paymentReceived:
        return Colors.green;
      case NotificationModel.NotificationType.lowStock:
        return Colors.red;
      case NotificationModel.NotificationType.orderCompleted:
        return Colors.green;
      case NotificationModel.NotificationType.taskAssigned:
        return Colors.indigo;
      case NotificationModel.NotificationType.systemUpdate:
        return Colors.grey;
    }
  }
}

