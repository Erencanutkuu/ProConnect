import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _adCtrl = TextEditingController();
  final _soyadCtrl = TextEditingController();
  final _epostaCtrl = TextEditingController();
  final _sifreCtrl = TextEditingController();
  final _telefonCtrl = TextEditingController();
  String _rol = 'MUSTERI';
  bool _loading = false;
  String? _hata;
  String? _basari;

  Future<void> _kaydol() async {
    if (_adCtrl.text.trim().isEmpty || _soyadCtrl.text.trim().isEmpty ||
        _epostaCtrl.text.trim().isEmpty || _sifreCtrl.text.isEmpty) {
      setState(() { _hata = 'Tüm alanları doldurun.'; });
      return;
    }
    setState(() { _loading = true; _hata = null; _basari = null; });
    try {
      await ApiService.register({
        'ad': _adCtrl.text.trim(),
        'soyad': _soyadCtrl.text.trim(),
        'eposta': _epostaCtrl.text.trim(),
        'sifre': _sifreCtrl.text,
        'telefon': _telefonCtrl.text.trim(),
        'rol': _rol,
      });
      setState(() { _basari = 'Kayıt başarılı! Giriş yapabilirsiniz.'; });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { _hata = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Rol seçimi
            Container(
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)]),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _rolBtn('MUSTERI', 'Müşteri', Icons.person),
                  _rolBtn('USTA', 'Usta', Icons.build),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(controller: _adCtrl, decoration: const InputDecoration(labelText: 'Ad', prefixIcon: Icon(Icons.person_outline))),
            const SizedBox(height: 14),
            TextField(controller: _soyadCtrl, decoration: const InputDecoration(labelText: 'Soyad', prefixIcon: Icon(Icons.person_outline))),
            const SizedBox(height: 14),
            TextField(controller: _epostaCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-posta', prefixIcon: Icon(Icons.email_outlined))),
            const SizedBox(height: 14),
            TextField(controller: _telefonCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefon', prefixIcon: Icon(Icons.phone_outlined))),
            const SizedBox(height: 14),
            TextField(controller: _sifreCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Şifre (min 6 karakter)', prefixIcon: Icon(Icons.lock_outline))),
            const SizedBox(height: 12),

            if (_hata != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_hata!, style: const TextStyle(color: kDanger, fontSize: 13))),
            if (_basari != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_basari!, style: const TextStyle(color: kSuccess, fontSize: 13, fontWeight: FontWeight.w600))),

            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loading ? null : _kaydol,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Kayıt Ol'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rolBtn(String value, String label, IconData icon) {
    final selected = _rol == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { _rol = value; }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? kPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : kMuted),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? Colors.white : kMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
