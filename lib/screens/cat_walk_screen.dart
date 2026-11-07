import '../l10n/app_language.dart';
import '../services/cloud_service.dart';
import '../services/cat_care_service.dart';
import '../mongi/integration/mongi_garden_store.dart';
import '../mongi/integration/session_transaction.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/app_state_provider.dart';
import '../providers/cat_care_provider.dart';
import '../services/sound_service.dart';
import '../services/subscription_service.dart';
import '../theme.dart';

/// The approved walk runs from bundled assets, never the private preview URL.
/// No record text, credentials or billing actions enter JS. Native code validates
/// bounded reward requests and persists inventory; JS never writes storage.
class CatWalkScreen extends StatefulWidget {
  const CatWalkScreen({super.key});
  @override
  State<CatWalkScreen> createState() => _CatWalkScreenState();
}

@visibleForTesting
bool isLocalWalkUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      uri.scheme == 'file' &&
      uri.path.endsWith('/flutter_assets/assets/cat_walk.html');
}

@visibleForTesting
Uint8List? decodeWalkPostcard(Object? input) {
  if (input is! String ||
      input.length > 8 * 1024 * 1024 ||
      !input.startsWith('data:image/png;base64,'))
    return null;
  try {
    final bytes = base64Decode(input.substring(22));
    const signature = [137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.length < 8 || bytes.length > 6 * 1024 * 1024) return null;
    for (var i = 0; i < 8; i++) {
      if (bytes[i] != signature[i]) return null;
    }
    return bytes;
  } catch (_) {
    return null;
  }
}

@visibleForTesting
Map<String, Object> createWalkProfile({
  required String name,
  required int coat,
  required Iterable<String> emotions,
  required String language,
}) => {
  'name': name.trim().isEmpty
      ? (language == 'en' ? 'Nabi' : tr("나비"))
      : name.trim(),
  'coat': coat,
  'emotions': emotions.toSet().toList(),
  'language': language == 'en' ? 'en' : 'ko',
};

class _CatWalkScreenState extends State<CatWalkScreen>
    with WidgetsBindingObserver {
  final _sound = SoundService();
  WebViewController? _controller;
  bool _ready = false, _failed = false, _sharing = false, _full = false;
  bool _visible = true;
  int _loadEpoch = 0;
  String? _walkId, _walkOwner, _walkAccount;
  bool get _ownsWalk =>
      _walkOwner == CatCareService.localOwner &&
      _walkAccount == CloudService.currentUser?.uid;
  final _walkClock = Stopwatch();
  bool _rewardSaving = false, _rewardSaved = false, _feeding = false;
  Map<String, int>? _pendingReward;
  Map<String, Object>? _profile;
  DateTime _lastEffect = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sound.addListener(_syncSound);
    AppLanguage.instance.addListener(_syncLanguage);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted ||
        kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS))
      return;
    final epoch = ++_loadEpoch;
    setState(() {
      _ready = false;
      _failed = false;
    });
    try {
      final care = context.read<CatCareProvider>();
      final app = context.read<AppStateProvider>();
      await care.loadJourney();
      final premium = await SubscriptionService().isPremium();
      if (!mounted || epoch != _loadEpoch) return;
      if (!care.journeyReady) throw StateError('companion unavailable');
      final name = (care.companionName ?? '').trim();
      _profile = createWalkProfile(
        name: name,
        coat: premium ? (care.journey.coat?.index ?? 0) : -1,
        emotions: app.todaysLetters.map((e) => e.catId),
        language: AppLanguage.instance.code,
      );
      final controller = WebViewController();
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setBackgroundColor(const Color(0xfffaf5ed));
      await controller.addJavaScriptChannel(
        'WalkHost',
        onMessageReceived: _message,
      );
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) => isLocalWalkUrl(request.url)
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
          onPageFinished: (url) async {
            if (!mounted || epoch != _loadEpoch || !isLocalWalkUrl(url)) return;
            try {
              await controller.runJavaScript(
                'window.applyWalkProfile(${jsonEncode(_profile)});',
              );
              if (!mounted || epoch != _loadEpoch) return;
              setState(() => _ready = true);
              _syncSound();
              if (!_visible)
                await controller.runJavaScript('window.hostPause();');
            } catch (_) {
              if (mounted) setState(() => _failed = true);
            }
          },
          onWebResourceError: (error) {
            if (mounted &&
                epoch == _loadEpoch &&
                error.isForMainFrame == true) {
              setState(() => _failed = true);
            }
          },
        ),
      );
      if (!mounted || epoch != _loadEpoch) return;
      setState(() => _controller = controller);
      await controller.loadFlutterAsset('assets/cat_walk.html');
    } catch (_) {
      if (mounted && epoch == _loadEpoch) setState(() => _failed = true);
    }
  }

  void _syncLanguage() {
    final language = AppLanguage.instance.code;
    _profile?['language'] = language;
    unawaited(_run('window.setWalkLanguage(${jsonEncode(language)});'));
  }

  Future<void> _run(String script) async {
    if (!_ready || !mounted) return;
    try {
      await _controller?.runJavaScript(script);
    } catch (_) {}
  }

  void _syncSound() {
    if (!_sound.sfxEnabled) unawaited(_sound.stopPurr());
    unawaited(
      _run(
        'window.applyHostSound(${jsonEncode({'bgm': _sound.bgmEnabled, 'sfx': _sound.sfxEnabled, 'volume': _sound.bgmVolume})});',
      ),
    );
  }

  Future<void> _message(JavaScriptMessage message) async {
    if (!mounted ||
        !_ready ||
        !_visible ||
        message.message.length > 8 * 1024 * 1024)
      return;
    try {
      final data = jsonDecode(message.message);
      if (data is! Map<String, dynamic>) return;
      switch (data['type']) {
        case 'walkBegin':
          if (_rewardSaving || (_pendingReward != null && !_rewardSaved))
            return;
          _walkId = SessionTransaction.newId();
          _walkOwner = CatCareService.localOwner;
          _walkAccount = CloudService.currentUser?.uid;
          _pendingReward = null;
          _rewardSaved = false;
          _walkClock
            ..reset()
            ..start();
        case 'walkPause':
          _walkClock.stop();
        case 'walkResume':
          if (_walkId != null && !_rewardSaved) _walkClock.start();
        case 'walkReward':
          await _saveWalkReward(data);
        case 'walkFeed':
          final kind = data['kind'];
          if (_feeding || !_rewardSaved || !['churu', 'snack'].contains(kind))
            return;
          _feeding = true;
          try {
            final ok = await MongiGardenStore.instance.consumeWalkFood(
              kind == 'churu' ? 'churu_tuna' : 'food_dry',
              isCurrentOwner: () => _ownsWalk,
            );
            await _run('window.walkFeedResult(${jsonEncode(kind)}, $ok);');
          } catch (_) {
            await _run('window.walkFeedResult(${jsonEncode(kind)}, false);');
          } finally {
            _feeding = false;
          }

        case 'fullscreen':
          await _setFullscreen(data['value'] == true);
        case 'startMusic':
          await _sound.tryStartBgm();
        case 'bgm':
          if (data['value'] is bool)
            await _sound.setBgmEnabled(data['value'] as bool);
        case 'sfx':
          if (data['value'] is bool)
            await _sound.setSfxEnabled(data['value'] as bool);
        case 'volume':
          final v = data['value'];
          if (v is num && v.isFinite && v >= 0 && v <= 1) {
            await _sound.setBgmVolume(v.toDouble());
          }
        case 'stopPurr':
          await _sound.stopPurr();
        case 'chime':
        case 'purr':
          final now = DateTime.now();
          if (now.difference(_lastEffect).inMilliseconds < 200) return;
          _lastEffect = now;
          if (data['type'] == 'purr') {
            await _sound.playPurr();
          } else {
            await _sound.playChime();
          }
        case 'postcard':
          if (_sharing) return;
          final bytes = decodeWalkPostcard(data['png']);
          if (bytes == null) return;
          _sharing = true;
          try {
            final box = context.findRenderObject() as RenderBox?;
            await SharePlus.instance.share(
              ShareParams(
                files: [
                  XFile.fromData(
                    bytes,
                    mimeType: 'image/png',
                    name: 'cat-walk.png',
                  ),
                ],
                fileNameOverrides: ['cat-walk.png'],
                sharePositionOrigin: box == null
                    ? null
                    : box.localToGlobal(Offset.zero) & box.size,
              ),
            );
          } finally {
            _sharing = false;
          }
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr("요청을 완료하지 못했어요. 다시 시도해 주세요."))),
        );
    }
  }

  Future<void> _saveWalkReward(Map<String, dynamic> data) async {
    if (_rewardSaving || _walkId == null) return;
    _walkClock.stop();
    _rewardSaving = true;
    try {
      if (!_ownsWalk) throw StateError(tr("계정 변경"));
      if (_pendingReward == null) {
        final raw = data['bag'];
        if (raw is! Map ||
            [
              'churu',
              'snack',
              'light',
            ].any((k) => raw[k] is! int || raw[k] < 0)) {
          throw StateError(tr("잘못된 보상"));
        }
        final reward = {
          for (final k in ['churu', 'snack', 'light']) k: raw[k] as int,
        };
        final seconds = _walkClock.elapsedMilliseconds / 1000;
        if (reward['churu']! > 12 ||
            reward['snack']! > 12 ||
            reward['light']! > 80 ||
            (seconds < 2 && reward.values.any((n) => n > 0)) ||
            reward['churu']! +
                    reward['snack']! +
                    (reward['light']! / 20).ceil() >
                (seconds / 2).floor() + 1) {
          throw StateError(tr("잘못된 보상"));
        }
        _pendingReward = reward;
      }
      await MongiGardenStore.instance.receiveWalkReward(
        _walkId!,
        _pendingReward!,
        isCurrentOwner: () => _ownsWalk,
      );
      _rewardSaved = true;
      _rewardSaving = false;
      await _run('window.walkRewardResult(true);');
    } catch (_) {
      await _run('window.walkRewardResult(false);');
    } finally {
      _rewardSaving = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _visible = state == AppLifecycleState.resumed;
    if (!_visible) {
      _walkClock.stop();
      unawaited(_sound.stopPurr());
    }
    if (!_visible) unawaited(_run('window.hostPause();'));
    // The app's existing lifecycle owner controls the one SoundService player.
  }

  Future<void> _nativeFullscreen(bool value) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await const MethodChannel(
        'garden/walk_fullscreen',
      ).invokeMethod<void>('set', value);
    } on MissingPluginException {
      // Older hosts retain Flutter's fallback.
    } on PlatformException {}
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncInsets());
  }

  void _syncInsets() {
    if (!mounted) return;
    final p = MediaQuery.viewPaddingOf(context);
    unawaited(
      _run("window.setWalkInsets(${p.top},${p.right},${p.bottom},${p.left});"),
    );
  }

  Future<void> _setFullscreen(bool value) async {
    if (!mounted) return;
    setState(() => _full = value);
    await SystemChrome.setEnabledSystemUIMode(
      value ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
    await _nativeFullscreen(value);
    await _run("window.setWalkFullscreen($value);");
    _syncInsets();
    if (!value) await SystemChrome.setPreferredOrientations([]);
  }

  Future<void> _rotate() async {
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    await SystemChrome.setPreferredOrientations(
      landscape
          ? [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]
          : [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
    );
  }

  @override
  void dispose() {
    _walkClock.stop();
    _loadEpoch++;
    unawaited(_sound.stopPurr());
    unawaited(_nativeFullscreen(false));
    _sound.removeListener(_syncSound);
    AppLanguage.instance.removeListener(_syncLanguage);
    WidgetsBinding.instance.removeObserver(this);
    unawaited(SystemChrome.setPreferredOrientations([]));
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    // Keep the app's BGM playing when returning to healing; do not create or
    // dispose another player for this route.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final supported =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    return PopScope(
      canPop: !_full,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _full) unawaited(_setFullscreen(false));
      },
      child: Scaffold(
        backgroundColor: AppColors.bg0,
        appBar: _full
            ? null
            : AppBar(
                title: Text(tr("마음냥 산책")),
                actions: [
                  IconButton(
                    onPressed: _load,
                    tooltip: tr("산책 새로 불러오기"),
                    icon: const Icon(Icons.refresh),
                  ),
                  IconButton(
                    onPressed: _ready ? () => _setFullscreen(true) : null,
                    tooltip: tr("가로·세로 전체 화면"),
                    icon: Icon(Icons.fullscreen),
                  ),
                ],
              ),
        body: !supported
            ? Center(child: Text(tr("산책은 Android·iPhone 앱에서 이용할 수 있어요.")))
            : _failed
            ? Center(
                child: TextButton(
                  onPressed: _load,
                  child: Text(tr("산책을 불러오지 못했어요 · 다시 시도")),
                ),
              )
            : Stack(
                children: [
                  if (_controller != null)
                    WebViewWidget(controller: _controller!),
                  if (_full)
                    Positioned(
                      top: 0,
                      right: 4,
                      child: SafeArea(
                        child: Material(
                          color: const Color(0xDDFFFAF2),
                          borderRadius: BorderRadius.circular(20),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                iconSize: 18,
                                tooltip: tr("가로·세로 전환"),
                                onPressed: _rotate,
                                icon: const Icon(
                                  Icons.screen_rotation_outlined,
                                ),
                              ),
                              IconButton(
                                iconSize: 18,
                                tooltip: tr("전체 화면 닫기"),
                                onPressed: () => _setFullscreen(false),
                                icon: const Icon(Icons.fullscreen_exit),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (!_ready)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Color(0xfffaf5ed),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
