class FaqItemModel {
  final String group;
  final String question;
  final String answer;

  FaqItemModel({
    required this.group,
    required this.question,
    required this.answer,
  });

  factory FaqItemModel.fromJson(Map<String, dynamic> json) {
    return FaqItemModel(
      group: json['group'] ?? 'Umum',
      question: json['q'] ?? '',
      answer: json['a'] ?? '',
    );
  }
}

class SupportTicketModel {
  final int id;
  final int userId;
  final String subject;
  final String category;
  final String message;
  final String status;
  final String? createdAt;

  SupportTicketModel({
    required this.id,
    required this.userId,
    required this.subject,
    required this.category,
    required this.message,
    required this.status,
    this.createdAt,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse('${json['user_id']}') ?? 0,
      subject: json['subject'] ?? '',
      category: json['category'] ?? 'general',
      message: json['message'] ?? '',
      status: json['status'] ?? 'open',
      createdAt: json['created_at'],
    );
  }
}
