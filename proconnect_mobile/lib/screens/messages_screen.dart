import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/api_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<dynamic> _konusmalar = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() { _loading = true; });
    try {
      final data = await ApiService.getKonusmalar();
      if (mounted) setState(() { _konusmalar = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mesajlar')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : _konusmalar.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: kMuted.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      const Text('Henüz mesajınız yok', style: TextStyle(color: kMuted, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _yukle,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _konusmalar.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
                    itemBuilder: (context, index) {
                      final k = _konusmalar[index];
                      final partnerAd = k['partnerAd'] ?? 'Kullanıcı';
                      final basHarf = partnerAd.isNotEmpty ? partnerAd[0].toUpperCase() : '?';
                      final sonMesaj = k['sonMesaj'] ?? '';
                      final okunmamis = k['okunmamis'] ?? 0;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: kPrimary,
                          child: Text(basHarf, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                        ),
                        title: Text(partnerAd, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          (k['sonMesajBendenMi'] == true ? 'Sen: ' : '') + sonMesaj,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: kMuted, fontSize: 13, fontWeight: okunmamis > 0 ? FontWeight.w600 : FontWeight.normal),
                        ),
                        trailing: okunmamis > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: kDanger, borderRadius: BorderRadius.circular(12)),
                                child: Text('$okunmamis', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                              )
                            : null,
                        onTap: () async {
                          await Navigator.pushNamed(context, '/chat', arguments: {'partnerId': k['partnerId'], 'partnerAd': partnerAd});
                          _yukle();
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
