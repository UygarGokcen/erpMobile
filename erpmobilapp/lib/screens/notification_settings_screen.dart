import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late SharedPreferences prefs;
  bool orderNotifications = true;
  bool inventoryAlerts = true;
  bool financialUpdates = true;
  bool employeeUpdates = true;
  bool taskReminders = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      orderNotifications = prefs.getBool('order_notifications') ?? true;
      inventoryAlerts = prefs.getBool('inventory_alerts') ?? true;
      financialUpdates = prefs.getBool('financial_updates') ?? true;
      employeeUpdates = prefs.getBool('employee_updates') ?? true;
      taskReminders = prefs.getBool('task_reminders') ?? true;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Choose which notifications you want to receive',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          SwitchListTile(
            title: const Text('Order Notifications'),
            subtitle: const Text('Get notified about new and updated orders'),
            value: orderNotifications,
            onChanged: (bool value) {
              setState(() {
                orderNotifications = value;
                _savePreference('order_notifications', value);
              });
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Inventory Alerts'),
            subtitle: const Text('Low stock and inventory updates'),
            value: inventoryAlerts,
            onChanged: (bool value) {
              setState(() {
                inventoryAlerts = value;
                _savePreference('inventory_alerts', value);
              });
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Financial Updates'),
            subtitle:
                const Text('Revenue, expenses, and payment notifications'),
            value: financialUpdates,
            onChanged: (bool value) {
              setState(() {
                financialUpdates = value;
                _savePreference('financial_updates', value);
              });
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Employee Updates'),
            subtitle: const Text('Staff schedule and attendance notifications'),
            value: employeeUpdates,
            onChanged: (bool value) {
              setState(() {
                employeeUpdates = value;
                _savePreference('employee_updates', value);
              });
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Task Reminders'),
            subtitle: const Text('Reminders for upcoming tasks and deadlines'),
            value: taskReminders,
            onChanged: (bool value) {
              setState(() {
                taskReminders = value;
                _savePreference('task_reminders', value);
              });
            },
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Note: Make sure to allow notifications in your device settings for the app to send you notifications.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
