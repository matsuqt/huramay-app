// lib/screens/item_screens.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../globals.dart';
import '../widgets/app_sidebar.dart';
import 'auth_screens.dart';
import 'borrowing_screens.dart';

// ==================== DEPARTMENT SCREEN ====================
class DepartmentScreen extends StatefulWidget {
  const DepartmentScreen({super.key});
  @override
  State<DepartmentScreen> createState() => _DepartmentScreenState();
}

class _DepartmentScreenState extends State<DepartmentScreen> {
  List items = []; 
  bool isLoading = true;
  String? _currentFilter; 
  String? _selectedDeptFilter; 
  final TextEditingController _searchCtrl = TextEditingController(); 
  
  final List<String> _lnuDepartments = [
    'Bachelor of Elementary Education', 'Bachelor of Early Childhood Education', 'Bachelor of Special Needs Education', 'Bachelor of Technology and Livelihood Education', 'Bachelor of Physical Education', 'Bachelor of Secondary Education major in English', 'Bachelor of Secondary Education major in Filipino', 'Bachelor of Secondary Education major in Mathematics', 'Bachelor of Secondary Education major in Science', 'Bachelor of Secondary Education major in Social Studies', 'Bachelor of Secondary Education major in Values Education', 'Teacher Certificate Program (TCP)', 'Bachelor of Library and Information Science', 'Bachelor of Arts in Communication', 'Bachelor of Music in Music Education', 'Bachelor of Science in Information Technology', 'Bachelor of Arts in English Language', 'Bachelor of Arts in Political Science', 'Bachelor of Science in Biology', 'Bachelor of Science in Social Work', 'Bachelor of Science in Tourism Management', 'Bachelor of Science in Hospitality Management', 'Bachelor of Science in Entrepreneurship', 'Faculty / Staff'
  ];

  @override
  void initState() { 
    super.initState(); 
    _selectedDeptFilter = currentUser?['department'] ?? _lnuDepartments[0];
    _fetchDepartmentItems(); 
  }

  Future<void> _fetchDepartmentItems() async {
    setState(() => isLoading = true);
    try {
      String url = 'http://10.174.134.39:5000/api/items';
      List<String> queryParams = [];
      
      if (_selectedDeptFilter != null) {
        queryParams.add('department=${Uri.encodeComponent(_selectedDeptFilter!)}');
      }

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
      debugPrint("Dept Fetch Error: $e");
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
          child: TextField(
            controller: _searchCtrl,
            onChanged: (value) => _fetchDepartmentItems(), 
            decoration: const InputDecoration(
              hintText: "Search",
              prefixIcon: Icon(Icons.search, color:Colors.black),
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
            padding: const EdgeInsets.all(20).copyWith(bottom: 5), 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Department",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A0088),
                  ),
                ),
                Row(
                  children: [
                    const Text("Filters ", style: TextStyle(fontSize: 12, color: Color.fromARGB(255, 0, 0, 0))),
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
                            _fetchDepartmentItems();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black12)
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedDeptFilter,
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1A0088)),
                  style: const TextStyle(
                    color: Color(0xFF1A0088),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  onChanged: (String? newValue) {
                    setState(() => _selectedDeptFilter = newValue);
                    _fetchDepartmentItems();
                  },
                  items: _lnuDepartments.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis));
                  }).toList(),
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : items.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.inventory_2_outlined, size: 80, color:Colors.black),
                          SizedBox(height: 10),
                          Text(
                            "No Items Found",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (c, i) => _DeptItemCard(item: items[i]),
                    ),
          ),
        ],
      ),
    );
  }
}

// Modernized Department Card (Clickable Entirely)
class _DeptItemCard extends StatelessWidget {
  final dynamic item;
  const _DeptItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    String? imgPath = item['image']; 
    bool hasImage = imgPath != null && imgPath.isNotEmpty;
    bool isAvailable = item['status']?.toString().toLowerCase() == 'available';

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (c) => DetailedItemScreen(item: item)));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 3))],
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
                image: hasImage ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) : null,
              ),
              child: !hasImage ? const Icon(Icons.image, size: 35, color:Colors.black) : null,
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
                          maxLines: 1, overflow: TextOverflow.ellipsis,
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
                          style: TextStyle(color: isAvailable ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['title'],
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['dept'],
                    style: const TextStyle(fontSize: 11, color: Color.fromARGB(255, 0, 0, 0), fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
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

// ==================== FAVORITES SCREEN ====================
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List items = []; 
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse('http://10.174.134.39:5000/api/favorites/${currentUser!['id']}'));
      if (res.statusCode == 200) {
        setState(() {
          items = jsonDecode(res.body);
        });
      }
    } catch (e) {
      debugPrint("Favorites Fetch Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _unfavorite(int itemId) async {
    try {
      await http.post(
        Uri.parse('http://10.174.134.39:5000/api/favorites/toggle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': currentUser!['id'], 'item_id': itemId}),
      );
      _fetchFavorites(); 
    } catch (e) {
      debugPrint("Toggle Favorite Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0088),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Favorites", style: TextStyle(color: Colors.white)),
      ),
      drawer: const AppSidebar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "Favorites",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A0088),
              ),
            ),
          ),
          Expanded(
            child: isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : items.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.favorite_border, size: 80, color:Colors.black),
                          SizedBox(height: 10),
                          Text(
                            "No Saved Items",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (c, i) => _FavoriteCard(
                        item: items[i],
                        onRemoveTap: () => _unfavorite(items[i]['id']),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

// Modernized Favorites Card
class _FavoriteCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onRemoveTap;
  const _FavoriteCard({required this.item, required this.onRemoveTap});

  @override
  Widget build(BuildContext context) {
    String? imgPath = item['image'];
    bool hasImage = imgPath != null && imgPath.isNotEmpty;
    bool isAvailable = item['status']?.toString().toLowerCase() == 'available';

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (c) => DetailedItemScreen(item: item)));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 3))],
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
                image: hasImage ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) : null,
              ),
              child: !hasImage ? const Icon(Icons.image, size: 35, color:Colors.black) : null,
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
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: onRemoveTap,
                        child: const Icon(Icons.favorite, color: Colors.red, size: 22),
                      )
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['title'],
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['status'],
                    style: TextStyle(color: isAvailable ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
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

// ==================== DETAILED ITEM SCREEN ====================
class DetailedItemScreen extends StatefulWidget {
  final dynamic item;
  const DetailedItemScreen({super.key, required this.item});

  @override
  State<DetailedItemScreen> createState() => _DetailedItemScreenState();
}

class _DetailedItemScreenState extends State<DetailedItemScreen> {
  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorited();
  }

  Future<void> _checkIfFavorited() async {
    try {
      final res = await http.post(
        Uri.parse('http://10.174.134.39:5000/api/favorites/check'), // USING BASE URL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': currentUser!['id'], 'item_id': widget.item['id']}),
      );
      if (res.statusCode == 200) {
        if (mounted) setState(() => _isFavorited = jsonDecode(res.body)['is_favorite']);
      }
    } catch (e) {
      debugPrint("Check Favorite Error: $e");
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final res = await http.post(
        Uri.parse('http://10.174.134.39:5000/api/favorites/toggle'), // USING BASE URL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': currentUser!['id'], 'item_id': widget.item['id']}),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        if (mounted) setState(() => _isFavorited = jsonDecode(res.body)['is_favorite']);
      }
    } catch (e) {
      debugPrint("Toggle Favorite Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    String? imgPath = widget.item['image'];
    bool hasImage = imgPath != null && imgPath.isNotEmpty;
    bool isAvailable = widget.item['status']?.toString().toLowerCase() == 'available';

    return Scaffold(
      backgroundColor: Colors.white, // Modern white background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0088),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Item Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Modern Image Container with overlapping Heart Button
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black12, width: 1.5),
                      image: hasImage 
                        ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) 
                        : null,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: !hasImage ? const Icon(Icons.image, size: 50, color: Colors.grey) : null,
                  ),
                  
                  // The Modernized RED Heart Button
                  Positioned(
                    bottom: -15,
                    right: -15,
                    child: GestureDetector(
                      onTap: _toggleFavorite,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 3))],
                        ),
                        child: Icon(
                          _isFavorited ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorited ? Colors.red : Colors.grey.shade400, // Red when favorited!
                          size: 28,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 45), // Space for overlapping heart

            // 2. Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6), // Matches Dashboard modern grey
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailLabel("Item Name"),
                  _detailValue(widget.item['title']),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: Colors.black12)),
                  
                  _detailLabel("Owner"),
                  _detailValue(widget.item['owner']),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: Colors.black12)),
                  
                  _detailLabel("Department"),
                  _detailValue(widget.item['dept']),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: Colors.black12)),
                  
                  _detailLabel("Description"),
                  _detailValue(widget.item['description']),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Status Highlight Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: isAvailable ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: isAvailable ? Colors.green.shade200 : Colors.orange.shade200),
              ),
              child: Column(
                children: [
                  const Text("Current Status", style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(
                    widget.item['status'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isAvailable ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 35),

            // 4. Continue Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => BorrowingFormScreen(item: widget.item)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: const Text("Continue Borrowing", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _detailLabel(String t) => Text(
    t, 
    style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 12),
  );

  Widget _detailValue(String v) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      v, 
      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
    ),
  );
}

// ==================== MY ITEMS SCREEN ====================
class MyItemsScreen extends StatefulWidget {
  const MyItemsScreen({super.key});

  @override
  State<MyItemsScreen> createState() => _MyItemsScreenState();
}

class _MyItemsScreenState extends State<MyItemsScreen> {
  List items = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyItems();
  }

  Future<void> _fetchMyItems() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse('http://10.174.134.39:5000/api/items/user/${currentUser!['id']}'));
      if (res.statusCode == 200) {
        setState(() {
          items = jsonDecode(res.body);
        });
      }
    } catch (e) {
      debugPrint("My Items Fetch Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _deleteItem(int id) async {
    try {
      await http.delete(Uri.parse('http://10.174.134.39:5000/api/items/$id'));
      _fetchMyItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Delete failed")));
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
              hintText: "Search",
              prefixIcon: Icon(Icons.search, color:Colors.black),
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
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "My Items",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A0088),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.inventory_2_outlined, size: 80, color:Colors.black),
                            SizedBox(height: 10),
                            Text(
                              "No Items Yet",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:Colors.black,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 80), // Padding for FAB
                        itemCount: items.length,
                        itemBuilder: (c, i) => _MyItemCard(
                          item: items[i],
                          onDeleteConfirm: () => _deleteItem(items[i]['id']),
                          onUpdateTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (c) => EditItemScreen(item: items[i])),
                            );
                            _fetchMyItems(); // Same exact routing logic!
                          },
                        ),
                      ),
          ),
        ],
      ),
      // Modern FAB implementation
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const AddItemScreen()),
          );
          _fetchMyItems();
        },
        backgroundColor: const Color(0xFF1A0088),
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// Modernized My Items Card with sleek action buttons
class _MyItemCard extends StatefulWidget {
  final dynamic item;
  final VoidCallback onDeleteConfirm;
  final VoidCallback onUpdateTap;

  const _MyItemCard({required this.item, required this.onDeleteConfirm, required this.onUpdateTap});

  @override
  State<_MyItemCard> createState() => _MyItemCardState();
}

class _MyItemCardState extends State<_MyItemCard> {
  bool _showConfirm = false;

  @override
  Widget build(BuildContext context) {
    String? imgPath = widget.item['image'];
    bool hasImage = imgPath != null && imgPath.isNotEmpty;
    bool isAvailable = widget.item['status']?.toString().toLowerCase() == 'available';

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.black12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 3))],
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
                  image: hasImage ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) : null,
                ),
                child: !hasImage ? const Icon(Icons.image, size: 35, color:Colors.black) : null,
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
                            widget.item['title'],
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
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
                            widget.item['status'],
                            style: TextStyle(color: isAvailable ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.item['dept'],
                      style: const TextStyle(fontSize: 11, color: Color.fromARGB(251, 0, 0, 0), fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // The modernized action row: Sleek text/icon buttons instead of yellow pills!
                    if (!_showConfirm)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: widget.onUpdateTap, // UNTOUCHED ROUTING LOGIC
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text("Edit", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(foregroundColor: Colors.blue, padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                          ),
                          const SizedBox(width: 10),
                          TextButton.icon(
                            onPressed: () => setState(() => _showConfirm = true), // UNTOUCHED STATE LOGIC
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text("Delete", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(foregroundColor: Colors.red, padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                          ),
                        ],
                      )
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Modernized inline delete confirmation!
        if (_showConfirm)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 10),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Delete this item?",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _showConfirm = false),
                      style: TextButton.styleFrom(foregroundColor:Colors.black, minimumSize: const Size(40, 30)),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: widget.onDeleteConfirm, // UNTOUCHED DELETE LOGIC
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(60, 30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Confirm"),
                    )
                  ],
                )
              ],
            ),
          )
      ],
    );
  }
}

// ==================== EDIT ITEM SCREEN ====================
class EditItemScreen extends StatefulWidget {
  final dynamic item;
  const EditItemScreen({super.key, required this.item});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  String? _selectedCondition;
  String? _selectedStatus;
  String? _selectedDept;
  String? _itemPhotoPath;
  bool _isUpdating = false;

  final List<String> _lnuDepartments = [
    'Bachelor of Elementary Education', 'Bachelor of Early Childhood Education', 'Bachelor of Special Needs Education', 'Bachelor of Technology and Livelihood Education', 'Bachelor of Physical Education', 'Bachelor of Secondary Education major in English', 'Bachelor of Secondary Education major in Filipino', 'Bachelor of Secondary Education major in Mathematics', 'Bachelor of Secondary Education major in Science', 'Bachelor of Secondary Education major in Social Studies', 'Bachelor of Secondary Education major in Values Education', 'Teacher Certificate Program (TCP)', 'Bachelor of Library and Information Science', 'Bachelor of Arts in Communication', 'Bachelor of Music in Music Education', 'Bachelor of Science in Information Technology', 'Bachelor of Arts in English Language', 'Bachelor of Arts in Political Science', 'Bachelor of Science in Biology', 'Bachelor of Science in Social Work', 'Bachelor of Science in Tourism Management', 'Bachelor of Science in Hospitality Management', 'Bachelor of Science in Entrepreneurship', 'Faculty / Staff'
  ];
  final List<String> _conditions = ['New', 'Like New', 'Good', 'Fair', 'Poor'];
  final List<String> _statuses = ['Available', 'Borrowed', 'Lost', 'Flagged'];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.item['title']);
    _descCtrl = TextEditingController(text: widget.item['description']);
    _selectedCondition = widget.item['condition'];
    _selectedStatus = widget.item['status'];
    _selectedDept = widget.item['dept'];
    _itemPhotoPath = widget.item['image'];
    if (_itemPhotoPath != null && _itemPhotoPath!.isEmpty) _itemPhotoPath = null;
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _itemPhotoPath = image.path);
  }

  Future<void> _updateItem() async {
    setState(() => _isUpdating = true);
    try {
      await http.put(
        // FIXED: Using $baseUrl instead of the hardcoded IP
        Uri.parse('http://10.174.134.39:5000/api/items/${widget.item['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': _titleCtrl.text,
          'description': _descCtrl.text,
          'condition': _selectedCondition,
          'status': _selectedStatus,
          'department': _selectedDept,
          'item_image_path': _itemPhotoPath ?? ""
        }),
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Clean white background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0088),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Edit Item", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Modern Interactive Image Picker
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black12, width: 2),
                    image: _itemPhotoPath != null
                        ? DecorationImage(image: FileImage(File(_itemPhotoPath!)), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _itemPhotoPath == null 
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_a_photo_outlined, color: Color(0xFF1A0088), size: 50),
                          SizedBox(height: 10),
                          Text("Tap to update photo", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold))
                        ],
                      ) 
                    : null,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 2. Form Fields
            const Text("Item Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A0088))),
            const SizedBox(height: 15),
            
            _editItemLabel("Owner"),
            Padding(
              padding: const EdgeInsets.only(left: 5, bottom: 10),
              child: Text(widget.item['owner'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A0088))),
            ),
            
            _editItemLabel("Item Name"),
            _editItemInput(_titleCtrl),
            
            _editItemLabel("Department"),
            _editItemDropdown(_selectedDept, _lnuDepartments, (v) => setState(() => _selectedDept = v)),
            
            _editItemLabel("Description"),
            _editItemInput(_descCtrl, maxLines: 3),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _editItemLabel("Condition"),
                      _editItemDropdown(_selectedCondition, _conditions, (v) => setState(() => _selectedCondition = v)),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _editItemLabel("Status"),
                      _editItemDropdown(_selectedStatus, _statuses, (v) => setState(() => _selectedStatus = v)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            
            // 3. Update Button
            _isUpdating
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A0088)))
                : ElevatedButton(
                    onPressed: _updateItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("UPDATE ITEM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
                  ),
            const SizedBox(height: 20)
          ],
        ),
      ),
    );
  }

  // Modernized Input Labels
  Widget _editItemLabel(String t) => Padding(
    padding: const EdgeInsets.only(left: 5, bottom: 8, top: 15),
    child: Text(t, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
  );

  // Modernized Input Fields
  Widget _editItemInput(TextEditingController ctrl, {int maxLines = 1}) => TextField(
    controller: ctrl,
    maxLines: maxLines,
    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
    decoration: InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF3F4F6), 
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.black12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.black12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF1A0088), width: 1.5)),
    ),
  );

  // Modernized Dropdown
  Widget _editItemDropdown(String? val, List<String> items, Function(String?) onChanged) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.black12)
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: val,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF1A0088)),
        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
        items: items.map((c) => DropdownMenuItem(value: c, child: Text(c, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: onChanged,
      ),
    ),
  );
}
// ==================== ADD ITEM SCREEN ====================
class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: "1");
  String? _selectedCondition;
  String? _itemPhotoPath;
  bool _isPosting = false;
  final List<String> _conditions = ['New', 'Like New', 'Good', 'Fair', 'Poor'];

  Future<void> _pickItemImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _itemPhotoPath = image.path);
  }

  Future<void> _postItem() async {
    if (_titleCtrl.text.isEmpty || _descCtrl.text.isEmpty || _selectedCondition == null) return;
    setState(() => _isPosting = true);
    try {
      final res = await http.post(
        // FIXED: Swapped hardcoded IP for $baseUrl
        Uri.parse('http://10.174.134.39:5000/api/items'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': _titleCtrl.text,
          'description': _descCtrl.text,
          'quantity': _qtyCtrl.text.isEmpty ? "1" : _qtyCtrl.text,
          'condition': _selectedCondition,
          'item_image_path': _itemPhotoPath ?? "",
          'owner_name': currentUser!['full_name'],
          'department': currentUser!['department'],
          'user_id': currentUser!['id']
        }),
      );
      if (res.statusCode == 201) Navigator.pop(context);
    } finally {
      setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Clean white background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0088),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Post New Item", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Modern Interactive Image Picker
            Center(
              child: GestureDetector(
                onTap: _pickItemImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black12, width: 2), // Subtle border
                    image: _itemPhotoPath != null
                        ? DecorationImage(image: FileImage(File(_itemPhotoPath!)), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _itemPhotoPath == null 
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_a_photo_outlined, color: Color(0xFF1A0088), size: 50),
                          SizedBox(height: 10),
                          Text("Tap to upload photo", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold))
                        ],
                      ) 
                    : null,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 2. Form Fields
            const Text("Item Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A0088))),
            const SizedBox(height: 15),
            
            _addItemLabel("Item Name"),
            _addItemInput(_titleCtrl, "e.g., IT 101 Textbook"),
            
            _addItemLabel("Description"),
            _addItemInput(_descCtrl, "Details about the item...", maxLines: 3),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _addItemLabel("Quantity"),
                      _addItemInput(_qtyCtrl, "1", isNumber: true)
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _addItemLabel("Condition"),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.black12)
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCondition,
                            hint: const Text("Select", style: TextStyle(fontSize: 14)),
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF1A0088)),
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                            items: _conditions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (v) => setState(() => _selectedCondition = v),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            
            // 3. Post Button
            _isPosting
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A0088)))
                : ElevatedButton(
                    onPressed: _postItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("POST ITEM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
                  ),
            const SizedBox(height: 20)
          ],
        ),
      ),
    );
  }

  // Modernized Input Labels
  Widget _addItemLabel(String t) => Padding(
    padding: const EdgeInsets.only(left: 5, bottom: 8, top: 15),
    child: Text(t, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
  );

  // Modernized Input Fields
  Widget _addItemInput(TextEditingController ctrl, String hint, {int maxLines = 1, bool isNumber = false}) => TextField(
    controller: ctrl,
    maxLines: maxLines,
    keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
    decoration: InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF3F4F6), // Matches the modern dashboard grey
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontWeight: FontWeight.normal),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.black12), 
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF1A0088), width: 1.5), // LNU Blue highlight on focus
      ),
    ),
  );
}