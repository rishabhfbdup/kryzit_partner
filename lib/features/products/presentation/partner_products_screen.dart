import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../data/partner_product_model.dart';

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
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PartnerProduct> get _filteredProducts {
    return partnerInventory.where((p) {
      final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  // Stock edit popup
  void _updateStockDialog(PartnerProduct p) {
    final stockCtrl = TextEditingController(text: p.stockQty.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Stock: ${p.name}'),
        content: TextField(
          controller: stockCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Available Units in Store', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              int val = int.tryParse(stockCtrl.text) ?? 0;
              setState(() {
                p.stockQty = val;
                p.isInStock = val > 0;
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Save Stock'),
          ),
        ],
      ),
    );
  }

  // Add / Edit full product bottom sheet
  void _openProductFormSheet({PartnerProduct? editProduct}) {
    final nameCtrl = TextEditingController(text: editProduct?.name ?? '');
    final priceCtrl = TextEditingController(text: editProduct != null ? editProduct.price.toStringAsFixed(0) : '');
    final mrpCtrl = TextEditingController(text: editProduct != null ? editProduct.mrp.toStringAsFixed(0) : '');
    final unitCtrl = TextEditingController(text: editProduct?.unit ?? '');
    final imgCtrl = TextEditingController(text: editProduct?.imageUrl ?? '');
    final stockCtrl = TextEditingController(text: editProduct != null ? editProduct.stockQty.toString() : '20');
    String category = editProduct?.category ?? 'Vegetables & Fruits';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                      editProduct == null ? 'Add New Product' : 'Edit Product Details',
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
                  decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'Vegetables & Fruits', child: Text('Vegetables & Fruits')),
                    DropdownMenuItem(value: 'Dairy, Bread & Eggs', child: Text('Dairy, Bread & Eggs')),
                    DropdownMenuItem(value: 'Atta, Rice, Oil & Dals', child: Text('Atta, Rice, Oil & Dals')),
                    DropdownMenuItem(value: 'Snacks & Munchies', child: Text('Snacks & Munchies')),
                  ],
                  onChanged: (val) => setModalState(() => category = val!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: unitCtrl,
                        decoration: const InputDecoration(labelText: 'Unit (1 kg)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Price (₹)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: mrpCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'MRP (₹)', border: OutlineInputBorder()),
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
                        decoration: const InputDecoration(labelText: 'Image Direct URL', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: stockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Initial Stock', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                        setState(() {
                          int qty = int.tryParse(stockCtrl.text) ?? 10;
                          if (editProduct == null) {
                            partnerInventory.add(
                              PartnerProduct(
                                id: 'p_${DateTime.now().millisecondsSinceEpoch}',
                                name: nameCtrl.text.trim(),
                                category: category,
                                unit: unitCtrl.text.isEmpty ? '1 pc' : unitCtrl.text.trim(),
                                price: double.tryParse(priceCtrl.text) ?? 50,
                                mrp: double.tryParse(mrpCtrl.text) ?? 60,
                                imageUrl: imgCtrl.text.isEmpty
                                    ? 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&q=80'
                                    : imgCtrl.text.trim(),
                                isInStock: qty > 0,
                                stockQty: qty,
                              ),
                            );
                          } else {
                            editProduct.name = nameCtrl.text.trim();
                            editProduct.category = category;
                            editProduct.unit = unitCtrl.text.trim();
                            editProduct.price = double.tryParse(priceCtrl.text) ?? editProduct.price;
                            editProduct.mrp = double.tryParse(mrpCtrl.text) ?? editProduct.mrp;
                            editProduct.stockQty = qty;
                            editProduct.isInStock = qty > 0;
                            if (imgCtrl.text.isNotEmpty) editProduct.imageUrl = imgCtrl.text.trim();
                          }
                        });
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(editProduct == null ? 'Save & Publish Product' : 'Update Product'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Delete product confirmation
  void _deleteProduct(PartnerProduct product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Kya aap sach me "${product.name}" ko catalog se hatana chahte hain?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => partnerInventory.remove(product));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProducts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Store Inventory & Stock', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openProductFormSheet(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
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
                  onChanged: (val) => setState(() => _searchQuery = val),
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
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text('No products found', style: TextStyle(color: Colors.grey.shade600)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final p = filtered[idx];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                p.imageUrl,
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
                                  Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text('${p.unit} • ₹${p.price.toStringAsFixed(0)} (MRP ₹${p.mrp.toStringAsFixed(0)})', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  // Stock Counter Badge (Tap to update stock count)
                                  InkWell(
                                    onTap: () => _updateStockDialog(p),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: p.stockQty > 5 ? Colors.blue.shade50 : Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: p.stockQty > 5 ? Colors.blue.shade200 : Colors.red.shade200),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.inventory, size: 12, color: p.stockQty > 5 ? Colors.blue.shade800 : Colors.red),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Stock: ${p.stockQty} (Tap to Edit)',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: p.stockQty > 5 ? Colors.blue.shade800 : Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Action Buttons: Edit, Delete, Stock Switch
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
                                      onPressed: () => _openProductFormSheet(editProduct: p),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                      tooltip: 'Delete Product',
                                      onPressed: () => _deleteProduct(p),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: p.isInStock,
                                  activeTrackColor: AppColors.primary,
                                  onChanged: (val) => setState(() => p.isInStock = val),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}