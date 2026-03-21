import 'package:flutter/material.dart';
import '../globals.dart';
import '../utils/ui_helpers.dart';
import 'auth_screens.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
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
              hintText: "Search items or users",
              prefixIcon: Icon(Icons.search),
              border: InputBorder.none,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 30),
            onPressed: () {
              // Standard profile or logout
            },
          )
        ],
      ),
      // We can add the sidebar here later if the Admin needs it
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "Admin Dashboard",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1A0088)),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.admin_panel_settings, size: 80, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text("Welcome, ${currentUser?['full_name']}"),
                  const Text("Admin Item Feed will appear here."),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      currentUser = null;
                      Navigator.pushAndRemoveUntil(
                        context, 
                        MaterialPageRoute(builder: (c) => LoginScreen()), 
                        (route) => false
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    child: const Text("Logout"),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}