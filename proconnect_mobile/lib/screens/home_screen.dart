import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/api_service.dart';
import 'ilan_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<dynamic> _ilanlar = [];
  List<int> _rezvIlanIds = [];
  bool _loading = true;
  final _aramaCtrl = TextEditingController();

  void refresh() => _yukle();

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() { _loading = true; });
    try {
      final ilanlar = await ApiService.getIlanlar();
      List<int> rezvIds = [];
      if (ApiService.isLoggedIn) {
        final rezvlar = await ApiService.getRezervasyon();
        rezvIds = rezvlar
            .where((r) => r['durum'] == 'BEKLEMEDE' || r['durum'] == 'ONAYLANDI')
            .map<int>((r) => r['ilan']?['id'] as int? ?? 0)
            .where((id) => id > 0)
            .toList();
      }
      if (mounted) {
        setState(() { _ilanlar = ilanlar; _rezvIlanIds = rezvIds; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _ara(String query) async {
    if (query.trim().isEmpty) {
      _yukle();
      return;
    }
    setState(() { _loading = true; });
    try {
      final sonuclar = await ApiService.aramaYap(query);
      setState(() { _ilanlar = sonuclar; _loading = false; });
    } catch (_) {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _yukle,
        color: kPrimary,
        child: CustomScrollView(
          slivers: [
            // Arama barı
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: kPrimary,
              expandedHeight: 140,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimary, kAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ProConnect', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                            child: TextField(
                              controller: _aramaCtrl,
                              onSubmitted: _ara,
                              decoration: InputDecoration(
                                hintText: 'Hizmet veya usta ara...',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                suffixIcon: IconButton(icon: const Icon(Icons.search, color: kPrimary), onPressed: () => _ara(_aramaCtrl.text)),
                                fillColor: Colors.transparent,
                                filled: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // İlanlar grid
            if (_loading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: kPrimary)))
            else if (_ilanlar.isEmpty)
              const SliverFillRemaining(child: Center(child: Text('Henüz aktif ilan bulunmuyor.', style: TextStyle(color: kMuted))))
            else
              SliverPadding(
                padding: const EdgeInsets.all(14),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final ilan = _ilanlar[index];
                      final ilanId = ilan['id'] as int;
                      final rezerveEdildi = _rezvIlanIds.contains(ilanId);
                      return _IlanCard(
                        ilan: ilan,
                        rezerveEdildi: rezerveEdildi,
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => IlanDetailScreen(ilan: ilan)));
                          _yukle();
                        },
                      );
                    },
                    childCount: _ilanlar.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _IlanCard extends StatelessWidget {
  final Map<String, dynamic> ilan;
  final bool rezerveEdildi;
  final VoidCallback onTap;

  const _IlanCard({required this.ilan, required this.rezerveEdildi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gorsel = ilan['gorselYolu'];
    final usta = ilan['olusturanKullanici'];
    final ustaAd = usta != null ? '${usta['ad']} ${usta['soyad']}' : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Görsel
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: gorsel != null
                      ? null
                      : const LinearGradient(colors: [Color(0xFFD9E8FF), Color(0xFFFEF3D4)]),
                ),
                child: gorsel != null
                    ? Image.network('$apiBaseUrl/uploads/$gorsel', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox())
                    : const Center(child: Icon(Icons.build_circle_outlined, size: 40, color: kPrimary)),
              ),
            ),
            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ilan['baslik'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E7B46))),
                    const SizedBox(height: 4),
                    if (ustaAd != null)
                      Row(children: [const Icon(Icons.person, size: 13, color: kMuted), const SizedBox(width: 4), Expanded(child: Text(ustaAd, style: const TextStyle(fontSize: 12, color: kMuted), overflow: TextOverflow.ellipsis))]),
                    if (ilan['butce'] != null) ...[
                      const SizedBox(height: 3),
                      Row(children: [const Icon(Icons.monetization_on, size: 13, color: kPrimary), const SizedBox(width: 4), Text('${ilan['butce']} ₺', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kPrimaryDark))]),
                    ],
                    const Spacer(),
                    // Durum
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: rezerveEdildi ? kWarning : kPrimary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        rezerveEdildi ? '✓ Yapıldı' : 'Rezervasyon',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
