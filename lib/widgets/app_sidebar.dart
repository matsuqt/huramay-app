// lib/widgets/app_sidebar.dart
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
import '../screens/admin_dashboard.dart'; 
import '../screens/reports_screen.dart'; // NEW IMPORT

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
    bool isAdmin = currentUser?['is_admin'] ?? false; // Check if the user is an admin

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
                // Only show this button if they are an admin
                if (isAdmin)
                  _figmaMenuBtn(context, "Admin Panel", Icons.admin_panel_settings),

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
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const LoginScreen()), (route) => false);
            } else if (title == "Admin Panel") {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const AdminDashboard()));
            } else if (title == "My Items") {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MyItemsScreen()));
            } else if (title == "Dashboard") {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const DashboardScreen()));
            } else if (title == "Department Filters") {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const DepartmentScreen()));
            } else if (title == "Favorites") {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const FavoritesScreen()));
            } else if (title == "Messages") {
              Navigator.pop(context); 
              Navigator.push(context, MaterialPageRoute(builder: (c) => const ChatInboxScreen()));
            } else if (title == "History") {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const HistoryScreen()));
            } else if (title == "Requests") {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const RequestsScreen()));
            } else if (title == "Report") {
              // TICKET VAVT-63: Route to the new Reports Page
              Navigator.pop(context); // Close the side menu first
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const ReportsScreen()));
            } else {
              Navigator.pop(context); 
            }
          },
        ),
      ),
    );
  }
}