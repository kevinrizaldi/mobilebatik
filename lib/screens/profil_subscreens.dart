import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/profile_store.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

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

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    ProfileStore.instance.updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      birthDate: _birthDate,
      gender: _gender,
    );
    context.pop();
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
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final address = store.addresses[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
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
                            const Icon(
                              Icons.location_on_outlined,
                              size: 17,
                              color: AppTheme.primaryDark,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              address.label,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textMain,
                              ),
                            ),
                            if (address.isPrimary) ...[
                              const SizedBox(width: 7),
                              _smallTag('Utama'),
                            ],
                            const Spacer(),
                            PopupMenuButton<String>(
                              tooltip: 'Aksi alamat',
                              onSelected: (action) {
                                if (action == 'edit') {
                                  _openAddressEditor(context, address: address);
                                } else {
                                  store.removeAddress(address.id);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Ubah'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Hapus'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          address.recipient,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMain,
                          ),
                        ),
                        Text(
                          address.phone,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          address.address,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            height: 1.4,
                            color: AppTheme.textSubtle,
                          ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (_) => _AddressEditor(address: address),
    );
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
  late final TextEditingController _label;
  late final TextEditingController _recipient;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late bool _primary;

  @override
  void initState() {
    super.initState();
    final initial = widget.address;
    _label = TextEditingController(text: initial?.label ?? 'Rumah');
    _recipient = TextEditingController(
      text: initial?.recipient ?? ProfileStore.instance.name,
    );
    _phone = TextEditingController(
      text: initial?.phone ?? ProfileStore.instance.phone,
    );
    _address = TextEditingController(text: initial?.address ?? '');
    _primary = initial?.isPrimary ?? ProfileStore.instance.addresses.isEmpty;
  }

  @override
  void dispose() {
    _label.dispose();
    _recipient.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, bottomInset + 18),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              widget.address == null ? 'Tambah Alamat' : 'Ubah Alamat',
              style: GoogleFonts.outfit(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMain,
              ),
            ),
            const SizedBox(height: 14),
            _sheetField(_label, 'Label alamat'),
            _sheetField(_recipient, 'Nama penerima'),
            _sheetField(
              _phone,
              'Nomor telepon',
              keyboardType: TextInputType.phone,
            ),
            _sheetField(_address, 'Alamat lengkap', maxLines: 3),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _primary,
              activeThumbColor: AppTheme.primaryDark,
              title: Text(
                'Jadikan alamat utama',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              onChanged: (value) => setState(() => _primary = value),
            ),
            const SizedBox(height: 8),
            _primaryButton(label: 'Simpan Alamat', onPressed: _save),
          ],
        ),
      ),
    );
  }

  Widget _sheetField(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (value) => _required(value, hint),
        decoration: _inputDecoration(hint: hint),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final old = widget.address;
    ProfileStore.instance.saveAddress(
      ProfileAddress(
        id: old?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        label: _label.text.trim(),
        recipient: _recipient.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        isPrimary: _primary,
      ),
    );
    Navigator.pop(context);
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
                            itemBuilder: (context, photoIndex) => ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.memory(
                                review.photos[photoIndex],
                                width: 54,
                                height: 54,
                                fit: BoxFit.cover,
                              ),
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
            value,
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
