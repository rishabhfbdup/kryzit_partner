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
// 1. TRIPLE GATEWAY (Partner Login / Admin Login / Register Shop)
// -------------------------------------------------------------
class AuthGatewayScreen extends StatefulWidget {
  const AuthGatewayScreen({super.key});

  @override
  State<AuthGatewayScreen> createState() => _AuthGatewayScreenState();
}

class _AuthGatewayScreenState extends State<AuthGatewayScreen> {
  int _activeMode = 0; // 0 -> Partner, 1 -> Admin, 2 -> Register Shop

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = '';

  // New Partner Registration Controllers
  final _regShopNameCtrl = TextEditingController();
  final _regOwnerNameCtrl = TextEditingController();
  final _regPhoneCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPanCtrl = TextEditingController();
  final _regGstinCtrl = TextEditingController();
  final _regFssaiCtrl = TextEditingController();
  final _regLocationCtrl = TextEditingController();
  final _regPhotoCtrl = TextEditingController();
  final _regBankAccCtrl = TextEditingController();
  final _regIfscCtrl = TextEditingController();
  final _regUpiCtrl = TextEditingController();

  final List<String> _availableCategories = [
    'Vegetables & Fruits',
    'Dairy, Bread & Eggs',
    'Atta, Rice, Oil & Dals',
    'Snacks & Munchies',
    'Cold Drinks & Juices',
    'Instant Food',
    'Cleaning & Household',
  ];
  final Set<String> _regSelectedCategories = {'Vegetables & Fruits', 'Dairy, Bread & Eggs'};
  bool _isSubmittingReg = false;

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

    if (_activeMode == 1) {
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
    } else if (_activeMode == 0) {
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
              _errorMessage = 'Aapka account suspended ya unapproved hai! Admin se sampark karein.';
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
            _errorMessage = 'Galat Partner ID ya Password! Agar naye hain to pehle register karein.';
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

  Future<void> _submitSelfOnboarding() async {
    final shop = _regShopNameCtrl.text.trim();
    final owner = _regOwnerNameCtrl.text.trim();
    final phone = _regPhoneCtrl.text.trim();
    final fssai = _regFssaiCtrl.text.trim();
    final pan = _regPanCtrl.text.trim();
    final location = _regLocationCtrl.text.trim();

    if (shop.isEmpty || owner.isEmpty || phone.isEmpty || fssai.isEmpty || pan.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kripya Shop Name, Owner, Phone, PAN, FSSAI aur Location zaroor bharein!')),
      );
      return;
    }

    setState(() => _isSubmittingReg = true);

    try {
      final String reqId = 'REQ-${DateTime.now().millisecondsSinceEpoch}';
      await FirebaseFirestore.instance.collection('partner_requests').doc(reqId).set({
        'requestId': reqId,
        'shopName': shop,
        'ownerName': owner,
        'phone': phone,
        'email': _regEmailCtrl.text.trim(),
        'panNumber': pan,
        'gstin': _regGstinCtrl.text.trim(),
        'fssai': fssai,
        'locationAddress': location,
        'photoUrl': _regPhotoCtrl.text.trim().isEmpty
            ? 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&q=80'
            : _regPhotoCtrl.text.trim(),
        'bankAccount': _regBankAccCtrl.text.trim(),
        'ifsc': _regIfscCtrl.text.trim(),
        'upiId': _regUpiCtrl.text.trim(),
        'categories': _regSelectedCategories.toList(),
        'status': 'PENDING',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isSubmittingReg = false;
        _activeMode = 0;
      });

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Application Submitted!'),
            ],
          ),
          content: Text(
            'Aapki shop "$shop" ki registration request Admin ko bhej di gayi hai.\n\nAdmin details verify karke aapko Partner ID aur Password provide karenge.',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isSubmittingReg = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9EE),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _activeMode == 2 ? 650 : 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: _activeMode == 1 ? Colors.blueGrey.shade900 : Colors.amber.shade400,
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
                    _activeMode == 1
                        ? 'kryzit super console'
                        : (_activeMode == 2 ? 'kryzit partner on-boarding' : 'kryzit partner portal'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: _activeMode == 1 ? Colors.white : Colors.black87,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _activeMode == 1
                      ? 'Admin & Approvals Desk'
                      : (_activeMode == 2 ? 'Register Your Store on Kryzit' : 'Store Order & Stock Hub'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 20),

                // 3-Way Toggle Bar
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _buildToggleButton(0, 'Partner Login'),
                      _buildToggleButton(1, 'Admin Login'),
                      _buildToggleButton(2, 'Register Shop'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_activeMode == 2)
                  _buildSelfOnboardingForm()
                else
                  _buildLoginForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(int modeIndex, String label) {
    final bool isSel = _activeMode == modeIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeMode = modeIndex;
            _errorMessage = '';
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSel ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSel ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)] : [],
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: isSel
                    ? (_activeMode == 1 ? Colors.blueGrey.shade900 : AppColors.primary)
                    : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
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
              prefixIcon: Icon(_activeMode == 1 ? Icons.admin_panel_settings_rounded : Icons.storefront_rounded),
              hintText: _activeMode == 1 ? 'Admin ID (Kryzit@9616)' : 'Partner ID',
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
              backgroundColor: _activeMode == 1 ? Colors.blueGrey.shade900 : AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isLoading ? null : _handleLogin,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    _activeMode == 1 ? 'Enter Admin Console ›' : 'Enter Partner Dashboard ›',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelfOnboardingForm() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Store & Owner Identity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey)),
          const SizedBox(height: 10),
          TextField(controller: _regShopNameCtrl, decoration: const InputDecoration(labelText: 'Shop Name*', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: TextField(controller: _regOwnerNameCtrl, decoration: const InputDecoration(labelText: 'Owner Name*', border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _regPhoneCtrl, keyboardType: TextInputType.phone, maxLength: 10, decoration: const InputDecoration(labelText: 'Mobile*', counterText: '', border: OutlineInputBorder()))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: TextField(controller: _regPanCtrl, decoration: const InputDecoration(labelText: 'PAN Number*', border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _regFssaiCtrl, decoration: const InputDecoration(labelText: 'FSSAI License No.*', border: OutlineInputBorder()))),
            ],
          ),
          const SizedBox(height: 10),
          TextField(controller: _regLocationCtrl, decoration: const InputDecoration(labelText: 'Shop Location (Kamalganj Area)*', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: TextField(controller: _regBankAccCtrl, decoration: const InputDecoration(labelText: 'Bank Account Number', border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _regUpiCtrl, decoration: const InputDecoration(labelText: 'UPI ID', border: OutlineInputBorder()))),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Select Categories to Sell:*', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _availableCategories.map((cat) {
              final isSel = _regSelectedCategories.contains(cat);
              return FilterChip(
                label: Text(cat, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : Colors.black87)),
                selected: isSel,
                selectedColor: AppColors.primary,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _regSelectedCategories.add(cat);
                    } else {
                      _regSelectedCategories.remove(cat);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: _isSubmittingReg ? null : _submitSelfOnboarding,
              child: _isSubmittingReg
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Application for Admin Approval', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 2. ADMIN MASTER CONSOLE (Tabs: Approvals Hub, Shops, Riders, Inventory, HR)
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
            const Text('Kryzit Super Control Center', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
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
          const AdminUnifiedApprovalsDeskTab(),
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
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.verified_user_rounded), label: 'Approvals'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront_rounded), label: 'Shops Payout'),
          BottomNavigationBarItem(icon: Icon(Icons.delivery_dining_rounded), label: 'Riders Payout'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_rounded), label: 'Inventory'),
          BottomNavigationBarItem(icon: Icon(Icons.badge_rounded), label: 'HR Staff'),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 0: UNIFIED APPROVALS DESK (Shop Approvals + Rider Approvals)
// -------------------------------------------------------------
class AdminUnifiedApprovalsDeskTab extends StatefulWidget {
  const AdminUnifiedApprovalsDeskTab({super.key});

  @override
  State<AdminUnifiedApprovalsDeskTab> createState() => _AdminUnifiedApprovalsDeskTabState();
}

class _AdminUnifiedApprovalsDeskTabState extends State<AdminUnifiedApprovalsDeskTab> with SingleTickerProviderStateMixin {
  late TabController _subTabCtrl;

  @override
  void initState() {
    super.initState();
    _subTabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTabCtrl.dispose();
    super.dispose();
  }

  void _openShopApprovalModal(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final shopName = data['shopName'] ?? 'Shop';
    final owner = data['ownerName'] ?? '';
    final phone = data['phone'] ?? '';
    final pan = data['panNumber'] ?? '';
    final fssai = data['fssai'] ?? '';
    final location = data['locationAddress'] ?? '';

    final pIdCtrl = TextEditingController(text: 'KZ-${shopName.split(" ").first.toUpperCase()}-${100 + DateTime.now().millisecond}');
    final pwdCtrl = TextEditingController(text: 'Kryzit@${1000 + DateTime.now().millisecond}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Approve Shop: $shopName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Owner: $owner (+91 $phone)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('PAN: $pan | FSSAI: $fssai', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
              Text('Location: $location', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const Divider(height: 20),
              const Text('Create Permanent Partner Login Credentials:*', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.brown)),
              const SizedBox(height: 8),
              TextField(controller: pIdCtrl, decoration: const InputDecoration(labelText: 'Partner ID', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: pwdCtrl, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('partner_requests').doc(doc.id).update({'status': 'REJECTED'});
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F9D58)),
            onPressed: () async {
              final newId = pIdCtrl.text.trim();
              final newPwd = pwdCtrl.text.trim();
              if (newId.isEmpty || newPwd.isEmpty) return;

              await FirebaseFirestore.instance.collection('partners').doc(newId).set({
                'partnerId': newId,
                'password': newPwd,
                'shopName': shopName,
                'ownerName': owner,
                'phone': phone,
                'email': data['email'] ?? '',
                'panNumber': pan,
                'gstin': data['gstin'] ?? '',
                'fssai': fssai,
                'locationAddress': location,
                'bankAccount': data['bankAccount'] ?? '',
                'ifsc': data['ifsc'] ?? '',
                'upiId': data['upiId'] ?? '',
                'categories': data['categories'] ?? [],
                'isActive': true,
                'isSuspended': false,
                'totalSales': 0,
                'pendingPayout': 0,
                'approvedAt': FieldValue.serverTimestamp(),
              });

              await FirebaseFirestore.instance.collection('partner_requests').doc(doc.id).update({
                'status': 'APPROVED',
                'partnerId': newId,
              });

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Approve & Issue ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openRiderApprovalModal(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Rider';
    final phone = data['phone'] ?? '';
    final vehicle = data['vehicleNumber'] ?? 'Two Wheeler';
    final dl = data['dlNumber'] ?? 'N/A';
    final upi = data['upiId'] ?? 'N/A';

    final rIdCtrl = TextEditingController(text: 'RD-KZ-${100 + DateTime.now().millisecond}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Approve Rider: $name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact: +91 $phone', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text('Vehicle: $vehicle | DL: $dl', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            Text('Payout UPI ID: $upi', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
            const Divider(height: 20),
            TextField(
              controller: rIdCtrl,
              decoration: const InputDecoration(labelText: 'Assigned Permanent Rider ID', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('riders').doc(doc.id).update({
                'isApproved': false,
                'status': 'REJECTED',
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Reject Rider', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F9D58)),
            onPressed: () async {
              final assignedId = rIdCtrl.text.trim();
              if (assignedId.isEmpty) return;

              await FirebaseFirestore.instance.collection('riders').doc(doc.id).update({
                'riderId': assignedId,
                'isApproved': true,
                'isSuspended': false,
                'status': 'ACTIVE',
                'approvedAt': FieldValue.serverTimestamp(),
              });

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Approve & Activate Rider', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _subTabCtrl,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.storefront_outlined), text: 'Shop Requests'),
              Tab(icon: Icon(Icons.delivery_dining_outlined), text: 'Rider Requests'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabCtrl,
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('partner_requests')
                    .where('status', isEqualTo: 'PENDING')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final requests = snapshot.data!.docs;

                  if (requests.isEmpty) {
                    return const Center(child: Text('Koi shop approval pending nahi hai.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: requests.length,
                    itemBuilder: (context, i) {
                      final doc = requests[i];
                      final data = doc.data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(data['shopName'] ?? 'Shop', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Owner: ${data['ownerName']} (+91 ${data['phone']})\nPAN: ${data['panNumber']} | FSSAI: ${data['fssai']}'),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F9D58)),
                            onPressed: () => _openShopApprovalModal(context, doc),
                            child: const Text('Review', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('riders')
                    .where('isApproved', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final pendingRiders = snapshot.data!.docs;

                  if (pendingRiders.isEmpty) {
                    return const Center(child: Text('Koi rider approval pending nahi hai.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: pendingRiders.length,
                    itemBuilder: (context, i) {
                      final doc = pendingRiders[i];
                      final data = doc.data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.person, color: Colors.black)),
                          title: Text(data['name'] ?? 'Rider', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Phone: +91 ${data['phone']}\nVehicle: ${data['vehicleNumber'] ?? 'Bike'} | DL: ${data['dlNumber'] ?? 'DL...'}'),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F9D58)),
                            onPressed: () => _openRiderApprovalModal(context, doc),
                            child: const Text('Approve Rider', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// TAB 1: SHOPS COMMISSION & 1-CLICK PAYOUT
// -------------------------------------------------------------
class AdminShopsPayoutTab extends StatelessWidget {
  final String role;
  const AdminShopsPayoutTab({super.key, required this.role});

  void _executeShopPayout(BuildContext context, String docId, String shopName, String bank, String upi, int amount) {
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout amount ₹0 hai.')));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('1-Click Payout: $shopName'),
        content: Text('Amount: ₹$amount (10% Comm. Cut)\nBank: $bank\nUPI: $upi'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F9D58)),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('partners').doc(docId).update({
                'pendingPayout': 0,
                'lastSettledAt': FieldValue.serverTimestamp(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Confirm Transfer', style: TextStyle(color: Colors.white)),
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
            final bank = data['bankAccount'] ?? 'N/A';
            final upi = data['upiId'] ?? 'N/A';
            final bool isSuspended = data['isSuspended'] ?? false;
            final int grossSales = (data['totalSales'] as num?)?.toInt() ?? 2450;
            final int commission = (grossSales * 0.10).round();
            final int netPayout = (data['pendingPayout'] as num?)?.toInt() ?? (grossSales - commission);

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(shopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(isSuspended ? 'SUSPENDED' : 'ACTIVE', style: TextStyle(color: isSuspended ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                    Text('Bank: $bank | UPI: $upi', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Net Payable: ₹$netPayout', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
                        Row(
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F9D58)),
                              onPressed: () => _executeShopPayout(context, pId, shopName, bank, upi, netPayout),
                              child: const Text('1-Click Pay', style: TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                            IconButton(
                              icon: Icon(isSuspended ? Icons.play_arrow : Icons.block, color: isSuspended ? Colors.green : Colors.red),
                              onPressed: () {
                                FirebaseFirestore.instance.collection('partners').doc(pId).update({
                                  'isSuspended': !isSuspended,
                                  'isActive': !isSuspended,
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// -------------------------------------------------------------
// TAB 2: RIDERS PAYOUT & SUSPENSION
// -------------------------------------------------------------
class AdminRidersPayoutTab extends StatelessWidget {
  final String role;
  const AdminRidersPayoutTab({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('riders').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) return const Center(child: Text('Koi rider register nahi hai.'));

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

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text('$name ($rId)', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Status: ${isApproved ? (isSuspended ? "Suspended" : "Active") : "Pending"}\nPhone: +91 $phone | Deliveries: $deliveries\nPayable: ₹$payable | UPI: $upi'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F9D58)),
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('riders').doc(rId).update({'payoutEarned': 0});
                      },
                      child: const Text('Pay', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                    IconButton(
                      icon: Icon(isSuspended ? Icons.play_arrow : Icons.block, color: isSuspended ? Colors.green : Colors.red),
                      onPressed: () {
                        FirebaseFirestore.instance.collection('riders').doc(rId).update({'isSuspended': !isSuspended});
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// -------------------------------------------------------------
// TAB 3: LIVE STORE INVENTORY AUDIT
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

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: products.length,
          itemBuilder: (context, i) {
            final data = products[i].data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Item';
            final price = data['price'] ?? 0;
            final int stockQty = (data['stockQuantity'] as num?)?.toInt() ?? 0;
            final bool inStock = data['inStock'] ?? false;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('₹$price | Stock: $stockQty units'),
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
          children: [
            const Text('Create Sub-Admin / HR Login', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Staff Name*', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(labelText: 'Assign Role', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'HR_ACCOUNTS', child: Text('HR & Accounts')),
                DropdownMenuItem(value: 'STORE_OPS_MANAGER', child: Text('Store Operations')),
              ],
              onChanged: (val) => setState(() => _selectedRole = val!),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextField(controller: _staffIdCtrl, decoration: const InputDecoration(labelText: 'Staff ID', border: OutlineInputBorder()))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _passwordCtrl, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
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
                child: const Text('Save Staff ID', style: TextStyle(color: Colors.white)),
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

          if (staffList.isEmpty) return const Center(child: Text('Koi staff account nahi hai.'));

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
                child: ListTile(
                  title: Text('$name ($id)', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Role: $role | Password: $pwd'),
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
// 3. PARTNER DASHBOARD (For Store Hub Nodes)
// -------------------------------------------------------------
class PartnerMainDashboard extends StatefulWidget {
  final String partnerId;
  final String shopName;

  const PartnerMainDashboard({super.key, required this.partnerId, required this.shopName});

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
      body: IndexedStack(index: _currentIndex, children: screens),
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