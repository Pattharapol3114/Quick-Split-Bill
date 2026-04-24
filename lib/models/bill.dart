class Bill {
  final String id;
  final String description;
  final double totalAmount;
  final String payerId;
  final List<String> involvedMemberIds;
  final DateTime timestamp;

  Bill({
    required this.id,
    required this.description,
    required this.totalAmount,
    required this.payerId,
    required this.involvedMemberIds,
    required this.timestamp,
  });
}
