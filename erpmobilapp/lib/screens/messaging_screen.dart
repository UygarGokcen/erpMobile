import 'package:flutter/material.dart';
import 'package:erpmobilapp/models/employee.dart';
import 'package:erpmobilapp/models/message.dart';
import 'package:erpmobilapp/services/employee_service.dart';

class ChatRoom {
  final int id;
  final String name;
  final String description;
  final List<int> participantIds;
  final List<Message> messages;
  final DateTime lastActivity;
  final String type; // 'channel', 'direct', 'group'

  ChatRoom({
    required this.id,
    required this.name,
    required this.description,
    required this.participantIds,
    required this.messages,
    required this.lastActivity,
    required this.type,
  });
}

class MessagingScreen extends StatefulWidget {
  final Employee currentUser;

  MessagingScreen({required this.currentUser});

  @override
  _MessagingScreenState createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen>
    with TickerProviderStateMixin {
  List<ChatRoom> chatRooms = [];
  List<Employee> teamMembers = [];
  TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String selectedFilter = 'Tümü';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _loadChatRooms();
    _loadTeamMembers();
    _animationController.forward();
  }

  void _loadChatRooms() async {
    setState(() {
      // Başlangıçta boş chat room listesi
      chatRooms = [];
    });
  }

  void _loadTeamMembers() async {
    // Gerçek employee verilerini çek
    final employees = await EmployeeService.getEmployees();
    setState(() {
      teamMembers = employees;
    });
  }

  List<ChatRoom> get filteredChatRooms {
    List<ChatRoom> filtered = chatRooms;
    
    if (selectedFilter != 'Tümü') {
      filtered = filtered.where((room) {
        switch (selectedFilter) {
          case 'Kanallar':
            return room.type == 'channel';
          case 'Gruplar':
            return room.type == 'group';
          case 'Direkt':
            return room.type == 'direct';
          default:
            return true;
        }
      }).toList();
    }

    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((room) =>
        room.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
        room.description.toLowerCase().contains(_searchController.text.toLowerCase())
      ).toList();
    }

    return filtered;
  }

  Widget _buildStatsCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF013220),
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChatRoomCard(ChatRoom room) {
    IconData roomIcon;
    switch (room.type) {
      case 'channel':
        roomIcon = Icons.tag;
        break;
      case 'group':
        roomIcon = Icons.group;
        break;
      case 'direct':
        roomIcon = Icons.person;
        break;
      default:
        roomIcon = Icons.chat;
    }

    String timeAgo = _getTimeAgo(room.lastActivity);
    bool hasRecentActivity = room.lastActivity.isAfter(DateTime.now().subtract(Duration(hours: 1)));

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openChatRoom(room),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF013220), Color(0xFF2E7D57)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(roomIcon, color: Colors.white, size: 28),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              room.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF013220),
                              ),
                            ),
                          ),
                          if (hasRecentActivity)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        room.description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.people, color: Colors.grey[500], size: 16),
                          SizedBox(width: 4),
                          Text(
                            '${room.participantIds.length} üye',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                          Spacer(),
                          Text(
                            timeAgo,
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),
                      if (room.messages.isNotEmpty) ...[
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            room.messages.last.content,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF013220),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamMemberCard(Employee member) {
    bool isOnline = member.id % 2 == 0; // Simulated online status
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Stack(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF013220), Color(0xFF2E7D57)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  member.name[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            if (isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          member.name,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('${member.department} - ${member.position}'),
        trailing: Container(
          decoration: BoxDecoration(
            color: Color(0xFF013220).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(Icons.chat, color: Color(0xFF013220), size: 20),
            onPressed: () => _startDirectChat(member),
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Şimdi';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}dk önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}sa önce';
    } else {
      return '${difference.inDays}g önce';
    }
  }

  void _openChatRoom(ChatRoom room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          chatRoom: room,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  void _startDirectChat(Employee member) {
    // Create or find existing direct chat
    ChatRoom directChat = ChatRoom(
      id: 1000 + member.id,
      name: member.name,
      description: 'Direkt mesaj',
      participantIds: [widget.currentUser.id, member.id],
      messages: [],
      lastActivity: DateTime.now(),
      type: 'direct',
    );
    
    _openChatRoom(directChat);
  }

  void _showCreateRoomDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateRoomDialog(
        currentUser: widget.currentUser,
        onRoomCreated: (ChatRoom newRoom) {
          setState(() {
            chatRooms.add(newRoom);
          });
          _showSnackBar('${newRoom.name} odası oluşturuldu!', Colors.green);
        },
      ),
    );
  }

  void _showTeamMembersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF013220).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.people, color: Color(0xFF013220), size: 24),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Ekip Üyeleri',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF013220),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: teamMembers.length,
                itemBuilder: (context, index) {
                  return _buildTeamMemberCard(teamMembers[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[50]!, Colors.white],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 280,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              actions: [
                Container(
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.people, color: Colors.white),
                    onPressed: _showTeamMembersBottomSheet,
                  ),
                ),
                Container(
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.add, color: Colors.white),
                    onPressed: _showCreateRoomDialog,
                  ),
                ),
              ],
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF013220), Color(0xFF2E7D57)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: FlexibleSpaceBar(
                  title: Text(
                    '',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF013220), Color(0xFF2E7D57)],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 100,
                          right: -50,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 120,
                          left: -30,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.chat,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      'FounderChat',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatsCard(
                                      'Toplam Oda',
                                      chatRooms.length.toString(),
                                      Icons.chat_bubble_outline,
                                      Colors.blue,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatsCard(
                                      'Aktif Üye',
                                      teamMembers.length.toString(),
                                      Icons.people,
                                      Colors.green,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatsCard(
                                      'Kanallar',
                                      chatRooms.where((r) => r.type == 'channel').length.toString(),
                                      Icons.tag,
                                      Colors.orange,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatsCard(
                                      'Gruplar',
                                      chatRooms.where((r) => r.type == 'group').length.toString(),
                                      Icons.group,
                                      Colors.purple,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    // Arama ve Filtreler
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Oda adı ile ara...',
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                prefixIcon: Icon(Icons.search, color: Color(0xFF013220)),
                                suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear, color: Colors.grey[500]),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: ['Tümü', 'Kanallar', 'Gruplar', 'Direkt'].map((filter) {
                                bool isSelected = selectedFilter == filter;
                                return Container(
                                  margin: EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(filter),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        selectedFilter = filter;
                                      });
                                    },
                                    backgroundColor: Colors.white,
                                    selectedColor: Color(0xFF013220).withOpacity(0.1),
                                    labelStyle: TextStyle(
                                      color: isSelected ? Color(0xFF013220) : Colors.grey[700],
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    side: BorderSide(
                                      color: isSelected ? Color(0xFF013220) : Colors.grey[300]!,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            filteredChatRooms.isEmpty
              ? SliverToBoxAdapter(
                  child: Container(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchController.text.isNotEmpty 
                              ? Icons.search_off 
                              : Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            _searchController.text.isNotEmpty
                              ? 'Arama sonucu bulunamadı'
                              : 'Henüz chat odası yok',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _searchController.text.isNotEmpty
                              ? 'Farklı arama kriterleri deneyin'
                              : 'İlk chat odanızı oluşturmak için + butonuna tıklayın',
                            style: TextStyle(color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= filteredChatRooms.length) return null;
                      return _buildChatRoomCard(filteredChatRooms[index]);
                    },
                    childCount: filteredChatRooms.length,
                  ),
                ),
            SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF013220), Color(0xFF2E7D57)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF013220).withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showCreateRoomDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

// Chat Room Screen
class ChatRoomScreen extends StatefulWidget {
  final ChatRoom chatRoom;
  final Employee currentUser;

  ChatRoomScreen({required this.chatRoom, required this.currentUser});

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  TextEditingController _messageController = TextEditingController();
  List<Message> messages = [];

  @override
  void initState() {
    super.initState();
    messages = List.from(widget.chatRoom.messages);
  }

  Widget _buildMessageBubble(Message message) {
    final bool isCurrentUser = message.senderId == widget.currentUser.id;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF013220), Color(0xFF2E7D57)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  'U',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isCurrentUser 
                  ? LinearGradient(
                      colors: [Color(0xFF013220), Color(0xFF2E7D57)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
                color: isCurrentUser ? null : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isCurrentUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (isCurrentUser) ...[
            SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF013220), Color(0xFF2E7D57)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  widget.currentUser.name[0].toUpperCase(),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        messages.add(Message(
          id: messages.length + 1,
          senderId: widget.currentUser.id,
          receiverId: 0,
          content: _messageController.text.trim(),
          timestamp: DateTime.now(),
        ));
        _messageController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatRoom.name),
        backgroundColor: Color(0xFF013220),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              // Show room info
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'Henüz mesaj yok',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'İlk mesajı gönderin!',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(messages[index]);
                  },
                ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, -2),
                  blurRadius: 8,
                  color: Colors.black12,
                ),
              ],
            ),
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Mesajınızı yazın...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF013220), Color(0xFF2E7D57)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

// Create Room Dialog
class CreateRoomDialog extends StatefulWidget {
  final Function(ChatRoom) onRoomCreated;
  final Employee currentUser;

  CreateRoomDialog({required this.onRoomCreated, required this.currentUser});

  @override
  _CreateRoomDialogState createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<CreateRoomDialog> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  String selectedType = 'channel';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey[50]!],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF013220).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.add_circle, color: Color(0xFF013220), size: 24),
                ),
                SizedBox(width: 12),
                Text(
                  'Yeni Oda Oluştur',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF013220),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Oda Adı',
                labelStyle: TextStyle(color: Color(0xFF013220)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF013220)),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Açıklama',
                labelStyle: TextStyle(color: Color(0xFF013220)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF013220)),
                ),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: InputDecoration(
                labelText: 'Oda Tipi',
                labelStyle: TextStyle(color: Color(0xFF013220)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF013220)),
                ),
              ),
              items: [
                DropdownMenuItem(value: 'channel', child: Text('Kanal')),
                DropdownMenuItem(value: 'group', child: Text('Grup')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedType = value!;
                });
              },
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('İptal'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_nameController.text.isNotEmpty) {
                        ChatRoom newRoom = ChatRoom(
                          id: DateTime.now().millisecondsSinceEpoch,
                          name: _nameController.text,
                          description: _descriptionController.text,
                          participantIds: [widget.currentUser.id], // Current user
                          messages: [],
                          lastActivity: DateTime.now(),
                          type: selectedType,
                        );
                        widget.onRoomCreated(newRoom);
                        Navigator.pop(context);
                      }
                    },
                    child: Text('Oluştur'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF013220),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

