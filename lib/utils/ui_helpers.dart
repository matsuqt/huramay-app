import 'package:flutter/material.dart';

// ==================== GLOBAL UI HELPERS ====================
BoxDecoration figmaBackground() => const BoxDecoration(
  gradient: LinearGradient(colors: [Color(0xFF1A0088), Color(0xFFFDEB00)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
);

Widget figmaLabel(String text) => Padding(
  padding: const EdgeInsets.only(left: 10, bottom: 5, top: 15),
  child: Align(
    alignment: Alignment.centerLeft, 
    child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
  ),
);

Widget figmaInputAuth(TextEditingController ctrl, {bool isPass = false}) => TextField(
  controller: ctrl,
  obscureText: isPass,
  decoration: InputDecoration(
    filled: true,
    fillColor: Colors.grey[300],
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
  ),
);

Widget figmaButton(String text, Function() action) => ElevatedButton(
  onPressed: action,
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.grey[300],
    foregroundColor: Colors.black87,
    minimumSize: const Size(120, 45),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
    elevation: 5,
  ),
  child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
);

Widget miniBtn(String t, Color c, VoidCallback action) {
  return GestureDetector(
    onTap: action,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c, 
        borderRadius: BorderRadius.circular(10), 
        border: Border.all(color: Colors.black12)
      ),
      child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    ),
  );
}