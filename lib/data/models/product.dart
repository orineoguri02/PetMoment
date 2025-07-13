enum Category {
  all,
  book,
  clothing,
  home,
}

class Product {
  const Product({
    required this.category,
    required this.id,
    required this.name,
    required this.price,
    required this.image,
  });

  final Category category;
  final String id;
  final String name;
  final int price;
  final String image;

  @override
  String toString() => "$name (id=$id)";
} 