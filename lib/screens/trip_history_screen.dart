import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:promptpay_qrcode_generate/promptpay_qrcode_generate.dart';

import '../services/trip_storage_service.dart';

class TripHistoryScreen extends StatelessWidget {
  final TripStorageService _tripStorageService = TripStorageService();

  TripHistoryScreen({super.key});

  Future<void> _confirmDeleteTrip(BuildContext context, String tripId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Trip'),
          content: const Text('Are you sure you want to delete this trip?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _tripStorageService.deleteTrip(tripId);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Trip deleted.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip History')),
        body: const Center(
          child: Text('Trip history is available only for logged-in users.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Trip History')),
      body: StreamBuilder(
        stream: _tripStorageService.streamTripsByUser(user.uid),
        builder: (context, snapshot) {
          final theme = Theme.of(context);

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = [...snapshot.data!.docs]
            ..sort((a, b) {
              final aTime = a.data()['createdAt'];
              final bTime = b.data()['createdAt'];

              if (aTime == null && bTime == null) {
                return 0;
              }
              if (aTime == null) {
                return 1;
              }
              if (bTime == null) {
                return -1;
              }

              final aDate = (aTime as dynamic).toDate() as DateTime;
              final bDate = (bTime as dynamic).toDate() as DateTime;
              return bDate.compareTo(aDate);
            });

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history_toggle_off,
                          size: 48,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.75,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No trip history yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Saved trips will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          final totalTrips = docs.length;
          final totalAmount = docs.fold<double>(0.0, (sum, doc) {
            final summary =
                (doc.data()['summary'] as Map<String, dynamic>?) ?? {};
            final amount = (summary['totalAmount'] as num?)?.toDouble() ?? 0.0;
            return sum + amount;
          });

          DateTime? latestSavedAt;
          for (final doc in docs) {
            final createdAt = doc.data()['createdAt'];
            if (createdAt != null) {
              latestSavedAt = (createdAt as dynamic).toDate() as DateTime;
              break;
            }
          }

          final latestSavedText = latestSavedAt == null
              ? '-'
              : DateFormat('dd MMM yyyy, HH:mm').format(latestSavedAt);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.insights_outlined,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Saved Trips: $totalTrips',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Total amount: ${NumberFormat.currency(locale: 'th_TH', symbol: '฿').format(totalAmount)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Latest save: $latestSavedText',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final tripId = docs[index].id;
                          final data = docs[index].data();
                          final group =
                              (data['group'] as Map<String, dynamic>?) ?? {};
                          final summary =
                              (data['summary'] as Map<String, dynamic>?) ?? {};
                          final billsRaw = (data['bills'] as List?) ?? const [];
                          final billNames = billsRaw
                              .map((item) {
                                if (item is Map<String, dynamic>) {
                                  return (item['description'] as String?) ?? '';
                                }
                                return '';
                              })
                              .where((name) => name.isNotEmpty)
                              .toList();
                          final billPreview = billNames.isEmpty
                              ? 'No bill names'
                              : billNames.take(2).join(', ');
                          final hasMoreBills = billNames.length > 2;
                          final createdAt = data['createdAt'];
                          final dateText = createdAt == null
                              ? '-'
                              : DateFormat('yyyy-MM-dd HH:mm').format(
                                  (createdAt as dynamic).toDate() as DateTime,
                                );
                          final totalAmount =
                              (summary['totalAmount'] as num?)?.toDouble() ??
                              0.0;
                          final billCount =
                              (summary['billCount'] as num?)?.toInt() ?? 0;

                          return Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        TripDetailScreen(trip: data),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.receipt_long_outlined,
                                        color: theme.colorScheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (group['name'] as String?) ??
                                                'Quick Split Group',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Bills: $billCount • $billPreview${hasMoreBills ? ', ...' : ''}',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Saved: $dateText',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const Divider(height: 20),
                                          Row(
                                            children: [
                                              Text(
                                                NumberFormat.currency(
                                                  locale: 'th_TH',
                                                  symbol: '฿',
                                                ).format(totalAmount),
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                              ),
                                              const Spacer(),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: theme
                                                      .colorScheme
                                                      .secondary
                                                      .withValues(alpha: 0.2),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                  ),
                                                  color: theme
                                                      .colorScheme
                                                      .secondary,
                                                  tooltip: 'Delete trip',
                                                  onPressed: () =>
                                                      _confirmDeleteTrip(
                                                        context,
                                                        tripId,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class TripDetailScreen extends StatefulWidget {
  final Map<String, dynamic> trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  String? _visibleSettlementKey;

  Widget _buildSectionHeader(
    BuildContext context,
    IconData icon,
    String title,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildEmptySection(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

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
    final theme = Theme.of(context);
    final group = (widget.trip['group'] as Map<String, dynamic>?) ?? {};
    final members = (widget.trip['members'] as List?) ?? const [];
    final bills = (widget.trip['bills'] as List?) ?? const [];
    final settlements = (widget.trip['settlements'] as List?) ?? const [];
    final summary = (widget.trip['summary'] as Map<String, dynamic>?) ?? {};
    final createdAt = widget.trip['createdAt'];
    final savedAtText = createdAt == null
        ? '-'
        : DateFormat(
            'dd MMM yyyy, HH:mm',
          ).format((createdAt as dynamic).toDate() as DateTime);
    final totalAmount = (summary['totalAmount'] as num?)?.toDouble() ?? 0.0;

    final memberNameById = <String, String>{};
    final memberPromptPayById = <String, String>{};
    for (final item in members) {
      if (item is Map<String, dynamic>) {
        final id = item['id']?.toString() ?? '';
        final name = item['name']?.toString() ?? '';
        final promptPay = item['promptPayNumber']?.toString();
        if (id.isNotEmpty) {
          memberNameById[id] = name;
          if (promptPay != null && promptPay.isNotEmpty) {
            memberPromptPayById[id] = promptPay;
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text((group['name'] as String?) ?? 'Trip Detail')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (group['name'] as String?) ?? 'Quick Split Group',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(label: Text('Members ${members.length}')),
                          Chip(label: Text('Bills ${bills.length}')),
                          Chip(
                            label: Text('Settlements ${settlements.length}'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Total: ${NumberFormat.currency(locale: 'th_TH', symbol: '฿').format(totalAmount)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Saved: $savedAtText',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.72,
                          ),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        context,
                        Icons.people_alt_outlined,
                        'Members (${members.length})',
                      ),
                      const SizedBox(height: 12),
                      if (members.isEmpty)
                        _buildEmptySection(
                          context,
                          'No members in this trip',
                          'Members used in this trip will appear here.',
                        )
                      else
                        ...List.generate(members.length, (index) {
                          final item = members[index];
                          if (item is! Map<String, dynamic>) {
                            return const SizedBox.shrink();
                          }
                          final hasPrompt =
                              item['promptPayNumber']?.toString().isNotEmpty ??
                              false;
                          return Column(
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: theme.colorScheme.primary
                                      .withValues(alpha: 0.12),
                                  child: Icon(
                                    Icons.person_outline,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                title: Text(
                                  item['name']?.toString() ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: hasPrompt
                                    ? Text(
                                        'PromptPay: ${item['promptPayNumber']}',
                                      )
                                    : const Text('No PromptPay'),
                              ),
                              if (index != members.length - 1)
                                const Divider(height: 1),
                            ],
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        context,
                        Icons.receipt_long_outlined,
                        'Bills (${bills.length})',
                      ),
                      const SizedBox(height: 12),
                      if (bills.isEmpty)
                        _buildEmptySection(
                          context,
                          'No bills in this trip',
                          'Bills added to this trip will appear here.',
                        )
                      else
                        ...List.generate(bills.length, (index) {
                          final item = bills[index];
                          if (item is! Map<String, dynamic>) {
                            return const SizedBox.shrink();
                          }
                          final payerId = item['payerId']?.toString() ?? '';
                          final payerName = memberNameById[payerId] ?? payerId;
                          final amount =
                              (item['totalAmount'] as num?)?.toDouble() ?? 0.0;
                          return Column(
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  item['description']?.toString() ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text('Paid by: $payerName'),
                                trailing: Text(
                                  NumberFormat.currency(
                                    locale: 'th_TH',
                                    symbol: '฿',
                                  ).format(amount),
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (index != bills.length - 1)
                                const Divider(height: 1),
                            ],
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        context,
                        Icons.compare_arrows_rounded,
                        'Settlement (${settlements.length})',
                      ),
                      const SizedBox(height: 12),
                      if (settlements.isEmpty)
                        _buildEmptySection(
                          context,
                          'No settlements needed',
                          'Settlement rows will appear when balances are calculated.',
                        )
                      else
                        ...List.generate(settlements.length, (index) {
                          final item = settlements[index];
                          if (item is! Map<String, dynamic>) {
                            return const SizedBox.shrink();
                          }
                          final amount =
                              (item['amount'] as num?)?.toDouble() ?? 0.0;
                          final toMemberId =
                              item['toMemberId']?.toString() ?? '';
                          final promptPayRaw = memberPromptPayById[toMemberId];
                          final normalizedPromptPay = _normalizePromptPayId(
                            promptPayRaw,
                          );
                          final key =
                              '${item['fromMemberId']}-${item['toMemberId']}-${amount.toStringAsFixed(2)}';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  '${item['from'] ?? '-'} -> ${item['to'] ?? '-'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  normalizedPromptPay == null
                                      ? 'No PromptPay available'
                                      : 'PromptPay available',
                                ),
                                trailing: Text(
                                  NumberFormat.currency(
                                    locale: 'th_TH',
                                    symbol: '฿',
                                  ).format(amount),
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  const Spacer(),
                                  if (normalizedPromptPay == null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.secondary
                                            .withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Recipient PromptPay not available',
                                        style: TextStyle(
                                          color: theme.colorScheme.secondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  else
                                    TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _visibleSettlementKey =
                                              _visibleSettlementKey == key
                                              ? null
                                              : key;
                                        });
                                      },
                                      icon: Icon(
                                        _visibleSettlementKey == key
                                            ? Icons.qr_code_2
                                            : Icons.qr_code,
                                      ),
                                      label: Text(
                                        _visibleSettlementKey == key
                                            ? 'Hide saved QR'
                                            : 'Show saved QR',
                                      ),
                                    ),
                                ],
                              ),
                              if (_visibleSettlementKey == key &&
                                  normalizedPromptPay != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: QRCodeGenerate(
                                    promptPayId: normalizedPromptPay,
                                    amount: amount,
                                    height: 320,
                                    isShowAccountDetail: true,
                                    isShowAmountDetail: true,
                                  ),
                                ),
                              if (index != settlements.length - 1)
                                const Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: Divider(height: 1),
                                ),
                            ],
                          );
                        }),
                    ],
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
