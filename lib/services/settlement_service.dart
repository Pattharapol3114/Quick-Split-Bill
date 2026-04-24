import '../models/member.dart';
import '../models/bill.dart';

class Transaction {
  final String fromMemberId;
  final String toMemberId;
  final String from;
  final String to;
  final double amount;

  Transaction({
    required this.fromMemberId,
    required this.toMemberId,
    required this.from,
    required this.to,
    required this.amount,
  });
}

class SettlementService {
  List<Transaction> calculateNetSettlement(
    List<Member> members,
    List<Bill> bills,
  ) {
    if (members.isEmpty || bills.isEmpty) {
      return [];
    }

    final memberById = {for (final member in members) member.id: member};

    // Reset balances
    for (var member in members) {
      member.netBalance = 0;
    }

    final paidByMemberCents = <String, int>{
      for (final member in members) member.id: 0,
    };
    final owedByMemberCents = <String, int>{
      for (final member in members) member.id: 0,
    };

    // Total paid: full bill amount goes to payer.
    for (var bill in bills) {
      if (!paidByMemberCents.containsKey(bill.payerId)) {
        continue;
      }

      final billAmountCents = (bill.totalAmount * 100).round();
      paidByMemberCents[bill.payerId] =
          (paidByMemberCents[bill.payerId] ?? 0) + billAmountCents;

      final involvedMemberIds =
          bill.involvedMemberIds.where(memberById.containsKey).toSet().toList()
            ..sort();

      if (involvedMemberIds.isEmpty) {
        continue;
      }

      // Split by bill with cent-level remainder distribution for exact totals.
      final baseShare = billAmountCents ~/ involvedMemberIds.length;
      final remainder = billAmountCents % involvedMemberIds.length;

      for (var i = 0; i < involvedMemberIds.length; i++) {
        final memberId = involvedMemberIds[i];
        final owed = baseShare + (i < remainder ? 1 : 0);
        owedByMemberCents[memberId] = (owedByMemberCents[memberId] ?? 0) + owed;
      }
    }

    // Net balance = TotalPaid - TotalOwed.
    for (var member in members) {
      final paid = paidByMemberCents[member.id] ?? 0;
      final owed = owedByMemberCents[member.id] ?? 0;
      member.netBalance = (paid - owed) / 100.0;
    }

    // Separate members into creditors and debtors
    final creditors = members.where((m) => m.netBalance > 0).toList();
    final debtors = members.where((m) => m.netBalance < 0).toList();
    final transactions = <Transaction>[];

    // Sort creditors and debtors to optimize
    creditors.sort((a, b) => b.netBalance.compareTo(a.netBalance));
    debtors.sort((a, b) => a.netBalance.compareTo(b.netBalance));

    final creditorRemainingCents = {
      for (final c in creditors) c.id: (c.netBalance * 100).round(),
    };
    final debtorRemainingCents = {
      for (final d in debtors) d.id: (-d.netBalance * 100).round(),
    };

    int i = 0, j = 0;
    while (i < creditors.length && j < debtors.length) {
      final creditor = creditors[i];
      final debtor = debtors[j];
      final creditorRemaining = creditorRemainingCents[creditor.id] ?? 0;
      final debtorRemaining = debtorRemainingCents[debtor.id] ?? 0;
      final transferCents = creditorRemaining < debtorRemaining
          ? creditorRemaining
          : debtorRemaining;

      if (transferCents > 0) {
        transactions.add(
          Transaction(
            fromMemberId: debtor.id,
            toMemberId: creditor.id,
            from: debtor.name,
            to: creditor.name,
            amount: transferCents / 100.0,
          ),
        );
        creditorRemainingCents[creditor.id] = creditorRemaining - transferCents;
        debtorRemainingCents[debtor.id] = debtorRemaining - transferCents;
      }

      if ((creditorRemainingCents[creditor.id] ?? 0) == 0) {
        i++;
      }
      if ((debtorRemainingCents[debtor.id] ?? 0) == 0) {
        j++;
      }
    }

    return transactions;
  }
}
