import 'package:flutter/material.dart';
import 'package:erpmobilapp/models/log_entry.dart';
import 'package:erpmobilapp/services/logging_service.dart';
import 'package:intl/intl.dart';

class AdminLogsScreen extends StatefulWidget {
  @override
  _AdminLogsScreenState createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LogEntry> _allLogs = [];
  List<LogEntry> _filteredLogs = [];
  String _selectedFilter = 'Tümü';
  TextEditingController _searchController = TextEditingController();

  final List<String> _filterOptions = [
    'Tümü',
    'Envanter',
    'Siparişler',
    'Müşteriler',
    'Çalışanlar',
    'Kullanıcı İşlemleri'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLogs();
    _searchController.addListener(_filterLogs);
  }

  void _loadLogs() {
    setState(() {
      _allLogs = LoggingService.getLogs();
      _filteredLogs = _allLogs;
    });
  }

  void _filterLogs() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLogs = _allLogs.where((log) {
        bool matchesSearch = query.isEmpty ||
            log.description.toLowerCase().contains(query) ||
            log.userName.toLowerCase().contains(query);
        
        bool matchesFilter = _selectedFilter == 'Tümü' ||
            (_selectedFilter == 'Envanter' && log.entityType == LogEntityType.inventory) ||
            (_selectedFilter == 'Siparişler' && log.entityType == LogEntityType.order) ||
            (_selectedFilter == 'Müşteriler' && log.entityType == LogEntityType.customer) ||
            (_selectedFilter == 'Çalışanlar' && log.entityType == LogEntityType.employee) ||
            (_selectedFilter == 'Kullanıcı İşlemleri' && (log.action == LogAction.login || log.action == LogAction.logout));
        
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Widget _buildLogsList() {
    if (_filteredLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Henüz log kaydı bulunamadı', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredLogs.length,
      itemBuilder: (context, index) {
        final log = _filteredLogs[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: _getActionIcon(log.action),
            title: Text(log.description),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kullanıcı: ${log.userName}'),
                Text('Zaman: ${DateFormat('dd/MM/yyyy HH:mm').format(log.timestamp)}'),
                if (log.changes.isNotEmpty)
                  Text('Değişiklikler: ${log.changes.entries.map((e) => '${e.key}: ${e.value}').join(', ')}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            trailing: _getEntityTypeChip(log.entityType),
            onTap: () => _showLogDetails(log),
          ),
        );
      },
    );
  }

  Widget _buildStatistics() {
    Map<LogAction, int> actionCounts = {};
    Map<LogEntityType, int> entityCounts = {};
    Map<String, int> userCounts = {};

    for (var log in _allLogs) {
      actionCounts[log.action] = (actionCounts[log.action] ?? 0) + 1;
      entityCounts[log.entityType] = (entityCounts[log.entityType] ?? 0) + 1;
      userCounts[log.userName] = (userCounts[log.userName] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatCard('Toplam Log', _allLogs.length.toString(), Icons.description),
          SizedBox(height: 16),
          
          _buildStatCard('Bugünkü Loglar', 
            _allLogs.where((log) => 
              DateFormat('dd/MM/yyyy').format(log.timestamp) == 
              DateFormat('dd/MM/yyyy').format(DateTime.now())
            ).length.toString(), 
            Icons.today),
          SizedBox(height: 16),
          
          Text('İşlemler', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          ...actionCounts.entries.map((entry) => 
            _buildStatRow(_getActionName(entry.key), entry.value.toString())),
          
          SizedBox(height: 20),
          Text('Varlık Türleri', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          ...entityCounts.entries.map((entry) => 
            _buildStatRow(_getEntityTypeName(entry.key), entry.value.toString())),
          
          SizedBox(height: 20),
          Text('En Aktif Kullanıcılar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          ...userCounts.entries.take(5).map((entry) => 
            _buildStatRow(entry.key, entry.value.toString())),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Color(0xFF013220)),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Log Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text('Clear All Logs'),
                  subtitle: Text('Remove all log entries'),
                  leading: Icon(Icons.delete_sweep, color: Colors.red),
                  onTap: _showClearLogsDialog,
                ),
                Divider(),
                ListTile(
                  title: Text('Export Logs'),
                  subtitle: Text('Export logs to file'),
                  leading: Icon(Icons.download, color: Colors.blue),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Export functionality not implemented yet')),
                    );
                  },
                ),
                Divider(),
                ListTile(
                  title: Text('Auto-delete old logs'),
                  subtitle: Text('Automatically delete logs older than 30 days'),
                  leading: Icon(Icons.auto_delete, color: Colors.orange),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Auto-delete ${value ? 'enabled' : 'disabled'}')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showClearLogsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Logs'),
        content: Text('Are you sure you want to delete all log entries? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              LoggingService.clearLogs();
              _loadLogs();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('All logs cleared')),
              );
            },
            child: Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showLogDetails(LogEntry log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Action', _getActionName(log.action)),
              _buildDetailRow('Entity Type', _getEntityTypeName(log.entityType)),
              _buildDetailRow('Entity ID', log.entityId),
              _buildDetailRow('User', log.userName),
              _buildDetailRow('User ID', log.userId),
              _buildDetailRow('Timestamp', DateFormat('dd/MM/yyyy HH:mm:ss').format(log.timestamp)),
              _buildDetailRow('Description', log.description),
              if (log.changes.isNotEmpty) ...[
                SizedBox(height: 10),
                Text('Changes:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...log.changes.entries.map((e) => 
                  _buildDetailRow(e.key, e.value)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _getActionIcon(LogAction action) {
    switch (action) {
      case LogAction.create:
        return Icon(Icons.add_circle, color: Colors.green);
      case LogAction.update:
        return Icon(Icons.edit, color: Colors.blue);
      case LogAction.delete:
        return Icon(Icons.delete, color: Colors.red);
      case LogAction.login:
        return Icon(Icons.login, color: Colors.purple);
      case LogAction.logout:
        return Icon(Icons.logout, color: Colors.orange);
    }
  }

  Widget _getEntityTypeChip(LogEntityType entityType) {
    Color color;
    switch (entityType) {
      case LogEntityType.inventory:
        color = Colors.brown;
        break;
      case LogEntityType.order:
        color = Colors.green;
        break;
      case LogEntityType.customer:
        color = Colors.blue;
        break;
      case LogEntityType.employee:
        color = Colors.purple;
        break;
      case LogEntityType.user:
        color = Colors.orange;
        break;
    }
    
    return Chip(
      label: Text(_getEntityTypeName(entityType), style: TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
    );
  }

  String _getActionName(LogAction action) {
    switch (action) {
      case LogAction.create:
        return 'Oluştur';
      case LogAction.update:
        return 'Güncelle';
      case LogAction.delete:
        return 'Sil';
      case LogAction.login:
        return 'Giriş';
      case LogAction.logout:
        return 'Çıkış';
    }
  }

  String _getEntityTypeName(LogEntityType entityType) {
    switch (entityType) {
      case LogEntityType.inventory:
        return 'Envanter';
      case LogEntityType.order:
        return 'Sipariş';
      case LogEntityType.customer:
        return 'Müşteri';
      case LogEntityType.employee:
        return 'Çalışan';
      case LogEntityType.user:
        return 'Kullanıcı';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Logları'),
        backgroundColor: Color(0xFF013220),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(icon: Icon(Icons.list), text: 'Loglar'),
            Tab(icon: Icon(Icons.analytics), text: 'İstatistikler'),
            Tab(icon: Icon(Icons.settings), text: 'Ayarlar'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Loglarda ara...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedFilter,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedFilter = newValue!;
                      _filterLogs();
                    });
                  },
                  items: _filterOptions.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLogsList(),
                _buildStatistics(),
                _buildSettings(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
} 