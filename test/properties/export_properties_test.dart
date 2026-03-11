// test/properties/export_properties_test.dart
//
// Property-based tests for task 28.4: TransactionExportService receipt
// generation and CSV output.
//
// Developer: Developer 4

import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/models/coffee_listing.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/escrow_transaction.dart';
import 'package:brewmaster/data/services/transaction_export_service.dart';

// ---------------------------------------------------------------------------
// Helpers — pure model construction, no Firebase Timestamps
// ---------------------------------------------------------------------------

CoffeeListing _makeListing({
  String listingId = 'l1',
  String variety = 'Bourbon',
  double quantity = 100,
  double pricePerKg = 5.5,
  String? batchNumber,
  List<String>? certifications,
}) =>
    CoffeeListing(
      listingId: listingId,
      farmerId: 'f1',
      variety: variety,
      quantity: quantity,
      pricePerKg: pricePerKg,
      processingMethod: ProcessingMethod.washed,
      altitude: 1500,
      harvestDate: DateTime(2024, 1, 15),
      qualityScore: 85,
      description: 'Test listing',
      images: [],
      location: '-1.9,29.8',
      status: ListingStatus.active,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
      batchNumber: batchNumber,
      certifications: certifications,
    );

Transaction _makeTx({
  String id = 'tx1',
  String buyerId = 'buyer1',
  String farmerId = 'farmer1',
  String listingId = 'l1',
  double amount = 550.0,
  String? receiptNumber,
  Map<String, String>? traceabilityData,
}) =>
    Transaction(
      id: id,
      buyerId: buyerId,
      farmerId: farmerId,
      listingId: listingId,
      amount: amount,
      status: TransactionStatus.completed,
      paymentMethod: PaymentMethod.mpesa,
      createdAt: DateTime(2024, 6, 1),
      receiptNumber: receiptNumber,
      traceabilityData: traceabilityData,
    );

void main() {
  late TransactionExportService service;

  setUp(() => service = TransactionExportService());

  group('generateReceipt() (task 28.4)', () {
    test('receipt contains all required fields', () {
      final receipt = service.generateReceipt(_makeTx(), _makeListing());
      expect(receipt.transactionId, 'tx1');
      expect(receipt.buyerId, 'buyer1');
      expect(receipt.farmerId, 'farmer1');
      expect(receipt.variety, 'Bourbon');
      expect(receipt.quantity, 100);
      expect(receipt.pricePerKg, 5.5);
      expect(receipt.totalAmount, 550.0);
      expect(receipt.paymentMethod, 'mpesa');
      expect(receipt.status, 'completed');
    });

    test('receiptNumber uses transaction.receiptNumber when set', () {
      final tx = _makeTx(receiptNumber: 'RCP-CUSTOM-001');
      final receipt = service.generateReceipt(tx, _makeListing());
      expect(receipt.receiptNumber, 'RCP-CUSTOM-001');
    });

    test('receiptNumber is auto-generated when not set', () {
      final receipt = service.generateReceipt(_makeTx(), _makeListing());
      expect(receipt.receiptNumber, startsWith('RCP-'));
    });

    test('auto-generated receiptNumber contains transaction id prefix', () {
      final tx = _makeTx(id: 'abcdef1234567890');
      final receipt = service.generateReceipt(tx, _makeListing());
      expect(receipt.receiptNumber, contains('ABCDEF12'));
    });

    test('batchNumber from listing is propagated to receipt', () {
      final listing = _makeListing(batchNumber: 'BATCH-001');
      final receipt = service.generateReceipt(_makeTx(), listing);
      expect(receipt.batchNumber, 'BATCH-001');
    });

    test('certifications from listing are propagated to receipt', () {
      final listing = _makeListing(certifications: ['Organic', 'Fair Trade']);
      final receipt = service.generateReceipt(_makeTx(), listing);
      expect(receipt.certifications, ['Organic', 'Fair Trade']);
    });

    test('traceabilityData from transaction is propagated to receipt', () {
      final tx = _makeTx(traceabilityData: {'exportRef': 'EXP-42'});
      final receipt = service.generateReceipt(tx, _makeListing());
      expect(receipt.traceabilityData['exportRef'], 'EXP-42');
    });

    test('toMap() contains all receipt fields', () {
      final receipt = service.generateReceipt(_makeTx(), _makeListing());
      final map = receipt.toMap();
      expect(map.containsKey('receiptNumber'), isTrue);
      expect(map.containsKey('transactionId'), isTrue);
      expect(map.containsKey('totalAmount'), isTrue);
      expect(map.containsKey('variety'), isTrue);
      expect(map.containsKey('certifications'), isTrue);
      expect(map.containsKey('traceabilityData'), isTrue);
    });
  });

  group('toCsvRow() (task 28.4)', () {
    test('CSV row contains all expected comma-separated segments', () {
      final receipt = service.generateReceipt(_makeTx(), _makeListing());
      final csv = service.toCsvRow(receipt);
      expect(csv, contains('tx1'));
      expect(csv, contains('buyer1'));
      expect(csv, contains('Bourbon'));
      expect(csv, contains('mpesa'));
    });

    test('certifications are pipe-separated in CSV row', () {
      final listing = _makeListing(certifications: ['Organic', 'Fair Trade']);
      final receipt = service.generateReceipt(_makeTx(), listing);
      final csv = service.toCsvRow(receipt);
      expect(csv, contains('Organic|Fair Trade'));
    });

    test('empty certifications produce no pipe characters', () {
      final receipt = service.generateReceipt(_makeTx(), _makeListing());
      final csv = service.toCsvRow(receipt);
      // No pipe separator when certifications are empty
      expect(csv.endsWith(','), isTrue);
    });

    test('toCsvDocument() starts with header line', () {
      final receipt = service.generateReceipt(_makeTx(), _makeListing());
      final doc = service.toCsvDocument([receipt]);
      expect(doc.startsWith(service.csvHeader), isTrue);
    });

    test('toCsvDocument() contains one data row for one receipt', () {
      final receipt = service.generateReceipt(_makeTx(), _makeListing());
      final doc = service.toCsvDocument([receipt]);
      final lines = doc.split('\n');
      expect(lines.length, 2); // header + 1 row
    });

    test('toCsvDocument() contains N+1 lines for N receipts', () {
      final receipts = List.generate(
        5,
        (i) => service.generateReceipt(
          _makeTx(id: 'tx$i'),
          _makeListing(listingId: 'l$i'),
        ),
      );
      final doc = service.toCsvDocument(receipts);
      expect(doc.split('\n').length, 6); // header + 5 rows
    });

    test('empty receipts list produces only header', () {
      final doc = service.toCsvDocument([]);
      expect(doc.trim(), service.csvHeader);
    });
  });
}
