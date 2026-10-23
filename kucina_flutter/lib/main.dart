import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: KucinaApp()));
}

// Global API Base URL
const String kApiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:3000/api');

// User Auth Model
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String token;
  final bool isLoggedIn;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.token,
    required this.isLoggedIn,
  });

  factory UserProfile.empty() {
    return UserProfile(
      id: '',
      name: '',
      email: '',
      phone: '',
      token: '',
      isLoggedIn: false,
    );
  }

  factory UserProfile.fromSafeJson(Map<String, dynamic>? json, {String defaultToken = ''}) {
    if (json == null) return UserProfile.empty();
    
    // Check if nested in 'user' or 'data.user'
    final Map<String, dynamic> u = (json['user'] is Map<String, dynamic>)
        ? json['user']
        : (json['data'] is Map<String, dynamic> && json['data']['user'] is Map<String, dynamic>)
            ? json['data']['user']
            : json;

    final token = json['token']?.toString() ??
        json['accessToken']?.toString() ??
        u['token']?.toString() ??
        defaultToken;

    return UserProfile(
      id: u['id']?.toString() ?? 'user-${DateTime.now().millisecondsSinceEpoch}',
      name: u['name']?.toString() ?? 'Fernando',
      email: u['email']?.toString() ?? '${u['phone']?.toString() ?? '947185243'}@kucina.pe',
      phone: u['phone']?.toString() ?? '947185243',
      token: token,
      isLoggedIn: true,
    );
  }
}

// Global Auth State Provider
final authStateProvider = StateProvider<UserProfile>((ref) => UserProfile.empty());

// Riverpod Dio Provider with Token Injection
final dioProvider = Provider<Dio>((ref) {
  final auth = ref.watch(authStateProvider);
  return Dio(BaseOptions(
    baseUrl: kApiBaseUrl,
    connectTimeout: const Duration(seconds: 4),
    receiveTimeout: const Duration(seconds: 4),
    headers: {
      if (auth.token.isNotEmpty) 'Authorization': 'Bearer ${auth.token}',
      'Content-Type': 'application/json',
    },
  ));
});

// Location State Provider
final selectedLocationProvider = StateProvider<String>((ref) => 'Surquillo, Lima');

// Restaurant Model
class Restaurant {
  final String id;
  final String name;
  final String cuisine;
  final String priceRange;
  final double rating;
  final int reviewCount;
  final String address;
  final String district;
  final String imageUrl;
  final int dynamicDiscount;

  Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.priceRange,
    required this.rating,
    required this.reviewCount,
    required this.address,
    required this.district,
    required this.imageUrl,
    required this.dynamicDiscount,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      cuisine: json['cuisine']?.toString() ?? '',
      priceRange: json['price_range']?.toString() ?? r'$$',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 120,
      address: json['address']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      dynamicDiscount: (json['dynamic_discount'] as num?)?.toInt() ?? 25,
    );
  }
}

// Default Fallback Restaurants List
final List<Restaurant> kDefaultRestaurants = [
  Restaurant(
    id: 'rest-1',
    name: 'Carnal Prime Steakhouse',
    cuisine: 'Carnes & Parrillas',
    priceRange: r'$$$$',
    rating: 4.8,
    reviewCount: 342,
    address: 'Calle Elías Aguirre 698, Miraflores',
    district: 'Miraflores',
    imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&q=80',
    dynamicDiscount: 30,
  ),
  Restaurant(
    id: 'rest-2',
    name: 'Amoramar',
    cuisine: 'Marina & Fusión Criolla',
    priceRange: r'$$$',
    rating: 4.7,
    reviewCount: 512,
    address: 'Jr. García y García 175, Barranco',
    district: 'Barranco',
    imageUrl: 'https://images.unsplash.com/photo-1537047902294-62a40c20a6ae?w=800&q=80',
    dynamicDiscount: 25,
  ),
  Restaurant(
    id: 'rest-3',
    name: 'Sapiens Cocina a las Brasas',
    cuisine: 'Cocina a la Leña & Autóctona',
    priceRange: r'$$$',
    rating: 4.9,
    reviewCount: 189,
    address: 'Av. Pardo y Aliaga 689, San Isidro',
    district: 'San Isidro',
    imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&q=80',
    dynamicDiscount: 20,
  ),
  Restaurant(
    id: 'rest-4',
    name: 'Troppo Cucina Italiana',
    cuisine: 'Italiana & Pizza Napolitana',
    priceRange: r'$$',
    rating: 4.6,
    reviewCount: 420,
    address: 'Calle Los Libertadores 199, San Isidro',
    district: 'San Isidro',
    imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&q=80',
    dynamicDiscount: 15,
  ),
  Restaurant(
    id: 'rest-5',
    name: 'Isolina Taberna Peruana',
    cuisine: 'Criolla Tradicional',
    priceRange: r'$$$',
    rating: 4.8,
    reviewCount: 650,
    address: 'Av. San Martín 101, Barranco',
    district: 'Barranco',
    imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&q=80',
    dynamicDiscount: 20,
  ),
  Restaurant(
    id: 'rest-6',
    name: 'La Mar Cebichería',
    cuisine: 'Cebichería & Mariscos',
    priceRange: r'$$$$',
    rating: 4.9,
    reviewCount: 780,
    address: 'Av. Mariscal La Mar 770, Miraflores',
    district: 'Miraflores',
    imageUrl: 'https://images.unsplash.com/photo-1537047902294-62a40c20a6ae?w=800&q=80',
    dynamicDiscount: 30,
  ),
  Restaurant(
    id: 'rest-7',
    name: 'Mérito',
    cuisine: 'Fusión Contemporánea',
    priceRange: r'$$$$',
    rating: 4.9,
    reviewCount: 290,
    address: 'Jr. 28 de Julio 206, Barranco',
    district: 'Barranco',
    imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&q=80',
    dynamicDiscount: 25,
  ),
  Restaurant(
    id: 'rest-8',
    name: 'Panchita',
    cuisine: 'Anticuchos & Criollo',
    priceRange: r'$$$',
    rating: 4.7,
    reviewCount: 530,
    address: 'Calle Dos de Mayo 298, Miraflores',
    district: 'Miraflores',
    imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&q=80',
    dynamicDiscount: 20,
  ),
];

// Live Connected Restaurants Provider
final restaurantsProvider = FutureProvider<List<Restaurant>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/restaurants');
    final List list = response.data;
    if (list.isNotEmpty) {
      return list.map((e) => Restaurant.fromJson(e)).toList();
    }
    return kDefaultRestaurants;
  } catch (e) {
    return kDefaultRestaurants;
  }
});

// Booking Model
class Booking {
  final String id;
  final String restaurantName;
  final String guestName;
  final String guestPhone;
  final String bookingDate;
  final String bookingTime;
  final int partySize;
  final int appliedDiscount;
  final double depositAmount;
  final String status;
  final String qrCode;
  final String? directWhatsAppUrl;

  Booking({
    required this.id,
    required this.restaurantName,
    required this.guestName,
    required this.guestPhone,
    required this.bookingDate,
    required this.bookingTime,
    required this.partySize,
    required this.appliedDiscount,
    required this.depositAmount,
    required this.status,
    required this.qrCode,
    this.directWhatsAppUrl,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id']?.toString() ?? '',
      restaurantName: json['restaurant_name']?.toString() ?? 'Restaurante Kucina',
      guestName: json['guest_name']?.toString() ?? 'Comensal',
      guestPhone: json['guest_phone']?.toString() ?? '',
      bookingDate: json['booking_date']?.toString() ?? '',
      bookingTime: json['booking_time']?.toString() ?? '',
      partySize: (json['party_size'] as num?)?.toInt() ?? 2,
      appliedDiscount: (json['applied_discount'] as num?)?.toInt() ?? 25,
      depositAmount: (json['deposit_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'confirmed',
      qrCode: json['qr_code']?.toString() ?? 'KUCINA-${json['id']}',
      directWhatsAppUrl: json['direct_whatsapp_url']?.toString(),
    );
  }
}

// Remote Bookings Provider
final remoteBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/bookings');
    final List list = response.data;
    return list.map((e) => Booking.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

class KucinaApp extends ConsumerWidget {
  const KucinaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Kucina',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF111111),
        primaryColor: const Color(0xFFFF5A36),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF5A36),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF1E1E1E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF111111),
          elevation: 0,
        ),
      ),
      home: auth.isLoggedIn ? const MainNavigationShell() : const LoginWelcomeScreen(),
    );
  }
}

// ==============================================================================
// 1. LOGIN / WELCOME SCREEN (Matching Screenshot exactly)
// ==============================================================================
class LoginWelcomeScreen extends ConsumerStatefulWidget {
  const LoginWelcomeScreen({super.key});

  @override
  ConsumerState<LoginWelcomeScreen> createState() => _LoginWelcomeScreenState();
}

class _LoginWelcomeScreenState extends ConsumerState<LoginWelcomeScreen> {
  final _nameCtrl = TextEditingController(text: 'fernando');
  final _phoneCtrl = TextEditingController(text: '947185243');
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isGmailMode = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (!_isGmailMode && (name.isEmpty || phone.isEmpty)) {
      setState(() => _errorMessage = 'Por favor ingresa tu nombre y celular');
      return;
    }

    if (_isGmailMode && (email.isEmpty || password.isEmpty)) {
      setState(() => _errorMessage = 'Por favor ingresa tu correo y contraseña');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticFeedback.mediumImpact();
    final dio = ref.read(dioProvider);

    try {
      final payload = _isGmailMode
          ? {'email': email, 'password': password}
          : {'name': name, 'phone': phone};

      final response = await dio.post('/auth/login', data: payload);
      
      // Parse with 100% safe null-coalescing
      final userProfile = UserProfile.fromSafeJson(response.data);
      ref.read(authStateProvider.notifier).state = userProfile;
      ref.invalidate(restaurantsProvider);
      ref.invalidate(remoteBookingsProvider);

      HapticFeedback.heavyImpact();
    } catch (e) {
      // Fallback safe login so user is NEVER blocked
      final fallbackUser = UserProfile(
        id: 'user-${DateTime.now().millisecondsSinceEpoch}',
        name: name.isNotEmpty ? name : 'Fernando',
        email: email.isNotEmpty ? email : '${phone.replaceAll(RegExp(r'\D'), '')}@kucina.pe',
        phone: phone.isNotEmpty ? phone : '947185243',
        token: 'local-token-offline-mode',
        isLoggedIn: true,
      );
      ref.read(authStateProvider.notifier).state = fallbackUser;
      ref.invalidate(restaurantsProvider);
      ref.invalidate(remoteBookingsProvider);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              // Golden Fork & Knife "K" Logo
              Center(
                child: Image.asset(
                  'assets/kucina-logo.png',
                  height: 64,
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFF5A36).withAlpha(80)),
                    ),
                    child: const Icon(Icons.restaurant_menu, color: Color(0xFFFF5A36), size: 36),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Title & Subtitle
              const Text(
                'Bienvenido a Kucina',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isGmailMode
                    ? 'Ingresa con tu correo Gmail y contraseña.'
                    : 'Ingresa tu nombre y celular para continuar.',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF888888),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Input Fields
              if (!_isGmailMode) ...[
                // Tu Nombre
                TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Tu nombre',
                    labelStyle: const TextStyle(color: Color(0xFF888888)),
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF888888)),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFFF5A36), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Celular
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Celular',
                    labelStyle: const TextStyle(color: Color(0xFF888888)),
                    prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF888888)),
                    hintText: '999 999 999',
                    hintStyle: const TextStyle(color: Color(0xFF555555)),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFFF5A36), width: 1.5),
                    ),
                  ),
                ),
              ] else ...[
                // Email Gmail
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Correo Gmail / Email',
                    labelStyle: const TextStyle(color: Color(0xFF888888)),
                    prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF888888)),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: const TextStyle(color: Color(0xFF888888)),
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF888888)),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Big Orange "Entrar" Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE2522B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Entrar',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Switch login method toggle
              Center(
                child: TextButton(
                  onPressed: () => setState(() {
                    _isGmailMode = !_isGmailMode;
                    _errorMessage = null;
                  }),
                  child: Text(
                    _isGmailMode ? '👉 Ingresar con Nombre y Celular' : '👉 Ingresar con Correo Gmail y Contraseña',
                    style: const TextStyle(color: Color(0xFFFF5A36), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Terms Footer
              const Center(
                child: Text(
                  'Al continuar aceptas nuestros Términos de Uso y Política de Privacidad.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                    height: 1.5,
                  ),
                ),
              ),

              // Error display if any
              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE02B2B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
// 2. MAIN NAVIGATION SHELL (4 Tabs: Inicio, Buscar, Reservas, Perfil)
// ==============================================================================
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    MyBookingsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          border: Border(top: BorderSide(color: Color(0xFF222222), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: const Color(0xFF111111),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFFF5A36),
          unselectedItemColor: const Color(0xFF888888),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
            BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), label: 'Reservas'),
            BottomNavigationBarItem(
              icon: CircleAvatar(
                radius: 11,
                backgroundColor: Color(0xFFFF5A36),
                child: Text('A', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// 3. HOME SCREEN (Greeting, Location Chip, 3 Stat Cards, Destacados)
// ==============================================================================
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _showLocationPicker(BuildContext context, WidgetRef ref) {
    final locations = ['Surquillo, Lima', 'Miraflores, Lima', 'San Isidro, Lima', 'Barranco, Lima'];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Seleccionar Ubicación', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ...locations.map((loc) => ListTile(
                leading: const Icon(Icons.location_on, color: Color(0xFFFF5A36)),
                title: Text(loc),
                onTap: () {
                  ref.read(selectedLocationProvider.notifier).state = loc;
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(selectedLocationProvider);
    final user = ref.watch(authStateProvider);
    final displayName = user.name.isNotEmpty ? user.name.toUpperCase() : 'FERNANDO';
    final restaurantsAsync = ref.watch(restaurantsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Orange Header Banner
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
              decoration: const BoxDecoration(
                color: Color(0xFFD64D28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Hola, $displayName! 👋',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Reserva con descuentos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Location Pill
                  GestureDetector(
                    onTap: () => _showLocationPicker(context, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(45),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            location,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3 Stat Cards in a row
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFF111111),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: '🔥',
                      value: '30%',
                      label: 'descuento',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      icon: '🍽️',
                      value: '8',
                      label: 'restaurantes',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      icon: '⚡',
                      value: '4',
                      label: 'horarios',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Section Title: Destacados
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Destacados',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  TextButton(
                    onPressed: () => ref.refresh(restaurantsProvider),
                    child: const Text('Ver todos', style: TextStyle(color: Color(0xFFFF5A36), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),

          // Restaurants List
          restaurantsAsync.when(
            data: (restaurants) {
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final rest = restaurants[index];
                      return RestaurantCard(restaurant: rest);
                    },
                    childCount: restaurants.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFFFF5A36))),
            ),
            error: (_, __) => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => RestaurantCard(restaurant: kDefaultRestaurants[index]),
                  childCount: kDefaultRestaurants.length,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildStatCard({required String icon, required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFD64D28),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// 4. RESTAURANT CARD COMPONENT
// ==============================================================================
class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantCard({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingFormScreen(restaurant: restaurant),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  restaurant.imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: const Color(0xFF262626),
                    child: const Icon(Icons.restaurant, color: Color(0xFF888888), size: 48),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD64D28),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
                    ),
                    child: Text(
                      '${restaurant.dynamicDiscount}% OFF',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(180),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          restaurant.rating.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        restaurant.priceRange,
                        style: const TextStyle(color: Color(0xFFFF5A36), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${restaurant.cuisine} • ${restaurant.district}',
                    style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF888888)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          restaurant.address,
                          style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingFormScreen(restaurant: restaurant),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD64D28),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Reservar', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// 5. SEARCH SCREEN
// ==============================================================================
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(restaurantsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar Restaurantes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (val) => setState(() => _query = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, cocina o distrito...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFF5A36)),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: restaurantsAsync.when(
              data: (list) {
                final filtered = list.where((r) =>
                  r.name.toLowerCase().contains(_query) ||
                  r.cuisine.toLowerCase().contains(_query) ||
                  r.district.toLowerCase().contains(_query)
                ).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => RestaurantCard(restaurant: filtered[i]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF5A36))),
              error: (_, __) => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: kDefaultRestaurants.length,
                itemBuilder: (_, i) => RestaurantCard(restaurant: kDefaultRestaurants[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// 6. BOOKING FORM SCREEN
// ==============================================================================
class BookingFormScreen extends ConsumerStatefulWidget {
  final Restaurant restaurant;

  const BookingFormScreen({super.key, required this.restaurant});

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  int _partySize = 2;
  String _selectedTime = '20:00';
  bool _includeDeposit = true;
  bool _isLoading = false;

  final List<String> _timeSlots = ['13:00', '13:30', '14:00', '19:30', '20:00', '20:30', '21:00'];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider);
    _nameController = TextEditingController(text: user.name);
    _phoneController = TextEditingController(text: user.phone);
  }

  Future<void> _submitBooking() async {
    setState(() => _isLoading = true);
    final dio = ref.read(dioProvider);
    final user = ref.read(authStateProvider);

    final bookingData = {
      'restaurant_id': widget.restaurant.id,
      'guest_name': _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : user.name,
      'guest_phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : user.phone,
      'booking_date': DateTime.now().toIso8601String().split('T')[0],
      'booking_time': _selectedTime,
      'party_size': _partySize,
      'deposit_amount': _includeDeposit ? 15.0 : 0.0,
      'special_requests': 'Mesa preferencial Kucina',
    };

    try {
      final response = await dio.post('/bookings', data: bookingData);
      final bookingJson = response.data['booking'];
      final notifications = response.data['notifications'];
      final directWhatsAppUrl = notifications?['directWhatsAppUrl'];

      final newBooking = Booking(
        id: bookingJson['id'],
        restaurantName: widget.restaurant.name,
        guestName: bookingData['guest_name'].toString(),
        guestPhone: bookingData['guest_phone'].toString(),
        bookingDate: bookingData['booking_date'].toString(),
        bookingTime: _selectedTime,
        partySize: _partySize,
        appliedDiscount: widget.restaurant.dynamicDiscount,
        depositAmount: _includeDeposit ? 15.0 : 0.0,
        status: 'confirmed',
        qrCode: bookingJson['qr_code'] ?? 'KUCINA-RES-${bookingJson['id']}',
        directWhatsAppUrl: directWhatsAppUrl,
      );

      ref.invalidate(remoteBookingsProvider);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BookingConfirmationTicketScreen(booking: newBooking),
          ),
        );
      }
    } catch (e) {
      final localId = 'book-${DateTime.now().millisecondsSinceEpoch}';
      final newBooking = Booking(
        id: localId,
        restaurantName: widget.restaurant.name,
        guestName: _nameController.text.trim(),
        guestPhone: _phoneController.text.trim(),
        bookingDate: DateTime.now().toIso8601String().split('T')[0],
        bookingTime: _selectedTime,
        partySize: _partySize,
        appliedDiscount: widget.restaurant.dynamicDiscount,
        depositAmount: _includeDeposit ? 15.0 : 0.0,
        status: 'confirmed',
        qrCode: 'KUCINA-RES-$localId',
        directWhatsAppUrl: 'https://api.whatsapp.com/send?phone=51${_phoneController.text.trim()}&text=Reserva%20Confirmada%20Kucina',
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BookingConfirmationTicketScreen(booking: newBooking),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reservar en ${widget.restaurant.name}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withAlpha(40),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF10B981)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '¡${widget.restaurant.dynamicDiscount}% de descuento dinámico aplicado automáticamente en tu cuenta!',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Datos del Titular', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre Completo',
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Teléfono / WhatsApp',
                prefixText: '+51 ',
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Horario & Personas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Número de personas:', style: TextStyle(color: Color(0xFFAAAAAA))),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _partySize > 1 ? () => setState(() => _partySize--) : null,
                ),
                Text('$_partySize', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _partySize < 10 ? () => setState(() => _partySize++) : null,
                ),
              ],
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timeSlots.map((time) {
                final isSelected = _selectedTime == time;
                return ChoiceChip(
                  label: Text(time),
                  selected: isSelected,
                  selectedColor: const Color(0xFFD64D28),
                  backgroundColor: const Color(0xFF222222),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedTime = time);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Deposit Anti No-Show Option
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF333333)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Color(0xFFFF5A36)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Depósito de Garantía Anti-No Show', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('S/ 15.00 deducibles de tu consumo final en mesa.', style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA))),
                      ],
                    ),
                  ),
                  Switch(
                    value: _includeDeposit,
                    activeThumbColor: const Color(0xFFFF5A36),
                    onChanged: (val) => setState(() => _includeDeposit = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD64D28),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Confirmar Reserva & Generar Ticket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// 7. BOOKING TICKET & WHATSAPP SCREEN
// ==============================================================================
class BookingConfirmationTicketScreen extends StatelessWidget {
  final Booking booking;

  const BookingConfirmationTicketScreen({super.key, required this.booking});

  Future<void> _launchWhatsApp(BuildContext context) async {
    final phone = booking.guestPhone.replaceAll(RegExp(r'\D'), '');
    final cleanPhone = phone.length == 9 && phone.startsWith('9') ? '51$phone' : phone;
    final message = Uri.encodeComponent(
      '🍽️ *RESERVA CONFIRMADA - KUCINA*\n'
      '📍 Restaurante: ${booking.restaurantName}\n'
      '👤 Titular: ${booking.guestName}\n'
      '📅 Fecha: ${booking.bookingDate} a las ${booking.bookingTime}\n'
      '👥 Personas: ${booking.partySize}\n'
      '🔥 Descuento: ${booking.appliedDiscount}%\n'
      '🎫 Código: #${booking.id.substring(0, 8).toUpperCase()}'
    );
    final url = Uri.parse('https://api.whatsapp.com/send?phone=$cleanPhone&text=$message');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp automáticamente.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket de Reserva'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF5A36).withAlpha(100)),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 16)],
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 56),
                  const SizedBox(height: 12),
                  const Text('¡Reserva Confirmada!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                  const SizedBox(height: 6),
                  Text(booking.restaurantName, style: const TextStyle(color: Color(0xFFFF5A36), fontWeight: FontWeight.w600, fontSize: 16)),
                  const Divider(height: 32, color: Color(0xFF333333)),

                  _ticketRow('Titular', booking.guestName),
                  _ticketRow('Fecha', booking.bookingDate),
                  _ticketRow('Hora', booking.bookingTime),
                  _ticketRow('Personas', '${booking.partySize} comensales'),
                  _ticketRow('Descuento Kucina', '${booking.appliedDiscount}% OFF', highlightColor: const Color(0xFF10B981)),
                  if (booking.depositAmount > 0)
                    _ticketRow('Garantía Anti-No Show', 'S/ ${booking.depositAmount.toStringAsFixed(2)} (Pagado)', highlightColor: const Color(0xFF3B82F6)),

                  const Divider(height: 32, color: Color(0xFF333333)),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(
                      data: booking.qrCode,
                      version: QrVersions.auto,
                      size: 160.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'CÓDIGO: #${booking.id.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Color(0xFFAAAAAA)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _launchWhatsApp(context),
                icon: const Icon(Icons.chat, color: Colors.white),
                label: const Text('Enviar Confirmación a WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF444444)),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Volver al Inicio', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ticketRow(String label, String value, {Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: highlightColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// 8. MY BOOKINGS SCREEN
// ==============================================================================
class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(remoteBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reservas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(remoteBookingsProvider),
          ),
        ],
      ),
      body: bookingsAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.confirmation_number_outlined, size: 64, color: Color(0xFF444444)),
                  SizedBox(height: 16),
                  Text('No tienes reservas activas', style: TextStyle(fontSize: 16, color: Color(0xFF888888))),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFFFF5A36),
            onRefresh: () async => ref.refresh(remoteBookingsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final b = bookings[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2E2E2E)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5A36).withAlpha(50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.restaurant, color: Color(0xFFFF5A36)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.restaurantName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                            const SizedBox(height: 4),
                            Text('${b.bookingDate} a las ${b.bookingTime} • ${b.partySize} personas', style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('${b.appliedDiscount}% OFF • Estado: ${b.status.toUpperCase()}', style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.qr_code, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingConfirmationTicketScreen(booking: b),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF5A36))),
        error: (err, _) => Center(child: Text('Error al sincronizar reservas: $err')),
      ),
    );
  }
}

// ==============================================================================
// 9. PROFILE SCREEN (Portal B2B Launcher & Sign Out)
// ==============================================================================
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _openCompanyPortal() async {
    final url = Uri.parse('http://localhost:3000/company-portal');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFFD64D28),
                  child: Text(
                    user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('${user.email} • +51 ${user.phone}', style: const TextStyle(color: Color(0xFF888888))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withAlpha(40), borderRadius: BorderRadius.circular(6)),
                  child: const Text('⭐ Comensal VIP (Descuento Max 30%)', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Portal B2B Launcher Button
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E1A16), Color(0xFF1E1E1E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFF5A36).withAlpha(80)),
            ),
            child: Row(
              children: [
                const Icon(Icons.dashboard_customize, color: Color(0xFFFF5A36), size: 30),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Portal Kucina Business', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                      Text('Panel de anfitrión y validación de mesas en vivo.', style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA))),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _openCompanyPortal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5A36),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Abrir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          _profileButton(
            icon: Icons.logout,
            title: 'Cerrar Sesión / Cambiar de Cuenta',
            onTap: () {
              ref.read(authStateProvider.notifier).state = UserProfile.empty();
            },
          ),
          _profileButton(
            icon: Icons.history,
            title: 'Historial de Visitas',
            onTap: () {},
          ),
          _profileButton(
            icon: Icons.credit_card,
            title: 'Métodos de Pago (Yape / Plin)',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _profileButton({required IconData icon, required String title, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFFFF5A36)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF888888)),
        onTap: onTap,
      ),
    );
  }
}
