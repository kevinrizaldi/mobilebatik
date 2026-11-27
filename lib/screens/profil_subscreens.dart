import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/profile_store.dart';
import '../services/api_client.dart';
import '../services/profile_service.dart';
import '../services/shipping_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/full_screen_image_viewer.dart';

class EditProfilScreen extends StatefulWidget {
  const EditProfilScreen({super.key});

  @override
  State<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends State<EditProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _birthDateController;
  late String _gender;
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    final profile = ProfileStore.instance;
    _nameController = TextEditingController(text: profile.name);
    _emailController = TextEditingController(text: profile.email);
    _phoneController = TextEditingController(text: profile.phone);
    _birthDate = profile.birthDate;
    _birthDateController = TextEditingController(
      text: _formatDate(profile.birthDate),
    );
    _gender = profile.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return _SubpageScaffold(
      title: 'Edit Profil',
      child: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(r.pagePaddingH),
          children: [
            _formField(
              'Nama Lengkap',
              _nameController,
              validator: (value) => _required(value, 'Nama lengkap'),
            ),
            _formField(
              'Email',
              _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => _required(value, 'Email'),
            ),
            _formField(
              'Nomor Telepon',
              _phoneController,
              keyboardType: TextInputType.phone,
              validator: (value) => _required(value, 'Nomor telepon'),
            ),
            Text('Tanggal Lahir', style: _fieldLabelStyle()),
            const SizedBox(height: 6),
            TextFormField(
              controller: _birthDateController,
              readOnly: true,
              onTap: _selectBirthDate,
              decoration: _inputDecoration(
                hint: 'Pilih tanggal lahir',
                suffix: const Icon(Icons.calendar_month_outlined, size: 18),
              ),
            ),
            const SizedBox(height: 14),
            Text('Jenis Kelamin', style: _fieldLabelStyle()),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: _inputDecoration(),
              items: const ['Laki-laki', 'Perempuan']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _gender = value);
              },
            ),
            const SizedBox(height: 24),
            _primaryButton(label: 'Simpan Perubahan', onPressed: _save),
          ],
        ),
      ),
    );
  }

  Widget _formField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _fieldLabelStyle()),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            decoration: _inputDecoration(),
          ),
        ],
      ),
    );
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 20),
      firstDate: DateTime(1940),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryDark),
        ),
        child: child!,
      ),
    );
    if (selected != null) {
      setState(() {
        _birthDate = selected;
        _birthDateController.text = _formatDate(selected);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    ProfileStore.instance.updateProfile(
      name: name,
      email: email,
      phone: phone,
      birthDate: _birthDate,
      gender: _gender,
    );

    try {
      final token = await ApiClient.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await ProfileService.instance.updateProfile(
          name: name,
          email: email,
          phone: phone,
        );
      }
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppTheme.errorRed),
      );
    }
  }
}

class DataDiriScreen extends StatelessWidget {
  const DataDiriScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = ProfileStore.instance;
    return AnimatedBuilder(
      animation: profile,
      builder: (context, _) => _SubpageScaffold(
        title: 'Data Diri',
        child: ListView(
          padding: EdgeInsets.all(Responsive.of(context).pagePaddingH),
          children: [
            _InfoRow(label: 'Nama Lengkap', value: profile.name),
            _InfoRow(label: 'Email', value: profile.email),
            _InfoRow(label: 'Nomor Telepon', value: profile.phone),
            _InfoRow(
              label: 'Tanggal Lahir',
              value: _formatDate(profile.birthDate),
            ),
            _InfoRow(label: 'Jenis Kelamin', value: profile.gender),
            const SizedBox(height: 16),
            _primaryButton(
              label: 'Edit Data Diri',
              onPressed: () => context.push('/profil/edit'),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: AppTheme.primaryDark,
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Kata sandi dan keamanan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMain,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textSubtle,
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

class DaftarAlamatScreen extends StatelessWidget {
  const DaftarAlamatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ProfileStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => _SubpageScaffold(
        title: 'Daftar Alamat',
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openAddressEditor(context),
          backgroundColor: AppTheme.primaryBlack,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            'Tambah Alamat',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
        ),
        child: store.addresses.isEmpty
            ? const _EmptySubpage(message: 'Belum ada alamat tersimpan')
            : ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  Responsive.of(context).pagePaddingH,
                  12,
                  Responsive.of(context).pagePaddingH,
                  88,
                ),
                itemCount: store.addresses.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final address = store.addresses[index];
                  final isPrimary = address.isPrimary;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isPrimary ? const Color(0xFFFAF3EA) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isPrimary
                            ? AppTheme.primaryDark
                            : const Color(0xFFECE4D8),
                        width: isPrimary ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isPrimary
                                    ? AppTheme.primaryDark
                                    : const Color(0xFFF5EDE1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    address.label.toLowerCase() == 'kantor'
                                        ? Icons.business_outlined
                                        : Icons.home_outlined,
                                    size: 13,
                                    color: isPrimary
                                        ? Colors.white
                                        : AppTheme.primaryDark,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    address.label,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isPrimary
                                          ? Colors.white
                                          : AppTheme.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isPrimary) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryDark,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'UTAMA',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          address.recipient,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMain,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          address.phone,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          address.displayAddress,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            height: 1.45,
                            color: const Color(0xFF4A4036),
                          ),
                        ),
                        if (address.latitude != null &&
                            address.longitude != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.pin_drop_outlined,
                                size: 14,
                                color: Color(0xFF8C6226),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Titik Maps: ${address.latitude!.toStringAsFixed(5)}, ${address.longitude!.toStringAsFixed(5)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF8C6226),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  final uri = Uri.parse(
                                    'https://www.google.com/maps?q=${address.latitude},${address.longitude}',
                                  );
                                  launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                                child: Text(
                                  'Buka di Maps',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryDark,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Divider(
                          color: Color(0xFFECE4D8),
                          height: 1,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: const Color(0xFFF5EDE1),
                                side: const BorderSide(
                                  color: Color(0xFFDECDB8),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => _openAddressEditor(
                                context,
                                address: address,
                              ),
                              child: Text(
                                'Ubah',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textMain,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                foregroundColor: Colors.red.shade700,
                              ),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Hapus Alamat?'),
                                    content: Text(
                                      'Apakah Anda yakin ingin menghapus alamat "${address.label}"?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Batal'),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor:
                                              Colors.red.shade700,
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Hapus'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  store.removeAddress(address.id);
                                }
                              },
                              child: Text(
                                'Hapus',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (!isPrimary) ...[
                              const Spacer(),
                              FilledButton.tonal(
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: const Color(0xFFF1EBE4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () =>
                                    store.setPrimaryAddress(address.id),
                                child: Text(
                                  'Jadikan Utama',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textMain,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  static Future<void> _openAddressEditor(
    BuildContext context, {
    ProfileAddress? address,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgWarm,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddressEditor(address: address),
    );
  }
}

class _RegionSelectionResult {
  final String province;
  final int provinceId;
  final String city;
  final int cityId;
  final String district;
  final int? districtId;
  final String postalCode;

  const _RegionSelectionResult({
    required this.province,
    required this.provinceId,
    required this.city,
    required this.cityId,
    required this.district,
    this.districtId,
    required this.postalCode,
  });
}

class _RegionPickerSheet extends StatefulWidget {
  final int? initialProvinceId;
  final int? initialCityId;
  final String? initialDistrict;
  final String? initialPostalCode;

  const _RegionPickerSheet({
    this.initialProvinceId,
    this.initialCityId,
    this.initialDistrict,
    this.initialPostalCode,
  });

  @override
  State<_RegionPickerSheet> createState() => _RegionPickerSheetState();
}

class _RegionPickerSheetState extends State<_RegionPickerSheet> {
  int _activeTab = 0; // 0: Provinsi, 1: Kota, 2: Kecamatan, 3: Kode Pos
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _manualDistrictController =
      TextEditingController();
  final TextEditingController _manualPostalController = TextEditingController();

  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _postalCodes = [];

  bool _loading = false;

  String? _selectedProvince;
  int? _selectedProvinceId;
  String? _selectedCity;
  int? _selectedCityId;
  String? _selectedDistrict;
  int? _selectedDistrictId;
  String? _selectedPostalCode;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _manualDistrictController.dispose();
    _manualPostalController.dispose();
    super.dispose();
  }

  Future<void> _loadProvinces() async {
    setState(() => _loading = true);
    final list = await ShippingService.instance.fetchProvinces();
    if (!mounted) return;
    setState(() {
      _provinces = list;
      _loading = false;
    });
  }

  Future<void> _loadCities(int provinceId) async {
    setState(() => _loading = true);
    final list =
        await ShippingService.instance.fetchCities(provinceId: provinceId);
    if (!mounted) return;
    setState(() {
      _cities = list;
      _loading = false;
    });
  }

  Future<void> _loadDistricts(int cityId) async {
    setState(() => _loading = true);
    final list = await ShippingService.instance.fetchDistricts(cityId);
    if (!mounted) return;
    setState(() {
      _districts = list;
      _loading = false;
    });
  }

  Future<void> _loadPostalCodes(
    String districtName,
    String cityName,
    int? cityId,
  ) async {
    setState(() => _loading = true);
    final res = await ShippingService.instance.fetchPostalCodes(
      districtName: districtName,
      cityName: cityName,
      cityId: cityId,
    );
    if (!mounted) return;
    final items = res['items'];
    final defaultCode = res['default_postal_code']?.toString();
    setState(() {
      if (items is List) {
        _postalCodes = items
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      } else {
        _postalCodes = [];
      }
      if (defaultCode != null &&
          defaultCode.isNotEmpty &&
          _selectedPostalCode == null) {
        _selectedPostalCode = defaultCode;
        _manualPostalController.text = defaultCode;
      }
      _loading = false;
    });
  }

  void _finish() {
    final postal = _selectedPostalCode?.trim().isNotEmpty == true
        ? _selectedPostalCode!.trim()
        : _manualPostalController.text.trim();
    if (_selectedProvince != null &&
        _selectedProvinceId != null &&
        _selectedCity != null &&
        _selectedCityId != null &&
        _selectedDistrict != null &&
        postal.isNotEmpty) {
      Navigator.pop(
        context,
        _RegionSelectionResult(
          province: _selectedProvince!,
          provinceId: _selectedProvinceId!,
          city: _selectedCity!,
          cityId: _selectedCityId!,
          district: _selectedDistrict!,
          districtId: _selectedDistrictId,
          postalCode: postal,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 10, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih Wilayah Pengiriman',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMain,
                        ),
                      ),
                      Text(
                        'Provinsi, Kota, Kecamatan, Kode Pos',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFECE4D8)),

          // Step Tabs
          Container(
            color: const Color(0xFFFAF7F2),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                _buildTabItem(0, 'Provinsi', _selectedProvince),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Colors.black26,
                ),
                _buildTabItem(
                  1,
                  'Kota',
                  _selectedCity,
                  enabled: _selectedProvinceId != null,
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Colors.black26,
                ),
                _buildTabItem(
                  2,
                  'Kecamatan',
                  _selectedDistrict,
                  enabled: _selectedCityId != null,
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Colors.black26,
                ),
                _buildTabItem(
                  3,
                  'Kode Pos',
                  _selectedPostalCode,
                  enabled: _selectedDistrict != null,
                ),
              ],
            ),
          ),

          // Search Field (tabs 0, 1, 2)
          if (_activeTab < 3)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
                decoration: InputDecoration(
                  hintText: _activeTab == 0
                      ? 'Cari nama provinsi...'
                      : _activeTab == 1
                          ? 'Cari nama kota / kabupaten...'
                          : 'Cari nama kecamatan...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF9F7F4),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFECE4D8)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFECE4D8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.primaryDark),
                  ),
                ),
              ),
            ),

          // Content List
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryDark,
                      strokeWidth: 2,
                    ),
                  )
                : _buildTabContent(query),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(
    int tabIndex,
    String title,
    String? value, {
    bool enabled = true,
  }) {
    final isActive = _activeTab == tabIndex;
    final hasValue = value != null && value.isNotEmpty;
    return Expanded(
      child: GestureDetector(
        onTap: enabled
            ? () {
                _searchController.clear();
                setState(() => _activeTab = tabIndex);
              }
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppTheme.primaryDark : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: isActive
                      ? AppTheme.primaryDark
                      : enabled
                          ? (hasValue ? AppTheme.textMain : AppTheme.textMuted)
                          : Colors.black26,
                ),
              ),
              if (hasValue)
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    color: const Color(0xFF8C6226),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(String query) {
    switch (_activeTab) {
      case 0: // Provinsi
        final list = _provinces.where((p) {
          final name = (p['province'] ?? '').toString().toLowerCase();
          return query.isEmpty || name.contains(query);
        }).toList();
        if (list.isEmpty) {
          return const Center(
            child: Text('Tidak ada provinsi yang cocok.'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          itemCount: list.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, color: Color(0xFFF1EBE4)),
          itemBuilder: (context, i) {
            final item = list[i];
            final name = (item['province'] ?? '').toString();
            final id = int.tryParse(item['province_id']?.toString() ?? '') ?? 0;
            final isSelected = _selectedProvinceId == id;
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text(
                name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppTheme.primaryDark : AppTheme.textMain,
                ),
              ),
              trailing: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 18,
                      color: Color(0xFF8C6226),
                    )
                  : null,
              onTap: () {
                setState(() {
                  _selectedProvince = name;
                  _selectedProvinceId = id;
                  _selectedCity = null;
                  _selectedCityId = null;
                  _selectedDistrict = null;
                  _selectedDistrictId = null;
                  _selectedPostalCode = null;
                  _activeTab = 1;
                });
                _searchController.clear();
                _loadCities(id);
              },
            );
          },
        );

      case 1: // Kota
        final list = _cities.where((c) {
          final type = (c['type'] ?? '').toString();
          final name = (c['city_name'] ?? '').toString();
          final fullName = '$type $name'.toLowerCase();
          return query.isEmpty || fullName.contains(query);
        }).toList();
        if (list.isEmpty) {
          return const Center(
            child: Text('Tidak ada kota yang cocok.'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          itemCount: list.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, color: Color(0xFFF1EBE4)),
          itemBuilder: (context, i) {
            final item = list[i];
            final type = (item['type'] ?? '').toString();
            final name = (item['city_name'] ?? '').toString();
            final fullName = type.isNotEmpty ? '$type $name' : name;
            final id = int.tryParse(item['city_id']?.toString() ?? '') ?? 0;
            final postal = item['postal_code']?.toString();
            final isSelected = _selectedCityId == id;
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text(
                fullName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppTheme.primaryDark : AppTheme.textMain,
                ),
              ),
              subtitle: postal != null && postal.isNotEmpty
                  ? Text(
                      'Kode Pos: $postal',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    )
                  : null,
              trailing: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 18,
                      color: Color(0xFF8C6226),
                    )
                  : null,
              onTap: () {
                setState(() {
                  _selectedCity = fullName;
                  _selectedCityId = id;
                  _selectedDistrict = null;
                  _selectedDistrictId = null;
                  if (postal != null && postal.isNotEmpty) {
                    _selectedPostalCode = postal;
                    _manualPostalController.text = postal;
                  }
                  _activeTab = 2;
                });
                _searchController.clear();
                _loadDistricts(id);
              },
            );
          },
        );

      case 2: // Kecamatan
        final list = _districts.where((d) {
          final name = (d['district_name'] ?? '').toString().toLowerCase();
          return query.isEmpty || name.contains(query);
        }).toList();

        return Column(
          children: [
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Kecamatan tidak ditemukan di daftar.',
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _manualDistrictController,
                              style: GoogleFonts.plusJakartaSans(fontSize: 13),
                              decoration: _inputDecoration(
                                hint: 'Ketik nama kecamatan manual...',
                              ),
                            ),
                            const SizedBox(height: 8),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primaryDark,
                              ),
                              onPressed: () {
                                final text =
                                    _manualDistrictController.text.trim();
                                if (text.isNotEmpty) {
                                  setState(() {
                                    _selectedDistrict = text;
                                    _selectedDistrictId = null;
                                    _activeTab = 3;
                                  });
                                  _loadPostalCodes(
                                    text,
                                    _selectedCity ?? '',
                                    _selectedCityId,
                                  );
                                }
                              },
                              child: const Text('Gunakan Kecamatan Ini'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      itemCount: list.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: Color(0xFFF1EBE4)),
                      itemBuilder: (context, i) {
                        final item = list[i];
                        final name = (item['district_name'] ?? '').toString();
                        final id = int.tryParse(
                          item['district_id']?.toString() ?? '',
                        );
                        final isSelected = _selectedDistrict == name;
                        return ListTile(
                          dense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          title: Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? AppTheme.primaryDark
                                  : AppTheme.textMain,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Color(0xFF8C6226),
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedDistrict = name;
                              _selectedDistrictId = id;
                              _activeTab = 3;
                            });
                            _searchController.clear();
                            _loadPostalCodes(
                              name,
                              _selectedCity ?? '',
                              _selectedCityId,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );

      case 3: // Kode Pos
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Kode Pos untuk area ${_selectedDistrict ?? ""}:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 10),
              if (_postalCodes.isNotEmpty)
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: _postalCodes.length,
                    itemBuilder: (context, i) {
                      final item = _postalCodes[i];
                      final code =
                          (item['postal_code'] ?? item['zip_code'] ?? '')
                              .toString();
                      final sub = (item['subdistrict'] ?? '').toString();
                      final isSelected = _selectedPostalCode == code;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedPostalCode = code;
                            _manualPostalController.text = code;
                          });
                          _finish();
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFAF3EA)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryDark
                                  : const Color(0xFFECE4D8),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                code,
                                style: GoogleFonts.spaceMono(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? const Color(0xFF8C6226)
                                      : AppTheme.textMain,
                                ),
                              ),
                              if (sub.isNotEmpty)
                                Text(
                                  sub,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Text(
                      'Masukkan 5 digit kode pos di bawah ini:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
              const Divider(color: Color(0xFFECE4D8)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manualPostalController,
                      keyboardType: TextInputType.number,
                      maxLength: 5,
                      style: GoogleFonts.spaceMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'Kode Pos (5 digit)',
                        filled: true,
                        fillColor: const Color(0xFFF9F7F4),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFECE4D8)),
                        ),
                      ),
                      onChanged: (val) {
                        _selectedPostalCode = val;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryDark,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      if (_manualPostalController.text.trim().isNotEmpty) {
                        _selectedPostalCode =
                            _manualPostalController.text.trim();
                        _finish();
                      }
                    },
                    child: const Text('Selesai'),
                  ),
                ],
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

class _AddressEditor extends StatefulWidget {
  final ProfileAddress? address;
  const _AddressEditor({this.address});

  @override
  State<_AddressEditor> createState() => _AddressEditorState();
}

class _AddressEditorState extends State<_AddressEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _recipient;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _customLabelController;

  String _label = 'Rumah';
  String? _province;
  int? _provinceId;
  String? _city;
  int? _cityId;
  String? _district;
  int? _districtId;
  String? _postalCode;
  double? _latitude;
  double? _longitude;
  late bool _primary;
  bool _isSaving = false;
  String? _regionError;

  @override
  void initState() {
    super.initState();
    final initial = widget.address;
    _recipient = TextEditingController(
      text: initial?.recipient ?? ProfileStore.instance.name,
    );
    _phone = TextEditingController(
      text: initial?.phone ?? ProfileStore.instance.phone,
    );
    _address = TextEditingController(text: initial?.address ?? '');

    final currentLabel = initial?.label ?? 'Rumah';
    if (currentLabel == 'Rumah' || currentLabel == 'Kantor') {
      _label = currentLabel;
      _customLabelController = TextEditingController();
    } else {
      _label = 'Lainnya';
      _customLabelController = TextEditingController(text: currentLabel);
    }

    _province = initial?.province;
    _provinceId = initial?.provinceId;
    _city = initial?.city;
    _cityId = initial?.cityId;
    _district = initial?.district;
    _districtId = initial?.districtId;
    _postalCode = initial?.postalCode;
    _latitude = initial?.latitude;
    _longitude = initial?.longitude;
    _primary = initial?.isPrimary ?? ProfileStore.instance.addresses.isEmpty;
  }

  @override
  void dispose() {
    _recipient.dispose();
    _phone.dispose();
    _address.dispose();
    _customLabelController.dispose();
    super.dispose();
  }

  String get _regionDisplay {
    final parts = <String>[];
    if (_province != null && _province!.isNotEmpty) parts.add(_province!);
    if (_city != null && _city!.isNotEmpty) parts.add(_city!);
    if (_district != null && _district!.isNotEmpty) {
      parts.add('Kec. $_district');
    }
    if (_postalCode != null && _postalCode!.isNotEmpty) {
      parts.add(_postalCode!);
    }
    return parts.join(', ');
  }

  Future<void> _pickRegion() async {
    final res = await showModalBottomSheet<_RegionSelectionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RegionPickerSheet(
        initialProvinceId: _provinceId,
        initialCityId: _cityId,
        initialDistrict: _district,
        initialPostalCode: _postalCode,
      ),
    );

    if (res != null) {
      setState(() {
        _province = res.province;
        _provinceId = res.provinceId;
        _city = res.city;
        _cityId = res.cityId;
        _district = res.district;
        _districtId = res.districtId;
        _postalCode = res.postalCode;
        _regionError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isAdd = widget.address == null;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.fromLTRB(18, 18, 18, bottomInset + 18),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            // Header bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAdd ? 'Tambah Alamat Baru' : 'Ubah Alamat',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Lengkapi data alamat untuk pengiriman pesanan.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Color(0xFFECE4D8), height: 20),

            // Baris 1: Nama Lengkap & Nomor Telepon
            Text(
              'Nama Lengkap *',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B5E51),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _recipient,
              validator: (v) => _required(v, 'Nama lengkap penerima'),
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
              decoration: _inputDecoration(hint: 'Nama Lengkap Penerima'),
            ),
            const SizedBox(height: 12),

            Text(
              'Nomor Telepon *',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B5E51),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              validator: (v) => _required(v, 'Nomor telepon'),
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
              decoration: _inputDecoration(
                hint: 'Nomor Telepon (08xxxxxxxxxx)',
              ),
            ),
            const SizedBox(height: 14),

            // Baris 2: Pemilih Wilayah Terpadu (Provinsi, Kota, Kecamatan, Kode Pos)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Provinsi, Kota, Kecamatan, Kode Pos *',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6B5E51),
                  ),
                ),
                if (_province != null)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _province = null;
                        _provinceId = null;
                        _city = null;
                        _cityId = null;
                        _district = null;
                        _districtId = null;
                        _postalCode = null;
                      });
                    },
                    child: Text(
                      'Reset',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickRegion,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _regionError != null
                        ? Colors.red.shade700
                        : const Color(0xFFDECDB8),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _regionDisplay.isNotEmpty
                            ? _regionDisplay
                            : 'Pilih Provinsi, Kota, Kecamatan, Kode Pos',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: _regionDisplay.isNotEmpty
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: _regionDisplay.isNotEmpty
                              ? AppTheme.textMain
                              : AppTheme.textMuted,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (_regionError != null) ...[
              const SizedBox(height: 4),
              Text(
                _regionError!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: Colors.red.shade700,
                ),
              ),
            ],
            const SizedBox(height: 14),

            // Baris 3: Nama Jalan, Gedung, No. Rumah
            Text(
              'Nama Jalan, Gedung, No. Rumah *',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B5E51),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _address,
              maxLines: 3,
              validator: (v) => _required(v, 'Nama jalan dan nomor rumah'),
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
              decoration: _inputDecoration(
                hint:
                    'Nama Jalan, Nomor Gedung/Rumah, RT/RW, Patokan khusus...',
              ),
            ),
            const SizedBox(height: 14),

            // Baris 4: Titik Lokasi (Opsional)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Titik Lokasi (Opsional)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6B5E51),
                  ),
                ),
                if (_latitude != null && _longitude != null)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _latitude = null;
                        _longitude = null;
                      });
                    },
                    child: Text(
                      'Hapus Titik',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFECE4D8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.pin_drop_outlined,
                        size: 16,
                        color: Color(0xFF8C6226),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _latitude != null && _longitude != null
                              ? '📍 ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}'
                              : 'Titik koordinat opsional (membantu kurir menemukan alamat).',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: _latitude != null
                                ? const Color(0xFF8C6226)
                                : AppTheme.textMuted,
                            fontWeight: _latitude != null
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: const BorderSide(color: Color(0xFFDECDB8)),
                        ),
                        onPressed: _showCoordinateDialog,
                        child: Text(
                          _latitude != null ? 'Ubah' : 'Input Lat/Lng',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Baris 5: Tandai Sebagai
            Text(
              'Tandai Sebagai',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B5E51),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildLabelChip('Rumah', Icons.home_outlined),
                const SizedBox(width: 8),
                _buildLabelChip('Kantor', Icons.business_outlined),
                const SizedBox(width: 8),
                _buildLabelChip('Lainnya', Icons.bookmark_border_rounded),
              ],
            ),
            if (_label == 'Lainnya') ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _customLabelController,
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
                decoration: _inputDecoration(
                  hint: 'Masukkan label (mis. Toko, Kos, Gudang)',
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Baris 6: Atur Sebagai Alamat Utama
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _primary,
              activeColor: AppTheme.primaryDark,
              activeTrackColor: AppTheme.primaryDark.withValues(alpha: 0.5),
              title: Text(
                'Atur sebagai Alamat Utama',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Alamat ini akan otomatis dipilih saat checkout',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
              onChanged: (value) => setState(() => _primary = value),
            ),
            const SizedBox(height: 16),

            // Footer Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFDECDB8)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Nanti Saja',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isAdd ? 'Simpan Alamat' : 'Simpan Perubahan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelChip(String labelName, IconData icon) {
    final isSelected = _label == labelName;
    return InkWell(
      onTap: () => setState(() => _label = labelName),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryDark : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryDark : const Color(0xFFDECDB8),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : AppTheme.textMain,
            ),
            const SizedBox(width: 6),
            Text(
              labelName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCoordinateDialog() {
    final latController = TextEditingController(
      text: _latitude != null ? _latitude.toString() : '',
    );
    final lngController = TextEditingController(
      text: _longitude != null ? _longitude.toString() : '',
    );
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Input Titik Koordinat (Opsional)',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: latController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
              style: GoogleFonts.spaceMono(fontSize: 13),
              decoration: _inputDecoration(hint: 'Latitude (mis. -7.7956)'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: lngController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
              style: GoogleFonts.spaceMono(fontSize: 13),
              decoration: _inputDecoration(hint: 'Longitude (mis. 110.3695)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryDark,
            ),
            onPressed: () {
              final lat = double.tryParse(latController.text.trim());
              final lng = double.tryParse(lngController.text.trim());
              setState(() {
                _latitude = lat;
                _longitude = lng;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Terapkan'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_province == null || _province!.isEmpty) {
      setState(() {
        _regionError = 'Provinsi, kota, kecamatan, dan kode pos wajib dipilih';
      });
      return;
    }

    final finalLabel = _label == 'Lainnya'
        ? (_customLabelController.text.trim().isNotEmpty
            ? _customLabelController.text.trim()
            : 'Lainnya')
        : _label;

    setState(() => _isSaving = true);

    try {
      final old = widget.address;
      await ProfileStore.instance.saveAddress(
        ProfileAddress(
          id: old?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
          label: finalLabel,
          recipient: _recipient.text.trim(),
          phone: _phone.text.trim(),
          address: _address.text.trim(),
          province: _province,
          provinceId: _provinceId,
          city: _city,
          cityId: _cityId,
          district: _district,
          districtId: _districtId,
          postalCode: _postalCode,
          latitude: _latitude,
          longitude: _longitude,
          isPrimary: _primary,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            old == null
                ? 'Alamat baru berhasil ditambahkan.'
                : 'Alamat berhasil diperbarui.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppTheme.primaryDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menyimpan alamat: $e',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class UlasanSayaScreen extends StatelessWidget {
  const UlasanSayaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reviews = ProfileStore.instance.reviews;
    return _SubpageScaffold(
      title: 'Ulasan Saya',
      child: reviews.isEmpty
          ? const _EmptySubpage(message: 'Belum ada ulasan')
          : ListView.separated(
              padding: EdgeInsets.all(Responsive.of(context).pagePaddingH),
              itemCount: reviews.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final review = reviews[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              review.imageUrl,
                              width: 48,
                              height: 52,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 48,
                                height: 52,
                                color: AppTheme.terracottaLight,
                                child: const Icon(
                                  Icons.checkroom_outlined,
                                  color: AppTheme.terracotta,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  review.product,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textMain,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  review.date,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: AppTheme.textSubtle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            index < review.rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 16,
                            color: const Color(0xFFE49A36),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        review.comment,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          height: 1.45,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      if (review.photos.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 54,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: review.photos.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 6),
                            itemBuilder: (context, photoIndex) =>
                                ReviewPhotoThumbnail(
                                  imageUrl: review.photos[photoIndex],
                                  index: photoIndex,
                                  allImageUrls: review.photos,
                                  heroTagPrefix: 'profile_review_${review.orderId}_$photoIndex',
                                  size: 54,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _SubpageScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? floatingActionButton;
  const _SubpageScaffold({
    required this.title,
    required this.child,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        backgroundColor: AppTheme.bgWarm,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMain,
          ),
        ),
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
        ),
      ),
      floatingActionButton: floatingActionButton,
      body: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: AppTheme.textSubtle,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value.trim().isEmpty ? '-' : value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMain,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySubpage extends StatelessWidget {
  final String message;
  const _EmptySubpage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: AppTheme.textSubtle,
        ),
      ),
    );
  }
}

Widget _primaryButton({
  required String label,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    height: 46,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

InputDecoration _inputDecoration({String? hint, Widget? suffix}) {
  return InputDecoration(
    hintText: hint,
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppTheme.borderLight),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppTheme.borderLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppTheme.terracotta, width: 1.3),
    ),
  );
}

TextStyle _fieldLabelStyle() => GoogleFonts.plusJakartaSans(
  fontSize: 12,
  fontWeight: FontWeight.w600,
  color: AppTheme.textMain,
);

String? _required(String? value, String label) {
  if (value == null || value.trim().isEmpty) return '$label wajib diisi';
  return null;
}

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

Widget _smallTag(String label) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
  decoration: BoxDecoration(
    color: AppTheme.terracottaLight,
    borderRadius: BorderRadius.circular(4),
  ),
  child: Text(
    label,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 9,
      fontWeight: FontWeight.w600,
      color: AppTheme.primaryDark,
    ),
  ),
);
