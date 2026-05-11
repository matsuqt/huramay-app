// lib/screens/chat_screens.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; 

import '../globals.dart';
import '../widgets/app_sidebar.dart';

// ==================== SHARED DESIGN CONSTANTS ====================
const Color primaryBlue = Color(0xFF1A0088);
const Color accentYellow = Color(0xFFFFD700);
const Color textDark = Color(0xFF1F2937);
const Color textLight = Color(0xFF6B7280);
const Color borderGrey = Color(0xFFE5E7EB);
const Color bgGray = Color(0xFFF8FAFC);

// Helper function to safely parse UTC and convert to Local Time
String _formatLocalTime(String? utcTimeString) {
  if (utcTimeString == null || utcTimeString.isEmpty) return "";
  try {
    String cleanString = utcTimeString.trim();
    if (!cleanString.endsWith('Z')) {
      cleanString = "${cleanString}Z";
    }
    DateTime parsedUtc = DateTime.parse(cleanString);
    DateTime localTime = parsedUtc.toLocal();
    return DateFormat('hh:mm a').format(localTime);
  } catch (e) {
    debugPrint("Time Parse Error: $e");
    return utcTimeString; 
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
      final res = await http.get(Uri.parse('http://192.168.137.1:5000/api/messages/inbox/${currentUser!['id']}')); 
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
      backgroundColor: bgGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryBlue),
        title: Container(
          height: 40,
          decoration: BoxDecoration(color: bgGray, borderRadius: BorderRadius.circular(8), border: Border.all(color: primaryBlue.withOpacity(0.1))), 
          child: const TextField(
            style: TextStyle(fontSize: 14, color: textDark),
            decoration: InputDecoration(
              hintText: "Search Messages...", 
              hintStyle: TextStyle(color: textLight, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: primaryBlue, size: 20), 
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10)
            ),
          ),
        ),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderGrey, height: 1)),
      ),
      drawer: const AppSidebar(),
      body: Stack(
        children: [
          // Background Geometry
          Positioned(
            top: -80, right: -60, 
            child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: primaryBlue.withOpacity(0.04)))
          ),
          Positioned(
            bottom: 100, left: -80, 
            child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: accentYellow.withOpacity(0.06)))
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 16), 
                child: Text("Messages", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: primaryBlue, letterSpacing: -0.5)),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                    : threads.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: borderGrey)),
                                  child: const Icon(Icons.chat_bubble_outline, size: 48, color: textLight),
                                ),
                                const SizedBox(height: 24),
                                const Text("No messages yet", style: TextStyle(color: textLight, fontSize: 16, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: threads.length,
                            itemBuilder: (c, i) => _buildInboxThread(threads[i]),
                          ),
              ),
            ],
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

    String otherName = threadData['other_name'] ?? "Unknown";
    String initial = otherName.isNotEmpty ? otherName[0].toUpperCase() : "?";

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (c) => ChatRoomScreen(
          chatRoomId: threadData['chat_room_id'],
          otherId: threadData['other_id'], 
          otherName: threadData['other_name'],
          itemName: threadData['item_name'],
        )
      )).then((_) => _fetchInbox()), 
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: unread > 0 ? primaryBlue.withOpacity(0.3) : borderGrey, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: primaryBlue.withOpacity(0.1), 
              child: Text(initial, style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.w900, fontSize: 20)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          otherName, 
                          style: TextStyle(fontWeight: unread > 0 ? FontWeight.w900 : FontWeight.w700, color: textDark, fontSize: 15),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatLocalTime(threadData['timestamp']), 
                        style: TextStyle(
                          fontSize: 11, 
                          color: unread > 0 ? primaryBlue : textLight,
                          fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          threadData['last_message'], 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis, 
                          style: TextStyle(
                            fontSize: 13, 
                            color: unread > 0 ? textDark : textLight, 
                            fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400 
                          ),
                        ),
                      ),
                      if (unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.red.shade600, shape: BoxShape.circle),
                          child: Text(
                            unread.toString(), 
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
      final res = await http.get(Uri.parse('http://192.168.137.1:5000/api/messages/history/${widget.chatRoomId}')); 
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
        Uri.parse('http://192.168.137.1:5000/api/messages/read'), 
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
        Uri.parse('http://192.168.137.1:5000/api/messages/send'), 
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

  // ==========================================
  // NEW: VAVT-94 STATIC POLICY BANNER
  // ==========================================
  Widget _buildPolicyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.blueGrey.shade50,
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: primaryBlue, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Notice: If the item is not returned 3 days after the agreed date, the owner has the right to charge a late fee of 5% of the item's price per day.",
              style: TextStyle(color: textDark, fontSize: 11, fontWeight: FontWeight.w600, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGray,
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark), 
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherName, style: const TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.w800)),
            Row(
              children: [
                const Text("Regarding: ", style: TextStyle(color: textLight, fontSize: 11, fontWeight: FontWeight.w500)),
                Expanded(child: Text(widget.itemName, style: const TextStyle(color: primaryBlue, fontSize: 11, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            )
          ],
        ),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderGrey, height: 1)),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -80, right: -60, 
            child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: primaryBlue.withOpacity(0.04)))
          ),
          Positioned(
            bottom: 100, left: -80, 
            child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: accentYellow.withOpacity(0.06)))
          ),

          Column(
            children: [
              // Inject the Banner right at the top of the chat area
              _buildPolicyBanner(),

              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        itemCount: messages.length,
                        itemBuilder: (c, i) {
                          bool isMe = messages[i]['sender_id'] == currentUser!['id'];
                          
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75), 
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isMe ? primaryBlue : Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(20),
                                        topRight: const Radius.circular(20),
                                        bottomLeft: Radius.circular(isMe ? 20 : 4),
                                        bottomRight: Radius.circular(isMe ? 4 : 20),
                                      ),
                                      border: Border.all(color: isMe ? Colors.transparent : borderGrey),
                                      boxShadow: isMe ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
                                    ),
                                    child: Text(
                                      messages[i]['content'], 
                                      style: TextStyle(
                                        color: isMe ? Colors.white : textDark, 
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                        height: 1.3
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatLocalTime(messages[i]['timestamp']),
                                    style: const TextStyle(fontSize: 10, color: textLight, fontWeight: FontWeight.w600),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: borderGrey, width: 1))
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: bgGray,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: borderGrey)
                          ),
                          child: TextField(
                            controller: _msgCtrl, 
                            style: const TextStyle(fontWeight: FontWeight.w500, color: textDark, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: "Type a message...", 
                              hintStyle: TextStyle(fontWeight: FontWeight.normal, color: textLight),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _send,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: const BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
                          child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}