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

// ==================== SHARED DESIGN CONSTANTS ====================
const Color primaryBlue = Color(0xFF1A0088);
const Color accentYellow = Color(0xFFFFD700);
const Color textDark = Color(0xFF1F2937);
const Color textLight = Color(0xFF6B7280);
const Color borderGrey = Color(0xFFE5E7EB);
const Color bgGray = Color(0xFFF8FAFC);

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
      final res = await http.get(
        Uri.parse('https://huramay-app.onrender.com/api/borrow/requests/owner/${currentUser!['id']}'),
      );
      
      if (res.statusCode == 200) {
        setState(() {
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
              hintText: "Search requests...",
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
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Text("Requests", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: textDark, letterSpacing: -0.5)),
              ),
              Expanded(
                child: isLoading 
                  ? const Center(child: CircularProgressIndicator(color: primaryBlue)) 
                  : requests.isEmpty 
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: borderGrey)),
                                child: const Icon(Icons.notifications_none, size: 48, color: textLight),
                              ),
                              const SizedBox(height: 24),
                              const Text("No pending requests.", style: TextStyle(color: textLight, fontSize: 16, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: requests.length,
                          itemBuilder: (c, i) => _RequestCard(
                            requestData: requests[i],
                            onStatusChanged: _fetchRequests,
                          ),
                        ),
              ),
            ],
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
        Uri.parse('https://huramay-app.onrender.com/api/borrow/request/${widget.requestData['id']}'),
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
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Item Returned?", style: TextStyle(color: textDark, fontWeight: FontWeight.w800)),
        content: const Text("Are you sure you have received the item back from the borrower? \n\nThis will make the item available on the feed again and allow the borrower to leave a review.", style: TextStyle(color: textLight, fontSize: 14)),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              foregroundColor: textDark, 
              side: const BorderSide(color: borderGrey, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus('Returned');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600, 
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            child: const Text("Confirm Return", style: TextStyle(fontWeight: FontWeight.w600)),
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

    Color statusColor;
    Color statusBgColor;
    
    if (currentStatus.toLowerCase() == 'returned') {
      statusColor = Colors.green.shade700;
      statusBgColor = Colors.green.shade50;
    } else if (currentStatus.toLowerCase() == 'pending') {
      statusColor = Colors.orange.shade700;
      statusBgColor = Colors.orange.shade50;
    } else if (currentStatus.toLowerCase() == 'declined') {
      statusColor = Colors.red.shade700;
      statusBgColor = Colors.red.shade50;
    } else if (currentStatus.toLowerCase() == 'accepted') {
      statusColor = primaryBlue;
      statusBgColor = primaryBlue.withOpacity(0.1);
    } else {
      statusColor = textLight;
      statusBgColor = bgGray;
    }

    return GestureDetector(
      onTap: _showDetailOverlay,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderGrey, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: bgGray,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderGrey, width: 1), 
                image: hasImage ? DecorationImage(image: FileImage(File(imgPath)), fit: BoxFit.cover) : null,
              ),
              child: !hasImage ? const Icon(Icons.image_outlined, size: 32, color: textLight) : null,
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.requestData['full_name'] ?? "Unknown",
                          style: const TextStyle(fontWeight: FontWeight.w800, color: textDark, fontSize: 14),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
                        ),
                        child: Text(
                          currentStatus,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.requestData['department'] ?? "No Department",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textLight),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${widget.requestData['start_date']} to ${widget.requestData['end_date']}",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textDark),
                  ),

                  if (currentStatus == 'Pending' || currentStatus == 'Accepted') ...[
                    const SizedBox(height: 16),
                    
                    if (currentStatus == 'Pending') 
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _updateStatus('Declined'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade600,
                                side: BorderSide(color: borderGrey, width: 1), 
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 36),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text("Decline", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _updateStatus('Accepted'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue, 
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 36),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text("Accept", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
                              label: const Text("Message", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: textDark,
                                elevation: 0,
                                side: BorderSide(color: borderGrey),
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 36),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _confirmReturn,
                              icon: const Icon(Icons.check_circle_outline, size: 14),
                              label: const Text("Returned", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 36),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
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

// ==================== REQUEST DETAIL DIALOG ====================
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
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Request Details", style: TextStyle(color: textDark, fontWeight: FontWeight.w800, fontSize: 18)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: bgGray, shape: BoxShape.circle, border: Border.all(color: borderGrey)),
                      child: const Icon(Icons.close, size: 18, color: textLight),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: bgGray,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderGrey, width: 1),
                  image: hasImage ? DecorationImage(image: FileImage(File(imgPath)), fit: BoxFit.cover) : null,
                ),
                child: !hasImage ? const Icon(Icons.image_outlined, size: 40, color: textLight) : null,
              ),
              const SizedBox(height: 32),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: bgGray, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderGrey)),
                child: Column(
                  children: [
                    _detailRow("Borrower", requestData['full_name']),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: borderGrey)),
                    _detailRow("Department", requestData['department']),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: borderGrey)),
                    _detailRow("Duration", "${requestData['start_date']} to ${requestData['end_date']}"),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: borderGrey)),
                    _detailRow("Meetup", requestData['meetup_location']),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              if (currentStatus == 'Pending')
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onDecline,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textDark,
                          side: const BorderSide(color: borderGrey, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(0, 48),
                        ),
                        child: const Text("Decline", style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(0, 48),
                          elevation: 0,
                        ),
                        child: const Text("Accept Request", style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(color: textLight, fontWeight: FontWeight.w500, fontSize: 13))),
        Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(color: textDark, fontWeight: FontWeight.w700, fontSize: 14))),
      ],
    );
  }
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
      backgroundColor: Colors.white, 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text("Borrowing Form", style: TextStyle(color: textDark, fontWeight: FontWeight.w800)),
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
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: bgGray,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderGrey, width: 1),
                  image: hasImage ? DecorationImage(image: FileImage(File(imgPath)), fit: BoxFit.cover) : null,
                ),
                child: !hasImage ? const Icon(Icons.image_outlined, size: 40, color: textLight) : null,
              ),
            ),
            const SizedBox(height: 32),
            _modernInputLabel("Full Name"), _modernPillInput(_nameCtrl, isReadOnly: true),
            _modernInputLabel("Department"), _modernPillInput(_deptCtrl, isReadOnly: true),
            _modernInputLabel("Start Date"), _modernPillInput(_startCtrl, isReadOnly: true, onTap: () => _pickDate(_startCtrl), suffixIcon: Icons.calendar_today_outlined),
            _modernInputLabel("End Date"), _modernPillInput(_endCtrl, isReadOnly: true, onTap: () => _pickDate(_endCtrl), suffixIcon: Icons.calendar_today_outlined),
            _modernInputLabel("Proof of ID"), _modernPillInput(_proofCtrl, isReadOnly: true, onTap: _pickProof, suffixIcon: Icons.file_upload_outlined),
            _modernInputLabel("Meetup (LNU Campus Only)"), _buildModernLocationDropdown(),
            const SizedBox(height: 48),
            
            ElevatedButton(
              onPressed: _proceedToTerms,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
              ),
              child: const Text("Continue", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            const SizedBox(height: 24)
          ],
        ),
      ),
    );
  }

  Widget _modernInputLabel(String t) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
    child: Text(t, style: const TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 13)),
  );

  Widget _modernPillInput(TextEditingController ctrl, {bool isReadOnly = false, VoidCallback? onTap, IconData? suffixIcon}) => TextField(
    controller: ctrl, readOnly: isReadOnly, onTap: onTap,
    style: const TextStyle(color: textDark, fontWeight: FontWeight.w500, fontSize: 14),
    decoration: InputDecoration(
      filled: true, fillColor: bgGray,
      suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: textLight, size: 20) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderGrey)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderGrey)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryBlue, width: 1.5)),
    ),
  );

  Widget _buildModernLocationDropdown() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(color: bgGray, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderGrey)),
    child: DropdownButtonHideUnderline(
      child: DropdownButtonFormField<String>(
        value: _selectedLocation,
        decoration: const InputDecoration(border: InputBorder.none),
        icon: const Icon(Icons.keyboard_arrow_down, color: textLight),
        style: const TextStyle(color: textDark, fontWeight: FontWeight.w500, fontSize: 14),
        items: _locations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc))).toList(),
        onChanged: (v) => setState(() => _selectedLocation = v),
      ),
    ),
  );
}

// ==================== TERMS SCREEN ====================
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
        Uri.parse('https://huramay-app.onrender.com/api/borrow/request'),
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
      backgroundColor: bgGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text("Terms & Conditions", style: TextStyle(color: textDark, fontWeight: FontWeight.w800)),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderGrey, height: 1)),
      ),
      body: Column(
        children: [
          const SizedBox(height: 32),
          Center(
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderGrey, width: 1),
                image: hasImage ? DecorationImage(image: FileImage(File(imgPath)), fit: BoxFit.cover) : null,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
              ),
              child: !hasImage ? const Icon(Icons.image_outlined, size: 32, color: textLight) : null,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(20), 
                border: Border.all(color: borderGrey),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
              ),
              child: Column(
                children: [
                  const Expanded(
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Text(
                        "Huramay: A Mobile-Based Peer-to-Peer Academic Resource Exchange for LNU Students \n\nI. Acceptance of Responsibility \n\nBy proceeding with this request, the borrower acknowledges and accepts full responsibility for the academic resource identified in the listing. The borrower commits to treating the item with the utmost care and ensuring it remains in the same condition as documented at the time of the handover. Any pre-existing damages must be acknowledged by both parties during the physical exchange to avoid future disputes. The borrower understands that this item is being provided as a gesture of academic support within the LNU community and must not be used for any purpose that violates university policies. \n\nII. Liability and Accountability \n\nIn the event of loss, theft, or significant damage to the borrowed resource, the borrower agrees to be held liable for the repair or replacement of the item as negotiated with the lender. While the Huramay platform facilitates the connection, the legal and moral obligation to rectify damages rests solely on the borrower. Furthermore, the borrower understands that their Trust Rating is a permanent record within the local database; failure to return the item by the specified deadline or returning a damaged item will result in a formal deduction of rating points, which may limit their future access to the platform’s resources. \n\nIII. Code of Conduct and Safety \n\nAll transactions and physical handovers must take place within the designated landmarks of the Leyte Normal University (LNU) Tacloban Campus during official operating hours to ensure the safety and transparency of both parties. This agreement strictly prohibits the exchange of monetary fees or services in return for borrowing; Huramay is a non-commercial, peer-to-peer academic exchange. Both users agree to maintain professional and respectful communication through the integrated P2P chat and to promptly report any fraudulent activity or 'no-show' behavior to the project administrators.",
                        style: TextStyle(color: textDark, fontSize: 13, height: 1.6, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const Divider(height: 32, color: borderGrey),
                  Row(
                    children: [
                      SizedBox(
                        width: 24, height: 24,
                        child: Checkbox(
                          value: _isChecked, 
                          activeColor: primaryBlue, 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (v) => setState(() => _isChecked = v ?? false)
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text("I agree to the Huramay terms and conditions.", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textDark))
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: primaryBlue)
                : ElevatedButton(
                    onPressed: _isChecked ? _submitRequest : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: borderGrey,
                      disabledForegroundColor: textLight,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text("Submit Request", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
          ),
        ],
      ),
    );
  }
}

// ==================== SUCCESS SCREEN ====================
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
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                child: Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 80),
              ),
              const SizedBox(height: 32),
              const Text("Request Sent!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: textDark, letterSpacing: -0.5)),
              const SizedBox(height: 16),
              const Text(
                "Your request has been sent to the owner. Please wait for their approval in your History tab.", 
                textAlign: TextAlign.center, 
                style: TextStyle(color: textLight, fontSize: 15, height: 1.5, fontWeight: FontWeight.w500)
              ),
              const SizedBox(height: 48),
              Center(
                child: Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(
                    color: bgGray,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderGrey, width: 1),
                    image: hasImage ? DecorationImage(image: FileImage(File(imgPath)), fit: BoxFit.cover) : null,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]
                  ),
                  child: !hasImage ? const Icon(Icons.image_outlined, size: 48, color: textLight) : null,
                ),
              ),
              const SizedBox(height: 64),
              ElevatedButton(
                onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const DashboardScreen()), (route) => false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Back to Dashboard", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }
}