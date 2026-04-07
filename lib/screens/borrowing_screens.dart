// lib/screens/borrowing_screens.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../globals.dart';
import '../widgets/app_sidebar.dart';
import 'auth_screens.dart';
import 'chat_screens.dart';
import 'dashboard_screen.dart';

// ==================== REQUESTS SCREEN ====================
class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  List requests = []; 
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => isLoading = true);
    try {
      // FIX 1: Use $baseUrl to ensure it works perfectly in Chrome and Render
      final res = await http.get(
        Uri.parse('http://10.174.134.39:5000/api/borrow/requests/owner/${currentUser!['id']}'),
      );
      
      if (res.statusCode == 200) {
        setState(() {
          // FIX 2: .reversed.toList() flips the list so the newest items are at the top!
          requests = jsonDecode(res.body).reversed.toList();
        });
      }
    } catch (e) {
      debugPrint("Requests Fetch Error: $e");
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
          child: const TextField(
            decoration: InputDecoration(
              hintText: "Search",
              prefixIcon: Icon(Icons.search, color: Colors.grey),
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
      drawer: const AppSidebar(), // Keeping your side menu intact
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "Requests",
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
              : requests.isEmpty 
                  ? const Center(
                      child: Text(
                        "No Pending Requests",
                        style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    )
                  : ListView.builder(
                      itemCount: requests.length,
                      itemBuilder: (c, i) => _RequestCard(
                        requestData: requests[i],
                        onStatusChanged: _fetchRequests,
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  final dynamic requestData;
  final VoidCallback onStatusChanged;

  const _RequestCard({required this.requestData, required this.onStatusChanged});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  late String currentStatus;

  @override
  void initState() {
    super.initState();
    currentStatus = widget.requestData['status'];
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      final res = await http.put(
        Uri.parse('http://10.174.134.39:5000/api/borrow/request/${widget.requestData['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': newStatus}),
      );
      if (res.statusCode == 200) {
        setState(() => currentStatus = newStatus);
        widget.onStatusChanged(); 
      }
    } catch (e) {
      debugPrint("Update Status Error: $e");
    }
  }

  void _showDetailOverlay() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RequestDetailDialog(
          requestData: widget.requestData,
          currentStatus: currentStatus,
          onAccept: () {
            _updateStatus('Accepted');
            Navigator.pop(context);
          },
          onDecline: () {
            _updateStatus('Declined');
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _confirmReturn() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Item Returned?", style: TextStyle(color: Color(0xFF1A0088), fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you have received the item back from the borrower? \n\nThis will make the item available on the feed again and allow the borrower to leave a review."),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey, 
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
            ),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus('Returned');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
            ),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    dynamic item = widget.requestData['item'];
    String? imgPath = item['image'];
    bool hasImage = imgPath != null && imgPath.isNotEmpty;

    // Dynamic color system for the Status Pill
    Color statusColor;
    Color statusBgColor;
    
    if (currentStatus.toLowerCase() == 'returned') {
      statusColor = Colors.green;
      statusBgColor = Colors.green.shade50;
    } else if (currentStatus.toLowerCase() == 'pending') {
      statusColor = Colors.orange;
      statusBgColor = Colors.orange.shade50;
    } else if (currentStatus.toLowerCase() == 'declined') {
      statusColor = Colors.red;
      statusBgColor = Colors.red.shade50;
    } else if (currentStatus.toLowerCase() == 'accepted') {
      statusColor = Colors.blue;
      statusBgColor = Colors.blue.shade50;
    } else {
      statusColor = const Color(0xFF1A0088);
      statusBgColor = Colors.blue.shade50;
    }

    return GestureDetector(
      onTap: _showDetailOverlay,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6), // Modern Dashboard Grey
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black12, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 3))]
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Clean White Image Box
            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor, width: 1.5), // Colored border matches the status
                image: hasImage ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) : null,
              ),
              child: !hasImage ? const Icon(Icons.image, size: 30, color: Colors.grey) : null,
            ),
            const SizedBox(width: 15),
            
            // Right: Details and Actions
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Name & Status Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.requestData['full_name'] ?? "Unknown",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A0088), fontSize: 13),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 5),
                      // Modern Dynamic Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor, width: 1),
                        ),
                        child: Text(
                          currentStatus,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Row 2: Department
                  Text(
                    widget.requestData['department'] ?? "No Department",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  
                  // Row 3: Dates
                  Text(
                    "${widget.requestData['start_date']} - ${widget.requestData['end_date']}",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),

                  // Row 4: Buttons docked at the bottom
                  if (currentStatus == 'Pending' || currentStatus == 'Accepted') ...[
                    const SizedBox(height: 12),
                    
                    if (currentStatus == 'Pending') 
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _updateStatus('Accepted'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A0088), 
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 30),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              child: const Text("Accept", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _updateStatus('Declined'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red, width: 1), 
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 30),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              child: const Text("Decline", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      )
                    else if (currentStatus == 'Accepted')
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (c) => ChatRoomScreen(
                                      chatRoomId: widget.requestData['id'],
                                      otherId: widget.requestData['borrower_id'], 
                                      otherName: widget.requestData['full_name'],
                                      itemName: item['title'],
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.chat_bubble_outline, size: 14),
                              label: const Text("Message", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 30),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _confirmReturn,
                              icon: const Icon(Icons.check_circle_outline, size: 14),
                              label: const Text("Returned", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 30),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ] else ...[
                     const SizedBox(height: 12),
                     const Text(
                       "Tap to view details", 
                       style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)
                     ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== REQUEST DETAIL DIALOG (Modernized) ====================
class RequestDetailDialog extends StatelessWidget {
  final dynamic requestData;
  final String currentStatus;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const RequestDetailDialog({
    super.key,
    required this.requestData,
    required this.currentStatus,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    dynamic item = requestData['item'];
    String? imgPath = item['image'];
    bool hasImage = imgPath != null && imgPath.isNotEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
          ]
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50, 
                      shape: BoxShape.circle
                    ),
                    child: const Icon(Icons.close, size: 18, color: Color(0xFF1A0088)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFF1A0088), width: 3),
                  image: hasImage 
                    ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) 
                    : null,
                ),
                child: !hasImage ? const Icon(Icons.image, size: 50, color: Colors.grey) : null,
              ),
              const SizedBox(height: 25),
              _detailLabel("Full Name"),
              _detailValue(requestData['full_name']),
              const SizedBox(height: 15),
              _detailLabel("Department"),
              _detailValue(requestData['department']),
              const SizedBox(height: 15),
              _detailLabel("Start Date"),
              _detailValue(requestData['start_date']),
              const SizedBox(height: 15),
              _detailLabel("End Date"),
              _detailValue(requestData['end_date']),
              const SizedBox(height: 15),
              _detailLabel("Meetup Location"),
              _detailValue(requestData['meetup_location']),
              const SizedBox(height: 30),
              if (currentStatus == 'Pending')
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: onDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        minimumSize: const Size(110, 45),
                      ),
                      child: const Text("Decline", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A0088),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        minimumSize: const Size(110, 45),
                        elevation: 0,
                      ),
                      child: const Text("Accept", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailLabel(String t) => Text(
    t, 
    style: const TextStyle(color: Color(0xFF1A0088), fontWeight: FontWeight.bold, fontSize: 13),
  );

  Widget _detailValue(String v) => Text(
    v, 
    textAlign: TextAlign.center, 
    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
  );
}

// ==================== BORROWING PIPELINE ====================
class BorrowingFormScreen extends StatefulWidget {
  final dynamic item;
  const BorrowingFormScreen({super.key, required this.item});
  @override
  State<BorrowingFormScreen> createState() => _BorrowingFormScreenState();
}

class _BorrowingFormScreenState extends State<BorrowingFormScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _deptCtrl;
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  final _proofCtrl = TextEditingController();
  
  final List<String> _locations = [
    'MIS/ITSO', 'IGP Canteen', 'ORC Quadrangle', 'Bleachers', 
    'Student Center 2F', 'Alba Hall', 'Montejo Parking Lot', 
    'HUM Building', 'Paterno Campus Canteen', 'New Library', 
    'ACAD Building', 'CON Building', 'CME Building', 
    'LNU Dormitory', 'Hotel Cresencia', 'Youngfield Canteen'
  ];
  String? _selectedLocation;
  String? _proofPath;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: currentUser?['full_name'] ?? "");
    _deptCtrl = TextEditingController(text: currentUser?['department'] ?? "");
    _selectedLocation = _locations.first;
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    DateTime? picked = await showDatePicker(
        context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
    if (picked != null) {
      setState(() => ctrl.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}");
    }
  }

  Future<void> _pickProof() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _proofCtrl.text = image.path.split('/').last;
        _proofPath = image.path;
      });
    }
  }

  void _proceedToTerms() {
    if (_startCtrl.text.isEmpty || _endCtrl.text.isEmpty || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all required fields.")));
      return;
    }
    final borrowData = {
      "item_id": widget.item['id'],
      "borrower_id": currentUser!['id'],
      "full_name": _nameCtrl.text,
      "department": _deptCtrl.text,
      "start_date": _startCtrl.text,
      "end_date": _endCtrl.text,
      "proof_of_id_path": _proofPath,
      "meetup_location": _selectedLocation
    };
    Navigator.push(context, MaterialPageRoute(builder: (c) => TermsScreen(item: widget.item, borrowData: borrowData)));
  }

  @override
  Widget build(BuildContext context) {
    String? imgPath = widget.item['image'];
    bool hasImage = imgPath != null && imgPath.isNotEmpty;
    
    return Scaffold(
      backgroundColor: Colors.white, // Modern white background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0088),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Borrowing Form", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black12, width: 2),
                  image: hasImage ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) : null,
                ),
                child: !hasImage ? const Icon(Icons.image, size: 40, color: Colors.grey) : null,
              ),
            ),
            const SizedBox(height: 30),
            _modernInputLabel("Full Name"),
            _modernPillInput(_nameCtrl, isReadOnly: true),
            _modernInputLabel("Department"),
            _modernPillInput(_deptCtrl, isReadOnly: true),
            _modernInputLabel("Start Date"),
            _modernPillInput(_startCtrl, isReadOnly: true, onTap: () => _pickDate(_startCtrl), suffixIcon: Icons.calendar_today),
            _modernInputLabel("End Date"),
            _modernPillInput(_endCtrl, isReadOnly: true, onTap: () => _pickDate(_endCtrl), suffixIcon: Icons.calendar_today),
            _modernInputLabel("Proof of ID"),
            _modernPillInput(_proofCtrl, isReadOnly: true, onTap: _pickProof, suffixIcon: Icons.file_upload_outlined),
            _modernInputLabel("Meetup (LNU Campus Only)"),
            _buildModernLocationDropdown(),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _proceedToTerms,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 55),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), 
              ),
              child: const Text("CONTINUE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1)),
            ),
            const SizedBox(height: 20)
          ],
        ),
      ),
    );
  }

  Widget _modernInputLabel(String t) => Padding(
    padding: const EdgeInsets.only(left: 5, bottom: 8, top: 10),
    child: Text(t, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
  );

  Widget _modernPillInput(TextEditingController ctrl, {bool isReadOnly = false, VoidCallback? onTap, IconData? suffixIcon}) => TextField(
    controller: ctrl, readOnly: isReadOnly, onTap: onTap,
    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
    decoration: InputDecoration(
      filled: true, fillColor: const Color(0xFFF3F4F6),
      suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: const Color(0xFF1A0088), size: 20) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.black12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.black12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF1A0088), width: 1.5)),
    ),
  );

  Widget _buildModernLocationDropdown() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.black12)),
    child: DropdownButtonHideUnderline(
      child: DropdownButtonFormField<String>(
        value: _selectedLocation,
        decoration: const InputDecoration(border: InputBorder.none),
        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF1A0088)),
        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
        items: _locations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc))).toList(),
        onChanged: (v) => setState(() => _selectedLocation = v),
      ),
    ),
  );
}

// ==================== TERMS SCREEN (Modernized) ====================
class TermsScreen extends StatefulWidget {
  final dynamic item;
  final Map<String, dynamic> borrowData;
  const TermsScreen({super.key, required this.item, required this.borrowData});
  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _isChecked = false;
  bool _isSubmitting = false;

  Future<void> _submitRequest() async {
    if (!_isChecked) return;
    setState(() => _isSubmitting = true);
    try {
      final res = await http.post(
        Uri.parse('http://10.174.134.39:5000/api/borrow/request'), // Using $baseUrl dynamically!
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(widget.borrowData),
      );
      if (res.statusCode == 201) {
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => BorrowSuccessScreen(item: widget.item)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String? imgPath = widget.item['image'];
    bool hasImage = imgPath != null && imgPath.isNotEmpty;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0088),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Terms & Conditions", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 25),
          Center(
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.black12, width: 2),
                image: hasImage ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) : null,
              ),
              child: !hasImage ? const Icon(Icons.image, size: 30, color: Colors.grey) : null,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 25).copyWith(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6), 
                borderRadius: BorderRadius.circular(20), 
                border: Border.all(color: Colors.black12)
              ),
              child: Column(
                children: [
                  const Expanded(
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Text(
                        "Huramay: A Mobile-Based Peer-to-Peer Academic Resource Exchange for LNU Students \n\nI. Acceptance of Responsibility \n\nBy proceeding with this request, the borrower acknowledges and accepts full responsibility for the academic resource identified in the listing. The borrower commits to treating the item with the utmost care and ensuring it remains in the same condition as documented at the time of the handover. Any pre-existing damages must be acknowledged by both parties during the physical exchange to avoid future disputes. The borrower understands that this item is being provided as a gesture of academic support within the LNU community and must not be used for any purpose that violates university policies. \n\nII. Liability and Accountability \n\nIn the event of loss, theft, or significant damage to the borrowed resource, the borrower agrees to be held liable for the repair or replacement of the item as negotiated with the lender. While the Huramay platform facilitates the connection, the legal and moral obligation to rectify damages rests solely on the borrower. Furthermore, the borrower understands that their Trust Rating is a permanent record within the local database; failure to return the item by the specified deadline or returning a damaged item will result in a formal deduction of rating points, which may limit their future access to the platform’s resources. \n\nIII. Code of Conduct and Safety \n\nAll transactions and physical handovers must take place within the designated landmarks of the Leyte Normal University (LNU) Tacloban Campus during official operating hours to ensure the safety and transparency of both parties. This agreement strictly prohibits the exchange of monetary fees or services in return for borrowing; Huramay is a non-commercial, peer-to-peer academic exchange. Both users agree to maintain professional and respectful communication through the integrated P2P chat and to promptly report any fraudulent activity or 'no-show' behavior to the project administrators.",
                        style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const Divider(height: 30, color: Colors.black12),
                  Row(
                    children: [
                      Checkbox(
                        value: _isChecked, 
                        activeColor: const Color(0xFF1A0088), 
                        onChanged: (v) => setState(() => _isChecked = v ?? false)
                      ),
                      const Expanded(
                        child: Text("I agree to the Huramay terms and conditions.", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87))
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(25),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Color(0xFF1A0088))
                : ElevatedButton(
                    onPressed: _isChecked ? _submitRequest : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isChecked ? Colors.yellow : Colors.grey.shade300,
                      foregroundColor: _isChecked ? Colors.black : Colors.grey.shade600,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    child: const Text("SUBMIT REQUEST", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
          ),
        ],
      ),
    );
  }
}

// ==================== SUCCESS SCREEN (Modernized) ====================
class BorrowSuccessScreen extends StatelessWidget {
  final dynamic item;
  const BorrowSuccessScreen({super.key, required this.item});
  @override
  Widget build(BuildContext context) {
    String? imgPath = item['image'];
    bool hasImage = imgPath != null && imgPath.isNotEmpty;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
              ),
              const SizedBox(height: 30),
              const Text("Request Sent!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A0088))),
              const SizedBox(height: 15),
              const Text(
                "Your request has been sent to the owner. Please wait for their approval in your History tab.", 
                textAlign: TextAlign.center, 
                style: TextStyle(color: Colors.black54, fontSize: 15, height: 1.4)
              ),
              const SizedBox(height: 40),
              Center(
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.black12, width: 2),
                    image: hasImage ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) : null,
                  ),
                  child: !hasImage ? const Icon(Icons.image, size: 40, color: Colors.grey) : null,
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const DashboardScreen()), (route) => false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A0088),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("BACK TO DASHBOARD", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              )
            ],
          ),
        ),
      ),
    );
  }
}