class Product {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rating,
    required this.category,
    required this.brand,
    required this.stock,
    required this.thumbnail,
    required this.images,
  });

  final int id;
  final String title;
  final String description;
  final double price;
  final double rating;
  final String category;
  final String? brand;
  final int stock;
  final String thumbnail;
  final List<String> images;

  factory Product.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int) {
      throw const FormatException('Product is missing an id.');
    }

    final rawImages = json['images'];

    return Product(
      id: id,
      title: _text(json['title']),
      description: _text(json['description']),
      price: _number(json['price']),
      rating: _number(json['rating']),
      category: _text(json['category']),
      brand: json['brand'] is String ? json['brand'] as String : null,
      stock: json['stock'] is num ? (json['stock'] as num).toInt() : 0,
      thumbnail: _text(json['thumbnail']),
      images: rawImages is List
          ? rawImages.whereType<String>().toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'rating': rating,
      'category': category,
      'brand': brand,
      'stock': stock,
      'thumbnail': thumbnail,
      'images': images,
    };
  }
}

String _text(Object? value) => value is String ? value : '';

double _number(Object? value) => value is num ? value.toDouble() : 0;
