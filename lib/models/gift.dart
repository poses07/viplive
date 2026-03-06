class Gift {
  final int id;
  final String name;
  final int price;
  final String iconUrl;
  final String category;

  Gift({
    required this.id,
    required this.name,
    required this.price,
    required this.iconUrl,
    required this.category,
  });

  factory Gift.fromJson(Map<String, dynamic> json) {
    return Gift(
      id: int.parse(json['id'].toString()),
      name: json['name'] as String,
      price: int.parse(json['price'].toString()),
      iconUrl: json['icon_url'] as String? ?? '',
      category: json['category'] as String? ?? 'popular',
    );
  }
}
