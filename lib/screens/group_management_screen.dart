import 'package:flutter/material.dart';
import '../models/member.dart';
import 'multi_bill_ledger_screen.dart';
import 'trip_history_screen.dart';
import '../widgets/guest_mode_banner.dart';

class GroupManagementScreen extends StatefulWidget {
  final bool isGuestMode;
  final VoidCallback onSignOutOrExit;

  const GroupManagementScreen({
    super.key,
    required this.isGuestMode,
    required this.onSignOutOrExit,
  });

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  final List<Member> _members = [];
  final _nameController = TextEditingController();
  final _promptPayController = TextEditingController();

  void _removeMemberAt(int index) {
    setState(() {
      _members.removeAt(index);
    });
  }

  Future<void> _confirmClearAllMembers() async {
    if (_members.isEmpty) {
      return;
    }

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear All Members'),
          content: const Text('Are you sure you want to remove all members?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );

    if (shouldClear == true) {
      setState(() {
        _members.clear();
      });
    }
  }

  void _addMember() {
    if (_nameController.text.isNotEmpty) {
      setState(() {
        _members.add(
          Member(
            id: DateTime.now().toString(),
            name: _nameController.text,
            promptPayNumber: _promptPayController.text.isNotEmpty
                ? _promptPayController.text
                : null,
          ),
        );
        _nameController.clear();
        _promptPayController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Group'),
        actions: [
          if (!widget.isGuestMode)
            Tooltip(
              message: 'View trip history',
              child: IconButton(
                icon: const Icon(Icons.history),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TripHistoryScreen(),
                    ),
                  );
                },
              ),
            ),
          Tooltip(
            message: 'Remove all members',
            child: TextButton(
              onPressed: _members.isEmpty ? null : _confirmClearAllMembers,
              child: Text(
                'Clear All',
                style: TextStyle(
                  color: _members.isEmpty
                      ? theme.disabledColor
                      : theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          Tooltip(
            message: widget.isGuestMode ? 'Exit guest mode' : 'Sign out',
            child: IconButton(
              icon: Icon(widget.isGuestMode ? Icons.exit_to_app : Icons.logout),
              onPressed: widget.onSignOutOrExit,
            ),
          ),
          Tooltip(
            message: 'Go to bill entry',
            child: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MultiBillLedgerScreen(
                      members: _members,
                      isGuestMode: widget.isGuestMode,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
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
                        'Group Members',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Add names and optional PromptPay numbers.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Member Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _promptPayController,
                        decoration: const InputDecoration(
                          labelText: 'PromptPay (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _addMember,
                          child: const Text('Add Member'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Card(
                  color: Colors.white,
                  elevation: 2.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: _members.isEmpty
                      ? const Center(
                          child: Text(
                            'No members yet',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: _members.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final member = _members[index];
                            return ListTile(
                              title: Text(
                                member.name,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle:
                                  member.promptPayNumber != null &&
                                      member.promptPayNumber!.isNotEmpty
                                  ? Text(
                                      'PromptPay: ${member.promptPayNumber}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    )
                                  : const Text(
                                      'No PromptPay',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: theme.colorScheme.secondary,
                                ),
                                onPressed: () => _removeMemberAt(index),
                              ),
                            );
                          },
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
