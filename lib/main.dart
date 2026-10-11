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
      title: 'Kryzit Partner & Admin Hub',
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
// 1. DUAL AUTH GATEWAY (Partner Login / Admin Login)
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

  static const String adminIdConst = 'Kryzit@9616';
  static const String adminPasswordConst = 'Kryzit@961664#';

  Future<void> _handleLogin() async {
    final inputId = _idController.text.trim();
    final inputPassword = _passwordController.text.trim();

    if (inputId.isEmpty || inputPassword.isEmpty) {
      setState(() => _errorMessage = 'Kripya ID aur Password dono daalein!');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    if (_isAdminMode) {
      if (inputId == adminIdConst && inputPassword == adminPasswordConst) {
        setState(() => _isLoading = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (c) => const AdminMasterPortalScreen()),
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Galat Admin ID ya Password!';
        });
      }
    } else {
      try {
        final query = await FirebaseFirestore.instance
            .collection('partners')
            .where('partnerId', isEqualTo: inputId)
            .where('password', isEqualTo: inputPassword)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final partnerData = query.docs.first.data();
          final bool isSuspended = partnerData['isSuspended'] ?? false;
          final bool isActive = partnerData['isActive'] ?? true;

          if (isSuspended || !isActive) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Aapki Partner ID ko Admin dwara SUSPEND kar diya gaya hai. Kripya Admin se sampark karein.';
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
          if (inputId.toUpperCase() == 'KAMALGANJ01' && inputPassword == 'admin') {
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
          _errorMessage = 'Login error: $e';
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
                    _isAdminMode ? 'kryzit super admin' : 'kryzit partner portal',
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
                  _isAdminMode ? 'Super Control & Payout Desk' : 'Dark Store Order & Stock Hub',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Text(
                  _isAdminMode
                      ? 'ID: Kryzit@9616 | Password: Kryzit@961664#'
                      : 'Log in with credentials provided by Kryzit Admin',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                          onTap: () {
                            setState(() {
                              _isAdminMode = false;
                              _errorMessage = '';
                              _idController.clear();
                              _passwordController.clear();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isAdminMode ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: !_isAdminMode
                                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)]
                                  : [],
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
                          onTap: () {
                            setState(() {
                              _isAdminMode = true;
                              _errorMessage = '';
                              _idController.clear();
                              _passwordController.clear();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isAdminMode ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _isAdminMode
                                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                'Admin Login',
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
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
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
                      prefixIcon: Icon(
                        _isAdminMode ? Icons.admin_panel_settings_rounded : Icons.storefront_rounded,
                        color: Colors.black87,
                      ),
                      hintText: _isAdminMode ? 'Enter Admin ID (Kryzit@9616)' : 'Partner ID',
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
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.black87),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      hintText: _isAdminMode ? 'Enter Admin Password' : 'Store Password',
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
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _isAdminMode ? 'Open Super Admin Console ›' : 'Enter Partner Dashboard ›',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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
// 2. SUPER ADMIN MASTER CONSOLE (Tabs: Shops, Riders, Orders & Payouts)
// -------------------------------------------------------------
class AdminMasterPortalScreen extends StatefulWidget {
  const AdminMasterPortalScreen({super.key});

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
        title: const Text(
          'Kryzit Super Admin Console',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Log out',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (c) => const AuthGatewayScreen()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTab,
        children: const [
          AdminShopsTab(),
          AdminRidersTab(),
          AdminTransactionsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blueGrey.shade900,
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_rounded),
            label: 'Shops & Payout',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining_rounded),
            label: 'Riders & Approval',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Len-Den & Orders',
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 1: SHOPS MANAGEMENT, SUSPENSION & PAYOUTS
// -------------------------------------------------------------
class AdminShopsTab extends StatefulWidget {
  const AdminShopsTab({super.key});

  @override
  State<AdminShopsTab> createState() => _AdminShopsTabState();
}

class _AdminShopsTabState extends State<AdminShopsTab> {
  // Onboarding Controllers
  final _shopNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _fssaiCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _partnerIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  // Bank Account Details for Payout
  final _bankAccCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();

  final List<String> _availableCategories = [
    'Vegetables & Fruits',
    'Dairy, Bread & Eggs',
    'Atta, Rice, Oil & Dals',
    'Snacks & Munchies',
    'Cold Drinks & Juices',
    'Instant Food',
    'Cleaning & Household',
  ];
  final Set<String> _selectedCategories = {'Vegetables & Fruits', 'Dairy, Bread & Eggs'};
  bool _isSaving = false;

  void _openOnboardingSheet() {
    _partnerIdCtrl.text = 'KZ-${100 + DateTime.now().millisecond}';
    _passwordCtrl.text = 'Kryzit@${1000 + DateTime.now().millisecond}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.92,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Onboard New Shop & Partner', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _shopNameCtrl,
                  decoration: const InputDecoration(labelText: 'Shop Name*', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _ownerNameCtrl, decoration: const InputDecoration(labelText: 'Owner Name*', border: OutlineInputBorder()))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, maxLength: 10, decoration: const InputDecoration(labelText: 'Phone*', counterText: '', border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _fssaiCtrl, decoration: const InputDecoration(labelText: 'FSSAI No.*', border: OutlineInputBorder()))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: _gstinCtrl, decoration: const InputDecoration(labelText: 'GSTIN (Optional)', border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(labelText: 'Shop Location (Kamalganj Area)*', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                const Text('Partner Bank Account (For Payout Settlement):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
                const SizedBox(height: 6),
                TextField(controller: _bankAccCtrl, decoration: const InputDecoration(labelText: 'Bank Account Number', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _ifscCtrl, decoration: const InputDecoration(labelText: 'IFSC Code', border: OutlineInputBorder()))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: _upiCtrl, decoration: const InputDecoration(labelText: 'UPI ID (GPay / PhonePe)', border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('Select Selling Categories:*', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _availableCategories.map((cat) {
                    final isSel = _selectedCategories.contains(cat);
                    return FilterChip(
                      label: Text(cat, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : Colors.black87)),
                      selected: isSel,
                      selectedColor: AppColors.primary,
                      onSelected: (val) {
                        setSheetState(() {
                          if (val) {
                            _selectedCategories.add(cat);
                          } else {
                            _selectedCategories.remove(cat);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: TextField(controller: _partnerIdCtrl, decoration: const InputDecoration(labelText: 'Partner ID', border: OutlineInputBorder(), fillColor: Colors.white, filled: true))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _passwordCtrl, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), fillColor: Colors.white, filled: true))),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: _isSaving
                        ? null
                        : () async {
                            final shop = _shopNameCtrl.text.trim();
                            final pId = _partnerIdCtrl.text.trim();
                            final pwd = _passwordCtrl.text.trim();

                            if (shop.isEmpty || pId.isEmpty || pwd.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Kripya zaroori details bharein!')),
                              );
                              return;
                            }

                            setSheetState(() => _isSaving = true);

                            await FirebaseFirestore.instance.collection('partners').doc(pId).set({
                              'partnerId': pId,
                              'password': pwd,
                              'shopName': shop,
                              'ownerName': _ownerNameCtrl.text.trim(),
                              'phone': _phoneCtrl.text.trim(),
                              'gstin': _gstinCtrl.text.trim(),
                              'fssai': _fssaiCtrl.text.trim(),
                              'locationAddress': _locationCtrl.text.trim(),
                              'bankAccount': _bankAccCtrl.text.trim(),
                              'ifsc': _ifscCtrl.text.trim(),
                              'upiId': _upiCtrl.text.trim(),
                              'categories': _selectedCategories.toList(),
                              'isActive': true,
                              'isSuspended': false,
                              'totalOrdersCount': 0,
                              'pendingPayout': 0,
                              'onboardedAt': FieldValue.serverTimestamp(),
                            });

                            setSheetState(() => _isSaving = false);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save & Create Active Shop', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Toggle Suspend / Active Partner
  Future<void> _togglePartnerSuspend(String docId, bool currentSuspended) async {
    await FirebaseFirestore.instance.collection('partners').doc(docId).set({
      'isSuspended': !currentSuspended,
      'isActive': currentSuspended, // suspended = not active
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueGrey.shade900,
        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
        label: const Text('Onboard Shop', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _openOnboardingSheet,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('partners').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('Koi shop onboard nahi hai.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final pId = d['partnerId'] ?? docs[i].id;
              final shopName = d['shopName'] ?? 'Shop';
              final owner = d['ownerName'] ?? '';
              final phone = d['phone'] ?? '';
              final bank = d['bankAccount'] ?? 'N/A';
              final upi = d['upiId'] ?? 'N/A';
              final bool isSuspended = d['isSuspended'] ?? false;
              final int pendingPayout = d['pendingPayout'] ?? 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSuspended ? Colors.red.shade300 : Colors.green.shade200,
                    width: 1.4,
                  ),
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
                            isSuspended ? 'SUSPENDED' : 'ACTIVE SHOP',
                            style: TextStyle(
                              color: isSuspended ? Colors.red : Colors.green.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Owner: $owner • Phone: +91 $phone', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('Bank A/C: $bank | UPI: $upi', style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ID: $pId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F9D58))),
                            Text('Dena Hai (Payout): ₹$pendingPayout', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange)),
                          ],
                        ),
                        Row(
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSuspended ? Colors.green : Colors.red,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onPressed: () => _togglePartnerSuspend(docs[i].id, isSuspended),
                              child: Text(
                                isSuspended ? 'Unsuspend (Active)' : 'Suspend Shop',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                              onPressed: () => FirebaseFirestore.instance.collection('partners').doc(docs[i].id).delete(),
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
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 2: RIDERS APPROVAL, SUSPENSION & ACTIVE DESK
// -------------------------------------------------------------
class AdminRidersTab extends StatefulWidget {
  const AdminRidersTab({super.key});

  @override
  State<AdminRidersTab> createState() => _AdminRidersTabState();
}

class _AdminRidersTabState extends State<AdminRidersTab> {
  // Add Manual Rider Sheet
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  final _dlCtrl = TextEditingController();

  void _openAddRiderSheet() {
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
            const Text('Onboard New Delivery Rider', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Rider Name*', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone*', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(controller: _vehicleCtrl, decoration: const InputDecoration(labelText: 'Vehicle No. (UP 76...)', border: OutlineInputBorder()))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _dlCtrl, decoration: const InputDecoration(labelText: 'DL Number', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () async {
                  if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) return;
                  final rId = 'RD-${100 + DateTime.now().millisecond}';
                  await FirebaseFirestore.instance.collection('riders').doc(rId).set({
                    'riderId': rId,
                    'name': _nameCtrl.text.trim(),
                    'phone': _phoneCtrl.text.trim(),
                    'vehicleNumber': _vehicleCtrl.text.trim(),
                    'dlNumber': _dlCtrl.text.trim(),
                    'isApproved': true,
                    'isSuspended': false,
                    'totalDeliveries': 0,
                    'payoutEarned': 0,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Approve & Add Rider', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueGrey.shade900,
        icon: const Icon(Icons.two_wheeler_rounded, color: Colors.white),
        label: const Text('Add Rider', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _openAddRiderSheet,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('riders').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final riders = snapshot.data!.docs;

          if (riders.isEmpty) {
            return const Center(child: Text('Abhi koi rider registered nahi hai.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: riders.length,
            itemBuilder: (context, i) {
              final r = riders[i].data() as Map<String, dynamic>;
              final rId = r['riderId'] ?? riders[i].id;
              final name = r['name'] ?? 'Rider';
              final phone = r['phone'] ?? '';
              final vehicle = r['vehicleNumber'] ?? 'Two Wheeler';
              final bool isApproved = r['isApproved'] ?? false;
              final bool isSuspended = r['isSuspended'] ?? false;
              final int deliveries = r['totalDeliveries'] ?? 0;
              final int earned = r['payoutEarned'] ?? 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSuspended
                        ? Colors.red.shade300
                        : (!isApproved ? Colors.orange.shade300 : Colors.green.shade200),
                    width: 1.4,
                  ),
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
                            color: isSuspended
                                ? Colors.red.shade50
                                : (!isApproved ? Colors.orange.shade50 : Colors.green.shade50),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isSuspended ? 'SUSPENDED' : (!isApproved ? 'PENDING APPROVAL' : 'APPROVED & ACTIVE'),
                            style: TextStyle(
                              color: isSuspended ? Colors.red : (!isApproved ? Colors.orange.shade800 : Colors.green.shade800),
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Phone: +91 $phone • Vehicle: $vehicle', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text('Total Deliveries: $deliveries • Rider Earning: ₹$earned', style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!isApproved)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: () {
                              FirebaseFirestore.instance.collection('riders').doc(riders[i].id).update({'isApproved': true});
                            },
                            child: const Text('Approve Rider', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          )
                        else
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: isSuspended ? Colors.green : Colors.red),
                            onPressed: () {
                              FirebaseFirestore.instance.collection('riders').doc(riders[i].id).update({
                                'isSuspended': !isSuspended,
                              });
                            },
                            child: Text(isSuspended ? 'Activate Rider' : 'Suspend Rider', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
    );
  }
}

// -------------------------------------------------------------
// TAB 3: LEN-DEN (TRANSACTIONS), ORDERS & SETTLEMENTS
// -------------------------------------------------------------
class AdminTransactionsTab extends StatelessWidget {
  const AdminTransactionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final orders = snapshot.data!.docs;

        int totalBusinessAmount = 0;
        int totalOrdersCount = orders.length;

        for (var doc in orders) {
          final data = doc.data() as Map<String, dynamic>;
          totalBusinessAmount += (data['orderAmount'] as num?)?.toInt() ?? 0;
        }

        return Column(
          children: [
            // Top Financial Metrics Card
            Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade900,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Total Orders', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('$totalOrdersCount', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(width: 1, height: 40, color: Colors.white24),
                  Column(
                    children: [
                      const Text('Total GMV (Turnover)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('₹$totalBusinessAmount', style: const TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Live Len-Den & Order Tracking Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),

            Expanded(
              child: orders.isEmpty
                  ? const Center(child: Text('Koi order record nahi hai.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: orders.length,
                      itemBuilder: (context, i) {
                        final o = orders[i].data() as Map<String, dynamic>;
                        final orderId = o['orderId'] ?? '#KZ-ORD';
                        final amount = o['orderAmount'] ?? 0;
                        final status = o['status'] ?? 'STORE_PACKING';
                        final store = o['storeName'] ?? 'Kamalganj Dark Store Hub';
                        final customer = o['customerName'] ?? 'Customer';
                        final phone = o['customerPhone'] ?? '';
                        final payment = o['paymentMethod'] ?? 'COD';
                        final riderName = o['riderName'] ?? 'Unassigned Rider';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(orderId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text('₹$amount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Customer: $customer (+91 $phone)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              Text('Shop Node: $store', style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
                              Text('Rider Assigned: $riderName • Status: $status', style: const TextStyle(fontSize: 11, color: Colors.brown)),
                              const SizedBox(height: 4),
                              Text('Payment Mode: $payment', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
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
// 3. PARTNER DASHBOARD SCREEN
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
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Orders Queue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 4. PARTNER PROFILE SCREEN
// -------------------------------------------------------------
class PartnerProfileScreen extends StatefulWidget {
  final String partnerId;
  final String shopName;

  const PartnerProfileScreen({
    super.key,
    required this.partnerId,
    required this.shopName,
  });

  @override
  State<PartnerProfileScreen> createState() => _PartnerProfileScreenState();
}

class _PartnerProfileScreenState extends State<PartnerProfileScreen> {
  bool _isStoreOnline = true;

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Store Logout?'),
        content: const Text('Kya aap Dark Store portal se log out karna chahte hain?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (c) => const AuthGatewayScreen()),
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Store Profile & Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.green.shade50,
                    child: const Icon(Icons.storefront_rounded, size: 36, color: Color(0xFF0F9D58)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.shopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 3),
                        Text('Partner ID: ${widget.partnerId.toUpperCase()}', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: _isStoreOnline ? Colors.green : Colors.red, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(_isStoreOnline ? 'STORE ACTIVE' : 'STORE CLOSED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _isStoreOnline ? Colors.green.shade800 : Colors.red)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Store Ordering Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(_isStoreOnline ? 'Customer app par store open hai' : 'Customer app par order paused hai', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                value: _isStoreOnline,
                activeTrackColor: AppColors.primary,
                onChanged: (val) => setState(() => _isStoreOnline = val),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                label: const Text('Log out from Hub', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: _confirmLogout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}