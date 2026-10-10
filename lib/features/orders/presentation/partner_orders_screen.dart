import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';

class PartnerOrdersScreen extends StatefulWidget {
  const PartnerOrdersScreen({super.key});

  @override
  State<PartnerOrdersScreen> createState() => _PartnerOrdersScreenState();
}

class _PartnerOrdersScreenState extends State<PartnerOrdersScreen> {
  double _getCommissionPercent(double amount) {
    if (amount <= 50) return 12.0;
    if (amount <= 100) return 15.0;
    if (amount <= 150) return 18.0;
    if (amount <= 300) return 20.0;
    if (amount <= 500) return 23.0;
    return 25.0;
  }

  Future<void> _updateOrderStatus(String docId, String newStatus) async {
    await FirebaseFirestore.instance.collection('orders').doc(docId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Row(
          children: [
            Icon(Icons.storefront, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Kamalganj Dark Store Hub', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Row(
              children: [
                CircleAvatar(radius: 4, backgroundColor: Colors.green),
                SizedBox(width: 6),
                Text('SYSTEM ACTIVE', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data?.docs ?? [];
          
          // Store Partner ko sirf wo orders dekhne hain jo PLACED ya STORE_PACKING hain.
          // Packed hone ke baad wo Rider ke paas chala jata hai!
          final storeActiveDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? '';
            return status == 'PLACED' || status == 'STORE_PACKING';
          }).toList();

          final int totalDelivered = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'DELIVERED';
          }).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0C831F), Color(0xFF13A82B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dark Store Packing Desk',
                            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Active Orders: ${storeActiveDocs.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total Handed Over / Delivered: $totalDelivered',
                            style: const TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.inventory, color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4 Grid Metric Cards
                Row(
                  children: [
                    _buildStatCard('Total Orders', '${allDocs.length}', Icons.receipt_long, Colors.blue),
                    const SizedBox(width: 8),
                    _buildStatCard('To Pack', '${storeActiveDocs.length}', Icons.pending_actions, Colors.orange),
                    const SizedBox(width: 8),
                    _buildStatCard('Delivered', '$totalDelivered', Icons.check_circle_outline, Colors.green),
                    const SizedBox(width: 8),
                    _buildStatCard('Live Sync', 'ON', Icons.sync, Colors.teal),
                  ],
                ),
                const SizedBox(height: 20),

                const Text('Orders To Pack (Store Queue)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                if (storeActiveDocs.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 44),
                          SizedBox(height: 10),
                          Text('Sabhi Orders Pack Ho Chuke Hain!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          SizedBox(height: 4),
                          Text('Jaise hi Customer App se naya order aayega, yahan real-time dikhega.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  )
                else
                  ...storeActiveDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final String docId = doc.id;
                    final String orderId = data['orderId'] ?? '#KZ-ORDER';
                    final String status = data['status'] ?? 'PLACED';
                    final String customerName = data['customerName'] ?? 'Customer';
                    final String customerAddress = data['customerAddress'] ?? 'Kamalganj';
                    final double billAmount = ((data['totalAmount'] ?? 148.0) as num).toDouble();
                    final List items = (data['items'] as List?) ?? [];

                    final double commPercent = _getCommissionPercent(billAmount);
                    final double commAmount = (billAmount * commPercent) / 100;
                    final double currentPayout = billAmount - commAmount;

                    final bool isPending = status == 'PLACED';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isPending ? Colors.red : AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: isPending ? Colors.red.shade100 : Colors.green.shade100,
                                    child: Icon(
                                      isPending ? Icons.notifications_active : Icons.shopping_bag,
                                      color: isPending ? Colors.red : Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Order $orderId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      Text(
                                        'Customer: $customerName • $customerAddress',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isPending ? Colors.red : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPending ? Colors.red.shade50 : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isPending ? Colors.red : Colors.orange),
                                ),
                                child: Text(
                                  isPending ? '🚨 NAYA ORDER' : 'PACKING CHALU...',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isPending ? Colors.red : Colors.orange.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),

                          if (items.isNotEmpty)
                            ...items.map((it) {
                              final name = it['title'] ?? it['name'] ?? 'Item';
                              final qty = it['quantity'] ?? 1;
                              final price = it['price'] ?? 0;
                              return _buildOrderItem('$name', '$qty Pack', '₹$price');
                            })
                          else ...[
                            _buildOrderItem('General Grocery Items', '1 Pack', '₹${billAmount.toStringAsFixed(0)}'),
                          ],

                          const Divider(height: 20),

                          // Financial Breakdown
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Bill Total:', style: TextStyle(fontSize: 12)),
                                    Text('₹${billAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Commission (${commPercent.toStringAsFixed(0)}%):', style: const TextStyle(color: Colors.red, fontSize: 12)),
                                    Text('-₹${commAmount.toStringAsFixed(1)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                                const Divider(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Store Net Payout:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                                    Text('₹${currentPayout.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Only Store Actions
                          if (isPending)
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton.icon(
                                onPressed: () => _updateOrderStatus(docId, 'STORE_PACKING'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('Accept & Start Packing'),
                              ),
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton.icon(
                                onPressed: () => _updateOrderStatus(docId, 'STORE_PACKED'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                                icon: const Icon(Icons.inventory_2),
                                label: const Text('Mark as Packed (Handover to Rider)'),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(count, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(String name, String qty, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
          Text('$qty • $price', style: const TextStyle(color: Colors.black87, fontSize: 12)),
        ],
      ),
    );
  }
}