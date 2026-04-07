// lib/screens/chat_screens.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // REQUIRED FOR TIME FIX

import '../globals.dart';
import '../widgets/app_sidebar.dart';

// Helper function to safely parse UTC and convert to Local Time
String _formatLocalTime(String? utcTimeString) {
  if (utcTimeString == null || utcTimeString.isEmpty) return "";
  try {
    // 1. Force Flutter to recognize it as UTC by appending 'Z'
    String cleanString = utcTimeString.trim();
    if (!cleanString.endsWith('Z')) {
      cleanString = "${cleanString}Z";
    }
    
    // 2. Parse into DateTime
    DateTime parsedUtc = DateTime.parse(cleanString);
    
    // 3. Convert to Phone's Local Timezone
    DateTime localTime = parsedUtc.toLocal();
    
    // 4. Format beautifully (e.g. 04:59 AM)
    return DateFormat('hh:mm a').format(localTime);
  } catch (e) {
    debugPrint("Time Parse Error: $e");
    return utcTimeString; // Fallback to raw string if it fails
  }
}

// ==================== CHAT INBOX SCREEN ====================
class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key});
  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  List threads = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInbox();
  }

  Future<void> _fetchInbox() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse('https://huramay-app.onrender.com/api/messages/inbox/${currentUser!['id']}')); // Updated to baseUrl
      if (res.statusCode == 200) {
        if (mounted) setState(() { threads = jsonDecode(res.body); });
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0088), 
        iconTheme: const IconThemeData(color: Colors.white),
        title: Container(
          height: 35,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), 
          child: const TextField(
            decoration: InputDecoration(
              hintText: "Search Messages", 
              prefixIcon: Icon(Icons.search, color: Colors.grey), 
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10)
            ),
          ),
        ),
      ),
      drawer: const AppSidebar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20), 
            child: Text("Messages", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1A0088))),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A0088)))
                : threads.isEmpty
                    ? const Center(child: Text("No messages yet", style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold)))
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        itemCount: threads.length,
                        itemBuilder: (c, i) => _buildInboxThread(threads[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildInboxThread(dynamic threadData) {
    int unread = 0;
    if (threadData['unread_count'] != null) {
      unread = int.tryParse(threadData['unread_count'].toString()) ?? 0;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[300], 
              child: const Icon(Icons.person_outline, color: Colors.black87, size: 30),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (c) => ChatRoomScreen(
                  chatRoomId: threadData['chat_room_id'],
                  otherId: threadData['other_id'], 
                  otherName: threadData['other_name'],
                  itemName: threadData['item_name'],
                )
              )).then((_) => _fetchInbox()), 
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6), 
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black12)
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            threadData['other_name'], 
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A0088), fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            threadData['last_message'], 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis, 
                            style: TextStyle(
                              fontSize: 13, 
                              color: unread > 0 ? Colors.black87 : Colors.black54, 
                              fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal 
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // FIX: Applying the local time formatting
                        Text(
                          _formatLocalTime(threadData['timestamp']), 
                          style: TextStyle(
                            fontSize: 10, 
                            color: unread > 0 ? const Color(0xFF1A0088) : Colors.black54,
                            fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal
                          ),
                        ),
                        if (unread > 0) ...[
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: Text(
                              unread.toString(), 
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ]
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== CHAT ROOM SCREEN ====================
class ChatRoomScreen extends StatefulWidget {
  final int chatRoomId;
  final int otherId;
  final String otherName;
  final String itemName;

  const ChatRoomScreen({
    super.key, 
    required this.chatRoomId, 
    required this.otherId, 
    required this.otherName,
    required this.itemName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final List messages = [];
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final res = await http.get(Uri.parse('https://huramay-app.onrender.com/api/messages/history/${widget.chatRoomId}')); // Updated to baseUrl
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            messages.clear();
            messages.addAll(jsonDecode(res.body));
            isLoading = false;
          });
          _scrollToBottom();
          _markMessagesAsRead();
        }
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await http.post(
        Uri.parse('https://huramay-app.onrender.com/api/messages/read'), // Updated to baseUrl
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_room_id': widget.chatRoomId,
          'user_id': currentUser!['id']
        }),
      );
    } catch (e) {}
  }

  Future<void> _send() async {
    if (_msgCtrl.text.trim().isEmpty) return;
    final content = _msgCtrl.text.trim();
    _msgCtrl.clear();
    try {
      await http.post(
        Uri.parse('https://huramay-app.onrender.com/api/messages/send'), // Updated to baseUrl
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_room_id': widget.chatRoomId,
          'sender_id': currentUser!['id'], 
          'receiver_id': widget.otherId, 
          'content': content
        }),
      );
      _loadHistory();
    } catch (e) {}
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0088), 
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), 
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.pop(context)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text("Regarding: ${widget.itemName}", style: const TextStyle(color: Colors.yellow, fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A0088)))
                : ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    itemCount: messages.length,
                    itemBuilder: (c, i) {
                      bool isMe = messages[i]['sender_id'] == currentUser!['id'];
                      
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75), // Slightly wider
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isMe ? const Color(0xFF1A0088) : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: Radius.circular(isMe ? 18 : 0),
                                    bottomRight: Radius.circular(isMe ? 0 : 18),
                                  ),
                                  border: Border.all(color: isMe ? Colors.transparent : Colors.black12)
                                ),
                                child: Text(
                                  messages[i]['content'], 
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black87, 
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // FIX: Applying the local time formatting here too!
                              Text(
                                _formatLocalTime(messages[i]['timestamp']),
                                style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300))
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.black12)
                    ),
                    child: TextField(
                      controller: _msgCtrl, 
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        hintText: "Type a message...", 
                        hintStyle: TextStyle(fontWeight: FontWeight.normal),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: Color(0xFF1A0088), shape: BoxShape.circle),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}