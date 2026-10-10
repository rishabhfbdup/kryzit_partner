class PartnerProduct {
  final String id;
  String name;
  String category;
  String unit;
  double price;
  double mrp;
  String imageUrl;
  bool isInStock;
  int stockQty; // Dukandar ka exact stock count

  PartnerProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.price,
    required this.mrp,
    required this.imageUrl,
    this.isInStock = true,
    required this.stockQty,
  });
}

List<PartnerProduct> partnerInventory = [
  PartnerProduct(
    id: 'p1',
    name: 'Fresh Desi Tomato (Tamatar)',
    category: 'Vegetables & Fruits',
    unit: '1 kg',
    price: 32,
    mrp: 45,
    imageUrl: 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=500&q=80',
    isInStock: true,
    stockQty: 45,
  ),
  PartnerProduct(
    id: 'p2',
    name: 'Amul Taaza Toned Milk',
    category: 'Dairy, Bread & Eggs',
    unit: '500 ml',
    price: 27,
    mrp: 27,
    imageUrl: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=500&q=80',
    isInStock: true,
    stockQty: 28,
  ),
  PartnerProduct(
    id: 'p3',
    name: 'Fortune Sunlite Refined Oil',
    category: 'Atta, Rice, Oil & Dals',
    unit: '1 L',
    price: 135,
    mrp: 155,
    imageUrl: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=500&q=80',
    isInStock: true,
    stockQty: 12,
  ),
];