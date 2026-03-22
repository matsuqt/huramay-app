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

// ==================== REQUESTS SCREEN (VAVT-48) ====================
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
      // PRO FIX: Using baseUrl for reliability
      final res = await http.get(
        Uri.parse('http://10.33.87.39:5000/api/borrow/requests/owner/${currentUser!['id']}'),
      );
      if (res.statusCode == 200) {
        setState(() {
          requests = jsonDecode(res.body);
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
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "Request",
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
                        style: TextStyle(fontSize: 20, color: Colors.grey),
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
        Uri.parse('http://10.33.87.39:5000/api/borrow/request/${widget.requestData['id']}'),
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

  @override
  Widget build(BuildContext context) {
    dynamic item = widget.requestData['item'];
    String? imgPath = item['image'];
    bool hasImage = imgPath != null && imgPath.isNotEmpty;
    
    Color acceptColor = currentStatus == 'Accepted' ? Colors.green : Colors.yellow;
    Color declineColor = currentStatus == 'Declined' ? Colors.red : Colors.yellow;
    String acceptText = currentStatus == 'Accepted' ? "Accepted" : "Accept";
    String declineText = currentStatus == 'Declined' ? "Declined" : "Decline";

    return GestureDetector(
      onTap: _showDetailOverlay,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 120,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF1A0088), width: 3),
                image: hasImage 
                  ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) 
                  : null,
              ),
              child: !hasImage ? const Icon(Icons.image, size: 40, color: Colors.grey) : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.requestData['full_name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A0088), fontSize: 13),
                    ),
                    Text(
                      widget.requestData['department'],
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    Text(
                      "${widget.requestData['start_date']} - ${widget.requestData['end_date']}",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const Text(
                      "Borrowing",
                      style: TextStyle(color: Color(0xFF1A0088), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        if (currentStatus == 'Pending') ...[
                          _actionBtn(acceptText, acceptColor, () => _updateStatus('Accepted')),
                          const SizedBox(width: 10),
                          _actionBtn(declineText, declineColor, () => _updateStatus('Declined')),
                        ],
                        if (currentStatus == 'Accepted')
                          _actionBtn("Message", Colors.blue, () {
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
                          }),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(String t, Color c, Function() action) {
    return GestureDetector(
      onTap: action,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black87, width: 1),
        ),
        child: Text(
          t,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
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
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black),
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
                    decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 140,
                height: 160,
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
              _detailLabel("Proof of ID"),
              const Icon(Icons.assignment_ind, size: 40, color: Colors.white),
              const SizedBox(height: 15),
              _detailLabel("Meetup"),
              _detailValue(requestData['meetup_location']),
              const SizedBox(height: 30),
              if (currentStatus == 'Pending')
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25), 
                          side: const BorderSide(color: Colors.black),
                        ),
                      ),
                      child: const Text("Accept", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: onDecline,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25), 
                          side: const BorderSide(color: Colors.black),
                        ),
                      ),
                      child: const Text("Decline", style: TextStyle(fontWeight: FontWeight.bold)),
                    )
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
    style: const TextStyle(color: Color(0xFF1A0088), fontWeight: FontWeight.bold, fontSize: 14),
  );

  Widget _detailValue(String v) => Text(
    v, 
    textAlign: TextAlign.center, 
    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
  );
}

// ==================== BORROWING PIPELINE (UPDATED VAVT-65) ====================
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
  
  // TICKET VAVT-65: Locations List
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
    // Default the dropdown to the first location
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
      "meetup_location": _selectedLocation // Using dropdown value
    };
    Navigator.push(context, MaterialPageRoute(builder: (c) => TermsScreen(item: widget.item, borrowData: borrowData)));
  }

  @override
  Widget build(BuildContext context) {
    String? imgPath = widget.item['image'];
    bool hasImage = imgPath != null && imgPath.isNotEmpty;
    return Scaffold(
      backgroundColor: const Color(0xFF1A0088),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text("Huramay", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 5),
            const Text("Borrowing Form", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            Container(
              width: 120,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.yellow, width: 3),
                image: hasImage ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) : null,
              ),
              child: !hasImage ? const Icon(Icons.image, size: 40, color: Colors.grey) : null,
            ),
            const SizedBox(height: 30),
            _yellowPillInput("Full Name", _nameCtrl, isReadOnly: true),
            _yellowPillInput("Department", _deptCtrl, isReadOnly: true),
            _yellowPillInput("Start date", _startCtrl, isReadOnly: true, onTap: () => _pickDate(_startCtrl), suffixIcon: Icons.calendar_today),
            _yellowPillInput("End date", _endCtrl, isReadOnly: true, onTap: () => _pickDate(_endCtrl), suffixIcon: Icons.calendar_today),
            _yellowPillInput("Proof of ID", _proofCtrl, isReadOnly: true, onTap: _pickProof, suffixIcon: Icons.download),
            
            // TICKET VAVT-65: Meetup Dropdown
            _buildLocationDropdown(),
            
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _proceedToTerms,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
                minimumSize: const Size(160, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  side: const BorderSide(color: Colors.black),
                ),
              ),
              child: const Text("Continue Borrowing", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(height: 40)
          ],
        ),
      ),
    );
  }

  // TICKET VAVT-65: Dropdown UI Helper
  Widget _buildLocationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Meetup (LNU Campus Only)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.yellow,
            borderRadius: BorderRadius.circular(25),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: _selectedLocation,
              decoration: const InputDecoration(border: InputBorder.none),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
              dropdownColor: Colors.yellow,
              items: _locations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc))).toList(),
              onChanged: (v) => setState(() => _selectedLocation = v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _yellowPillInput(String label, TextEditingController ctrl, {bool isReadOnly = false, VoidCallback? onTap, IconData? suffixIcon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 5),
          TextField(
            controller: ctrl, readOnly: isReadOnly, onTap: onTap,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              filled: true, fillColor: Colors.yellow,
              suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: Colors.black) : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
            ),
          )
        ],
      ),
    );
  }
}

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
        Uri.parse('http://10.33.87.39:5000/api/borrow/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(widget.borrowData),
      );
      if (res.statusCode == 201) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => BorrowSuccessScreen(item: widget.item)));
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String? imgPath = widget.item['image'];
    bool hasImage = imgPath != null && imgPath.isNotEmpty;
    return Scaffold(
      backgroundColor: const Color(0xFF1A0088),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 30),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black),
                ),
              ),
            ),
          ),
          const Text("Huramay", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 5),
          const Text("Terms and Condition", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          Container(
            width: 120, height: 140,
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.yellow, width: 3),
              image: hasImage ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) : null,
            ),
            child: !hasImage ? const Icon(Icons.image, size: 40, color: Colors.grey) : null,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 25).copyWith(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: const Text(
                        "Huramay: A Mobile-Based Peer-to-Peer Academic Resource Exchange for LNU Students \n\nI. Acceptance of Responsibility \n\nBy proceeding with this request, the borrower acknowledges and accepts full responsibility for the academic resource identified in the listing. The borrower commits to treating the item with the utmost care and ensuring it remains in the same condition as documented at the time of the handover. Any pre-existing damages must be acknowledged by both parties during the physical exchange to avoid future disputes. The borrower understands that this item is being provided as a gesture of academic support within the LNU community and must not be used for any purpose that violates university policies. \n\nII. Liability and Accountability \n\nIn the event of loss, theft, or significant damage to the borrowed resource, the borrower agrees to be held liable for the repair or replacement of the item as negotiated with the lender. While the Huramay platform facilitates the connection, the legal and moral obligation to rectify damages rests solely on the borrower. Furthermore, the borrower understands that their Trust Rating is a permanent record within the local database; failure to return the item by the specified deadline or returning a damaged item will result in a formal deduction of rating points, which may limit their future access to the platform’s resources. \n\nIII. Code of Conduct and Safety \n\nAll transactions and physical handovers must take place within the designated landmarks of the Leyte Normal University (LNU) Tacloban Campus during official operating hours to ensure the safety and transparency of both parties. This agreement strictly prohibits the exchange of monetary fees or services in return for borrowing; Huramay is a non-commercial, peer-to-peer academic exchange. Both users agree to maintain professional and respectful communication through the integrated P2P chat and to promptly report any fraudulent activity or 'no-show' behavior to the project administrators.",
                        style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.4, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 24, width: 24,
                        child: Checkbox(value: _isChecked, activeColor: Colors.black, onChanged: (v) => setState(() => _isChecked = v ?? false)),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text("I agree to the Huramay terms and condition.", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
          _isSubmitting
              ? const Padding(padding: EdgeInsets.only(bottom: 30), child: CircularProgressIndicator(color: Colors.yellow))
              : Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: ElevatedButton(
                    onPressed: _isChecked ? _submitRequest : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isChecked ? Colors.yellow : Colors.grey,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(160, 45),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25), side: const BorderSide(color: Colors.black)),
                    ),
                    child: const Text("Continue Borrowing", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                )
        ],
      ),
    );
  }
}

class BorrowSuccessScreen extends StatelessWidget {
  final dynamic item;
  const BorrowSuccessScreen({super.key, required this.item});
  @override
  Widget build(BuildContext context) {
    String? imgPath = item['image'];
    bool hasImage = imgPath != null && imgPath.isNotEmpty;
    return Scaffold(
      backgroundColor: const Color(0xFF1A0088),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Huramay", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 5),
              const Text("Borrowed", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 30),
              Container(
                width: 140, height: 160,
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.yellow, width: 3),
                  image: hasImage ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) : null,
                ),
                child: !hasImage ? const Icon(Icons.image, size: 50, color: Colors.grey) : null,
              ),
              const SizedBox(height: 30),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Colors.grey, size: 30),
                    ),
                    const SizedBox(height: 15),
                    const Text("Successfully Borrowed this item.", textAlign: TextAlign.center, style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 15),
                    const Text("Waiting for approval from the owner.", textAlign: TextAlign.center, style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const DashboardScreen()), (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(200, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25), side: const BorderSide(color: Colors.black)),
                ),
                child: const Text("Back to Dashboard", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }
}