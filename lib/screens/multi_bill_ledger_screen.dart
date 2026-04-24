import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../models/member.dart';
import '../models/bill.dart';
import '../services/settlement_service.dart';
import '../services/trip_storage_service.dart';
import 'settlement_summary_screen.dart';
import '../widgets/guest_mode_banner.dart';

class MultiBillLedgerScreen extends StatefulWidget {
  final List<Member> members;
  final bool isGuestMode;

  const MultiBillLedgerScreen({
    super.key,
    required this.members,
    required this.isGuestMode,
  });

  @override
  State<MultiBillLedgerScreen> createState() => _MultiBillLedgerScreenState();
}

class _MultiBillLedgerScreenState extends State<MultiBillLedgerScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedPayerId;
  late Set<String> _selectedInvolvedMemberIds;
  final List<Bill> _bills = [];
  final _settlementService = SettlementService();
  final _tripStorageService = TripStorageService();
  bool _isSavingTrip = false;
  String? _lastSavedTripSignature;

  @override
  void initState() {
    super.initState();
    _selectedInvolvedMemberIds = widget.members.map((m) => m.id).toSet();
  }

  void _addBill() {
    if (_descriptionController.text.isNotEmpty &&
        _amountController.text.isNotEmpty &&
        _selectedPayerId != null &&
        _selectedInvolvedMemberIds.isNotEmpty) {
      setState(() {
        _bills.add(
          Bill(
            id: DateTime.now().toString(),
            description: _descriptionController.text,
            totalAmount: double.parse(_amountController.text),
            payerId: _selectedPayerId!,
            involvedMemberIds: _selectedInvolvedMemberIds.toList(),
            timestamp: DateTime.now(),
          ),
        );
        _descriptionController.clear();
        _amountController.clear();
        _selectedPayerId = null;
        _selectedInvolvedMemberIds = widget.members.map((m) => m.id).toSet();
      });
    } else if (_selectedInvolvedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one member sharing this bill.'),
        ),
      );
    }
  }

  String _buildTripSignature(List<Transaction> transactions) {
    final payload = {
      'members': widget.members
          .map((m) => {'id': m.id, 'name': m.name, 'pp': m.promptPayNumber})
          .toList(),
      'bills': _bills
          .map(
            (b) => {
              'id': b.id,
              'description': b.description,
              'totalAmount': b.totalAmount,
              'payerId': b.payerId,
              'involvedMemberIds': [...b.involvedMemberIds]..sort(),
            },
          )
          .toList(),
      'settlements': transactions
          .map(
            (t) => {
              'fromMemberId': t.fromMemberId,
              'toMemberId': t.toMemberId,
              'amount': t.amount,
            },
          )
          .toList(),
    };

    return jsonEncode(payload);
  }

  Future<bool> _saveTripIfLoggedIn(List<Transaction> transactions) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false;
    }

    if (_isSavingTrip) {
      return false;
    }

    final signature = _buildTripSignature(transactions);
    if (_lastSavedTripSignature == signature) {
      return false;
    }

    _isSavingTrip = true;
    try {
      await _tripStorageService.saveTrip(
        userId: user.uid,
        groupName: 'Quick Split Group',
        members: widget.members,
        bills: _bills,
        settlements: transactions,
      );
      _lastSavedTripSignature = signature;
      return true;
    } finally {
      _isSavingTrip = false;
    }
  }

  Future<void> _saveTripOnly() async {
    if (_bills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one bill before saving.')),
      );
      return;
    }

    final transactions = _settlementService.calculateNetSettlement(
      widget.members,
      _bills,
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guest mode: trip is kept locally and not saved.'),
          ),
        );
        return;
      }

      final didSave = await _saveTripIfLoggedIn(transactions);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              didSave
                  ? 'Trip saved to history.'
                  : 'This trip is already saved. No duplicate created.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save trip: $e')));
      }
    }
  }

  Future<void> _calculateSettlement() async {
    if (_bills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one bill first.')),
      );
      return;
    }

    final transactions = _settlementService.calculateNetSettlement(
      widget.members,
      _bills,
    );

    try {
      await _saveTripIfLoggedIn(transactions);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save trip: $e')));
      }
    }

    if (!mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettlementSummaryScreen(
          transactions: transactions,
          members: widget.members,
          isGuestMode: widget.isGuestMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Add Bills'),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              if (widget.isGuestMode) ...[
                const GuestModeBanner(),
                const SizedBox(height: 12),
              ],
              Card(
                color: Colors.white,
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bill Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Add each expense before calculating settlement.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Bill Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedPayerId,
                        decoration: const InputDecoration(
                          labelText: 'Paid By',
                          border: OutlineInputBorder(),
                        ),
                        items: widget.members.map((Member member) {
                          return DropdownMenuItem<String>(
                            value: member.id,
                            child: Text(member.name),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedPayerId = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Who shared this bill?',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: widget.members.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final member = widget.members[index];
                            final isChecked = _selectedInvolvedMemberIds
                                .contains(member.id);
                            return CheckboxListTile(
                              dense: true,
                              activeColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                member.name,
                                style: const TextStyle(color: Colors.black87),
                              ),
                              value: isChecked,
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedInvolvedMemberIds.add(member.id);
                                  } else {
                                    _selectedInvolvedMemberIds.remove(
                                      member.id,
                                    );
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _addBill,
                          child: const Text('Add Bill'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSavingTrip
                              ? null
                              : _calculateSettlement,
                          child: const Text('Settle Up'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSavingTrip ? null : _saveTripOnly,
                          child: const Text('Save Trip'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: Colors.white,
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: _bills.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(
                          child: Text(
                            'No bills added yet',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _bills.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final bill = _bills[index];
                          final payer = widget.members.firstWhere(
                            (m) => m.id == bill.payerId,
                          );
                          final excludedMembers = widget.members
                              .where(
                                (m) => !bill.involvedMemberIds.contains(m.id),
                              )
                              .map((m) => m.name)
                              .toList();
                          final formattedAmount = NumberFormat.currency(
                            locale: 'th_TH',
                            symbol: '฿',
                          ).format(bill.totalAmount);

                          return ListTile(
                            title: Text(
                              bill.description,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              excludedMembers.isEmpty
                                  ? 'Paid by: ${payer.name} • Shared by everyone'
                                  : 'Paid by: ${payer.name} • Excluded: ${excludedMembers.join(', ')}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            trailing: Text(
                              formattedAmount,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
  }
}
