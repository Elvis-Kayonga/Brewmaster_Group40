// tool/seed_listings.dart
//
// Seed script — writes sample coffee listings to Firestore.
//
// Usage:
//   flutter run -t tool/seed_listings.dart
//
// The script writes documents, prints progress, then exits.
// Re-running is safe: it checks for an existing "seeded" sentinel document
// and skips if already present. Pass --dart-define=FORCE=true to reseed:
//   flutter run -t tool/seed_listings.dart --dart-define=FORCE=true

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:brewmaster/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const _SeedApp());
}

class _SeedApp extends StatelessWidget {
  const _SeedApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: _SeedRunner(),
    );
  }
}

class _SeedRunner extends StatefulWidget {
  const _SeedRunner();

  @override
  State<_SeedRunner> createState() => _SeedRunnerState();
}

class _SeedRunnerState extends State<_SeedRunner> {
  final List<String> _log = [];
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  void _print(String msg) {
    // ignore: avoid_print
    print(msg);
    setState(() => _log.add(msg));
  }

  Future<void> _run() async {
    const force = bool.fromEnvironment('FORCE', defaultValue: false);
    final db = FirebaseFirestore.instance;
    final col = db.collection('listings');
    final sentinel = db.collection('_seed_meta').doc('listings_v1');

    if (!force) {
      final snap = await sentinel.get();
      if (snap.exists) {
        _print('✓ Already seeded. Pass --dart-define=FORCE=true to reseed.');
        setState(() => _done = true);
        return;
      }
    }

    _print('Seeding listings…');

    for (final data in _listings) {
      final docRef = await col.add(data);
      await docRef.update({'listingId': docRef.id});
      _print('  ✓ ${data['coffeeVariety']} (${data['locationAddress']}) → ${docRef.id}');
    }

    await sentinel.set({'seededAt': DateTime.now().toIso8601String()});
    _print('\nDone — ${_listings.length} listings written.');
    setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0A00),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B1F0A),
        title: const Text('Seed Listings', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _log.length,
              itemBuilder: (_, i) => Text(
                _log[i],
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Colors.greenAccent,
                ),
              ),
            ),
          ),
          if (_done)
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B4513),
                ),
                onPressed: () => WidgetsBinding.instance.addPostFrameCallback(
                  (_) => throw Exception('Exit'),
                ),
                child: const Text('Close app', style: TextStyle(color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Seed data ──────────────────────────────────────────────────────────────
//
// Three demo farmers, six listings spread across East Africa.
// farmerId values are fixed strings — they won't match any real auth UID, so
// buyers can contact all of them without "this is your listing" being triggered.

const _t = '2025-09-01T08:00:00.000';

final List<Map<String, dynamic>> _listings = [
  // ── Farmer 1: Amara Nkosi (Kenya) ─────────────────────────────────────────
  {
    'farmerId': 'demo_farmer_amara',
    'farmerName': 'Amara Nkosi',
    'coffeeVariety': 'Bourbon Natural',
    'quantityKg': 320.0,
    'askingPricePerKg': 8.50,
    'processingMethod': 'natural',
    'altitude': 1950.0,
    'harvestDate': '2025-06-15T00:00:00.000',
    'cuppingScore': 88.0,
    'flavorNotes':
        'Rich dark chocolate and dried blueberry notes with a wine-like '
        'finish. Sourced from a small family farm in Nyeri County, '
        'sun-dried on raised beds for 28 days.',
    'imageUrls': <String>[],
    'location': '{"latitude":-0.4167,"longitude":36.9500}',
    'locationAddress': 'Nyeri, Kenya',
    'status': 'active',
    'createdAt': _t,
    'updatedAt': _t,
    'batchNumber': 'BN-2025-KE-001',
    'certifications': ['Organic', 'Fair Trade'],
  },
  {
    'farmerId': 'demo_farmer_amara',
    'farmerName': 'Amara Nkosi',
    'coffeeVariety': 'SL28 Washed',
    'quantityKg': 180.0,
    'askingPricePerKg': 10.00,
    'processingMethod': 'washed',
    'altitude': 1800.0,
    'harvestDate': '2025-07-10T00:00:00.000',
    'cuppingScore': 90.0,
    'flavorNotes':
        'Bright blackcurrant acidity with a clean, tea-like body. '
        'Double-fermented at the washing station and dried on African '
        'beds under shade cloth.',
    'imageUrls': <String>[],
    'location': '{"latitude":-0.3980,"longitude":36.9600}',
    'locationAddress': 'Nyeri, Kenya',
    'status': 'active',
    'createdAt': _t,
    'updatedAt': _t,
    'batchNumber': 'BN-2025-KE-002',
    'certifications': ['Rainforest Alliance'],
  },

  // ── Farmer 2: Tigist Haile (Ethiopia) ─────────────────────────────────────
  {
    'farmerId': 'demo_farmer_tigist',
    'farmerName': 'Tigist Haile',
    'coffeeVariety': 'Typica Washed',
    'quantityKg': 240.0,
    'askingPricePerKg': 11.00,
    'processingMethod': 'washed',
    'altitude': 2100.0,
    'harvestDate': '2025-11-20T00:00:00.000',
    'cuppingScore': 91.0,
    'flavorNotes':
        'Classic Yirgacheffe floral jasmine aroma with bergamot and '
        'lemon zest on the palate. Exceptionally clean cup with a '
        'medium body and lingering sweetness.',
    'imageUrls': <String>[],
    'location': '{"latitude":6.1539,"longitude":38.2044}',
    'locationAddress': 'Yirgacheffe, Ethiopia',
    'status': 'active',
    'createdAt': _t,
    'updatedAt': _t,
    'batchNumber': 'BN-2025-ET-001',
    'certifications': ['Organic', 'UTZ'],
  },
  {
    'farmerId': 'demo_farmer_tigist',
    'farmerName': 'Tigist Haile',
    'coffeeVariety': 'Gesha Natural',
    'quantityKg': 80.0,
    'askingPricePerKg': 18.50,
    'processingMethod': 'natural',
    'altitude': 2200.0,
    'harvestDate': '2025-11-30T00:00:00.000',
    'cuppingScore': 94.0,
    'flavorNotes':
        'Extraordinary peach and passion-fruit sweetness with a '
        'champagne-like effervescence. Limited micro-lot from a single '
        'block of heritage Gesha trees planted in 1974.',
    'imageUrls': <String>[],
    'location': '{"latitude":6.1600,"longitude":38.2100}',
    'locationAddress': 'Yirgacheffe, Ethiopia',
    'status': 'active',
    'createdAt': _t,
    'updatedAt': _t,
    'batchNumber': 'BN-2025-ET-002',
    'certifications': ['Organic', 'Fair Trade', 'Cup of Excellence'],
  },

  // ── Farmer 3: Jean-Pierre Mugisha (Rwanda) ─────────────────────────────────
  {
    'farmerId': 'demo_farmer_jeanpierre',
    'farmerName': 'Jean-Pierre Mugisha',
    'coffeeVariety': 'Red Bourbon Honey',
    'quantityKg': 150.0,
    'askingPricePerKg': 7.80,
    'processingMethod': 'honey',
    'altitude': 1750.0,
    'harvestDate': '2025-08-05T00:00:00.000',
    'cuppingScore': 86.0,
    'flavorNotes':
        'Caramel sweetness balanced with stone-fruit and a subtle '
        'nuttiness. Honey-processed on raised beds at the Huye Mountain '
        'washing station, producing a rich and complex cup.',
    'imageUrls': <String>[],
    'location': '{"latitude":-2.5917,"longitude":29.7344}',
    'locationAddress': 'Huye, Rwanda',
    'status': 'active',
    'createdAt': _t,
    'updatedAt': _t,
    'batchNumber': 'BN-2025-RW-001',
    'certifications': ['Fair Trade'],
  },
  {
    'farmerId': 'demo_farmer_jeanpierre',
    'farmerName': 'Jean-Pierre Mugisha',
    'coffeeVariety': 'Jackson Washed',
    'quantityKg': 420.0,
    'askingPricePerKg': 6.50,
    'processingMethod': 'washed',
    'altitude': 1680.0,
    'harvestDate': '2025-08-20T00:00:00.000',
    'cuppingScore': 84.0,
    'flavorNotes':
        'Crisp red apple and brown sugar sweetness with a silky '
        'mouthfeel. Fully washed and meticulously sorted, making it '
        'an excellent high-volume specialty option.',
    'imageUrls': <String>[],
    'location': '{"latitude":-2.5800,"longitude":29.7200}',
    'locationAddress': 'Huye, Rwanda',
    'status': 'active',
    'createdAt': _t,
    'updatedAt': _t,
    'batchNumber': 'BN-2025-RW-002',
    'certifications': ['Rainforest Alliance', 'UTZ'],
  },
];
