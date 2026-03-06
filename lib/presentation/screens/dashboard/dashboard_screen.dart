import 'package:flutter/material.dart';
import '../profile/profile_screen.dart';

/// Placeholder dashboard screen; full implementation belongs to Developer 5.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Dashboard content coming soon',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
