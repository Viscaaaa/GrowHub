import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/support_model.dart';

class SupportRepository {
  final ApiClient apiClient;

  SupportRepository({required this.apiClient});

  Future<List<FaqItemModel>> getFaqs() async {
    final response = await apiClient.get(ApiEndpoints.faqs);
    if (response.data is List) {
      return (response.data as List)
          .map((item) => FaqItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<SupportTicketModel>> getTickets() async {
    final response = await apiClient.get(ApiEndpoints.tickets);
    if (response.data is List) {
      return (response.data as List)
          .map((t) => SupportTicketModel.fromJson(t as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<SupportTicketModel> createTicket({
    required String subject,
    required String category,
    required String message,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.tickets,
      data: {
        'subject': subject,
        'category': category,
        'message': message,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return SupportTicketModel.fromJson(data['ticket'] as Map<String, dynamic>);
  }
}
