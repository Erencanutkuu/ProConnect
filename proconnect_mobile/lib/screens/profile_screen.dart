import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _user;
  List<dynamic> _rezervasyonlar = [];
  bool _loading = true;
  late TabController _tabCtrl;

  void refresh() => _yukle();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _yukle();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _yukle() async {
    setState(() { _loading = true; });
    try {
      final me = await ApiService.getMe();
      final rezvlar = await ApiService.getRezervasyon();
      if (mounted) setState(() { _user = me; _rezervasyonlar = rezvlar; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _cikisYap() async {
    await ApiService.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _iptalEt(int rezvId) async {
    try {
      await ApiService.rezervasyonIptal(rezvId);
      _yukle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rezervasyon iptal edildi.'), backgroundColor: kSuccess));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: kDanger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: kPrimary)));
    }
    if (_user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Giriş yapmadınız.', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => Navigator.pushReplacementNamed(context, '/login'), child: const Text('Giriş Yap')),
            ],
          ),
        ),
      );
    }

    final ad = '${_user!['ad']} ${_user!['soyad']}';
    final rol = _user!['rol'] ?? '';
    final eposta = _user!['eposta'] ?? '';

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, inner) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: kPrimary,
            actions: [
              IconButton(onPressed: _cikisYap, icon: const Icon(Icons.logout, color: Colors.white)),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [kPrimary, kAccent])),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: kInk,
                        child: Text(ad.isNotEmpty ? ad[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(height: 10),
                      Text(ad, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text(rol, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(icon: Icon(Icons.info_outline), text: 'Bilgiler'),
                Tab(icon: Icon(Icons.calendar_month), text: 'Rezervasyonlar'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            // Tab 1: Bilgiler
            ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _bilgiKart(Icons.email, 'E-posta', eposta),
                _bilgiKart(Icons.phone, 'Telefon', _user!['telefon'] ?? '-'),
                _bilgiKart(Icons.badge, 'Rol', rol),
                _bilgiKart(Icons.calendar_today, 'Üyelik', _user!['olusturulmaTarihi']?.toString().substring(0, 10) ?? '-'),
              ],
            ),
            // Tab 2: Rezervasyonlar
            _rezervasyonlar.isEmpty
                ? const Center(child: Text('Henüz rezervasyonunuz yok.', style: TextStyle(color: kMuted)))
                : RefreshIndicator(
                    onRefresh: _yukle,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: _rezervasyonlar.length,
                      itemBuilder: (context, index) {
                        final r = _rezervasyonlar[index];
                        final ilan = r['ilan'];
                        final baslik = ilan?['baslik'] ?? 'İlan';
                        final durum = r['durum'] ?? '';
                        final tarih = r['rezervasyonTarihi']?.toString().substring(0, 10) ?? '';

                        Color durumRenk;
                        switch (durum) {
                          case 'BEKLEMEDE': durumRenk = kWarning; break;
                          case 'ONAYLANDI': durumRenk = kSuccess; break;
                          case 'TAMAMLANDI': durumRenk = Colors.blue; break;
                          case 'IPTAL': durumRenk = kDanger; break;
                          default: durumRenk = kMuted;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kCard,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(baslik, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text(tarih, style: const TextStyle(color: kMuted, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: durumRenk.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                    child: Text(durum, style: TextStyle(color: durumRenk, fontWeight: FontWeight.w700, fontSize: 11)),
                                  ),
                                  if (durum == 'BEKLEMEDE') ...[
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () => _iptalEt(r['id']),
                                      child: const Text('İptal Et', style: TextStyle(color: kDanger, fontSize: 12, fontWeight: FontWeight.w600)),
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
          ],
        ),
      ),
    );
  }

  Widget _bilgiKart(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: kPrimary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: kMuted, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
