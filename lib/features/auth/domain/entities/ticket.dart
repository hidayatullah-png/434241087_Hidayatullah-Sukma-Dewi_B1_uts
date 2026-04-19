
class Ticket {
  final String id;
  final String title;
  final String description;
  final String status; // open | in_progress | resolved | closed
  final String createdAt;
  final String? assigneeName;

  const Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.assigneeName,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
    id: json['id'].toString(),
    title: json['title'] as String,
    description: json['description'] as String,
    status: json['status'] as String,
    createdAt: json['created_at'] as String,
    assigneeName: json['assignee_name'] as String?,
  );
}
