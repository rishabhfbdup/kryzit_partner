import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'core/constants/app_colors.dart';
import 'features/orders/presentation/partner_orders_screen.dart';
import 'features/products/presentation/partner_products_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const KryzitPartnerApp());
}

class KryzitPartnerApp extends StatelessWidget {
  const KryzitPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kryzit Master Admin & Partner Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      home: const AuthGatewayScreen(),
    );
  }
}

// -------------------------------------------------------------
// 1. DUAL GATEWAY (Partner / Super Admin & HR Login)
// -------------------------------------------------------------
class AuthGatewayScreen extends StatefulWidget {
  const AuthGatewayScreen({super.key});

  @override
  State<AuthGatewayScreen> createState() => _AuthGatewayScreenState();
}

class _AuthGatewayScreenState extends State<AuthGatewayScreen> {
  bool _isAdminMode = false;
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = '';

  static const String superAdminId = 'Kryzit@9616';
  static const String superAdminPass = 'Kryzit@961664#';

  Future<void> _handleLogin() async {
    final inputId = _idController.text.trim();
    final inputPass = _passwordController.text.trim();

    if (inputId.isEmpty || inputPass.isEmpty) {
      setState(() => _errorMessage = 'Kripya ID aur Password dono enter karein!');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    if (_isAdminMode) {
      // 1. Super Admin Match
      if (inputId == superAdminId && inputPass == superAdminPass) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (c) => const AdminMasterPortalScreen(role: 'SUPER_ADMIN', staffName: 'Main Admin'),
          ),
        );
        return;
      }

      // 2. HR / Sub-Admin Match from Firestore
      try {
        final hrDoc = await FirebaseFirestore.instance
            .collection('admin_staff')
            .where('staffId', isEqualTo: inputId)
            .where('password', isEqualTo: inputPass)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();

        if (hrDoc.docs.isNotEmpty) {
          final data = hrDoc.docs.first.data();
          setState(() => _isLoading = false);
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (c) => AdminMasterPortalScreen(
                role: data['role'] ?? 'HR_ACCOUNTS',
                staffName: data['name'] ?? 'Staff User',
              ),
            ),
          );
          return;
        }
      } catch (_) {}

      setState(() {
        _isLoading = false;
        _errorMessage = 'Galat Admin/HR ID ya Password!';
      });
    } else {
      // Partner Login from Firestore
      try {
        final query = await FirebaseFirestore.instance
            .collection('partners')
            .where('partnerId', isEqualTo: inputId)
            .where('password', isEqualTo: inputPass)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final partnerData = query.docs.first.data();
          final bool isSuspended = partnerData['isSuspended'] ?? false;
          final bool isActive = partnerData['isActive'] ?? true;

          if (isSuspended || !isActive) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Aapki Partner ID suspended hai! Admin se sampark karein.';
            });
            return;
          }

          setState(() => _isLoading = false);
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (c) => PartnerMainDashboard(
                partnerId: partnerData['partnerId'] ?? inputId,
                shopName: partnerData['shopName'] ?? 'Dark Store Hub',
              ),
            ),
          );
        } else {
          // Backward compatibility fallback
          if (inputId.toUpperCase() == 'KAMALGANJ01' && inputPass == 'admin') {
            setState(() => _isLoading = false);
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (c) => const PartnerMainDashboard(
                  partnerId: 'KAMALGANJ01',
                  shopName: 'Kamalganj Dark Store Hub',
                ),
              ),
            );
            return;
          }

          setState(() {
            _isLoading = false;
            _errorMessage = 'Galat Partner ID ya Password!';
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Login Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9EE),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: _isAdminMode ? Colors.blueGrey.shade900 : Colors.amber.shade400,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    _isAdminMode ? 'kryzit super console' : 'kryzit partner portal',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: _isAdminMode ? Colors.white : Colors.black87,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _isAdminMode ? 'Admin & HR Financial Desk' : 'Dark Store Order & Stock Hub',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 20),

                // Dual Toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _isAdminMode = false;
                            _errorMessage = '';
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isAdminMode ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Partner Login',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: !_isAdminMode ? AppColors.primary : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _isAdminMode = true;
                            _errorMessage = '';
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isAdminMode ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Admin / HR Login',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _isAdminMode ? Colors.blueGrey.shade900 : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_errorMessage.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _idController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(_isAdminMode ? Icons.admin_panel_settings_rounded : Icons.storefront_rounded),
                      hintText: _isAdminMode ? 'Admin / HR Staff ID' : 'Partner ID',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      hintText: 'Password',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAdminMode ? Colors.blueGrey.shade900 : AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isAdminMode ? 'Enter Admin / HR Console ›' : 'Enter Partner Dashboard ›',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
}

// -------------------------------------------------------------
// 2. ENTERPRISE SUPER ADMIN & HR MASTER CONSOLE
// -------------------------------------------------------------
class AdminMasterPortalScreen extends StatefulWidget {
  final String role;
  final String staffName;
  const AdminMasterPortalScreen({super.key, required this.role, required this.staffName});

  @override
  State<AdminMasterPortalScreen> createState() => _AdminMasterPortalScreenState();
}

class _AdminMasterPortalScreenState extends State<AdminMasterPortalScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kryzit Control Center', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            Text('${widget.staffName} (${widget.role})', style: const TextStyle(fontSize: 11, color: Colors.amber)),
          ],
        ),
        backgroundColor: Colors.blueGrey.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (c) => const AuthGatewayScreen()),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTab,
        children: [
          AdminShopsPayoutTab(role: widget.role),
          AdminRidersPayoutTab(role: widget.role),
          const AdminInventoryAuditTab(),
          AdminHRManagementTab(isSuperAdmin: widget.role == 'SUPER_ADMIN'),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blueGrey.shade900,
        unselectedItemColor: Colors.grey.shade500,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.storefront_rounded), label: 'Shops & Payout'),
          BottomNavigationBarItem(icon: Icon(Icons.delivery_dining_rounded), label: 'Riders Payout'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_rounded), label: 'Store Inventory'),
          BottomNavigationBarItem(icon: Icon(Icons.badge_rounded), label: 'HR / Staff IDs'),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 1: SHOPS COMMISSION, 1-CLICK PAYOUT & ON-BOARDING
// -------------------------------------------------------------
class AdminShopsPayoutTab extends StatefulWidget {
  final String role;
  const AdminShopsPayoutTab({super.key, required this.role});

  @override
  State<AdminShopsPayoutTab> createState() => _AdminShopsPayoutTabState();
}

class _AdminShopsPayoutTabState extends State<AdminShopsPayoutTab> {
  // 1-Click Payout Settlement Dialog
  void _executeShopPayout(String docId, String shopName, String bank, String upi, int amount) {
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payout amount ₹0 hai. Koi pending balance nahi hai!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Execute 1-Click Payout: $shopName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transfer Amount: ₹$amount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
            const SizedBox(height: 6),
            Text('Bank A/C: $bank', style: const TextStyle(fontSize: 12)),
            Text('UPI ID: $upi', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const Divider(height: 16),
            const Text('Platform Commission (10%) deduct ho chuki hai. Bank account me transfer confirm karein:', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F9D58)),
            onPressed: () async {
              // Reset pending payout & record settlement log
              await FirebaseFirestore.instance.collection('partners').doc(docId).update({
                'pendingPayout': 0,
                'lastSettledAmount': amount,
                'lastSettledAt': FieldValue.serverTimestamp(),
              });

              await FirebaseFirestore.instance.collection('settlement_logs').add({
                'partnerId': docId,
                'shopName': shopName,
                'amount': amount,
                'type': 'PARTNER_PAYOUT',
                'settledAt': FieldValue.serverTimestamp(),
              });

              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('₹$amount payout to $shopName successfully SETTLED!'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Confirm Transfer & Clear', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('partners').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) return const Center(child: Text('Koi shop register nahi hai.'));

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final pId = docs[i].id;
            final shopName = data['shopName'] ?? 'Shop';
            final owner = data['ownerName'] ?? '';
            final phone = data['phone'] ?? '';
            final bank = data['bankAccount'] ?? 'N/A';
            final upi = data['upiId'] ?? 'N/A';
            final bool isSuspended = data['isSuspended'] ?? false;
            final int grossSales = (data['totalSales'] as num?)?.toInt() ?? 2450;
            // 10% commission deduction rule
            final int commission = (grossSales * 0.10).round();
            final int netPayout = (data['pendingPayout'] as num?)?.toInt() ?? (grossSales - commission);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSuspended ? Colors.red.shade300 : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(shopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSuspended ? Colors.red.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isSuspended ? 'SUSPENDED' : 'ACTIVE',
                          style: TextStyle(color: isSuspended ? Colors.red : Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Owner: $owner • Phone: +91 $phone', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('Bank: $bank | UPI: $upi', style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Gross Sales: ₹$grossSales', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          Text('Comm. Cut (10%): -₹$commission', style: const TextStyle(fontSize: 11, color: Colors.red)),
                          Text('Payable: ₹$netPayout', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F9D58)),
                            icon: const Icon(Icons.send_rounded, size: 14, color: Colors.white),
                            label: const Text('1-Click Pay', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () => _executeShopPayout(pId, shopName, bank, upi, netPayout),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: Icon(isSuspended ? Icons.play_arrow_rounded : Icons.block_flipped, color: isSuspended ? Colors.green : Colors.red),
                            onPressed: () {
                              FirebaseFirestore.instance.collection('partners').doc(pId).update({
                                'isSuspended': !isSuspended,
                                'isActive': isSuspended,
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// -------------------------------------------------------------
// TAB 2: RIDERS APPROVAL, 1-CLICK PAYOUT & SUSPENSION
// -------------------------------------------------------------
class AdminRidersPayoutTab extends StatelessWidget {
  final String role;
  const AdminRidersPayoutTab({super.key, required this.role});

  void _executeRiderPayout(BuildContext context, String rId, String name, String upi, int amount) {
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rider ka koi pending balance nahi hai!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear Rider Earning: $name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payout Amount: ₹$amount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
            const SizedBox(height: 4),
            Text('Rider UPI ID: $upi', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const Divider(height: 16),
            const Text('Doorstep delivery rate: ₹35 per completed delivery.', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F9D58)),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('riders').doc(rId).update({
                'payoutEarned': 0,
                'lastSettledAt': FieldValue.serverTimestamp(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('₹$amount paid to Rider $name!'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Transfer & Clear', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('riders').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) return const Center(child: Text('Koi registered rider nahi hai.'));

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final rId = docs[i].id;
            final name = data['name'] ?? 'Rider';
            final phone = data['phone'] ?? '';
            final upi = data['upiId'] ?? 'rider@upi';
            final bool isApproved = data['isApproved'] ?? false;
            final bool isSuspended = data['isSuspended'] ?? false;
            final int deliveries = (data['totalDeliveries'] as num?)?.toInt() ?? 8;
            final int payable = (data['payoutEarned'] as num?)?.toInt() ?? (deliveries * 35);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSuspended ? Colors.red.shade300 : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$name ($rId)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: !isApproved ? Colors.orange.shade50 : (isSuspended ? Colors.red.shade50 : Colors.green.shade50),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          !isApproved ? 'PENDING APPROVAL' : (isSuspended ? 'SUSPENDED' : 'ACTIVE RIDER'),
                          style: TextStyle(
                            color: !isApproved ? Colors.orange.shade800 : (isSuspended ? Colors.red : Colors.green.shade800),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Phone: +91 $phone | UPI: $upi', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('Deliveries Completed: $deliveries orders', style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Payable: ₹$payable', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green)),
                      Row(
                        children: [
                          if (!isApproved)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: () => FirebaseFirestore.instance.collection('riders').doc(rId).update({'isApproved': true}),
                              child: const Text('Approve', style: TextStyle(color: Colors.white, fontSize: 11)),
                            )
                          else ...[
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F9D58)),
                              icon: const Icon(Icons.send_rounded, size: 14, color: Colors.white),
                              label: const Text('1-Click Pay', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () => _executeRiderPayout(context, rId, name, upi, payable),
                            ),
                            IconButton(
                              icon: Icon(isSuspended ? Icons.play_arrow : Icons.block, color: isSuspended ? Colors.green : Colors.red),
                              onPressed: () {
                                FirebaseFirestore.instance.collection('riders').doc(rId).update({'isSuspended': !isSuspended});
                              },
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// -------------------------------------------------------------
// TAB 3: LIVE STORE INVENTORY & STOCK AUDIT
// -------------------------------------------------------------
class AdminInventoryAuditTab extends StatelessWidget {
  const AdminInventoryAuditTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final products = snapshot.data!.docs;

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade900,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('Total Listed: ${products.length} Items', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('In Stock: ${products.where((p) => (p.data() as Map)['inStock'] == true).length}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  Text('Out of Stock: ${products.where((p) => (p.data() as Map)['inStock'] != true).length}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: products.length,
                itemBuilder: (context, i) {
                  final data = products[i].data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'Item';
                  final price = data['price'] ?? 0;
                  final unit = data['unit'] ?? '';
                  final int stockQty = (data['stockQuantity'] as num?)?.toInt() ?? 0;
                  final bool inStock = data['inStock'] ?? false;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(Icons.circle, size: 12, color: inStock ? Colors.green : Colors.red),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('$unit • ₹$price | Hub Stock: $stockQty units'),
                      trailing: Switch(
                        value: inStock,
                        activeTrackColor: const Color(0xFF0F9D58),
                        onChanged: (val) {
                          FirebaseFirestore.instance.collection('products').doc(products[i].id).update({
                            'inStock': val,
                            'isAvailable': val,
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// -------------------------------------------------------------
// TAB 4: HR & SUB-ADMIN CREDENTIALS CREATOR
// -------------------------------------------------------------
class AdminHRManagementTab extends StatefulWidget {
  final bool isSuperAdmin;
  const AdminHRManagementTab({super.key, required this.isSuperAdmin});

  @override
  State<AdminHRManagementTab> createState() => _AdminHRManagementTabState();
}

class _AdminHRManagementTabState extends State<AdminHRManagementTab> {
  final _nameCtrl = TextEditingController();
  final _staffIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _selectedRole = 'HR_ACCOUNTS';

  void _openAddStaffSheet() {
    _staffIdCtrl.text = 'HR-${100 + DateTime.now().millisecond}';
    _passwordCtrl.text = 'Staff@${1000 + DateTime.now().millisecond}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create Sub-Admin / HR Login Access', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Staff Member Name*', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(labelText: 'Assign Role', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'HR_ACCOUNTS', child: Text('HR & Accounts (Payout Specialist)')),
                DropdownMenuItem(value: 'STORE_OPS_MANAGER', child: Text('Store Operations Manager')),
              ],
              onChanged: (val) => setState(() => _selectedRole = val!),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextField(controller: _staffIdCtrl, decoration: const InputDecoration(labelText: 'Login Staff ID', border: OutlineInputBorder()))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _passwordCtrl, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade900),
                onPressed: () async {
                  if (_nameCtrl.text.isEmpty) return;
                  final sId = _staffIdCtrl.text.trim();
                  await FirebaseFirestore.instance.collection('admin_staff').doc(sId).set({
                    'staffId': sId,
                    'name': _nameCtrl.text.trim(),
                    'password': _passwordCtrl.text.trim(),
                    'role': _selectedRole,
                    'isActive': true,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save & Issue Credentials', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: widget.isSuperAdmin
          ? FloatingActionButton.extended(
              backgroundColor: Colors.blueGrey.shade900,
              icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
              label: const Text('Create Staff ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: _openAddStaffSheet,
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('admin_staff').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final staffList = snapshot.data!.docs;

          if (staffList.isEmpty) {
            return const Center(child: Text('Koi HR / Sub-Admin account nahi bana hai.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: staffList.length,
            itemBuilder: (context, i) {
              final s = staffList[i].data() as Map<String, dynamic>;
              final id = staffList[i].id;
              final name = s['name'] ?? 'Staff';
              final role = s['role'] ?? 'HR_ACCOUNTS';
              final pwd = s['password'] ?? '';
              final bool isActive = s['isActive'] ?? true;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.badge_outlined)),
                  title: Text('$name ($id)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('Role: $role\nPassword: $pwd'),
                  trailing: widget.isSuperAdmin
                      ? IconButton(
                          icon: Icon(isActive ? Icons.toggle_on : Icons.toggle_off, color: isActive ? Colors.green : Colors.grey, size: 36),
                          onPressed: () {
                            FirebaseFirestore.instance.collection('admin_staff').doc(id).update({'isActive': !isActive});
                          },
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------
// 3. PARTNER DASHBOARD (Included for Store Nodes)
// -------------------------------------------------------------
class PartnerMainDashboard extends StatefulWidget {
  final String partnerId;
  final String shopName;

  const PartnerMainDashboard({
    super.key,
    required this.partnerId,
    required this.shopName,
  });

  @override
  State<PartnerMainDashboard> createState() => _PartnerMainDashboardState();
}

class _PartnerMainDashboardState extends State<PartnerMainDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const PartnerOrdersScreen(),
      const PartnerProductsScreen(),
      PartnerProfileScreen(partnerId: widget.partnerId, shopName: widget.shopName),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey.shade500,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Orders Queue'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Inventory'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 4. PARTNER PROFILE SCREEN
// -------------------------------------------------------------
class PartnerProfileScreen extends StatelessWidget {
  final String partnerId;
  final String shopName;

  const PartnerProfileScreen({super.key, required this.partnerId, required this.shopName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(title: const Text('Store Profile'), backgroundColor: Colors.white, elevation: 0.5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(shopName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('Partner ID: $partnerId', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Log out', style: TextStyle(color: Colors.white)),
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (c) => const AuthGatewayScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}