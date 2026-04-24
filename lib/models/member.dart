class Member {
  final String id;
  final String name;
  final String? promptPayNumber;
  double netBalance;

  Member({
    required this.id,
    required this.name,
    this.promptPayNumber,
    this.netBalance = 0.0,
  });
}
