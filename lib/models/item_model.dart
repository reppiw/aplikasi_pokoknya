class ItemData {
  final String id;
  final String categoryId; // Relasi ke Category
  final String title;
  final String description;
  final double price;
  final DateTime date;
  final bool isActive;

  ItemData({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.price,
    required this.date,
    required this.isActive,
  });
}