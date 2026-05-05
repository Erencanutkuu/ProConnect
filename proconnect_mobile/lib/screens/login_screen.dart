import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _epostaCtrl = TextEditingController();
  final _sifreCtrl = TextEditingController();
  bool _loading = false;
  String? _hata;

  Future<void> _girisYap() async {
    setState(() { _loading = true; _hata = null; });
    try {
      await ApiService.login(_epostaCtrl.text.trim(), _sifreCtrl.text);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      setState(() { _hata = 'Giriş başarısız: $e'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.handshake_rounded, size: 56, color: kPrimary),
                ),
                const SizedBox(height: 20),
                const Text('ProConnect', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: kInk)),
                const SizedBox(height: 6),
                const Text('Hesabınıza giriş yapın', style: TextStyle(color: kMuted, fontSize: 15)),
                const SizedBox(height: 36),

                // E-posta
                TextField(
                  controller: _epostaCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Şifre
                TextField(
                  controller: _sifreCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 8),

                if (_hata != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_hata!, style: const TextStyle(color: kDanger, fontSize: 13)),
                  ),

                const SizedBox(height: 24),

                // Giriş Butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _girisYap,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Giriş Yap'),
                  ),
                ),
                const SizedBox(height: 16),

                // Kayıt Ol linki
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text.rich(
                    TextSpan(
                      text: 'Hesabınız yok mu? ',
                      style: TextStyle(color: kMuted),
                      children: [TextSpan(text: 'Kayıt Ol', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700))],
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
