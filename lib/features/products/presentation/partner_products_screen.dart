import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';

class PartnerProductsScreen extends StatefulWidget {
  const PartnerProductsScreen({super.key});

  @override
  State<PartnerProductsScreen> createState() => _PartnerProductsScreenState();
}

class _PartnerProductsScreenState extends State<PartnerProductsScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Vegetables & Fruits',
    'Dairy, Bread & Eggs',
    'Atta, Rice, Oil & Dals',
    'Snacks & Munchies',
    'Cold Drinks & Juices',
    'Instant Food',
    'Cleaning & Household',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 1. Live Firestore Switch Toggle (In Stock / Out of Stock)
  Future<void> _toggleStock(String docId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance.collection('products').doc(docId).set({
        'inStock': !currentStatus,
        'isAvailable': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating stock: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 2. Stock Count Edit Popup
  void _updateStockDialog(String docId, String name, int currentQty) {
    final stockCtrl = TextEditingController(text: currentQty.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Stock: $name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: stockCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Available Units in Hub',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              int val = int.tryParse(stockCtrl.text.trim()) ?? 0;
              await FirebaseFirestore.instance.collection('products').doc(docId).set({
                'stockQuantity': val,
                'inStock': val > 0,
                'isAvailable': val > 0,
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save Stock'),
          ),
        ],
      ),
    );
  }

  // 3. Add or Edit Product BottomSheet (Direct Sync to Customer App)
  void _openProductFormSheet({String? editDocId, Map<String, dynamic>? editData}) {
    final nameCtrl = TextEditingController(text: editData?['name'] ?? '');
    final priceCtrl = TextEditingController(text: editData != null ? editData['price'].toString() : '');
    final mrpCtrl = TextEditingController(text: editData != null ? editData['mrp'].toString() : '');
    final unitCtrl = TextEditingController(text: editData?['unit'] ?? '1 kg');
    final imgCtrl = TextEditingController(text: editData?['imageUrl'] ?? '');
    final stockCtrl = TextEditingController(
      text: editData != null ? (editData['stockQuantity'] ?? 20).toString() : '20',
    );
    String category = editData?['category'] ?? 'Vegetables & Fruits';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      editDocId == null ? 'Add New Product (Go Live)' : 'Edit Product Details',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Product Name (e.g. Fresh Potato / Amul Milk)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.where((c) => c != 'All').map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (val) => setModalState(() => category = val!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: unitCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Unit (1 kg / 500 ml)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Selling Price (₹)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: mrpCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'MRP (₹)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: imgCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Image Direct URL',
                          hintText: 'https://images.unsplash.com/...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: stockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stock Units',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Kripya valid product name aur price daalein!')),
                        );
                        return;
                      }

                      int qty = int.tryParse(stockCtrl.text.trim()) ?? 10;
                      int price = int.tryParse(priceCtrl.text.trim()) ?? 50;
                      int mrp = int.tryParse(mrpCtrl.text.trim()) ?? (price + 10);
                      String img = imgCtrl.text.trim().isEmpty
                          ? 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&q=80'
                          : imgCtrl.text.trim();

                      final String targetId = editDocId ?? 'prod_${DateTime.now().millisecondsSinceEpoch}';

                      // Firestore me instant push -> Customer app par live
                      await FirebaseFirestore.instance.collection('products').doc(targetId).set({
                        'id': targetId,
                        'name': nameCtrl.text.trim(),
                        'category': category,
                        'unit': unitCtrl.text.trim().isEmpty ? '1 unit' : unitCtrl.text.trim(),
                        'price': price,
                        'mrp': mrp,
                        'imageUrl': img,
                        'stockQuantity': qty,
                        'inStock': qty > 0,
                        'isAvailable': qty > 0,
                        'updatedAt': FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));

                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"${nameCtrl.text.trim()}" customer app par LIVE ho gaya!'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    },
                    child: Text(
                      editDocId == null ? 'Save & Publish Product (Live Now)' : 'Update Product Live',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 4. Delete Product Confirmation Dialog
  void _deleteProduct(String docId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Kya aap sach me "$name" ko catalog se hatana chahte hain?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('products').doc(docId).delete();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Store Inventory & Stock (Live Sync)',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openProductFormSheet(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products by name...',
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: AppColors.primaryLight,
                          onSelected: (val) => setState(() => _selectedCategory = cat),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Real-time Firestore Product List Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('Abhi koi product live nahi hai.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Neeche "+ Add Product" dabakar live karein.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  );
                }

                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final category = data['category'] ?? '';

                  final matchesCategory = _selectedCategory == 'All' || category == _selectedCategory;
                  final matchesSearch = name.contains(_searchQuery.toLowerCase());
                  return matchesCategory && matchesSearch;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Text('No products found matching "$_searchQuery"', style: TextStyle(color: Colors.grey.shade600)),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final doc = filteredDocs[idx];
                    final data = doc.data() as Map<String, dynamic>;

                    final String name = data['name'] ?? 'Product';
                    final int price = data['price'] ?? 0;
                    final int mrp = data['mrp'] ?? price;
                    final String unit = data['unit'] ?? '1 unit';
                    final String imageUrl = data['imageUrl'] ?? '';
                    final bool isInStock = data['inStock'] ?? data['isAvailable'] ?? false;
                    final int stockQty = data['stockQuantity'] ?? 0;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isInStock ? Colors.green.shade200 : Colors.red.shade200,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: 55,
                              height: 55,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 55,
                                height: 55,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('$unit • ₹$price (MRP ₹$mrp)', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                // Tap to Edit Stock Count
                                InkWell(
                                  onTap: () => _updateStockDialog(doc.id, name, stockQty),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: stockQty > 5 ? Colors.blue.shade50 : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: stockQty > 5 ? Colors.blue.shade200 : Colors.red.shade200),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.inventory, size: 12, color: stockQty > 5 ? Colors.blue.shade800 : Colors.red),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Stock: $stockQty (Tap to Edit)',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: stockQty > 5 ? Colors.blue.shade800 : Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Actions: Edit, Delete, Stock Toggle Switch
                          Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                    icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey),
                                    tooltip: 'Edit Product',
                                    onPressed: () => _openProductFormSheet(editDocId: doc.id, editData: data),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                    tooltip: 'Delete Product',
                                    onPressed: () => _deleteProduct(doc.id, name),
                                  ),
                                ],
                              ),
                              Switch(
                                value: isInStock,
                                activeTrackColor: AppColors.primary,
                                onChanged: (val) => _toggleStock(doc.id, isInStock),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}