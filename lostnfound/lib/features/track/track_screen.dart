import 'package:flutter/material.dart';

class TrackScreen extends StatelessWidget {
  const TrackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.track_changes_outlined, size: 48,
              color: Colors.grey),
            SizedBox(height: 12),
            Text('Lacak Laporan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            SizedBox(height: 4),
            Text('Akan tersedia di Minggu 2',
              style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}