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
// 1. DUAL AUTH GATEWAY (Partner Login / Admin Login Toggle)
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

  // Hardcoded Super Admin Credentials
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
      // 1. ADMIN LOGIN VERIFICATION
      if (inputId == adminIdConst && inputPassword == adminPasswordConst) {
        setState(() => _isLoading = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (c) => const AdminOnboardingDashboardScreen()),
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Galat Admin ID ya Password!';
        });
      }
    } else {
      // 2. PARTNER LOGIN VERIFICATION (From Firestore 'partners' collection)
      try {
        final query = await FirebaseFirestore.instance
            .collection('partners')
            .where('partnerId', isEqualTo: inputId)
            .where('password', isEqualTo: inputPassword)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final partnerData = query.docs.first.data();
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
          // Backward compatibility: agar KAMALGANJ01 hai
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
            _errorMessage = 'Galat Partner ID ya Password! Kya aapki shop onboarded hai?';
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
                // Top Brand Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: _isAdminMode ? Colors.blueGrey.shade800 : Colors.amber.shade400,
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
                const SizedBox(height: 20),
                Text(
                  _isAdminMode ? 'Admin & Shop Onboarding Desk' : 'Dark Store Order & Stock Hub',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Text(
                  _isAdminMode
                    ? 'Only authorized personnel can onboard shops'
                    : 'Log in with credentials provided by Kryzit Admin',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 20),

                // Toggle Bar (Partner Login vs Admin Login)
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

                // ID Input
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
                      hintText: _isAdminMode ? 'Enter Admin ID' : 'Partner ID (e.g. KZ-SHOP-101)',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Password Input
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

                // Login Submit Button
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
                            _isAdminMode ? 'Enter Admin Dashboard ›' : 'Enter Partner Dashboard ›',
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
// 2. ADMIN SHOP ON-BOARDING DASHBOARD
// -------------------------------------------------------------
class AdminOnboardingDashboardScreen extends StatefulWidget {
  const AdminOnboardingDashboardScreen({super.key});

  @override
  State<AdminOnboardingDashboardScreen> createState() => _AdminOnboardingDashboardScreenState();
}

class _AdminOnboardingDashboardScreenState extends State<AdminOnboardingDashboardScreen> {
  // Onboarding Form Controllers
  final _shopNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _fssaiCtrl = TextEditingController();
  final _photoUrlCtrl = TextEditingController();
  final _locationAddressCtrl = TextEditingController();
  final _partnerIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

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
          height: MediaQuery.of(context).size.height * 0.9,
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
                    const Text('New Shop On-boarding Form',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _shopNameCtrl,
                  decoration: const InputDecoration(labelText: 'Shop / Store Name*', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ownerNameCtrl,
                        decoration: const InputDecoration(labelText: 'Owner Name*', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        decoration: const InputDecoration(labelText: 'Mobile Number*', counterText: '', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _gstinCtrl,
                        decoration: const InputDecoration(labelText: 'GSTIN (Optional)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _fssaiCtrl,
                        decoration: const InputDecoration(labelText: 'FSSAI License No.*', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _photoUrlCtrl,
                  decoration: const InputDecoration(labelText: 'Shop Photo Direct URL', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _locationAddressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Shop Exact Location / Address (Kamalganj 5km Area)*',
                    hintText: 'e.g. Near Railway Road / Bhatpura Village',
                    border: OutlineInputBorder(),
                  ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Permanent Login Credentials for Partner:*',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.brown)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _partnerIdCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Permanent Partner ID',
                                fillColor: Colors.white,
                                filled: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _passwordCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Permanent Password',
                                fillColor: Colors.white,
                                filled: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isSaving
                        ? null
                        : () async {
                            final shop = _shopNameCtrl.text.trim();
                            final owner = _ownerNameCtrl.text.trim();
                            final phone = _phoneCtrl.text.trim();
                            final pId = _partnerIdCtrl.text.trim();
                            final pwd = _passwordCtrl.text.trim();

                            if (shop.isEmpty || owner.isEmpty || phone.isEmpty || pId.isEmpty || pwd.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Kripya zaroori details aur ID/Password bharein!')),
                              );
                              return;
                            }

                            setSheetState(() => _isSaving = true);

                            // Save to Firestore 'partners' collection
                            await FirebaseFirestore.instance.collection('partners').doc(pId).set({
                              'partnerId': pId,
                              'password': pwd,
                              'shopName': shop,
                              'ownerName': owner,
                              'phone': phone,
                              'gstin': _gstinCtrl.text.trim(),
                              'fssai': _fssaiCtrl.text.trim(),
                              'photoUrl': _photoUrlCtrl.text.trim().isEmpty
                                  ? 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&q=80'
                                  : _photoUrlCtrl.text.trim(),
                              'locationAddress': _locationAddressCtrl.text.trim(),
                              'categories': _selectedCategories.toList(),
                              'isActive': true,
                              'onboardedAt': FieldValue.serverTimestamp(),
                            });

                            setSheetState(() => _isSaving = false);
                            if (ctx.mounted) Navigator.pop(ctx);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Shop "$shop" onboard ho gayi! Partner ID: $pId'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save & Generate Partner Account',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Admin Console: Onboarded Shops',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        backgroundColor: Colors.blueGrey.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (c) => const AuthGatewayScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
        label: const Text('Onboard New Shop', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _openOnboardingSheet,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('partners').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0F9D58)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storefront_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('Abhi tak koi shop onboard nahi hai.',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Neeche button dabakar pehli shop onboard karein.',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }

          final partners = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: partners.length,
            itemBuilder: (context, i) {
              final data = partners[i].data() as Map<String, dynamic>;
              final shopName = data['shopName'] ?? 'Shop';
              final owner = data['ownerName'] ?? '';
              final pId = data['partnerId'] ?? '';
              final pwd = data['password'] ?? '';
              final phone = data['phone'] ?? '';
              final address = data['locationAddress'] ?? 'Kamalganj Area';
              final bool isActive = data['isActive'] ?? true;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(shopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isActive ? 'ACTIVE STORE' : 'DISABLED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.green.shade800 : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Owner: $owner • Phone: +91 $phone', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('Location: $address', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Partner ID: $pId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F9D58))),
                            Text('Password: $pwd', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.brown)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () {
                            FirebaseFirestore.instance.collection('partners').doc(pId).delete();
                          },
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
// 3. MAIN PARTNER DASHBOARD (Orders Queue, Inventory, Profile)
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
        unselectedLabelStyle: const TextStyle(fontSize: 12),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
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
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: const Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.location_on_outlined, color: Colors.brown),
                    title: Text('Operational Dark Store Hub', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text('Kamalganj Block Center (5.0 KM Boundary)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.speed_rounded, color: Colors.amber),
                    title: Text('Delivery SLA', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text('11 - 15 Minutes Express Delivery', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ),
                ],
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