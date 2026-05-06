import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../constants.dart';
import '../services/api_service.dart';
import 'ilan_olustur_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _user;
  List<dynamic> _rezervasyonlar = [];
  List<dynamic> _ilanlarim = [];
  bool _loading = true;
  TabController? _tabCtrl;

  // Profil düzenleme
  bool _duzenleAcik = false;
  final _adCtrl = TextEditingController();
  final _soyadCtrl = TextEditingController();
  final _telefonCtrl = TextEditingController();
  bool _profilKaydediyor = false;

  // Şifre değiştirme
  bool _sifreAcik = false;
  final _mevcutSifreCtrl = TextEditingController();
  final _yeniSifreCtrl = TextEditingController();
  bool _sifreDegistiriyor = false;
  bool _mevcutSifreGizli = true;
  bool _yeniSifreGizli = true;

  // E-posta doğrulama
  final _kodCtrl = TextEditingController();
  bool _kodGonderiyor = false;
  bool _kodDogruluyor = false;

  // Belge yükleme
  bool _belgeYukleniyor = false;
  String? _secilenDosyaAdi;

  void refresh() => _yukle();

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  @override
  void dispose() {
    _tabCtrl?.dispose();
    _adCtrl.dispose();
    _soyadCtrl.dispose();
    _telefonCtrl.dispose();
    _mevcutSifreCtrl.dispose();
    _yeniSifreCtrl.dispose();
    _kodCtrl.dispose();
    super.dispose();
  }

  void _initTabController(bool isUsta) {
    final tabCount = isUsta ? 3 : 2;
    if (_tabCtrl == null || _tabCtrl!.length != tabCount) {
      _tabCtrl?.dispose();
      _tabCtrl = TabController(length: tabCount, vsync: this);
    }
  }

  Future<void> _yukle() async {
    setState(() { _loading = true; });
    try {
      final me = await ApiService.getMe();
      final rezvlar = await ApiService.getRezervasyon();
      List<dynamic> ilanlar = [];
      if (me['rol'] == 'USTA') {
        ilanlar = await ApiService.getBenimIlanlarim();
      }
      if (mounted) {
        setState(() {
          _user = me;
          _rezervasyonlar = rezvlar;
          _ilanlarim = ilanlar;
          _loading = false;
          _adCtrl.text = me['ad'] ?? '';
          _soyadCtrl.text = me['soyad'] ?? '';
          _telefonCtrl.text = me['telefon'] ?? '';
        });
      }
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

  void _mesajGoster(String mesaj, {bool hata = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj),
        backgroundColor: hata ? kDanger : kSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _profilKaydet() async {
    final ad = _adCtrl.text.trim();
    final soyad = _soyadCtrl.text.trim();
    final telefon = _telefonCtrl.text.trim();

    if (ad.isEmpty || soyad.isEmpty) {
      _mesajGoster('Ad ve soyad boş bırakılamaz.', hata: true);
      return;
    }

    setState(() { _profilKaydediyor = true; });
    try {
      await ApiService.profilGuncelle(ad, soyad, telefon);
      _mesajGoster('Profil güncellendi!');
      setState(() { _duzenleAcik = false; });
      _yukle();
    } catch (e) {
      _mesajGoster('Güncelleme başarısız.', hata: true);
    } finally {
      if (mounted) setState(() { _profilKaydediyor = false; });
    }
  }

  Future<void> _sifreDegistir() async {
    final mevcut = _mevcutSifreCtrl.text;
    final yeni = _yeniSifreCtrl.text;

    if (mevcut.isEmpty || yeni.isEmpty) {
      _mesajGoster('Tüm alanları doldurun.', hata: true);
      return;
    }
    if (yeni.length < 6) {
      _mesajGoster('Yeni şifre en az 6 karakter olmalıdır.', hata: true);
      return;
    }

    setState(() { _sifreDegistiriyor = true; });
    try {
      await ApiService.sifreDegistir(mevcut, yeni);
      _mesajGoster('Şifre başarıyla değiştirildi!');
      _mevcutSifreCtrl.clear();
      _yeniSifreCtrl.clear();
      setState(() { _sifreAcik = false; });
    } catch (e) {
      _mesajGoster('Şifre değiştirilemedi. Mevcut şifrenizi kontrol edin.', hata: true);
    } finally {
      if (mounted) setState(() { _sifreDegistiriyor = false; });
    }
  }

  Future<void> _epostaDogrula() async {
    final kod = _kodCtrl.text.trim();
    if (kod.length != 6) {
      _mesajGoster('Lütfen 6 haneli kodu giriniz.', hata: true);
      return;
    }

    setState(() { _kodDogruluyor = true; });
    try {
      await ApiService.epostaDogrula(_user!['eposta'], kod);
      _mesajGoster('E-posta doğrulandı!');
      _kodCtrl.clear();
      _yukle();
    } catch (e) {
      _mesajGoster('Doğrulama başarısız. Kodu kontrol edin.', hata: true);
    } finally {
      if (mounted) setState(() { _kodDogruluyor = false; });
    }
  }

  Future<void> _kodTekrarGonder() async {
    setState(() { _kodGonderiyor = true; });
    try {
      await ApiService.kodTekrarGonder(_user!['eposta']);
      _mesajGoster('Doğrulama kodu tekrar gönderildi.');
    } catch (e) {
      _mesajGoster('Kod gönderilemedi.', hata: true);
    } finally {
      if (mounted) setState(() { _kodGonderiyor = false; });
    }
  }

  // ==================== BELGE YÜKLEME ====================
  String? _secilenDosyaYolu;

  Future<void> _belgeSec() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _secilenDosyaYolu = result.files.single.path;
        _secilenDosyaAdi = result.files.single.name;
      });
    }
  }

  Future<void> _belgeYukle() async {
    if (_secilenDosyaYolu == null || _secilenDosyaAdi == null) {
      _mesajGoster('Lütfen bir dosya seçiniz.', hata: true);
      return;
    }

    setState(() { _belgeYukleniyor = true; });
    try {
      await ApiService.belgeYukle(_secilenDosyaYolu!, _secilenDosyaAdi!);
      _mesajGoster('Belge yüklendi! Başvurunuz inceleniyor.');
      setState(() {
        _secilenDosyaYolu = null;
        _secilenDosyaAdi = null;
      });
      _yukle();
    } catch (e) {
      _mesajGoster('Belge yüklenemedi.', hata: true);
    } finally {
      if (mounted) setState(() { _belgeYukleniyor = false; });
    }
  }

  // ==================== İLAN SİLME ====================
  Future<void> _ilanSil(int ilanId) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İlan Sil'),
        content: const Text('Bu ilanı silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: kDanger)),
          ),
        ],
      ),
    );
    if (onay != true) return;

    try {
      await ApiService.ilanSil(ilanId);
      _mesajGoster('İlan silindi.');
      _yukle();
    } catch (e) {
      _mesajGoster('İlan silinemedi.', hata: true);
    }
  }

  // ==================== İLAN DÜZENLEME ====================
  Future<void> _ilanDuzenle(Map<String, dynamic> ilan) async {
    final baslikCtrl = TextEditingController(text: ilan['baslik'] ?? '');
    final aciklamaCtrl = TextEditingController(text: ilan['aciklama'] ?? '');
    final butceCtrl = TextEditingController(text: ilan['butce']?.toString() ?? '');
    final sehirCtrl = TextEditingController(text: ilan['sehir'] ?? '');
    final ilceCtrl = TextEditingController(text: ilan['ilce'] ?? '');

    final sonuc = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit, color: kPrimary),
            SizedBox(width: 8),
            Text('İlan Düzenle'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: baslikCtrl, decoration: const InputDecoration(labelText: 'Başlık')),
              const SizedBox(height: 10),
              TextField(controller: aciklamaCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Açıklama')),
              const SizedBox(height: 10),
              TextField(controller: butceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Bütçe (₺)')),
              const SizedBox(height: 10),
              TextField(controller: sehirCtrl, decoration: const InputDecoration(labelText: 'Şehir')),
              const SizedBox(height: 10),
              TextField(controller: ilceCtrl, decoration: const InputDecoration(labelText: 'İlçe')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (sonuc != true) return;

    try {
      await ApiService.ilanGuncelle(ilan['id'], {
        'baslik': baslikCtrl.text.trim(),
        'aciklama': aciklamaCtrl.text.trim(),
        'butce': butceCtrl.text.isNotEmpty ? butceCtrl.text.trim() : null,
        'sehir': sehirCtrl.text.trim(),
        'ilce': ilceCtrl.text.trim(),
      });
      _mesajGoster('İlan güncellendi!');
      _yukle();
    } catch (e) {
      _mesajGoster('Güncelleme başarısız.', hata: true);
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
    final epostaDogrulandi = _user!['epostaDogrulandi'] == true;
    final belgeYuklendi = _user!['belgeYuklendi'] == true || (_user!['belgeYolu'] != null && _user!['belgeYolu'].toString().isNotEmpty);
    final isUsta = rol == 'USTA';

    _initTabController(isUsta);

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
              tabs: [
                const Tab(icon: Icon(Icons.info_outline), text: 'Bilgiler'),
                const Tab(icon: Icon(Icons.calendar_month), text: 'Rezervasyonlar'),
                if (isUsta) const Tab(icon: Icon(Icons.work_outline), text: 'İlanlarım'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            // Tab 1: Bilgiler + Düzenleme
            _buildBilgilerTab(eposta, epostaDogrulandi, belgeYuklendi, isUsta, rol),
            // Tab 2: Rezervasyonlar
            _buildReservasyonlarTab(),
            // Tab 3: İlanlarım (sadece USTA)
            if (isUsta) _buildIlanlarimTab(epostaDogrulandi, belgeYuklendi),
          ],
        ),
      ),
    );
  }

  // ==================== TAB 1: BİLGİLER ====================
  Widget _buildBilgilerTab(String eposta, bool epostaDogrulandi, bool belgeYuklendi, bool isUsta, String rol) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // E-posta doğrulama uyarısı
        if (!epostaDogrulandi) _epostaDogrulamaBolumu(eposta),

        // USTA: E-posta doğrulandı ama belge yüklenmedi
        if (isUsta && epostaDogrulandi && !belgeYuklendi) _belgeYuklemeBolumu(),

        // USTA: Her şey tamam
        if (isUsta && epostaDogrulandi && belgeYuklendi) _tamamBanner(),

        // Bilgi kartları
        _bilgiKart(Icons.email, 'E-posta', eposta, trailing: epostaDogrulandi
            ? const Icon(Icons.verified, color: kSuccess, size: 20)
            : const Icon(Icons.warning_amber, color: kWarning, size: 20)),
        _bilgiKart(Icons.phone, 'Telefon', _user!['telefon'] ?? '-'),
        _bilgiKart(Icons.badge, 'Rol', rol),
        _bilgiKart(Icons.calendar_today, 'Üyelik', _user!['olusturulmaTarihi']?.toString().substring(0, 10) ?? '-'),

        const SizedBox(height: 12),

        // Profil Düzenle butonu
        _aksiyonButonu(
          icon: Icons.edit,
          label: _duzenleAcik ? 'Düzenlemeyi Kapat' : 'Profili Düzenle',
          onTap: () => setState(() { _duzenleAcik = !_duzenleAcik; }),
        ),
        if (_duzenleAcik) _profilDuzenleFormu(),

        const SizedBox(height: 8),

        // Şifre Değiştir butonu
        _aksiyonButonu(
          icon: Icons.lock,
          label: _sifreAcik ? 'Şifre Bölümünü Kapat' : 'Şifre Değiştir',
          onTap: () => setState(() { _sifreAcik = !_sifreAcik; }),
          renk: kDanger,
        ),
        if (_sifreAcik) _sifreDegistirFormu(),
      ],
    );
  }

  // ==================== TAB 2: REZERVASYONLAR ====================
  Widget _buildReservasyonlarTab() {
    if (_rezervasyonlar.isEmpty) {
      return const Center(child: Text('Henüz rezervasyonunuz yok.', style: TextStyle(color: kMuted)));
    }
    return RefreshIndicator(
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
    );
  }

  // ==================== TAB 3: İLANLARIM ====================
  Widget _buildIlanlarimTab(bool epostaDogrulandi, bool belgeYuklendi) {
    return Column(
      children: [
        // İlan Oluştur butonu
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (!epostaDogrulandi || !belgeYuklendi) ? null : () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const IlanOlusturScreen()));
                if (result == true) _yukle();
              },
              icon: const Icon(Icons.add_circle),
              label: Text(
                !epostaDogrulandi
                    ? 'Önce e-postanızı doğrulayın'
                    : !belgeYuklendi
                        ? 'Önce belgenizi yükleyin'
                        : 'Yeni İlan Oluştur',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                disabledBackgroundColor: kMuted.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // İlanlar listesi
        Expanded(
          child: _ilanlarim.isEmpty
              ? const Center(child: Text('Henüz ilanınız bulunmuyor.', style: TextStyle(color: kMuted)))
              : RefreshIndicator(
                  onRefresh: _yukle,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: _ilanlarim.length,
                    itemBuilder: (context, index) {
                      final ilan = _ilanlarim[index];
                      final baslik = ilan['baslik'] ?? '';
                      final durum = ilan['durum'] ?? '';
                      final konum = [ilan['ilce'], ilan['sehir']].where((s) => s != null && s.toString().isNotEmpty).join(', ');
                      final butce = ilan['butce'] != null ? '${ilan['butce']} ₺' : '';
                      final gorsel = ilan['gorselYolu'];
                      final durumRenk = durum == 'ACIK' ? kSuccess : kDanger;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: kCard,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Görsel
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                              child: Container(
                                height: 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: gorsel != null
                                      ? null
                                      : const LinearGradient(colors: [Color(0xFFD9E8FF), Color(0xFFFEF3D4)]),
                                ),
                                child: gorsel != null
                                    ? Image.network('$apiBaseUrl/uploads/$gorsel', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.build_circle_outlined, size: 40, color: kPrimary)))
                                    : const Center(child: Icon(Icons.build_circle_outlined, size: 40, color: kPrimary)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Başlık ve durum
                                  Row(
                                    children: [
                                      Expanded(child: Text(baslik, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: durumRenk.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                        child: Text(durum == 'ACIK' ? 'Açık' : 'Kapalı', style: TextStyle(color: durumRenk, fontWeight: FontWeight.w700, fontSize: 11)),
                                      ),
                                    ],
                                  ),
                                  if (konum.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(children: [const Icon(Icons.location_on, size: 14, color: kMuted), const SizedBox(width: 4), Text(konum, style: const TextStyle(color: kMuted, fontSize: 13))]),
                                  ],
                                  if (butce.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(children: [const Icon(Icons.monetization_on, size: 14, color: kPrimary), const SizedBox(width: 4), Text(butce, style: const TextStyle(color: kPrimaryDark, fontWeight: FontWeight.w700, fontSize: 13))]),
                                  ],
                                  const SizedBox(height: 12),
                                  // Aksiyonlar
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _ilanDuzenle(ilan),
                                          icon: const Icon(Icons.edit, size: 16),
                                          label: const Text('Düzenle'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: kPrimary,
                                            side: const BorderSide(color: kPrimary),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _ilanSil(ilan['id']),
                                          icon: const Icon(Icons.delete, size: 16),
                                          label: const Text('Sil'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: kDanger,
                                            side: const BorderSide(color: kDanger),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ),
                                    ],
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
        ),
      ],
    );
  }

  // ==================== E-POSTA DOĞRULAMA ====================
  Widget _epostaDogrulamaBolumu(String eposta) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        border: Border.all(color: kWarning),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.email, color: Color(0xFF856404), size: 20),
              SizedBox(width: 8),
              Text('E-posta Doğrulama', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF856404))),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'E-postanıza gönderilen 6 haneli kodu girin.',
            style: TextStyle(color: Color(0xFF856404), fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 160,
                child: TextField(
                  controller: _kodCtrl,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 6),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '000000',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kWarning, width: 2)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kPrimary, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _kodDogruluyor ? null : _epostaDogrula,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSuccess,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _kodDogruluyor
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Doğrula', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _kodGonderiyor ? null : _kodTekrarGonder,
            child: Text(
              _kodGonderiyor ? 'Gönderiliyor...' : 'Kodu tekrar gönder',
              style: const TextStyle(color: Color(0xFF007BFF), fontSize: 13, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BELGE YÜKLEME ====================
  Widget _belgeYuklemeBolumu() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FD),
        border: Border.all(color: const Color(0xFFB8DAFF)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.upload_file, color: Color(0xFF004085), size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('Belge Yükleme', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF004085)))),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'İlan oluşturabilmek için diploma veya sertifikanızı yükleyin.\n(PDF, JPG, PNG - max 5MB)',
            style: TextStyle(color: Color(0xFF004085), fontSize: 13),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _belgeSec,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFB8DAFF), width: 2, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  Icon(_secilenDosyaAdi != null ? Icons.check_circle : Icons.cloud_upload, size: 36, color: _secilenDosyaAdi != null ? kSuccess : const Color(0xFF004085)),
                  const SizedBox(height: 6),
                  Text(
                    _secilenDosyaAdi ?? 'Dosya seçmek için dokunun',
                    style: TextStyle(color: _secilenDosyaAdi != null ? kSuccess : const Color(0xFF666666), fontSize: 14, fontWeight: _secilenDosyaAdi != null ? FontWeight.w600 : FontWeight.normal),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_belgeYukleniyor || _secilenDosyaAdi == null) ? null : _belgeYukle,
              icon: _belgeYukleniyor
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.upload),
              label: Text(_belgeYukleniyor ? 'Yükleniyor...' : 'Yükle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kSuccess,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TAMAM BANNER ====================
  Widget _tamamBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFD4EDDA),
        border: Border.all(color: const Color(0xFFC3E6CB)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: Color(0xFF155724), size: 20),
          SizedBox(width: 8),
          Expanded(child: Text('E-posta doğrulandı ve belgeniz yüklendi. İlan oluşturabilirsiniz.', style: TextStyle(color: Color(0xFF155724), fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  // ==================== PROFİL DÜZENLEME FORMU ====================
  Widget _profilDuzenleFormu() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person, color: kPrimary, size: 20),
              SizedBox(width: 8),
              Text('Profil Bilgilerini Düzenle', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(controller: _adCtrl, decoration: const InputDecoration(labelText: 'Ad', prefixIcon: Icon(Icons.person_outline))),
          const SizedBox(height: 12),
          TextField(controller: _soyadCtrl, decoration: const InputDecoration(labelText: 'Soyad', prefixIcon: Icon(Icons.person_outline))),
          const SizedBox(height: 12),
          TextField(controller: _telefonCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefon', prefixIcon: Icon(Icons.phone))),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _profilKaydediyor ? null : _profilKaydet,
              icon: _profilKaydediyor
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_profilKaydediyor ? 'Kaydediliyor...' : 'Kaydet'),
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ŞİFRE DEĞİŞTİRME FORMU ====================
  Widget _sifreDegistirFormu() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock, color: kDanger, size: 20),
              SizedBox(width: 8),
              Text('Şifre Değiştir', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _mevcutSifreCtrl,
            obscureText: _mevcutSifreGizli,
            decoration: InputDecoration(
              labelText: 'Mevcut Şifre',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(icon: Icon(_mevcutSifreGizli ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() { _mevcutSifreGizli = !_mevcutSifreGizli; })),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _yeniSifreCtrl,
            obscureText: _yeniSifreGizli,
            decoration: InputDecoration(
              labelText: 'Yeni Şifre (min 6 karakter)',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(icon: Icon(_yeniSifreGizli ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() { _yeniSifreGizli = !_yeniSifreGizli; })),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sifreDegistiriyor ? null : _sifreDegistir,
              icon: _sifreDegistiriyor
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.vpn_key),
              label: Text(_sifreDegistiriyor ? 'Değiştiriliyor...' : 'Şifreyi Değiştir'),
              style: ElevatedButton.styleFrom(backgroundColor: kDanger, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== AKSİYON BUTONU ====================
  Widget _aksiyonButonu({required IconData icon, required String label, required VoidCallback onTap, Color renk = kPrimary}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: renk.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: renk, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: renk))),
            Icon(Icons.chevron_right, color: renk.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  // ==================== BİLGİ KARTI ====================
  Widget _bilgiKart(IconData icon, String label, String value, {Widget? trailing}) {
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
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
