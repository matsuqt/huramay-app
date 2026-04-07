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
      String url = 'http://10.174.134.39:5000/api/items';
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
              prefixIcon: Icon(Icons.search, color: Colors.grey), // Icons can stay grey, text should be black
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
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
                    // CHANGED TO BLACK
                    const Text("Filters ", style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold)),
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
                              child: Text(value, style: const TextStyle(fontSize: 12, color: Colors.black)),
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
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 80), // Padding so FAB doesn't cover last item
                      itemCount: items.length,
                      itemBuilder: (c, i) => _itemCard(context, items[i]),
                    ),
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const AddItemScreen()),
          );
          _fetchItems();
        },
        backgroundColor: const Color(0xFF1A0088), 
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
          const Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            // CHANGED TO BLACK
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
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
    bool isAvailable = item['status']?.toString().toLowerCase() == 'available';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => DetailedItemScreen(item: item)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6), 
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03), 
              blurRadius: 5, 
              offset: const Offset(0, 3)
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1A0088), width: 1.5), 
                image: hasImage 
                  ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) 
                  : null,
              ),
              child: !hasImage ? const Icon(Icons.image, size: 35, color: Colors.grey) : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['owner'],
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A0088), fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isAvailable ? Colors.green : Colors.red, width: 0.5),
                        ),
                        child: Text(
                          item['status'],
                          style: TextStyle(
                            color: isAvailable ? Colors.green : Colors.red, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 10
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['title'],
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Qty: ${item['quantity']}  •  Cond: ${item['condition']}",
                    // CHANGED TO BLACK
                    style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      "Tap to view details", 
                      // CHANGED TO BLACK
                      style: TextStyle(fontSize: 10, color: Colors.black, fontStyle: FontStyle.italic)
                    ),
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