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

// ==================== SHARED DESIGN CONSTANTS ====================
const Color primaryBlue = Color(0xFF1A0088);
const Color accentYellow = Color(0xFFFFD700);
const Color textDark = Color(0xFF1F2937);
const Color textLight = Color(0xFF6B7280);
const Color borderGrey = Color(0xFFE5E7EB);
const Color bgGray = Color(0xFFF8FAFC);

// ==================== SAFETY NET HELPER ====================
// VAVT-87: This prevents the app from crashing if a bad image path gets into the database
ImageProvider? getSafeImage(String? base64Str) {
  if (base64Str == null || base64Str.isEmpty || base64Str.length < 100) return null;
  try {
    return MemoryImage(base64Decode(base64Str));
  } catch (e) {
    return null; // Fallback to empty icon if decoding fails
  }
}

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
      String url = 'https://huramay-app.onrender.com/api/items';
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
      backgroundColor: bgGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: Container(
          height: 40,
          decoration: BoxDecoration(color: bgGray, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderGrey)), 
          child: TextField(
            controller: _searchCtrl,
            onChanged: (value) => _fetchDepartmentItems(), 
            style: const TextStyle(fontSize: 14, color: textDark),
            decoration: const InputDecoration(
              hintText: "Search department...",
              hintStyle: TextStyle(color: textLight, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: textLight, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ProfileScreen())),
            icon: const Icon(Icons.account_circle_outlined, size: 28, color: textDark),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderGrey, height: 1)),
      ),
      drawer: const AppSidebar(),
      body: Stack(
        children: [
          Positioned(top: -80, right: -60, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: primaryBlue.withOpacity(0.03)))),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16), 
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Department", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: textDark, letterSpacing: -0.5)),
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: borderGrey), borderRadius: BorderRadius.circular(16)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _currentFilter,
                          hint: const Text("All Status", style: TextStyle(fontSize: 13, color: textDark, fontWeight: FontWeight.w600)),
                          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: textLight),
                          alignment: Alignment.centerRight,
                          items: ['Available', 'Borrowed'].map((String value) {
                            return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 13, color: textDark, fontWeight: FontWeight.w600)));
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
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderGrey)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedDeptFilter,
                      icon: const Icon(Icons.keyboard_arrow_down, color: textLight),
                      style: const TextStyle(color: textDark, fontWeight: FontWeight.w600, fontSize: 13),
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
                  ? const Center(child: CircularProgressIndicator(color: primaryBlue)) 
                  : items.isEmpty 
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: borderGrey)),
                                child: const Icon(Icons.domain_disabled, size: 48, color: textLight),
                              ),
                              const SizedBox(height: 24),
                              const Text("No items found in this department", textAlign: TextAlign.center, style: TextStyle(color: textLight, fontSize: 16, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: items.length,
                          itemBuilder: (c, i) => _DeptItemCard(item: items[i]),
                        ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeptItemCard extends StatelessWidget {
  final dynamic item;
  const _DeptItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    ImageProvider? safeImg = getSafeImage(item['image']);
    bool isAvailable = item['status']?.toString().toLowerCase() == 'available';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => DetailedItemScreen(item: item))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderGrey),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: bgGray, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderGrey),
                image: safeImg != null ? DecorationImage(image: safeImg, fit: BoxFit.cover) : null,
              ),
              child: safeImg == null ? const Icon(Icons.image_outlined, size: 32, color: textLight) : null,
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
                        child: Text(item['owner'], style: const TextStyle(fontWeight: FontWeight.w600, color: textLight, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: isAvailable ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: isAvailable ? Colors.green.shade200 : Colors.red.shade200)),
                        child: Text(item['status'], style: TextStyle(color: isAvailable ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
                      )
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(item['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text(item['dept'], style: const TextStyle(fontSize: 12, color: textLight, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
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
      final res = await http.get(Uri.parse('https://huramay-app.onrender.com/api/favorites/${currentUser!['id']}'));
      if (res.statusCode == 200) {
        setState(() => items = jsonDecode(res.body));
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
        Uri.parse('https://huramay-app.onrender.com/api/favorites/toggle'),
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
      backgroundColor: bgGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text("Favorites", style: TextStyle(color: textDark, fontWeight: FontWeight.w800)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderGrey, height: 1)),
      ),
      drawer: const AppSidebar(),
      body: Stack(
        children: [
          Positioned(top: -80, right: -60, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: primaryBlue.withValues(alpha: 0.03)))),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Text("Saved Items", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: textDark, letterSpacing: -0.5)),
              ),
              Expanded(
                child: isLoading 
                  ? const Center(child: CircularProgressIndicator(color: primaryBlue)) 
                  : items.isEmpty 
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: borderGrey)),
                                child: const Icon(Icons.favorite_border, size: 48, color: textLight),
                              ),
                              const SizedBox(height: 24),
                              const Text("No saved items yet.", textAlign: TextAlign.center, style: TextStyle(color: textLight, fontSize: 16, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: items.length,
                          itemBuilder: (c, i) => _FavoriteCard(item: items[i], onRemoveTap: () => _unfavorite(items[i]['id'])),
                        ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onRemoveTap;
  const _FavoriteCard({required this.item, required this.onRemoveTap});

  @override
  Widget build(BuildContext context) {
    ImageProvider? safeImg = getSafeImage(item['image']);
    bool isAvailable = item['status']?.toString().toLowerCase() == 'available';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => DetailedItemScreen(item: item))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderGrey),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: bgGray, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderGrey),
                image: safeImg != null ? DecorationImage(image: safeImg, fit: BoxFit.cover) : null,
              ),
              child: safeImg == null ? const Icon(Icons.image_outlined, size: 32, color: textLight) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(item['owner'], style: const TextStyle(fontWeight: FontWeight.w600, color: textLight, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      GestureDetector(
                        onTap: onRemoveTap,
                        child: const Icon(Icons.favorite, color: Colors.red, size: 22),
                      )
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(item['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: isAvailable ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(item['status'], style: TextStyle(color: isAvailable ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 10)),
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
        Uri.parse('https://huramay-app.onrender.com/api/favorites/check'), 
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
        Uri.parse('https://huramay-app.onrender.com/api/favorites/toggle'), 
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
    ImageProvider? safeImg = getSafeImage(widget.item['image']);
    bool isAvailable = widget.item['status']?.toString().toLowerCase() == 'available';

    return Scaffold(
      backgroundColor: bgGray, 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text("Item Details", style: TextStyle(color: textDark, fontWeight: FontWeight.w800)),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderGrey, height: 1)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 160, height: 160,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderGrey, width: 1),
                      image: safeImg != null ? DecorationImage(image: safeImg, fit: BoxFit.cover) : null,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: safeImg == null ? const Icon(Icons.image_outlined, size: 64, color: textLight) : null,
                  ),
                  Positioned(
                    bottom: -15, right: -15,
                    child: GestureDetector(
                      onTap: _toggleFavorite,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle, border: Border.all(color: borderGrey),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Icon(_isFavorited ? Icons.favorite : Icons.favorite_border, color: _isFavorited ? Colors.red : textLight, size: 24),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 48),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderGrey),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailLabel("Item Name"), _detailValue(widget.item['title']),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: borderGrey)),
                  _detailLabel("Owner"), _detailValue(widget.item['owner']),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: borderGrey)),
                  _detailLabel("Department"), _detailValue(widget.item['dept']),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: borderGrey)),
                  _detailLabel("Description"), _detailValue(widget.item['description'], isLight: true),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: isAvailable ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isAvailable ? Colors.green.shade200 : Colors.orange.shade200),
              ),
              child: Column(
                children: [
                  const Text("Current Status", style: TextStyle(fontSize: 12, color: textLight, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(widget.item['status'], style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: isAvailable ? Colors.green.shade700 : Colors.orange.shade700)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => BorrowingFormScreen(item: widget.item))),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue, foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text("Continue Borrowing", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _detailLabel(String t) => Text(t, style: const TextStyle(color: textLight, fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: 0.5));
  Widget _detailValue(String v, {bool isLight = false}) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(v, style: TextStyle(color: isLight ? textDark.withValues(alpha: 0.8) : textDark, fontWeight: isLight ? FontWeight.w500 : FontWeight.bold, fontSize: 15, height: 1.4)),
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
      final res = await http.get(Uri.parse('https://huramay-app.onrender.com/api/items/user/${currentUser!['id']}'));
      if (res.statusCode == 200) {
        setState(() => items = jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint("My Items Fetch Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _deleteItem(int id) async {
    try {
      await http.delete(Uri.parse('https://huramay-app.onrender.com/api/items/$id'));
      _fetchMyItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Delete failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: Container(
          height: 40,
          decoration: BoxDecoration(color: bgGray, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderGrey)),
          child: const TextField(
            style: TextStyle(fontSize: 14, color: textDark),
            decoration: InputDecoration(
              hintText: "Search my items...",
              hintStyle: TextStyle(color: textLight, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: textLight, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ProfileScreen())),
            icon: const Icon(Icons.account_circle_outlined, size: 28, color: textDark),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderGrey, height: 1)),
      ),
      drawer: const AppSidebar(),
      body: Stack(
        children: [
          Positioned(top: -80, right: -60, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: primaryBlue.withValues(alpha: 0.03)))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Text("My Items", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: textDark, letterSpacing: -0.5)),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                    : items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: borderGrey)),
                                  child: const Icon(Icons.inventory_2_outlined, size: 48, color: textLight),
                                ),
                                const SizedBox(height: 24),
                                const Text("You haven't posted any items yet.", textAlign: TextAlign.center, style: TextStyle(color: textLight, fontSize: 16, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 100), 
                            itemCount: items.length,
                            itemBuilder: (c, i) => _MyItemCard(
                              item: items[i],
                              onDeleteConfirm: () => _deleteItem(items[i]['id']),
                              onUpdateTap: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (c) => EditItemScreen(item: items[i])));
                                _fetchMyItems(); 
                              },
                            ),
                          ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (c) => const AddItemScreen()));
          _fetchMyItems();
        },
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

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
    ImageProvider? safeImg = getSafeImage(widget.item['image']);
    bool isAvailable = widget.item['status']?.toString().toLowerCase() == 'available';

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderGrey),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: bgGray, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderGrey),
                  image: safeImg != null ? DecorationImage(image: safeImg, fit: BoxFit.cover) : null,
                ),
                child: safeImg == null ? const Icon(Icons.image_outlined, size: 32, color: textLight) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(widget.item['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: isAvailable ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: isAvailable ? Colors.green.shade200 : Colors.red.shade200)),
                          child: Text(widget.item['status'], style: TextStyle(color: isAvailable ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 10)),
                        )
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(widget.item['dept'], style: const TextStyle(fontSize: 12, color: textLight, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 12),
                    
                    if (!_showConfirm)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: widget.onUpdateTap, 
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text("Edit", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            style: TextButton.styleFrom(foregroundColor: primaryBlue, padding: EdgeInsets.zero, minimumSize: const Size(60, 30)),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => setState(() => _showConfirm = true), 
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text("Delete", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            style: TextButton.styleFrom(foregroundColor: Colors.red.shade600, padding: EdgeInsets.zero, minimumSize: const Size(60, 30)),
                          ),
                        ],
                      )
                  ],
                ),
              ),
            ],
          ),
        ),
        
        if (_showConfirm)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 12),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Delete this item permanently?", style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _showConfirm = false),
                      style: TextButton.styleFrom(foregroundColor: textDark, minimumSize: const Size(50, 32)),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: widget.onDeleteConfirm, 
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white, elevation: 0, minimumSize: const Size(60, 32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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

  // VAVT-87: Compress and Convert to Base64 instantly
  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 20);
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      setState(() => _itemPhotoPath = base64Encode(bytes));
    }
  }

  Future<void> _updateItem() async {
    final titleText = _titleCtrl.text.trim();
    final descText = _descCtrl.text.trim();

    if (!RegExp(r'^[a-zA-Z0-9\s]+$').hasMatch(titleText)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: const [Icon(Icons.error_outline, color: Colors.white), SizedBox(width: 12), Expanded(child: Text("Item name cannot contain emojis or special characters.", style: TextStyle(fontWeight: FontWeight.w600)))],), backgroundColor: Colors.red.shade700, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(20)));
      return; 
    }

    if (!RegExp(r'^[a-zA-Z0-9\s.,]+$').hasMatch(descText)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: const [Icon(Icons.error_outline, color: Colors.white), SizedBox(width: 12), Expanded(child: Text("Description cannot contain emojis or special characters (only periods and commas allowed).", style: TextStyle(fontWeight: FontWeight.w600)))],), backgroundColor: Colors.red.shade700, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(20)));
      return; 
    }

    setState(() => _isUpdating = true);
    try {
      await http.put(
        Uri.parse('https://huramay-app.onrender.com/api/items/${widget.item['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': titleText,
          'description': descText,
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
    ImageProvider? safeImg = getSafeImage(_itemPhotoPath);

    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text("Edit Item", style: TextStyle(color: textDark, fontWeight: FontWeight.w800)),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderGrey, height: 1)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity, height: 180,
                  decoration: BoxDecoration(
                    color: bgGray, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderGrey, width: 2),
                    image: safeImg != null ? DecorationImage(image: safeImg, fit: BoxFit.cover) : null,
                  ),
                  child: safeImg == null 
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_a_photo_outlined, color: textLight, size: 40),
                          SizedBox(height: 12),
                          Text("Tap to update photo", style: TextStyle(color: textLight, fontWeight: FontWeight.w600))
                        ],
                      ) 
                    : null,
                ),
              ),
            ),
            const SizedBox(height: 32),

            const Text("Item Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textDark)),
            const SizedBox(height: 16),
            
            _formLabel("Owner"),
            Padding(padding: const EdgeInsets.only(left: 4, bottom: 12), child: Text(widget.item['owner'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textLight))),
            
            _formLabel("Item Name"), _formInput(_titleCtrl),
            _formLabel("Department"), _formDropdown(_selectedDept, _lnuDepartments, (v) => setState(() => _selectedDept = v)),
            _formLabel("Description"), _formInput(_descCtrl, maxLines: 3),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_formLabel("Condition"), _formDropdown(_selectedCondition, _conditions, (v) => setState(() => _selectedCondition = v))])),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_formLabel("Status"), _formDropdown(_selectedStatus, _statuses, (v) => setState(() => _selectedStatus = v))])),
              ],
            ),
            const SizedBox(height: 40),
            
            _isUpdating
                ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                : ElevatedButton(
                    onPressed: _updateItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue, foregroundColor: Colors.white, elevation: 0,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Update Item", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
            const SizedBox(height: 24)
          ],
        ),
      ),
    );
  }

  Widget _formLabel(String t) => Padding(padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16), child: Text(t, style: const TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 13)));
  Widget _formInput(TextEditingController ctrl, {int maxLines = 1}) => TextField(
    controller: ctrl, maxLines: maxLines, style: const TextStyle(color: textDark, fontWeight: FontWeight.w500, fontSize: 14),
    decoration: InputDecoration(
      filled: true, fillColor: bgGray, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderGrey)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderGrey)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryBlue, width: 1.5)),
    ),
  );
  Widget _formDropdown(String? val, List<String> items, Function(String?) onChanged) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(color: bgGray, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderGrey)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: val, isExpanded: true, icon: const Icon(Icons.keyboard_arrow_down, color: textLight),
        style: const TextStyle(color: textDark, fontWeight: FontWeight.w500, fontSize: 14),
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

  // VAVT-87: Compress and Convert to Base64 instantly
  Future<void> _pickItemImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 20);
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      setState(() => _itemPhotoPath = base64Encode(bytes));
    }
  }

  Future<void> _postItem() async {
    final titleText = _titleCtrl.text.trim();
    final descText = _descCtrl.text.trim();
    
    if (titleText.isEmpty || descText.isEmpty || _selectedCondition == null) return;

    if (!RegExp(r'^[a-zA-Z0-9\s]+$').hasMatch(titleText)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: const [Icon(Icons.error_outline, color: Colors.white), SizedBox(width: 12), Expanded(child: Text("Item name cannot contain emojis or special characters.", style: TextStyle(fontWeight: FontWeight.w600)))],), backgroundColor: Colors.red.shade700, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(20)));
      return; 
    }

    if (!RegExp(r'^[a-zA-Z0-9\s.,]+$').hasMatch(descText)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: const [Icon(Icons.error_outline, color: Colors.white), SizedBox(width: 12), Expanded(child: Text("Description cannot contain emojis or special characters (only periods and commas allowed).", style: TextStyle(fontWeight: FontWeight.w600)))],), backgroundColor: Colors.red.shade700, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(20)));
      return; 
    }

    setState(() => _isPosting = true);
    try {
      final res = await http.post(
        Uri.parse('https://huramay-app.onrender.com/api/items'),
        headers: {'Content-Type': 'application/json'},  
        body: jsonEncode({
          'title': titleText,
          'description': descText,
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
    ImageProvider? safeImg = getSafeImage(_itemPhotoPath);

    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text("Post New Item", style: TextStyle(color: textDark, fontWeight: FontWeight.w800)),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderGrey, height: 1)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickItemImage,
                child: Container(
                  width: double.infinity, height: 180,
                  decoration: BoxDecoration(
                    color: bgGray, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderGrey, width: 2),
                    image: safeImg != null ? DecorationImage(image: safeImg, fit: BoxFit.cover) : null,
                  ),
                  child: safeImg == null 
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_a_photo_outlined, color: textLight, size: 40),
                          SizedBox(height: 12),
                          Text("Tap to upload photo", style: TextStyle(color: textLight, fontWeight: FontWeight.w600))
                        ],
                      ) 
                    : null,
                ),
              ),
            ),
            const SizedBox(height: 32),

            const Text("Item Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textDark)),
            const SizedBox(height: 16),
            
            _formLabel("Item Name"), _formInput(_titleCtrl, hint: "e.g., IT 101 Textbook"),
            _formLabel("Description"), _formInput(_descCtrl, hint: "Details about the item...", maxLines: 3),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 1, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_formLabel("Quantity"), _formInput(_qtyCtrl, isNumber: true)])),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _formLabel("Condition"),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(color: bgGray, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderGrey)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCondition, hint: const Text("Select", style: TextStyle(fontSize: 14, color: textLight)),
                            isExpanded: true, icon: const Icon(Icons.keyboard_arrow_down, color: textLight),
                            style: const TextStyle(color: textDark, fontWeight: FontWeight.w500, fontSize: 14),
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
            
            _isPosting
                ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                : ElevatedButton(
                    onPressed: _postItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue, foregroundColor: Colors.white, elevation: 0,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Post Item", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
            const SizedBox(height: 24)
          ],
        ),
      ),
    );
  }

  Widget _formLabel(String t) => Padding(padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16), child: Text(t, style: const TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 13)));
  Widget _formInput(TextEditingController ctrl, {String hint = "", int maxLines = 1, bool isNumber = false}) => TextField(
    controller: ctrl, maxLines: maxLines, keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
    style: const TextStyle(color: textDark, fontWeight: FontWeight.w500, fontSize: 14),
    decoration: InputDecoration(
      filled: true, fillColor: bgGray, hintText: hint, hintStyle: const TextStyle(color: textLight, fontWeight: FontWeight.normal),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderGrey)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderGrey)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryBlue, width: 1.5)),
    ),
  );
}