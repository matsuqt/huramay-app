// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import '../widgets/app_sidebar.dart';
import '../utils/ui_helpers.dart';
import 'auth_screens.dart';
import 'item_screens.dart';

// ==================== DASHBOARD SCREEN ====================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List items = []; 
  bool isLoading = true;
  String? _currentFilter; 
  final TextEditingController _searchCtrl = TextEditingController(); 

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() => isLoading = true);
    try {
      String url = 'http://10.33.87.39:5000/api/items';
      List<String> queryParams = [];
      
      if (_currentFilter != null && _currentFilter != 'All') {
        queryParams.add('status=$_currentFilter');
      }
      
      String searchQuery = _searchCtrl.text.trim();
      if (searchQuery.isNotEmpty) {
        queryParams.add('search=${Uri.encodeComponent(searchQuery)}');
      }
      
      if (queryParams.isNotEmpty) url += '?${queryParams.join('&')}';
      
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        setState(() {
          items = jsonDecode(res.body);
        });
      }
    } catch (e) {
      debugPrint("Dashboard Fetch Error: $e");
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (value) => _fetchItems(), 
            decoration: const InputDecoration(
              hintText: "Search",
              prefixIcon: Icon(Icons.search),
              border: InputBorder.none,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const ProfileScreen()),
            ),
            icon: const Icon(Icons.account_circle, size: 30),
          )
        ],
      ),
      drawer: const AppSidebar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20), 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Dashboard",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A0088),
                  ),
                ),
                Row(
                  children: [
                    const Text("Filters ", style: TextStyle(fontSize: 12, color: Colors.black54)),
                    Container(
                      height: 35,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _currentFilter,
                          hint: const Text("All", style: TextStyle(fontSize: 12, color: Colors.black)),
                          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black),
                          items: ['Available', 'Borrowed'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: const TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() => _currentFilter = newValue);
                            _fetchItems();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : items.isEmpty 
                  ? _emptyStateDashboard() 
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (c, i) => _itemCard(context, items[i]),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const AddItemScreen()),
          );
          _fetchItems();
        },
        backgroundColor: const Color(0xFFFDEB00),
        label: const Text(
          "Add Item",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _emptyStateDashboard() {
    String message = "No Items Found";
    if (_searchCtrl.text.trim().isNotEmpty) message = "No\nItems\nFound";
    else if (_currentFilter == "Available") message = "No\nAvailable\nItems";
    else if (_currentFilter == "Borrowed") message = "No\nBorrowed\nItems";
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.block, size: 80, color: Colors.black87),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(BuildContext context, dynamic item) {
    String? imgPath = item['image'];
    bool hasImage = imgPath != null && imgPath.isNotEmpty;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              image: hasImage 
                ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) 
                : null,
            ),
            child: !hasImage ? const Icon(Icons.image, size: 40, color: Colors.grey) : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['owner'],
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                Text(
                  item['title'],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Qty: ${item['quantity']} | Cond: ${item['condition']}",
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  item['status'],
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    miniBtn("Read", Colors.yellow, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (c) => DetailedItemScreen(item: item)),
                      );
                    }), 
                    const SizedBox(width: 10), 
                    miniBtn("Borrow", Colors.yellow, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (c) => DetailedItemScreen(item: item)),
                      );
                    })
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}