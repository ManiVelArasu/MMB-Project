

class ProductList {
  final bool? success;
  final List<ProductListData> data;
  final Meta? meta;

  ProductList({
    required this.success,
    required this.data,
    required this.meta,
  });

  factory ProductList.fromJson(Map<String, dynamic> json) => ProductList(
    success: json["success"]??false,
    data:json["data"]==null?[]: List<ProductListData>.from(json["data"].map((x) => ProductListData.fromJson(x))),
    meta:json["meta"]==null?null: Meta.fromJson(json["meta"]),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "meta": meta?.toJson(),
  };
}

class ProductListData {
  final String? id;
  final String? uid;
  final String? businessId;
  final String? type;
  final String? name;
  final String? unit;
  final String? serviceArea;
  final String? description;
  final String? price;
  final String? offerPrice;
  final String? isActive;
  final String? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<dynamic> productImages;

  ProductListData({
    required this.id,
    required this.uid,
    required this.businessId,
    required this.type,
    required this.name,
    required this.unit,
    required this.serviceArea,
    required this.description,
    required this.price,
    required this.offerPrice,
    required this.isActive,
    required this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.productImages,
  });

  factory ProductListData.fromJson(Map<String, dynamic> json) => ProductListData(
    id: json["id"]?.toString(),
    uid: json["uid"]?.toString(),
    businessId: json["business_id"]?.toString(),
    type: json["type"]?.toString(),
    name: json["name"]?.toString(),
    unit: json["unit"]?.toString(),
    serviceArea: json["service_area"]?.toString(),
    description: json["description"]?.toString(),
    price: json["price"]?.toString(),
    offerPrice: json["offer_price"]?.toString(),
    isActive: json["is_active"]?.toString(),
    deletedAt: json["deleted_at"]?.toString(),
    createdAt:json["created_at"]==null?null: DateTime.parse(json["created_at"]),
    updatedAt:json["updated_at"]==null?null: DateTime.parse(json["updated_at"]),
    productImages:json["ProductImages"]==null?[]: List<dynamic>.from(json["ProductImages"].map((x) => x)),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "uid": uid,
    "business_id": businessId,
    "type": type,
    "name": name,
    "unit": unit,
    "service_area": serviceArea,
    "description": description,
    "price": price,
    "offer_price": offerPrice,
    "is_active": isActive,
    "deleted_at": deletedAt,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "ProductImages": List<dynamic>.from(productImages.map((x) => x)),
  };
}

class Meta {
  final ProductCounts ? counts;

  Meta({
    required this.counts,
  });

  factory Meta.fromJson(Map<String, dynamic> json) => Meta(
    counts:json["counts"]==null?null: ProductCounts.fromJson(json["counts"]),
  );

  Map<String, dynamic> toJson() => {
    "counts": counts?.toJson(),
  };
}

class ProductCounts  {
  final String? all;
  final String? products;
  final String? services;
  final String? inactive;

  ProductCounts ({
    required this.all,
    required this.products,
    required this.services,
    required this.inactive,
  });

  factory ProductCounts .fromJson(Map<String, dynamic> json) => ProductCounts (
    all: json["all"]?.toString(),
    products: json["products"]?.toString(),
    services: json["services"]?.toString(),
    inactive: json["inactive"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "all": all,
    "products": products,
    "services": services,
    "inactive": inactive,
  };
}
