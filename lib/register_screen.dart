import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_style.dart';
import 'user_service.dart';
import 'views/otp_view.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final UserService userService = UserService();
  final formKey = GlobalKey<FormState>();

  final namaDepanController = TextEditingController();
  final namaBelakangController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final alamatController = TextEditingController();
  final nationalityController = TextEditingController(text: 'Indonesia');

  DateTime? tanggalLahir;
  String? gender;
  bool setujuSyarat = false;
  bool loading = false;

  @override
  void dispose() {
    namaDepanController.dispose();
    namaBelakangController.dispose();
    emailController.dispose();
    phoneController.dispose();
    alamatController.dispose();
    nationalityController.dispose();
    super.dispose();
  }

  void pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> pilihTanggal() async {
    final sekarang = DateTime.now();
    final hasil = await showDatePicker(
      context: context,
      initialDate: DateTime(sekarang.year - 18, sekarang.month, sekarang.day),
      firstDate: DateTime(1900),
      lastDate: sekarang,
      helpText: 'Pilih tanggal lahir',
    );

    if (hasil != null) {
      setState(() => tanggalLahir = hasil);
    }
  }

  String tanggalFormat(DateTime? tanggal) {
    if (tanggal == null) return 'Pilih tanggal lahir';

    return '${tanggal.day.toString().padLeft(2, '0')}/'
        '${tanggal.month.toString().padLeft(2, '0')}/${tanggal.year}';
  }

  Future<void> daftar() async {
    if (!formKey.currentState!.validate()) return;

    if (tanggalLahir == null) {
      pesan('Silakan pilih tanggal lahir');
      return;
    }

    if (gender == null) {
      pesan('Silakan pilih gender');
      return;
    }

    if (!setujuSyarat) {
      pesan('Silakan setujui syarat dan ketentuan');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => loading = true);

    try {
      final dataUser = await userService.register(
        namaDepan: namaDepanController.text,
        namaBelakang: namaBelakangController.text,
        email: emailController.text,
        phone: phoneController.text,
        tanggalLahir: tanggalLahir!,
        gender: gender!,
        alamat: alamatController.text,
        kewarganegaraan: nationalityController.text,
      );

      if (!mounted) return;

      final userId = dataUser['id'] as String?;
      final email = dataUser['email'] as String?;

      if (userId == null || email == null) {
        pesan('Data akun tidak lengkap.');
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OTPView(email: email, userId: userId),
        ),
      );
    } on RegisterException catch (e) {
      pesan(e.pesan);
    } catch (e) {
      pesan('Pendaftaran gagal. Periksa koneksi dan konfigurasi Firebase.');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  InputDecoration dekor(String label, {IconData? ikon, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: ikon == null ? null : Icon(ikon, color: AppColors.biru),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.biru, width: 1.5),
      ),
    );
  }

  Widget kolom(
    TextEditingController controller,
    String label, {
    IconData? ikon,
    TextInputType tipe = TextInputType.text,
    TextCapitalization kapital = TextCapitalization.none,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        enabled: !loading,
        keyboardType: tipe,
        textCapitalization: kapital,
        maxLines: maxLines,
        inputFormatters: formatters,
        validator:
            validator ??
            (v) => v == null || v.trim().isEmpty ? '$label wajib diisi' : null,
        decoration: dekor(label, ikon: ikon, hint: hint),
      ),
    );
  }

  Widget judulBagian(String judul, String deskripsi) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            judul,
            style: TextStyle(
              color: AppColors.biruTua,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            deskripsi,
            style: const TextStyle(color: AppColors.abu, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget kartu(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE3EA)),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.biruMuda,
      appBar: AppBar(
        backgroundColor: AppColors.biruMuda,
        foregroundColor: AppColors.biruTua,
        elevation: 0,
        title: const Text(
          'Create Account',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/myBCA.jpg',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Daftar MyBCA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.biruTua,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Lengkapi informasi pribadi untuk membuat akun',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.abu, fontSize: 13),
                ),
                const SizedBox(height: 20),

                kartu(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      judulBagian(
                        'Profile Information',
                        'Informasi dasar pengguna',
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: kolom(
                              namaDepanController,
                              'Nama depan',
                              ikon: Icons.person_outline,
                              kapital: TextCapitalization.words,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: kolom(
                              namaBelakangController,
                              'Nama belakang',
                              kapital: TextCapitalization.words,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: loading ? null : pilihTanggal,
                        borderRadius: BorderRadius.circular(14),
                        child: InputDecorator(
                          decoration: dekor(
                            'Date of Birth',
                            ikon: Icons.calendar_month_outlined,
                          ),
                          child: Text(
                            tanggalFormat(tanggalLahir),
                            style: TextStyle(
                              color: tanggalLahir == null
                                  ? AppColors.abu
                                  : AppColors.biruTua,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        initialValue: gender,
                        decoration: dekor('Gender', ikon: Icons.wc_outlined),
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(
                            value: 'Female',
                            child: Text('Female'),
                          ),
                          DropdownMenuItem(
                            value: 'Other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: loading
                            ? null
                            : (v) => setState(() => gender = v),
                        validator: (v) =>
                            v == null ? 'Gender wajib dipilih' : null,
                      ),
                    ],
                  ),
                ),

                kartu(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      judulBagian(
                        'Contact Information',
                        'Pastikan email dan nomor HP masih aktif',
                      ),
                      kolom(
                        emailController,
                        'Email Address',
                        ikon: Icons.email_outlined,
                        tipe: TextInputType.emailAddress,
                        validator: (v) {
                          final value = (v ?? '').trim();

                          if (value.isEmpty) {
                            return 'Email wajib diisi';
                          }

                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(value)) {
                            return 'Format email tidak valid';
                          }

                          return null;
                        },
                      ),
                      kolom(
                        phoneController,
                        'Phone Number',
                        ikon: Icons.phone_outlined,
                        tipe: TextInputType.phone,
                        hint: '08xxxxxxxxxx',
                        formatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) {
                          final phone = UserService.normalisasiPhone(v ?? '');

                          if (!RegExp(r'^08\d{8,11}$').hasMatch(phone)) {
                            return 'Masukkan nomor HP Indonesia yang valid';
                          }

                          return null;
                        },
                      ),
                      kolom(
                        alamatController,
                        'Address',
                        ikon: Icons.location_on_outlined,
                        kapital: TextCapitalization.sentences,
                        maxLines: 2,
                      ),
                      kolom(
                        nationalityController,
                        'Nationality',
                        ikon: Icons.flag_outlined,
                        kapital: TextCapitalization.words,
                      ),
                    ],
                  ),
                ),

                kartu(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      judulBagian(
                        'Account Agreement',
                        'Persetujuan sebelum mengirim pendaftaran',
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: setujuSyarat,
                        activeColor: AppColors.biru,
                        onChanged: loading
                            ? null
                            : (v) => setState(() => setujuSyarat = v ?? false),
                        title: const Text(
                          'Saya menyetujui Terms & Conditions dan Privacy Policy.',
                          style: TextStyle(fontSize: 13),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: loading ? null : daftar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.biru,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.blueGrey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Sudah punya akun? ',
                      style: TextStyle(color: AppColors.abu),
                    ),
                    GestureDetector(
                      onTap: loading ? null : () => Navigator.pop(context),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: AppColors.biru,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
