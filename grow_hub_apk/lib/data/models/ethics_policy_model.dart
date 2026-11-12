class EthicsPolicyModel {
  final int id;
  final String title;
  final String description;
  final int pointDeduction;
  final bool isActive;
  final int sortOrder;

  EthicsPolicyModel({
    required this.id,
    required this.title,
    required this.description,
    required this.pointDeduction,
    required this.isActive,
    required this.sortOrder,
  });

  factory EthicsPolicyModel.fromJson(Map<String, dynamic> json) {
    return EthicsPolicyModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      pointDeduction: json['point_deduction'] is int
          ? json['point_deduction']
          : int.tryParse('${json['point_deduction']}') ?? 1,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      sortOrder: json['sort_order'] is int
          ? json['sort_order']
          : int.tryParse('${json['sort_order']}') ?? 0,
    );
  }
}

