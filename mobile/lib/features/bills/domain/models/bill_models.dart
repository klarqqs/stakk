/// Top-level bill category (e.g. Airtime, Data, Electricity, TV Cable)
class BillCategoryModel {
  final int id;
  final String code;
  final String name;
  final String description;

  const BillCategoryModel({
    required this.id,
    required this.code,
    required this.name,
    this.description = '',
  });

  factory BillCategoryModel.fromJson(Map<String, dynamic> json) =>
      BillCategoryModel(
        id: json['id'] as int? ?? 0,
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
      );
}

/// Provider within a category (e.g. MTN, Glo, Airtel for Airtime)
class BillProviderModel {
  final int id;
  final String billerCode;
  final String name;
  final String shortName;

  const BillProviderModel({
    required this.id,
    required this.billerCode,
    required this.name,
    this.shortName = '',
  });

  factory BillProviderModel.fromJson(Map<String, dynamic> json) =>
      BillProviderModel(
        id: json['id'] as int? ?? 0,
        billerCode: json['billerCode'] as String? ?? '',
        name: json['name'] as String? ?? '',
        shortName: json['shortName'] as String? ?? json['name'] as String? ?? '',
      );
}

/// Product within a provider (e.g. data bundle, DSTV plan, fixed amount)
class BillProductModel {
  final String id;
  final String productCode;
  final String name;
  final double amount;

  const BillProductModel({
    required this.id,
    required this.productCode,
    required this.name,
    this.amount = 0,
  });

  factory BillProductModel.fromJson(Map<String, dynamic> json) =>
      BillProductModel(
        id: json['id']?.toString() ?? json['productCode']?.toString() ?? '',
        productCode: json['productCode']?.toString() ?? json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
      );
}
