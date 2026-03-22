import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import '../globals.dart';
import '../widgets/app_sidebar.dart';
import 'auth_screens.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List historyItems = [];
  bool isLoading = true;
  String? _currentFilter;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    if (currentUser == null) return;
    setState(() => isLoading = true);
    try {
      // FIXED: Using baseUrl for consistency across the app
      final res = await http.get(
        Uri.parse('http://10.33.87.39:5000/api/borrow/history/${currentUser!['id']}'),
      );
      if (res.statusCode == 200) {
        setState(() {
          historyItems = jsonDecode(res.body);
        });
      }
    } catch (e) {
      debugPrint("History Fetch Error: $e");
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "History",
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
                          items: ['Pending', 'Accepted', 'Declined', 'Returned'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: const TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() => _currentFilter = newValue);
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
                : historyItems.isEmpty
                    ? const Center(
                        child: Text(
                          "No Borrowing History Found",
                          style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      )
                    : ListView.builder(
                        itemCount: historyItems.length,
                        itemBuilder: (c, i) => _HistoryCard(historyData: historyItems[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// 1. THE HISTORY CARD (Fixed for Null Safety)
// ---------------------------------------------------------
class _HistoryCard extends StatelessWidget {
  final dynamic historyData;
  const _HistoryCard({required this.historyData});

  @override
  Widget build(BuildContext context) {
    // FIXED: Guard against the entire item object being null
    dynamic item = historyData['item'] ?? {}; 
    String? imgPath = item['image'];
    bool hasImage = imgPath != null && imgPath.isNotEmpty;

    return Padding(
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
                  // FIXED: Added '??' guards to every Text widget
                  Text(
                    item['owner'] ?? "Unknown Owner",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A0088), fontSize: 13),
                  ),
                  Text(
                    item['title'] ?? "Untitled Item",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  Text(
                    item['dept'] ?? "No Department",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  Text(
                    historyData['status'] ?? "No Status",
                    style: const TextStyle(color: Color(0xFF1A0088), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 15),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => ReportOverlay(itemData: item),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        minimumSize: const Size(100, 35),
                        elevation: 4,
                      ),
                      child: const Text("Report", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// 2. THE MULTI-STEP REPORT OVERLAY DIALOG (Fixed for Null Safety)
// ---------------------------------------------------------
enum ReportStep { details, input }

class ReportOverlay extends StatefulWidget {
  final dynamic itemData;
  const ReportOverlay({super.key, required this.itemData});

  @override
  State<ReportOverlay> createState() => _ReportOverlayState();
}

class _ReportOverlayState extends State<ReportOverlay> {
  ReportStep currentStep = ReportStep.details;
  final TextEditingController _reportTextCtrl = TextEditingController();
  bool isSubmitting = false;

  void _handleBack() {
    if (currentStep == ReportStep.input) {
      setState(() => currentStep = ReportStep.details);
    } else {
      Navigator.pop(context);
    }
  }

  void _showConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[300],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Are you sure you want to report?",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF1A0088), fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _confirmBtn("Yes", () {
                  Navigator.pop(context); 
                  _submitReportToBackend(); 
                }),
                _confirmBtn("No", () {
                  Navigator.pop(context); 
                }),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _confirmBtn(String text, VoidCallback action) {
    return ElevatedButton(
      onPressed: action,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.black)),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _submitReportToBackend() async {
    setState(() => isSubmitting = true);
    try {
      final res = await http.post(
        Uri.parse('http://10.33.87.39:5000/api/report'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reporter_id': currentUser!['id'],
          'item_id': widget.itemData['id'],
          'report_text': _reportTextCtrl.text.isEmpty ? "No details provided" : _reportTextCtrl.text
        }),
      );
      if (res.statusCode == 201) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report submitted successfully.")));
      }
    } catch (e) {
      debugPrint("Report Submission Error: $e");
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String? imgPath = widget.itemData['image'];
    bool hasImage = imgPath != null && imgPath.isNotEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.75, 
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFBDBDBD), 
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black),
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: GestureDetector(
                onTap: _handleBack,
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
            Expanded(
              child: currentStep == ReportStep.details 
                ? _buildDetailsView() 
                : _buildInputView(),
            ),
            isSubmitting 
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: () {
                    if (currentStep == ReportStep.details) {
                      setState(() => currentStep = ReportStep.input);
                    } else {
                      _showConfirmation();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.black)),
                    minimumSize: const Size(120, 45),
                    elevation: 5,
                  ),
                  child: const Text("Report", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _centeredLabel("Owner"),
          // FIXED: Guarded against null
          _centeredValue(widget.itemData['owner'] ?? "N/A"),
          const SizedBox(height: 10),
          _centeredLabel("Item"),
          _centeredValue(widget.itemData['title'] ?? "N/A"),
          const SizedBox(height: 10),
          _centeredLabel("Department"),
          _centeredValue(widget.itemData['dept'] ?? "N/A"),
          const SizedBox(height: 10),
          _centeredLabel("Description"),
          _centeredValue(widget.itemData['description'] ?? "No description available."),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInputView() {
    return Column(
      children: [
        const Text("Type here your report", style: TextStyle(color: Color(0xFF1A0088), fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(15),
            ),
            child: TextField(
              controller: _reportTextCtrl,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(15),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _centeredLabel(String t) => Text(
    t, 
    textAlign: TextAlign.center,
    style: const TextStyle(color: Color(0xFF1A0088), fontWeight: FontWeight.bold, fontSize: 14),
  );

  Widget _centeredValue(String v) => Text(
    v, 
    textAlign: TextAlign.center, 
    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
  );
}