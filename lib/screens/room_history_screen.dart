import 'package:flutter/material.dart';

class RoomHistoryScreen extends StatelessWidget {
  const RoomHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.history, size: 100, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Room History',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Your past room sessions will appear here',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
