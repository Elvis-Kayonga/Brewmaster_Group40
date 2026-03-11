// Feature: brewmaster-compliance
// Service for exporting transaction receipts.
// Produces structured receipt data (Map) and CSV rows usable for
// PDF rendering or file export.
//
// Requirements: 15.3, 15.4
// Developer: Developer 4

import '../../domain/models/coffee_listing.dart';
import '../../domain/models/escrow_transaction.dart';

/// Structured receipt data ready for rendering or serialisation.
class TransactionReceipt {
  final String receiptNumber;
  final String transactionId;
  final String buyerId;
  final String farmerId;
  final String listingId;
  final String variety;
  final double quantity;
  final double pricePerKg;
  final double totalAmount;
  final String paymentMethod;
  final String status;
  final String createdAt;
  final String? batchNumber;
  final List<String> certifications;
  final Map<String, String> traceabilityData;

  const TransactionReceipt({
    required this.receiptNumber,
    required this.transactionId,
    required this.buyerId,
    required this.farmerId,
    required this.listingId,
    required this.variety,
    required this.quantity,
    required this.pricePerKg,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.batchNumber,
    this.certifications = const [],
    this.traceabilityData = const {},
  });

  Map<String, dynamic> toMap() => {
        'receiptNumber': receiptNumber,
        'transactionId': transactionId,
        'buyerId': buyerId,
        'farmerId': farmerId,
        'listingId': listingId,
        'variety': variety,
        'quantity': quantity,
        'pricePerKg': pricePerKg,
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod,
        'status': status,
        'createdAt': createdAt,
        'batchNumber': batchNumber,
        'certifications': certifications,
        'traceabilityData': traceabilityData,
      };
}

class TransactionExportService {
  static const _csvHeader =
      'receiptNumber,transactionId,buyerId,farmerId,listingId,'
      'variety,quantity,pricePerKg,totalAmount,paymentMethod,status,'
      'createdAt,batchNumber,certifications';

  /// Build a [TransactionReceipt] from a transaction and its listing.
  TransactionReceipt generateReceipt(
    Transaction transaction,
    CoffeeListing listing,
  ) {
    final idPart = transaction.id.length >= 8
        ? transaction.id.substring(0, 8)
        : transaction.id;
    final receiptNo =
        transaction.receiptNumber ?? 'RCP-${idPart.toUpperCase()}';

    return TransactionReceipt(
      receiptNumber: receiptNo,
      transactionId: transaction.id,
      buyerId: transaction.buyerId,
      farmerId: transaction.farmerId,
      listingId: transaction.listingId,
      variety: listing.variety,
      quantity: listing.quantity,
      pricePerKg: listing.pricePerKg,
      totalAmount: transaction.amount,
      paymentMethod: transaction.paymentMethod.name,
      status: transaction.status.name,
      createdAt: transaction.createdAt.toIso8601String(),
      batchNumber: listing.batchNumber,
      certifications: listing.certifications ?? [],
      traceabilityData: transaction.traceabilityData ?? {},
    );
  }

  /// Convert a receipt to a single CSV data row.
  String toCsvRow(TransactionReceipt receipt) {
    final certs = receipt.certifications.join('|');
    return '${receipt.receiptNumber},${receipt.transactionId},'
        '${receipt.buyerId},${receipt.farmerId},${receipt.listingId},'
        '${receipt.variety},${receipt.quantity},${receipt.pricePerKg},'
        '${receipt.totalAmount},${receipt.paymentMethod},${receipt.status},'
        '${receipt.createdAt},${receipt.batchNumber ?? ""},$certs';
  }

  /// Build a complete CSV document (header + rows) from multiple receipts.
  String toCsvDocument(List<TransactionReceipt> receipts) {
    final rows = receipts.map(toCsvRow).join('\n');
    return '$_csvHeader\n$rows';
  }

  /// Returns the standard CSV column header string.
  String get csvHeader => _csvHeader;
}
