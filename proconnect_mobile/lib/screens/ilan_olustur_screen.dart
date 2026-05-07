import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants.dart';
import '../services/api_service.dart';
import '../data/sehirler.dart';

class IlanOlusturScreen extends StatefulWidget {
  const IlanOlusturScreen({super.key});
  @override
  State<IlanOlusturScreen> createState() => _IlanOlusturScreenState();
}

class _IlanOlusturScreenState extends State<IlanOlusturScreen> {
  final _baslikCtrl = TextEditingController();
  final _aciklamaCtrl = TextEditingController();
  final _butceCtrl = TextEditingController();
  XFile? _gorsel;
  bool _loading = false;

  String? _secilenSehir;
  String? _secilenIlce;
  List<String> _ilceler = [];

  // Fiyat önerisi
  bool _fiyatYukleniyor = false;
  Map<String, dynamic>? _fiyatOneri;

  final List<String> _sehirListesi = sehirIlceler.keys.toList()..sort((a, b) => a.compareTo(b));

  void _sehirSecildi(String? sehir) {
    setState(() {
      _secilenSehir = sehir;
      _secilenIlce = null;
      _ilceler = sehir != null ? (sehirIlceler[sehir] ?? []) : [];
    });
  }

  Future<void> _gorselSec() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (picked != null) setState(() { _gorsel = picked; });
  }

  void _gorselKaldir() {
    setState(() { _gorsel = null; });
  }

  Future<void> _fiyatOnerisiAl() async {
    final baslik = _baslikCtrl.text.trim();
    if (baslik.isEmpty) {
      _mesaj('Önce ilan başlığını girin.', hata: true);
      return;
    }

    setState(() { _fiyatYukleniyor = true; _fiyatOneri = null; });
    try {
      final sonuc = await ApiService.fiyatOnerisi(baslik);
      setState(() { _fiyatOneri = sonuc; });
    } catch (e) {
      _mesaj('Fiyat önerisi alınamadı.', hata: true);
    } finally {
      if (mounted) setState(() { _fiyatYukleniyor = false; });
    }
  }

  void _oneriKullan(String deger) {
    _butceCtrl.text = deger;
    setState(() {});
  }

  Future<void> _olustur() async {
    final baslik = _baslikCtrl.text.trim();
    final aciklama = _aciklamaCtrl.text.trim();

    if (baslik.isEmpty || aciklama.isEmpty) {
      _mesaj('Başlık ve açıklama zorunludur.', hata: true);
      return;
    }

    setState(() { _loading = true; });
    try {
      await ApiService.ilanOlustur(
        baslik: baslik,
        aciklama: aciklama,
        butce: _butceCtrl.text.trim(),
        sehir: _secilenSehir ?? '',
        ilce: _secilenIlce ?? '',
        gorselPath: _gorsel?.path,
        gorselName: _gorsel?.name,
      );
      _mesaj('İlan başarıyla oluşturuldu!');
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _mesaj('İlan oluşturulamadı.', hata: true);
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  void _mesaj(String mesaj, {bool hata = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mesaj),
      backgroundColor: hata ? kDanger : kSuccess,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlan Oluştur'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Görsel seçimi
            GestureDetector(
              onTap: _gorselSec,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kPrimary.withValues(alpha: 0.3), width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                ),
                child: _gorsel != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(_gorsel!.path), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _gorselKaldir,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(color: kDanger, shape: BoxShape.circle),
                                child: const Icon(Icons.close, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome, size: 40, color: kPrimary.withValues(alpha: 0.6)),
                          const SizedBox(height: 8),
                          Text('Görsel eklemek için dokunun', style: TextStyle(color: kMuted.withValues(alpha: 0.7), fontSize: 14)),
                          const SizedBox(height: 4),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 30),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: kPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Eklenmezse AI ile otomatik oluşturulur',
                              style: TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Başlık
            TextField(
              controller: _baslikCtrl,
              decoration: const InputDecoration(
                labelText: 'İlan Başlığı *',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 14),

            // Açıklama
            TextField(
              controller: _aciklamaCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Açıklama *',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),

            // Bütçe + AI Önerilen
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _butceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Bütçe (₺)',
                      prefixIcon: Icon(Icons.monetization_on),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: ElevatedButton.icon(
                    onPressed: _fiyatYukleniyor ? null : _fiyatOnerisiAl,
                    icon: _fiyatYukleniyor
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('AI Öneri'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),

            // Fiyat öneri sonucu
            if (_fiyatOneri != null) _fiyatOneriKarti(),

            const SizedBox(height: 14),

            // Şehir dropdown
            DropdownButtonFormField<String>(
              value: _secilenSehir,
              decoration: const InputDecoration(
                labelText: 'Şehir',
                prefixIcon: Icon(Icons.location_city),
              ),
              isExpanded: true,
              menuMaxHeight: 300,
              items: _sehirListesi.map((sehir) => DropdownMenuItem(
                value: sehir,
                child: Text(sehir),
              )).toList(),
              onChanged: _sehirSecildi,
            ),
            const SizedBox(height: 14),

            // İlçe dropdown
            DropdownButtonFormField<String>(
              value: _secilenIlce,
              decoration: const InputDecoration(
                labelText: 'İlçe',
                prefixIcon: Icon(Icons.location_on),
              ),
              isExpanded: true,
              menuMaxHeight: 300,
              items: _ilceler.map((ilce) => DropdownMenuItem(
                value: ilce,
                child: Text(ilce),
              )).toList(),
              onChanged: (val) => setState(() { _secilenIlce = val; }),
              disabledHint: const Text('Önce şehir seçin'),
            ),
            const SizedBox(height: 24),

            // Oluştur butonu
            ElevatedButton.icon(
              onPressed: _loading ? null : _olustur,
              icon: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle),
              label: Text(_loading ? 'Oluşturuluyor...' : 'İlan Oluştur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fiyatOneriKarti() {
    final oneri = _fiyatOneri!['oneri'] == true;
    if (!oneri) {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kWarning.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF856404), size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(_fiyatOneri!['mesaj'] ?? 'Veri bulunamadı.', style: const TextStyle(fontSize: 13, color: Color(0xFF856404)))),
          ],
        ),
      );
    }

    final ortalama = _fiyatOneri!['ortalama']?.toString() ?? '0';
    final min = _fiyatOneri!['min']?.toString() ?? '0';
    final max = _fiyatOneri!['max']?.toString() ?? '0';
    final ilanSayisi = _fiyatOneri!['ilanSayisi']?.toString() ?? '0';

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF3E8FF), Color(0xFFEDE9FE)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF7C3AED), size: 18),
              const SizedBox(width: 6),
              Text('$ilanSayisi benzer ilan analiz edildi', style: const TextStyle(fontSize: 12, color: Color(0xFF7C3AED), fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          // Fiyat aralığı çubuğu
          Row(
            children: [
              _fiyatChip('Min', '$min ₺', const Color(0xFF059669)),
              const Spacer(),
              _fiyatChip('Ortalama', '$ortalama ₺', const Color(0xFF7C3AED)),
              const Spacer(),
              _fiyatChip('Max', '$max ₺', const Color(0xFFDC2626)),
            ],
          ),
          const SizedBox(height: 12),
          // Kullan butonları
          Row(
            children: [
              Expanded(child: _kullanButonu('$min ₺', min, const Color(0xFF059669))),
              const SizedBox(width: 8),
              Expanded(child: _kullanButonu('$ortalama ₺', ortalama, const Color(0xFF7C3AED))),
              const SizedBox(width: 8),
              Expanded(child: _kullanButonu('$max ₺', max, const Color(0xFFDC2626))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fiyatChip(String label, String deger, Color renk) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: renk, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(deger, style: TextStyle(fontSize: 16, color: renk, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _kullanButonu(String label, String deger, Color renk) {
    return OutlinedButton(
      onPressed: () => _oneriKullan(deger),
      style: OutlinedButton.styleFrom(
        foregroundColor: renk,
        side: BorderSide(color: renk),
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text('Kullan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
