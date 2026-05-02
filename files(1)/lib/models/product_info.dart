// ============================================================
// product_info.dart — product + manufacturer snapshot
//
// Holds what we learned from Open Food Facts (or manual entry).
// Screens copy this onto a ScanRecord as the flow progresses.
// ============================================================

class ProductInfo {
  /// Raw barcode digits (often EAN / UPC)
  final String barcode;

  /// Human-readable barcode format description (e.g. "EAN-13").
  final String formatLabel;

  final String productName;
  final String brand;
  final String? category;
  final String? weight;
  final String? batchNo;
  final DateTime? bestBefore;

  final String manufacturerName;
  final String manufacturerEmail;
  final String manufacturerCountry;
  final String certificationNotes;

  /// True when fetched from OFF; false after manual fallback.
  final bool fromOpenFoodFacts;

  const ProductInfo({
    required this.barcode,
    this.formatLabel = 'Unknown',
    required this.productName,
    required this.brand,
    this.category,
    this.weight,
    this.batchNo,
    this.bestBefore,
    required this.manufacturerName,
    required this.manufacturerEmail,
    required this.manufacturerCountry,
    this.certificationNotes = '',
    required this.fromOpenFoodFacts,
  });

  /// Placeholder email when the API does not provide one.
  static String placeholderEmailForBrand(String brand) {
    final slug = brand
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
    final safe = slug.isEmpty ? 'manufacturer' : slug;
    return 'contact@$safe.com';
  }

  ProductInfo copyWith({
    String? barcode,
    String? formatLabel,
    String? productName,
    String? brand,
    String? category,
    String? weight,
    String? batchNo,
    DateTime? bestBefore,
    String? manufacturerName,
    String? manufacturerEmail,
    String? manufacturerCountry,
    String? certificationNotes,
    bool? fromOpenFoodFacts,
  }) {
    return ProductInfo(
      barcode: barcode ?? this.barcode,
      formatLabel: formatLabel ?? this.formatLabel,
      productName: productName ?? this.productName,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      weight: weight ?? this.weight,
      batchNo: batchNo ?? this.batchNo,
      bestBefore: bestBefore ?? this.bestBefore,
      manufacturerName: manufacturerName ?? this.manufacturerName,
      manufacturerEmail: manufacturerEmail ?? this.manufacturerEmail,
      manufacturerCountry: manufacturerCountry ?? this.manufacturerCountry,
      certificationNotes: certificationNotes ?? this.certificationNotes,
      fromOpenFoodFacts: fromOpenFoodFacts ?? this.fromOpenFoodFacts,
    );
  }

  Map<String, dynamic> toJson() => {
        'barcode': barcode,
        'formatLabel': formatLabel,
        'productName': productName,
        'brand': brand,
        'category': category,
        'weight': weight,
        'batchNo': batchNo,
        'bestBefore': bestBefore?.toIso8601String(),
        'manufacturerName': manufacturerName,
        'manufacturerEmail': manufacturerEmail,
        'manufacturerCountry': manufacturerCountry,
        'certificationNotes': certificationNotes,
        'fromOpenFoodFacts': fromOpenFoodFacts,
      };

  factory ProductInfo.fromJson(Map<String, dynamic> j) {
    return ProductInfo(
      barcode: j['barcode'] as String? ?? '',
      formatLabel: j['formatLabel'] as String? ?? 'Unknown',
      productName: j['productName'] as String? ?? '',
      brand: j['brand'] as String? ?? '',
      category: j['category'] as String?,
      weight: j['weight'] as String?,
      batchNo: j['batchNo'] as String?,
      bestBefore: j['bestBefore'] != null
          ? DateTime.tryParse(j['bestBefore'] as String)
          : null,
      manufacturerName: j['manufacturerName'] as String? ?? '',
      manufacturerEmail: j['manufacturerEmail'] as String? ?? '',
      manufacturerCountry: j['manufacturerCountry'] as String? ?? '',
      certificationNotes: j['certificationNotes'] as String? ?? '',
      fromOpenFoodFacts: j['fromOpenFoodFacts'] as bool? ?? false,
    );
  }
}
