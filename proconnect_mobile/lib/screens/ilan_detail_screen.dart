import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/api_service.dart';

class IlanDetailScreen extends StatefulWidget {
  final Map<String, dynamic> ilan;
  const IlanDetailScreen({super.key, required this.ilan});
  @override
  State<IlanDetailScreen> createState() => _IlanDetailScreenState();
}

class _IlanDetailScreenState extends State<IlanDetailScreen> {
  bool _rezerveEdildi = false;
  bool _rezvLoading = false;
  List<dynamic> _yorumlar = [];
  Map<String, dynamic> _puanOzeti = {};
  int _secilenPuan = 0;
  final _yorumCtrl = TextEditingController();
  String? _userRol;
  String? _userEposta;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final ilanId = widget.ilan['id'] as int;
    // Kullanıcı bilgisi
    if (ApiService.isLoggedIn) {
      try {
        final me = await ApiService.getMe();
        _userRol = me['rol'];
        _userEposta = me['eposta'];
      } catch (_) {}
      // Rezervasyon kontrolü
      try {
        final rezvlar = await ApiService.getRezervasyon();
        final mevcut = rezvlar.any((r) => r['ilan']?['id'] == ilanId && (r['durum'] == 'BEKLEMEDE' || r['durum'] == 'ONAYLANDI'));
        setState(() { _rezerveEdildi = mevcut; });
      } catch (_) {}
    }
    // Puanlar & yorumlar
    try {
      final puan = await ApiService.getPuanOzeti(ilanId);
      final yorumlar = await ApiService.getYorumlar(ilanId);
      if (mounted) setState(() { _puanOzeti = puan; _yorumlar = yorumlar; });
    } catch (_) {}
  }

  Future<void> _rezervasyonYap() async {
    if (!ApiService.isLoggedIn) {
      Navigator.pushNamed(context, '/login');
      return;
    }
    setState(() { _rezvLoading = true; });
    try {
      await ApiService.rezervasyonOlustur(widget.ilan['id']);
      setState(() { _rezerveEdildi = true; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Rezervasyon başarıyla oluşturuldu!'), backgroundColor: kSuccess),
        );
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('zaten')) {
        setState(() { _rezerveEdildi = true; });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $msg'), backgroundColor: kDanger),
          );
        }
      }
    } finally {
      if (mounted) setState(() { _rezvLoading = false; });
    }
  }

  Future<void> _yorumGonder() async {
    if (_secilenPuan == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen puan seçin.'), backgroundColor: kWarning));
      return;
    }
    try {
      await ApiService.yorumYaz(widget.ilan['id'], _secilenPuan, _yorumCtrl.text.trim());
      _yorumCtrl.clear();
      _secilenPuan = 0;
      _yukle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yorumunuz eklendi!'), backgroundColor: kSuccess));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: kDanger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ilan = widget.ilan;
    final usta = ilan['olusturanKullanici'];
    final ustaAd = usta != null ? '${usta['ad']} ${usta['soyad']}' : 'Bilinmiyor';
    final gorsel = ilan['gorselYolu'];
    final ort = (_puanOzeti['ortalama'] ?? 0).toDouble();
    final yorumSayisi = _puanOzeti['yorumSayisi'] ?? 0;
    final benimIlanim = _userEposta != null && usta != null && _userEposta == usta['eposta'];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero görsel
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: kPrimary,
            flexibleSpace: FlexibleSpaceBar(
              background: gorsel != null
                  ? Image.network('$apiBaseUrl/uploads/$gorsel', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(gradient: LinearGradient(colors: [kPrimary, kAccent])),
                    ))
                  : Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [kPrimary, kAccent]))),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık + Fiyat
                  Text(ilan['baslik'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  if (ilan['butce'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Text('${ilan['butce']} ₺', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kPrimaryDark)),
                    ),
                  const SizedBox(height: 16),

                  // Bilgiler
                  _bilgiSatir(Icons.person, ustaAd),
                  if (ilan['konum'] != null) _bilgiSatir(Icons.location_on, ilan['konum']),
                  if (ilan['kategori'] != null) _bilgiSatir(Icons.category, ilan['kategori']),
                  const SizedBox(height: 16),

                  // Açıklama
                  if (ilan['aciklama'] != null && ilan['aciklama'].isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
                      child: Text(ilan['aciklama'], style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF444444))),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Rezervasyon butonu
                  if (!benimIlanim)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _rezerveEdildi || _rezvLoading ? null : _rezervasyonYap,
                        icon: _rezvLoading
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Icon(_rezerveEdildi ? Icons.check : Icons.calendar_today),
                        label: Text(_rezerveEdildi ? 'Rezervasyon Yapıldı' : 'Hemen Rezervasyon Yap'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _rezerveEdildi ? kWarning : kPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),

                  // Mesaj gönder butonu
                  if (!benimIlanim && ApiService.isLoggedIn && usta != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/chat', arguments: {'partnerId': usta['id'], 'partnerAd': ustaAd}),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Ustaya Mesaj Yaz'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimary,
                          side: const BorderSide(color: kPrimary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),
                  const Divider(),

                  // Yorumlar başlık
                  Row(
                    children: [
                      const Icon(Icons.star, color: kStar, size: 22),
                      const SizedBox(width: 6),
                      const Text('Yorumlar ve Değerlendirmeler', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Puan özeti
                  if (yorumSayisi > 0)
                    Row(
                      children: [
                        Text(ort.toStringAsFixed(1), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 8),
                        Row(children: List.generate(5, (i) => Icon(i < ort.round() ? Icons.star : Icons.star_border, color: kStar, size: 20))),
                        const SizedBox(width: 8),
                        Text('($yorumSayisi)', style: const TextStyle(color: kMuted)),
                      ],
                    )
                  else
                    const Text('Henüz değerlendirme yapılmamış.', style: TextStyle(color: kMuted)),

                  const SizedBox(height: 16),

                  // Yorum formu (sadece müşteri)
                  if (ApiService.isLoggedIn && _userRol == 'MUSTERI') ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFF9FCFA), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEEF7F1))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Puan Ver & Yorum Yaz', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          // Yıldızlar
                          Row(
                            children: List.generate(5, (i) => GestureDetector(
                              onTap: () => setState(() { _secilenPuan = i + 1; }),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(i < _secilenPuan ? Icons.star : Icons.star_border, color: kStar, size: 32),
                              ),
                            )),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _yorumCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(hintText: 'Deneyiminizi paylaşın (isteğe bağlı)', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(onPressed: _yorumGonder, child: const Text('Gönder')),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Yorum listesi
                  ..._yorumlar.map<Widget>((y) {
                    final puan = y['puan'] ?? 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEEEEEE))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(y['kullaniciAd'] ?? 'Anonim', style: const TextStyle(fontWeight: FontWeight.w700)),
                              Row(children: List.generate(5, (i) => Icon(i < puan ? Icons.star : Icons.star_border, color: kStar, size: 14))),
                            ],
                          ),
                          if (y['yorumMetni'] != null && y['yorumMetni'].isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(y['yorumMetni'], style: const TextStyle(fontSize: 14, color: Color(0xFF444444))),
                          ],
                        ],
                      ),
                    );
                  }),
                  if (_yorumlar.isEmpty)
                    const Center(child: Text('İlk yorumu sen yap!', style: TextStyle(fontWeight: FontWeight.w700, color: kMuted))),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bilgiSatir(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kPrimary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}
