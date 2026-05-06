import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants.dart';
import '../services/api_service.dart';

class IlanOlusturScreen extends StatefulWidget {
  const IlanOlusturScreen({super.key});
  @override
  State<IlanOlusturScreen> createState() => _IlanOlusturScreenState();
}

class _IlanOlusturScreenState extends State<IlanOlusturScreen> {
  final _baslikCtrl = TextEditingController();
  final _aciklamaCtrl = TextEditingController();
  final _butceCtrl = TextEditingController();
  final _sehirCtrl = TextEditingController();
  final _ilceCtrl = TextEditingController();
  XFile? _gorsel;
  bool _loading = false;

  Future<void> _gorselSec() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (picked != null) setState(() { _gorsel = picked; });
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
        sehir: _sehirCtrl.text.trim(),
        ilce: _ilceCtrl.text.trim(),
        gorselPath: _gorsel?.path,
        gorselName: _gorsel?.name,
      );
      _mesaj('İlan başarıyla oluşturuldu!');
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _mesaj('İlan oluşturulamadı: $e', hata: true);
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
                  border: Border.all(color: kPrimary.withOpacity(0.3), width: 2, style: BorderStyle.solid),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                ),
                child: _gorsel != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(_gorsel!.path), fit: BoxFit.cover, width: double.infinity),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 48, color: kPrimary.withOpacity(0.5)),
                          const SizedBox(height: 8),
                          Text('Görsel Ekle (Opsiyonel)', style: TextStyle(color: kMuted.withOpacity(0.7), fontSize: 14)),
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

            // Bütçe
            TextField(
              controller: _butceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Bütçe (₺)',
                prefixIcon: Icon(Icons.monetization_on),
              ),
            ),
            const SizedBox(height: 14),

            // Şehir ve İlçe yan yana
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sehirCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Şehir',
                      prefixIcon: Icon(Icons.location_city),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _ilceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'İlçe',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                ),
              ],
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
}
