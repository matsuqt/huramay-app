import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../globals.dart';
import '../screens/auth_screens.dart';
import '../screens/dashboard_screen.dart';
import '../screens/item_screens.dart';
import '../screens/chat_screens.dart';
import '../screens/borrowing_screens.dart';
import '../screens/history_screen.dart';

// ==================== GLOBAL SIDEBAR ====================
class AppSidebar extends StatefulWidget {
  const AppSidebar({super.key});

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    if (currentUser == null) return;
    try {
      final res = await http.get(Uri.parse('http://10.33.87.39:5000/api/messages/unread/${currentUser!['id']}'));
      if (res.statusCode == 200) {
        setState(() {
          unreadCount = jsonDecode(res.body)['unread_count'];
        });
      }
    } catch (e) {
      debugPrint("Badge Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFD9D9D9), 
      child: Column(
        children: [
          const SizedBox(height: 60),
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 20.0),
              child: Icon(Icons.menu, size: 30, color: Colors.black),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _figmaMenuBtn(context, "Dashboard", Icons.dashboard_outlined),
                _figmaMenuBtn(context, "My Items", Icons.inventory_2_outlined),
                _figmaMenuBtn(context, "Department Filters", Icons.filter_list),
                _figmaMenuBtn(context, "Favorites", Icons.favorite_border),
                _figmaMenuBtn(
                  context, "Messages", Icons.message_outlined, 
                  trailing: unreadCount > 0 
                    ? Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text(
                          unreadCount.toString(), 
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                        ),
                      )
                    : null
                ),
                _figmaMenuBtn(context, "History", Icons.history),
                _figmaMenuBtn(context, "Report", Icons.report_gmailerrorred),
                _figmaMenuBtn(context, "Requests", Icons.notifications_none),
                const SizedBox(height: 20),
                _figmaMenuBtn(context, "Logout", Icons.logout, isLogout: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _figmaMenuBtn(BuildContext context, String title, IconData icon, {bool isLogout = false, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: const Color(0xFFFDEB00),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: ListTile(
          dense: true,
          visualDensity: const VisualDensity(vertical: -3),
          title: Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
          trailing: trailing,
          onTap: () {
            if (isLogout) {
              currentUser = null;
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => LoginScreen()), (route) => false);
            } else if (title == "My Items") {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => MyItemsScreen()));
            } else if (title == "Dashboard") {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => DashboardScreen()));
            } else if (title == "Department Filters") {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => DepartmentScreen()));
            } else if (title == "Favorites") {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => FavoritesScreen()));
            } else if (title == "Messages") {
              Navigator.pop(context); 
              Navigator.push(context, MaterialPageRoute(builder: (c) => ChatInboxScreen()));
            } else if (title == "History") {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => HistoryScreen()));
            } else if (title == "Requests") {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => RequestsScreen()));
            } else {
              Navigator.pop(context); 
            }
          },
        ),
      ),
    );
  }
}