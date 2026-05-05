import 'dart:async';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final int partnerId;
  final String partnerAd;
  const ChatScreen({super.key, required this.partnerId, required this.partnerAd});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<dynamic> _mesajlar = [];
  final _mesajCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _timer;
  String? _benimEposta;

  @override
  void initState() {
    super.initState();
    _yukle();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _yenile());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mesajCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _yukle() async {
    try {
      if (_benimEposta == null) {
        final me = await ApiService.getMe();
        _benimEposta = me['eposta'];
      }
      final mesajlar = await ApiService.getMesajlar(widget.partnerId);
      if (mounted) {
        setState(() { _mesajlar = mesajlar; });
        _scrollAlt();
      }
    } catch (_) {}
  }

  Future<void> _yenile() async {
    try {
      final mesajlar = await ApiService.getMesajlar(widget.partnerId);
      if (mounted && mesajlar.length != _mesajlar.length) {
        setState(() { _mesajlar = mesajlar; });
        _scrollAlt();
      }
    } catch (_) {}
  }

  void _scrollAlt() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _gonder() async {
    final metin = _mesajCtrl.text.trim();
    if (metin.isEmpty) return;
    _mesajCtrl.clear();
    try {
      await ApiService.mesajGonder(widget.partnerId, metin);
      _yukle();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(radius: 16, backgroundColor: kPrimary, child: Text(widget.partnerAd[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
            const SizedBox(width: 10),
            Text(widget.partnerAd, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Mesaj listesi
          Expanded(
            child: _mesajlar.isEmpty
                ? const Center(child: Text('Henüz mesaj yok. İlk mesajı gönderin!', style: TextStyle(color: kMuted)))
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(14),
                    itemCount: _mesajlar.length,
                    itemBuilder: (context, index) {
                      final m = _mesajlar[index];
                      final benMi = m['gonderen']?['eposta'] == _benimEposta;
                      final saat = m['tarih'] != null ? _formatTarih(m['tarih']) : '';

                      return Align(
                        alignment: benMi ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: benMi ? const Color(0xFFDCF8C6) : const Color(0xFFF1F0F0),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(benMi ? 16 : 4),
                              bottomRight: Radius.circular(benMi ? 4 : 16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(m['mesajMetni'] ?? '', style: const TextStyle(fontSize: 14)),
                              const SizedBox(height: 3),
                              Text(saat, style: const TextStyle(fontSize: 10, color: kMuted)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: kCard, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))]),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mesajCtrl,
                      onSubmitted: (_) => _gonder(),
                      decoration: InputDecoration(
                        hintText: 'Mesajınızı yazın...',
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                    child: IconButton(
                      onPressed: _gonder,
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTarih(String tarih) {
    try {
      final dt = DateTime.parse(tarih);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
