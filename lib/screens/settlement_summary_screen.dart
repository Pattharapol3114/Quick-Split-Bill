import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:promptpay_qrcode_generate/promptpay_qrcode_generate.dart';
import '../models/member.dart';
import '../services/settlement_service.dart';
import '../widgets/guest_mode_banner.dart';

class SettlementSummaryScreen extends StatefulWidget {
  final List<Transaction> transactions;
  final List<Member> members;
  final bool isGuestMode;

  const SettlementSummaryScreen({
    super.key,
    required this.transactions,
    required this.members,
    required this.isGuestMode,
  });

  @override
  State<SettlementSummaryScreen> createState() =>
      _SettlementSummaryScreenState();
}

class _SettlementSummaryScreenState extends State<SettlementSummaryScreen> {
  String? _visibleTransactionId;

  String? _normalizePromptPayId(String? raw) {
    if (raw == null) {
      return null;
    }

    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return null;
    }

    if (digits.length == 13) {
      return digits;
    }

    if (digits.length == 10 && digits.startsWith('0')) {
      return digits;
    }

    if (digits.length == 9) {
      return '0$digits';
    }

    if (digits.length == 11 && digits.startsWith('66')) {
      return '0${digits.substring(2)}';
    }

    if (digits.length == 12 && digits.startsWith('660')) {
      return digits.substring(2);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final settlementList = widget.transactions.isEmpty
        ? const Center(
            child: Text(
              'No settlement needed.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          )
        : ListView.separated(
            itemCount: widget.transactions.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final transaction = widget.transactions[index];
              final toMember = widget.members.firstWhere(
                (m) => m.id == transaction.toMemberId,
              );
              final normalizedPromptPay = _normalizePromptPayId(
                toMember.promptPayNumber,
              );
              final formattedAmount = NumberFormat.currency(
                locale: 'th_TH',
                symbol: '฿',
              ).format(transaction.amount);
              final transactionId =
                  '${transaction.fromMemberId}-${transaction.toMemberId}-${transaction.amount.toStringAsFixed(2)}';

              return Column(
                children: [
                  ListTile(
                    title: Text(
                      '${transaction.from} pays ${transaction.to}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Settlement transaction',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    trailing: Text(
                      formattedAmount,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12, bottom: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: normalizedPromptPay == null
                          ? const Text(
                              'No valid PromptPay available',
                              style: TextStyle(color: Colors.grey),
                            )
                          : TextButton(
                              onPressed: () {
                                setState(() {
                                  _visibleTransactionId =
                                      _visibleTransactionId == transactionId
                                      ? null
                                      : transactionId;
                                });
                              },
                              child: Text(
                                _visibleTransactionId == transactionId
                                    ? 'Hide QR'
                                    : 'Show PromptPay QR',
                              ),
                            ),
                    ),
                  ),
                  if (_visibleTransactionId == transactionId &&
                      normalizedPromptPay != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: QRCodeGenerate(
                        promptPayId: normalizedPromptPay,
                        amount: transaction.amount,
                        height: 340,
                        isShowAccountDetail: true,
                        isShowAmountDetail: true,
                      ),
                    ),
                ],
              );
            },
          );

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Settlement'),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isGuestMode) ...[
                const GuestModeBanner(),
                const SizedBox(height: 12),
              ],
              const Text(
                'Settlement Summary',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Review who pays whom and complete transfers.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Card(
                  color: Colors.white,
                  elevation: 2.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: settlementList,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
