import 'package:cloud_firestore/cloud_firestore.dart' as fs;

import '../models/bill.dart';
import '../models/member.dart';
import 'settlement_service.dart';

class TripStorageService {
  final fs.FirebaseFirestore _firestore;

  TripStorageService({fs.FirebaseFirestore? firestore})
    : _firestore = firestore ?? fs.FirebaseFirestore.instance;

  Future<void> saveTrip({
    required String userId,
    required String groupName,
    required List<Member> members,
    required List<Bill> bills,
    required List<Transaction> settlements,
  }) async {
    final totalAmount = bills.fold<double>(
      0,
      (acc, bill) => acc + bill.totalAmount,
    );

    await _firestore.collection('trips').add({
      'userId': userId,
      'createdAt': fs.FieldValue.serverTimestamp(),
      'group': {'name': groupName, 'memberCount': members.length},
      'summary': {
        'billCount': bills.length,
        'settlementCount': settlements.length,
        'totalAmount': totalAmount,
      },
      'members': members
          .map(
            (member) => {
              'id': member.id,
              'name': member.name,
              'promptPayNumber': member.promptPayNumber,
            },
          )
          .toList(),
      'bills': bills
          .map(
            (bill) => {
              'id': bill.id,
              'description': bill.description,
              'totalAmount': bill.totalAmount,
              'payerId': bill.payerId,
              'involvedMemberIds': bill.involvedMemberIds,
              'timestamp': bill.timestamp.toIso8601String(),
            },
          )
          .toList(),
      'settlements': settlements
          .map(
            (transaction) => {
              'fromMemberId': transaction.fromMemberId,
              'toMemberId': transaction.toMemberId,
              'from': transaction.from,
              'to': transaction.to,
              'amount': transaction.amount,
            },
          )
          .toList(),
    });
  }

  Stream<fs.QuerySnapshot<Map<String, dynamic>>> streamTripsByUser(
    String userId,
  ) {
    return _firestore
        .collection('trips')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Future<void> deleteTrip(String tripId) async {
    await _firestore.collection('trips').doc(tripId).delete();
  }
}
