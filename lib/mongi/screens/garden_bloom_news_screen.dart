import 'package:flutter/material.dart';
import '../../services/cloud_service.dart';
import '../models/garden_gifts.dart';
import '../widgets/garden_gift_art.dart';

class GardenBloomNewsScreen extends StatefulWidget {
  const GardenBloomNewsScreen({super.key});
  @override
  State<GardenBloomNewsScreen> createState() => _GardenBloomNewsScreenState();
}

class _GardenBloomNewsScreenState extends State<GardenBloomNewsScreen> {
  List<Map<String, dynamic>> _news = [];
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (!CloudService.enabled) throw StateError('온라인 연결 후 꽃 소식을 확인해 주세요.');
      final news = await CloudService.listFlowerBlooms();
      if (mounted)
        setState(
          () => _news = news
              .where((n) => gardenFlowerNames.containsKey(n['flowerKind']))
              .toList(),
        );
    } catch (_) {
      if (mounted) setState(() => _error = '꽃 소식을 불러오지 못했어요. 연결 후 다시 확인해 주세요.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('내가 건넨 꽃 소식')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                if (_error != null) ...[
                  Text(_error!),
                  TextButton(onPressed: _load, child: const Text('다시 확인')),
                ] else if (_news.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 50),
                    child: Text(
                      '이웃이 선물한 꽃을 심으면 여기에 소식이 도착해요.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ..._news.map((n) {
                    final date = DateTime.tryParse(
                      n['createdAt']?.toString() ?? '',
                    )?.toLocal();
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      leading: SizedBox(
                        width: 64,
                        height: 64,
                        child: GardenFlowerArt(kind: n['flowerKind'] as String),
                      ),
                      title: Text('당신이 건넨 마음이 이웃의 정원에 피었어요.'),
                      subtitle: Text(
                        '${gardenFlowerNames[n['flowerKind']]}${date == null ? '' : ' · ${date.month}월 ${date.day}일'}',
                      ),
                    );
                  }),
              ],
            ),
          ),
  );
}
