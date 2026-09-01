import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'app_theme.dart';
import 'sales_chart_screen.dart';
import 'export_excel_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const JhonSeafoodApp());
}

// ==========================================
// FUNGSI UTILITAS: FORMAT RUPIAH DENGAN TITIK
// ==========================================
String formatRupiah(int number) {
  // Mengubah angka menjadi string dan menyisipkan titik setiap 3 digit dari belakang
  RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
  String result = number.toString().replaceAllMapped(reg, (Match match) => '${match[1]}.');
  return 'Rp $result';
}

// ==========================================
// REFERENSI KOLEKSI FIRESTORE
// ==========================================
final CollectionReference ordersCollection =
    FirebaseFirestore.instance.collection('orders');
final CollectionReference menuCollection =
    FirebaseFirestore.instance.collection('menu');
final CollectionReference settingsCollection =
    FirebaseFirestore.instance.collection('settings');

class JhonSeafoodApp extends StatelessWidget {
  const JhonSeafoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jhon Seafood 68',
      theme: AppTheme.themeData,
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}

// ==========================================
// 1. DATA MODELS
// ==========================================
class MenuItem {
  final String id;
  String name;
  int price;

  MenuItem({required this.id, required this.name, required this.price});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'price': price};

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(id: map['id'], name: map['name'], price: map['price']);
  }
}

class OrderItem {
  final MenuItem menu;
  int quantity;
  String note;

  OrderItem({required this.menu, this.quantity = 1, this.note = ''});
}

class Order {
  final String orderId;
  final List<OrderItem> items;
  final int totalAmount;
  final DateTime dateTime;
  final String cashierName;
  final String customerName;
  final String tableNumber;
  final String notes;
  final String paymentMethod;
  final String? qrisImagePath;

  Order({
    required this.orderId,
    required this.items,
    required this.totalAmount,
    required this.dateTime,
    required this.cashierName,
    required this.customerName,
    required this.tableNumber,
    required this.notes,
    required this.paymentMethod,
    this.qrisImagePath,
  });

  // Dipakai untuk simpan ke SharedPreferences maupun Firestore
  Map<String, dynamic> toMap() => {
        'orderId': orderId,
        'totalAmount': totalAmount,
        'dateTime': dateTime.toIso8601String(),
        'cashierName': cashierName,
        'customerName': customerName,
        'tableNumber': tableNumber,
        'notes': notes,
        'paymentMethod': paymentMethod,
        'qrisImagePath': qrisImagePath,
        'items': items
    .map((item) => {
          'quantity': item.quantity,
          'menu': item.menu.toMap(),
          'note': item.note,
        })
    .toList(),
      };

  factory Order.fromMap(Map<String, dynamic> json) {
    List<dynamic> itemsJson = json['items'];
    return Order(
      orderId: json['orderId'],
      totalAmount: json['totalAmount'],
      dateTime: DateTime.parse(json['dateTime']),
      cashierName: json['cashierName'],
      customerName: json['customerName'] ?? 'Umum',
      tableNumber: json['tableNumber'] ?? '-',
      notes: json['notes'] ?? '',
      paymentMethod: json['paymentMethod'] ?? 'Cash',
      qrisImagePath: json['qrisImagePath'],
      items: itemsJson
    .map((item) => OrderItem(
          quantity: item['quantity'],
          menu: MenuItem.fromMap(item['menu']),
          note: item['note'] ?? '',
        ))
    .toList(),
    );
  }
}

// ==========================================
// 2. STORAGE MANAGEMENT
// ==========================================
List<MenuItem> seafoodMenu = [
  MenuItem(id: '1', name: 'Kepiting Saus Padang', price: 120000),
  MenuItem(id: '2', name: 'Udang Bakar Madu', price: 65000),
  MenuItem(id: '3', name: 'Cumi Goreng Tepung', price: 50000),
];

List<Order> dailyOrders = [];
String? masterQrisPath;

// ---------- MENU ----------

Future<void> saveMenuToStorage() async {
  final prefs = await SharedPreferences.getInstance();
  List<Map<String, dynamic>> jsonList = seafoodMenu.map((item) => item.toMap()).toList();
  await prefs.setString('saved_seafood_menu', jsonEncode(jsonList));
}

Future<void> loadMenuFromFirebase() async {
  final snapshot = await menuCollection.get(); // pakai 'menu', bukan 'seafood_menu'
  if (snapshot.docs.isNotEmpty) {
    seafoodMenu = snapshot.docs
        .map((doc) => MenuItem.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
    await saveMenuToStorage(); // simpan ulang ke cache lokal juga
  }
}

Future<void> loadMenuFromStorage() async {
  final prefs = await SharedPreferences.getInstance();
  String? jsonString = prefs.getString('saved_seafood_menu');
  if (jsonString != null) {
    List<dynamic> decodedList = jsonDecode(jsonString);
    seafoodMenu = decodedList.map((item) => MenuItem.fromMap(item)).toList();
  }
}

// Update satu item menu + sync ke Firestore
Future<void> updateMenuItem(MenuItem item) async {
  final index = seafoodMenu.indexWhere((m) => m.id == item.id);
  if (index != -1) {
    seafoodMenu[index] = item;
  } else {
    seafoodMenu.add(item);
  }
  await saveMenuToStorage(); // simpan lokal juga
  await menuCollection.doc(item.id).set(item.toMap());
}

// ---------- ORDERS ----------

Future<void> saveOrdersToStorage() async {
  final prefs = await SharedPreferences.getInstance();
  List<Map<String, dynamic>> jsonList = dailyOrders.map((order) => order.toMap()).toList();
  await prefs.setString('saved_daily_orders', jsonEncode(jsonList));
}

Future<void> loadOrdersFromStorage() async {
  final prefs = await SharedPreferences.getInstance();
  String? jsonString = prefs.getString('saved_daily_orders');
  if (jsonString != null) {
    List<dynamic> decodedList = jsonDecode(jsonString);
    dailyOrders = decodedList.map((json) => Order.fromMap(json)).toList();
  }
  masterQrisPath = prefs.getString('master_qris_path');
}

// ==========================================
// PASSWORD AKUN (ADMIN & KASIR)
// ==========================================
Map<String, String> accountPasswords = {
  'admin': 'admin123',
  'kasir': 'kasir123',
};

Future<void> saveCredentialsToStorage() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('account_passwords', jsonEncode(accountPasswords));

  // Sync ke Firestore supaya password baru berlaku juga di device lain.
  try {
    await settingsCollection.doc('credentials').set(accountPasswords);
  } catch (e) {
    debugPrint('Gagal sinkronisasi password ke Firestore: $e');
  }
}

Future<void> loadCredentialsFromStorage() async {
  final prefs = await SharedPreferences.getInstance();
  final String? jsonString = prefs.getString('account_passwords');
  if (jsonString != null) {
    final Map<String, dynamic> decoded = jsonDecode(jsonString);
    accountPasswords = decoded.map((key, value) => MapEntry(key, value.toString()));
  }

  // Tarik juga versi terbaru dari Firestore (kalau sudah pernah diubah
  // dari device lain), supaya password selalu konsisten di semua device.
  try {
    final doc = await settingsCollection.doc('credentials').get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      accountPasswords = data.map((key, value) => MapEntry(key, value.toString()));
      await prefs.setString('account_passwords', jsonEncode(accountPasswords));
    }
  } catch (e) {
    debugPrint('Gagal sinkronisasi password dari Firestore: $e');
  }
}

// ==========================================
// FIRESTORE SYNC (HYBRID: LOKAL + CLOUD)
// ==========================================
// Menyimpan satu order baru ke Firestore. Dipanggil setelah order
// tersimpan secara lokal, jadi transaksi tetap tercatat di device
// meskipun proses upload ke cloud gagal (misalnya karena tidak ada
// koneksi internet).
Future<void> saveOrderToFirestore(Order order) async {
  try {
    await ordersCollection.doc(order.orderId).set(order.toMap());
  } catch (e) {
    debugPrint('Gagal menyimpan order ke Firestore: $e');
    // Tidak melempar ulang error supaya UI tidak terganggu;
    // data tetap aman di SharedPreferences.
  }
}

// Mengunduh semua order dari Firestore lalu menggabungkannya ke data
// lokal berdasarkan orderId (dipanggil misalnya saat login, agar order
// yang dibuat dari device lain juga muncul).
Future<void> syncOrdersFromFirestore() async {
  try {
    final snapshot = await ordersCollection.get();
    final cloudOrders = snapshot.docs
        .map((doc) => Order.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    final existingIds = dailyOrders.map((o) => o.orderId).toSet();
    for (final order in cloudOrders) {
      if (!existingIds.contains(order.orderId)) {
        dailyOrders.add(order);
      }
    }
    await saveOrdersToStorage();
  } catch (e) {
    debugPrint('Gagal sinkronisasi order dari Firestore: $e');
  }
}

// ==========================================
// NOTIFIKASI TRANSAKSI UNTUK ADMIN
// ==========================================
class AppNotification {
  final String message;
  final DateTime time;

  AppNotification({required this.message, required this.time});

  Map<String, dynamic> toMap() => {'message': message, 'time': time.toIso8601String()};

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(message: map['message'], time: DateTime.parse(map['time']));
  }
}

List<AppNotification> adminNotifications = [];
int unseenNotificationCount = 0;

Future<void> saveNotificationsToStorage() async {
  final prefs = await SharedPreferences.getInstance();
  List<Map<String, dynamic>> jsonList = adminNotifications.map((n) => n.toMap()).toList();
  await prefs.setString('admin_notifications', jsonEncode(jsonList));
  await prefs.setInt('unseen_notification_count', unseenNotificationCount);
}

Future<void> loadNotificationsFromStorage() async {
  final prefs = await SharedPreferences.getInstance();
  String? jsonString = prefs.getString('admin_notifications');
  if (jsonString != null) {
    List<dynamic> decodedList = jsonDecode(jsonString);
    adminNotifications = decodedList.map((n) => AppNotification.fromMap(n)).toList();
  }
  unseenNotificationCount = prefs.getInt('unseen_notification_count') ?? 0;
}

// Dipanggil setiap ada transaksi baru tersimpan, agar Admin mendapat notifikasi.
void addTransactionNotification(Order order) {
  adminNotifications.insert(
    0,
    AppNotification(
      message:
          'Transaksi baru dari ${order.customerName} (Meja ${order.tableNumber}) sebesar ${formatRupiah(order.totalAmount)}',
      time: order.dateTime,
    ),
  );
  if (adminNotifications.length > 50) {
    adminNotifications = adminNotifications.sublist(0, 50);
  }
  unseenNotificationCount++;
  saveNotificationsToStorage();
}

// ==========================================
// 3. LAYER INTERFACE: LOGIN SCREEN
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    Future.wait([
      loadMenuFromStorage(),
      loadOrdersFromStorage(),
      loadNotificationsFromStorage(),
      loadCredentialsFromStorage(),
    ]).then((_) async {
      await syncOrdersFromFirestore();
      await loadMenuFromFirebase();
       await syncOrdersFromFirestore();
      if (mounted) setState(() {});
    });
  }

  void _handleLogin() {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    String? role;

    if (username == 'admin' && password == accountPasswords['admin']) {
      role = 'Admin';
    } else if (username == 'kasir' && password == accountPasswords['kasir']) {
      role = 'Kasir';
    }

    if (role != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainNavigationScreen(role: role!)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username/Password salah!'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.restaurant, size: 80, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text('Jhon Seafood 68', style: AppTextStyles.appTitle),
              const SizedBox(height: 40),
              TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(style: AppButtonStyles.primary, onPressed: _handleLogin, child: const Text('LOGIN')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 4. MAIN NAVIGATION INTERFACE
// ==========================================
class MainNavigationScreen extends StatefulWidget {
  final String role;
  const MainNavigationScreen({super.key, required this.role});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _showNotifications() {
    setState(() {
      unseenNotificationCount = 0;
    });
    saveNotificationsToStorage();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifikasi Transaksi'),
        content: SizedBox(
          width: double.maxFinite,
          child: adminNotifications.isEmpty
              ? const Text('Belum ada notifikasi.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: adminNotifications.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final notif = adminNotifications[index];
                    return ListTile(
                      leading: const Icon(Icons.receipt_long, color: AppColors.primary),
                      title: Text(notif.message),
                      subtitle: Text(
                        '${notif.time.day}/${notif.time.month}/${notif.time.year} '
                        '${notif.time.hour.toString().padLeft(2, '0')}:${notif.time.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = widget.role == 'Admin';

    final List<Widget> screens = [
      const CreateOrderScreen(),
      DailyReportScreen(role: widget.role),
      if (isAdmin) const SalesChartScreen(),
      ManageMenuScreen(role: widget.role),
    ];

    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.add_shopping_cart), label: 'Pesanan'),
      const BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Laporan'),
      if (isAdmin) const BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Grafik'),
      BottomNavigationBarItem(icon: const Icon(Icons.restaurant_menu), label: isAdmin ? 'Kelola Menu' : 'Daftar Menu'),
    ];

    if (_currentIndex >= screens.length) _currentIndex = 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jhon Seafood 68', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.primary,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.password, color: AppColors.white),
              tooltip: 'Ubah Password',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                );
              },
            ),
          if (isAdmin)
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications, color: AppColors.white),
                  onPressed: _showNotifications,
                ),
                if (unseenNotificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        unseenNotificationCount > 9 ? '9+' : '$unseenNotificationCount',
                        style: const TextStyle(color: AppColors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Chip(label: Text(widget.role, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)), backgroundColor: AppColors.white),
          ),
          IconButton(icon: const Icon(Icons.logout, color: AppColors.white), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())))
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primary,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: navItems,
      ),
    );
  }
}

// ==========================================
// 5. FEATURE SCREEN: CREATE ORDER
// ==========================================
class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});
  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  List<OrderItem> currentCart = [];
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  bool _cartPanelExpanded = true;

  void addToCart(MenuItem menu) {
    final existingIndex = currentCart.indexWhere((item) => item.menu.id == menu.id);
    setState(() {
      if (existingIndex >= 0) currentCart[existingIndex].quantity++;
      else currentCart.add(OrderItem(menu: menu));
    });
  }

  void removeFromCart(MenuItem menu) {
    final existingIndex = currentCart.indexWhere((item) => item.menu.id == menu.id);
    if (existingIndex >= 0) {
      setState(() {
        if (currentCart[existingIndex].quantity > 1) currentCart[existingIndex].quantity--;
        else currentCart.removeAt(existingIndex);
      });
    }
  }

  int calculateTotal() => currentCart.fold(0, (sum, item) => sum + (item.menu.price * item.quantity));

  int get totalItemCount => currentCart.fold(0, (sum, item) => sum + item.quantity);

  // ==========================================
  // CATATAN PER ITEM (BARU)
  // Membuka dialog kecil untuk menambah/mengubah
  // catatan khusus pada satu item di keranjang,
  // misalnya "pedas level 2", "tanpa bawang", dst.
  // ==========================================
  void _editItemNote(OrderItem item) {
    final TextEditingController noteController = TextEditingController(text: item.note);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Catatan untuk ${item.menu.name}'),
          content: TextField(
            controller: noteController,
            maxLines: 3,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Contoh: pedas level 2, tanpa bawang, extra sambal...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              style: AppButtonStyles.primary,
              onPressed: () {
                setState(() {
                  item.note = noteController.text.trim();
                });
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void showCheckoutDialog() {
    if (currentCart.isEmpty) return;

    final TextEditingController customerController = TextEditingController();
    final TextEditingController tableController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    String selectedPayment = 'Cash';
    String? uploadedProofPath;
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Detail Transaksi'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: customerController, decoration: const InputDecoration(labelText: 'Nama Pelanggan', prefixIcon: Icon(Icons.person))),
                    const SizedBox(height: 10),
                    TextField(controller: tableController, decoration: const InputDecoration(labelText: 'No. Meja', prefixIcon: Icon(Icons.table_restaurant))),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedPayment,
                      decoration: const InputDecoration(labelText: 'Metode Pembayaran', border: OutlineInputBorder()),
                      items: ['Cash', 'QRIS'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (val) => setDialogState(() => selectedPayment = val!),
                    ),

                    if (selectedPayment == 'QRIS') ...[
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Barcode QRIS Toko:', style: AppTextStyles.qrisSectionLabel),
                          TextButton.icon(
                            style: AppButtonStyles.qrisTextButton,
                            onPressed: () async {
                              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                              if (image != null) {
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setString('master_qris_path', image.path);
                                setDialogState(() {
                                  masterQrisPath = image.path;
                                });
                              }
                            },
                            icon: const Icon(Icons.cloud_upload, size: 16, color: AppColors.primary),
                            label: const Text('Ganti QRIS', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                          )
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        height: 160,
                        width: 160,
                        decoration: AppDecorations.qrisImageBox,
                        child: masterQrisPath != null
                            ? (kIsWeb
                                ? Image.network(masterQrisPath!, fit: BoxFit.contain)
                                : Image.file(File(masterQrisPath!), fit: BoxFit.contain)
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code, size: 50, color: AppColors.grey),
                                  SizedBox(height: 4),
                                  Text('QRIS belum diupload.\nKlik "Ganti QRIS"', style: AppTextStyles.qrisPlaceholder, textAlign: TextAlign.center),
                                ],
                              ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 6),
                      const Text('Simpan Bukti Pembayaran Pelanggan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            style: AppButtonStyles.infoDark,
                            onPressed: () async {
                              final XFile? photo = await picker.pickImage(source: ImageSource.camera);
                              if (photo != null) setDialogState(() => uploadedProofPath = photo.path);
                            },
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Foto Bukti'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                              if (image != null) setDialogState(() => uploadedProofPath = image.path);
                            },
                            icon: const Icon(Icons.collections),
                            label: const Text('Galeri'),
                          ),
                        ],
                      ),
                      if (uploadedProofPath != null)
                        const Padding(
                          padding: EdgeInsets.only(top: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: AppColors.success, size: 18),
                              SizedBox(width: 4),
                              Text('Bukti Berhasil Ditempel!', style: AppTextStyles.proofSuccess),
                            ],
                          ),
                        )
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  style: AppButtonStyles.primary,
                  onPressed: () {
                    if (selectedPayment == 'QRIS' && masterQrisPath == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Harap upload foto QRIS toko kamu terlebih dahulu lewat tombol "Ganti QRIS"!'), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    if (selectedPayment == 'QRIS' && uploadedProofPath == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Harap foto atau pilih file bukti transfer pelanggan dahulu!'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    _processCheckout(
                      customerName: customerController.text.isEmpty ? 'Umum' : customerController.text,
                      tableNumber: tableController.text.isEmpty ? '-' : tableController.text,
                      notes: notesController.text,
                      paymentMethod: selectedPayment,
                      qrisImagePath: uploadedProofPath,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('SIMPAN TRANSAKSI'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _processCheckout({
    required String customerName,
    required String tableNumber,
    required String notes,
    required String paymentMethod,
    String? qrisImagePath,
  }) {
    final newOrder = Order(
      orderId: 'JS-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      items: List.from(currentCart),
      totalAmount: calculateTotal(),
      dateTime: DateTime.now(),
      cashierName: 'Kasir Jhon Seafood',
      customerName: customerName,
      tableNumber: tableNumber,
      notes: notes,
      paymentMethod: paymentMethod,
      qrisImagePath: qrisImagePath,
    );

    setState(() {
      dailyOrders.add(newOrder);
      currentCart.clear();
      _searchQuery = "";
      _searchController.clear();
    });

    // 1) Simpan lokal dulu -> app tetap jalan walau offline / Firestore lambat.
    saveOrdersToStorage();
    // 2) Kirim ke Firestore secara async di belakang layar.
    saveOrderToFirestore(newOrder);

    addTransactionNotification(newOrder);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi Berhasil Disimpan!'), backgroundColor: Colors.green));
  }

  // ==========================================
  // PANEL RINGKASAN PESANAN
  // Menampilkan semua item yang sudah dipilih,
  // supaya kasir tidak perlu scroll ke atas
  // untuk mengecek pesanan yang sedang dibuat.
  // Setiap item juga punya baris catatan kecil
  // di bawahnya (tap untuk tambah/ubah catatan).
  // ==========================================
  Widget _buildCartSummaryPanel() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: _cartPanelExpanded ? 260 : 52,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        border: Border(top: BorderSide(color: AppColors.primarySoftBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _cartPanelExpanded = !_cartPanelExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Pesanan Saat Ini · $totalItemCount item',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  Icon(
                    _cartPanelExpanded ? Icons.expand_more : Icons.expand_less,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_cartPanelExpanded)
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: currentCart.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: AppColors.borderGrey.withOpacity(0.5)),
                itemBuilder: (context, index) {
                  final item = currentCart[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.menu.name,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              iconSize: 18,
                              icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger),
                              onPressed: () => removeFromCart(item.menu),
                            ),
                            SizedBox(
                              width: 20,
                              child: Text(
                                '${item.quantity}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              iconSize: 18,
                              icon: const Icon(Icons.add_circle, color: AppColors.primary),
                              onPressed: () => addToCart(item.menu),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 78,
                              child: Text(
                                formatRupiah(item.menu.price * item.quantity),
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        InkWell(
                          onTap: () => _editItemNote(item),
                          child: Row(
                            children: [
                              Icon(
                                item.note.isEmpty ? Icons.note_add_outlined : Icons.edit_note,
                                size: 14,
                                color: item.note.isEmpty ? AppColors.textSecondary : AppColors.ocean,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.note.isEmpty ? 'Tambah catatan...' : item.note,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: item.note.isEmpty ? AppColors.textSecondary : AppColors.ocean,
                                    fontWeight: item.note.isEmpty ? FontWeight.normal : FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
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

  @override
  Widget build(BuildContext context) {
    final filteredMenu = seafoodMenu.where((menu) => menu.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: AppDecorations.searchField(
              labelText: 'Cari Menu Makanan...',
              showClear: _searchQuery.isNotEmpty,
              onClear: () => setState(() { _searchController.clear(); _searchQuery = ""; }),
            ),
          ),
        ),
        Expanded(
          child: filteredMenu.isEmpty
              ? const Center(child: Text('Menu tidak ditemukan', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: filteredMenu.length,
                  itemBuilder: (context, index) {
                    final menu = filteredMenu[index];
                    final cartItem = currentCart.firstWhere((item) => item.menu.id == menu.id, orElse: () => OrderItem(menu: menu, quantity: 0));
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(menu.name, style: AppTextStyles.menuName),
                        subtitle: Text(formatRupiah(menu.price)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (cartItem.quantity > 0) ...[
                              IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger), onPressed: () => removeFromCart(menu)),
                              Text('${cartItem.quantity}', style: AppTextStyles.cartQuantity),
                            ],
                            IconButton(icon: const Icon(Icons.add_circle, color: AppColors.primary), onPressed: () => addToCart(menu)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (currentCart.isNotEmpty) _buildCartSummaryPanel(),
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment : CrossAxisAlignment.start,
                mainAxisSize  : MainAxisSize.min,
                children: [
                  const Text('Total:', style: AppTextStyles.totalLabel),
                  Text(formatRupiah(calculateTotal()), style: AppTextStyles.totalValue),
                ],
              ),
              ElevatedButton.icon(
                style: AppButtonStyles.primary,
                onPressed: currentCart.isEmpty ? null : showCheckoutDialog,
                icon: const Icon(Icons.receipt_long),
                label: const Text('PROSES PESANAN'),
              )
            ],
          ),
        )
      ],
    );
  }
}

// ==========================================
// 6. FEATURE SCREEN: DAILY REPORT
// ==========================================
class DailyReportScreen extends StatefulWidget {
  final String role;
  const DailyReportScreen({super.key, required this.role});
  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isExporting = false;

  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showUploadedProof(String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Foto Bukti Pembayaran Pelanggan'),
        content: kIsWeb ? Image.network(path) : Image.file(File(path)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
      ),
    );
  }

  Future<void> _exportToExcel() async {
    setState(() => _isExporting = true);
    try {
      final result = await exportYearlyMonthlyRecapToExcel(_selectedDate.year);
if (mounted) {
  if (result != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result), backgroundColor: AppColors.success),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Penyimpanan dibatalkan')),
    );
  }
}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal export: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = widget.role == 'Admin';
    final filteredOrders = dailyOrders.where((order) {
      return order.dateTime.year == _selectedDate.year &&
             order.dateTime.month == _selectedDate.month &&
             order.dateTime.day == _selectedDate.day;
    }).toList();

    int calculateTotalOmzet() => filteredOrders.fold(0, (sum, order) => sum + order.totalAmount);

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.deepOrange.shade50, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Laporan: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(formatRupiah(calculateTotalOmzet()), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                    Text('${filteredOrders.length} Transaksi', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500)),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.calendar_month, color: Colors.deepOrange, size: 32), onPressed: _pickDate),
                    if (isAdmin)
                      _isExporting
                          ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : IconButton(
                              icon: const Icon(Icons.file_download, color: Colors.green),
                              tooltip: 'Export Excel Bulan Ini',
                              onPressed: _exportToExcel,
                            ),
                  ],
                ),
              ],
            ),
          ),
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tombol unduh mengekspor SELURUH transaksi bulan '
                  '${_selectedDate.month}/${_selectedDate.year} ke Excel.',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ),
          const SizedBox(height: 4),
          Expanded(
            child: filteredOrders.isEmpty
                ? const Center(child: Text('Tidak ada transaksi di tanggal ini.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders.reversed.toList()[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ExpansionTile(
                          leading: Icon(order.paymentMethod == 'QRIS' ? Icons.qr_code : Icons.money, color: Colors.green),
                          title: Text('${order.customerName} (Meja ${order.tableNumber})', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${order.dateTime.hour.toString().padLeft(2, '0')}:${order.dateTime.minute.toString().padLeft(2, '0')} | ${order.paymentMethod}'),
                          trailing: Text(formatRupiah(order.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              color: Colors.grey.shade50,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (order.notes.isNotEmpty) ...[
                                    Text('Catatan: ${order.notes}', style: const TextStyle(color: Colors.redAccent, fontStyle: FontStyle.italic)),
                                    const Divider(),
                                  ],
                                  ...order.items.map((item) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${item.menu.name} (x${item.quantity})'), Text(formatRupiah(item.menu.price * item.quantity))]),
                                      )),
                                  if (order.paymentMethod == 'QRIS' && order.qrisImagePath != null) ...[
                                    const Divider(),
                                    TextButton.icon(
                                      style: TextButton.styleFrom(foregroundColor: Colors.blue.shade800),
                                      onPressed: () => _showUploadedProof(order.qrisImagePath!),
                                      icon: const Icon(Icons.image_search),
                                      label: const Text('Lihat Lampiran Foto Bukti'),
                                    ),
                                  ],
                                  const Divider(),
                                  Text('Kasir: ${order.cashierName}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            )
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

// ==========================================
// 7. FEATURE SCREEN: MANAGE MENU
// ==========================================
class ManageMenuScreen extends StatefulWidget {
  final String role;
  const ManageMenuScreen({super.key, required this.role});
  @override
  State<ManageMenuScreen> createState() => _ManageMenuScreenState();
}

class _ManageMenuScreenState extends State<ManageMenuScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  void _showFormDialog({MenuItem? item}) {
    if (widget.role != 'Admin') return;
    final bool isEdit = item != null;
    if (isEdit) {
      _nameController.text = item.name;
      _priceController.text = item.price.toString();
    } else {
      _nameController.clear();
      _priceController.clear();
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Ubah Menu Makanan' : 'Tambah Menu Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nama Menu')),
              TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga (Rp)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final String name = _nameController.text.trim();
                final int price = int.tryParse(_priceController.text.trim()) ?? 0;
                if (name.isEmpty || price <= 0) return;
                setState(() {
                  if (isEdit) { item.name = name; item.price = price; }
                  else { seafoodMenu.add(MenuItem(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, price: price)); }
                });
                await saveMenuToStorage();
                // Sinkronkan menu ke Firestore juga (opsional tapi berguna
                // kalau nanti mau tampilkan menu di device lain).
                final savedItem = isEdit ? item : seafoodMenu.last;
                menuCollection.doc(savedItem.id).set(savedItem.toMap()).catchError((e) {
                  debugPrint('Gagal sinkronisasi menu ke Firestore: $e');
                });
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _deleteMenu(String id) async {
    if (widget.role != 'Admin') return;
    setState(() => seafoodMenu.removeWhere((element) => element.id == id));
    await saveMenuToStorage();
    menuCollection.doc(id).delete().catchError((e) {
      debugPrint('Gagal hapus menu di Firestore: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = widget.role == 'Admin';
    return Scaffold(
      body: seafoodMenu.isEmpty
          ? const Center(child: Text('Belum ada data menu.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: seafoodMenu.length,
              itemBuilder: (context, index) {
                final item = seafoodMenu[index];
                return Card(
                  child: ListTile(
                    title: Text(item.name, style: AppTextStyles.menuName),
                    subtitle: Text(formatRupiah(item.price)),
                    trailing: isAdmin
                        ? Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showFormDialog(item: item)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteMenu(item.id)),
                          ])
                        : const Icon(Icons.lock_outline, color: Colors.grey),
                  ),
                );
              },
            ),
      floatingActionButton: isAdmin ? FloatingActionButton(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white, onPressed: () => _showFormDialog(), child: const Icon(Icons.add)) : null,
    );
  }
}

// ==========================================
// 8. FEATURE SCREEN: UBAH PASSWORD (ADMIN ONLY)
// ==========================================
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  String _selectedAccount = 'admin';
  final TextEditingController _currentAdminPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  void _submit() async {
    final currentAdminPass = _currentAdminPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    // Verifikasi identitas admin yang sedang login, supaya tidak
    // sembarang orang yang kebetulan membuka layar ini bisa ganti password.
    if (currentAdminPass != accountPasswords['admin']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password admin saat ini salah!'), backgroundColor: Colors.red),
      );
      return;
    }

    if (newPass.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password baru minimal 4 karakter!'), backgroundColor: Colors.red),
      );
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password baru tidak cocok!'), backgroundColor: Colors.red),
      );
      return;
    }

    // Cegah password baru sama dengan password lama akun yang dipilih.
    if (newPass == accountPasswords[_selectedAccount]) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password baru tidak boleh sama dengan password ${_selectedAccount == 'admin' ? 'Admin' : 'Kasir'} saat ini!',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    setState(() {
      accountPasswords[_selectedAccount] = newPass;
    });
    await saveCredentialsToStorage();
    setState(() => _isSaving = false);

    _currentAdminPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password akun ${_selectedAccount == 'admin' ? 'Admin' : 'Kasir'} berhasil diubah!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubah Password'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih akun yang ingin diubah passwordnya',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedAccount,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(value: 'kasir', child: Text('Kasir')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedAccount = val);
              },
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Konfirmasi identitas Admin',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Masukkan password Admin saat ini untuk mengonfirmasi perubahan.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _currentAdminPasswordController,
              obscureText: _obscureCurrent,
              decoration: InputDecoration(
                labelText: 'Password Admin Saat Ini',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.admin_panel_settings),
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Password Baru untuk ${_selectedAccount == 'admin' ? 'Admin' : 'Kasir'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPasswordController,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: 'Password Baru',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Konfirmasi Password Baru',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: AppButtonStyles.primary,
                onPressed: _isSaving ? null : _submit,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Menyimpan...' : 'SIMPAN PASSWORD BARU'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}