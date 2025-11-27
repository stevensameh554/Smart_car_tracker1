// lib/screens/trips.dart
import 'package:flutter/material.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // For demo we show static content. You can wire real trips stored in another Hive box.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Trip History', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        tripCard('32.7 km', '10:05 AM - 11:05 AM'),
        SizedBox(height: 8),
        tripCard('18.3 km', '11:05 AM - 12:05 PM'),
        SizedBox(height: 8),
        tripCard('24.5 km', '12:05 PM - 1:05 PM'),
      ]),
    );
  }

  Widget tripCard(String distance, String time) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Color(0xFF0B1620), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Color(0xFF112233), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.alt_route, color: Colors.white),
          ),
          SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(distance, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(time, style: TextStyle(color: Colors.white60)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Color(0xFF063F2E), borderRadius: BorderRadius.circular(6)),
            child: Text('1h 0m', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}
