import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:video_player/video_player.dart';
import 'package:volume_controller/volume_controller.dart';

/// ═══════════════════════════════════════════════════════════
/// 播放器 v2 —— 全功能
/// 手势：左滑亮度/右滑音量/横向快进快退/双击暂停/双击两侧±10s
/// 功能：倍速/锁屏/全屏/选集/自动下一集/缓冲进度/记忆播放位置
/// ═══════════════════════════════════════════════════════════
class PlayerV2Page extends StatefulWidget {
  final String url;
  final String title;
  final List<String> episodes; // 集名列表
  final int episodeIndex;
  final void Function(int index)? onEpisodeChange;
  final Duration? startPos;

  const PlayerV2Page({
    super.key,
    required this.url,
    this.title = '',
    this.episodes = const [],
    this.episodeIndex = 0,
    this.onEpisodeChange,
    this.startPos,
  });

  @override
  State<PlayerV2Page> createState() => _PlayerV2PageState();
}

class _PlayerV2PageState extends State<PlayerV2Page> {
  VideoPlayerController? _c;
  bool _ready = false;
  String? _err;
  bool _showCtrl = true;
  bool _locked = false;
  bool _fullscreen = false;
  double _speed = 1.0;
  Timer? _hideTimer;
  Timer? _posTimer;

  // 手势状态
  bool _vBri = false; // 正在竖直滑（左亮度/右音量）
  bool _vVol = false;
  bool _hSeek = false;
  double _dragStartDy = 0, _dragStartDx = 0;
  double _briStart = 1, _volStart = 0.5;
  double _briVal = 1, _volVal = 0.5;
  int _seekPreviewMs = 0; // 横滑预览目标位置
  int _seekDeltaMs = 0;
  Offset? _doubleTapPos;

  double _sysVol = 0.5;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    try {
      VolumeController().listener((v) {
        if (mounted && !_vVol) setState(() {});
      });
    } catch (_) {}
    _init();
    _posTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        httpHeaders: const {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120 Mobile Safari/537.36',
        },
      );
      _c = c;
      await c.initialize();
      if (widget.startPos != null && widget.startPos! > Duration.zero) {
        await c.seekTo(widget.startPos!);
      }
      await c.setPlaybackSpeed(_speed);
      await c.play();
      _briVal = 1;
      try {
        _briVal = await ScreenBrightness().current;
      } catch (_) {}
      _briStart = _briVal;
      try {
        final v2 = await VolumeController().getVolume();
        _sysVol = (v2 is num) ? v2.toDouble() : 0.5;
      } catch (_) {}
      if (!mounted) return;
      setState(() => _ready = true);
      _armHide();
    } catch (e) {
      if (!mounted) return;
      setState(() => _err = '播放失败，请检查网络后重试');
    }
  }

  void _armHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showCtrl = false);
    });
  }

  void _tapScreen() {
    if (_locked) return;
    setState(() => _showCtrl = !_showCtrl);
    if (_showCtrl) _armHide();
  }

  // ─── 双击：两侧±10s / 中间播放暂停 ───
  void _onDoubleTap(Offset local) {
    if (!_ready || _locked || _c == null) return;
    final w = MediaQuery.of(context).size.width;
    if (local.dx < w / 3) {
      _seekRel(-10);
      _flashHint('« 10s', Offset(60, 0));
    } else if (local.dx > w * 2 / 3) {
      _seekRel(10);
      _flashHint('10s »', Offset(-60, 0));
    } else {
      _c!.value.isPlaying ? _c!.pause() : _c!.play();
    }
    setState(() {});
  }

  void _flashHint(String text, Offset shift) {
    final overlay = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).size.height / 2 - 30,
        left: 0, right: 0,
        child: Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
              color: Colors.black54, borderRadius: BorderRadius.circular(20)),
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
        )),
      ),
    );
    Overlay.of(context).insert(overlay);
    Future.delayed(const Duration(milliseconds: 600), () => overlay.remove());
  }

  Future<void> _seekRel(int sec) async {
    final v = _c!.value;
    var t = v.position + Duration(seconds: sec);
    if (t < Duration.zero) t = Duration.zero;
    if (t > v.duration) t = v.duration;
    await _c!.seekTo(t);
  }

  // ─── 手势 ───
  void _onDragStart(DragStartDetails d, Size size) {
    if (_locked || !_ready) return;
    _dragStartDx = d.localPosition.dx;
    _dragStartDy = d.localPosition.dy;
    final leftZone = d.localPosition.dx < size.width / 2;
    _vBri = false;
    _vVol = false;
    _hSeek = false;
    // 先按起始点判定区域；竖直位移>12 且水平<12 → 亮度/音量
    if (d.localPosition.dy < size.height * 0.75) {
      if (leftZone) {
        _vBri = true;
        _briStart = _briVal;
      } else {
        _vVol = true;
        _volStart = _sysVol;
      }
    }
  }

  void _onDragUpdate(DragUpdateDetails d, Size size) {
    if (_locked || !_ready) return;
    if (_vBri) {
      final dy = d.localPosition.dy - _dragStartDy;
      _briVal = (_briStart - dy / (size.height * 0.6)).clamp(0.05, 1.0);
      try {
        ScreenBrightness().setScreenBrightness(_briVal);
      } catch (_) {}
      setState(() {});
    } else if (_vVol) {
      final dy = d.localPosition.dy - _dragStartDy;
      _volVal = (_volStart - dy / (size.height * 0.6)).clamp(0.0, 1.0);
      try {
        VolumeController().setVolume(_volVal);
      } catch (_) {}
      _sysVol = _volVal;
      setState(() {});
    } else if (d.localPosition.dy > size.height * 0.75 ||
        (d.localPosition.dy - _dragStartDy).abs() < 14 &&
            (d.localPosition.dx - _dragStartDx).abs() > 14) {
      if (!_hSeek && (d.localPosition.dx - _dragStartDx).abs() > 24) {
        _hSeek = true;
      }
      if (_hSeek && _c != null) {
        final dx = d.localPosition.dx - _dragStartDx;
        _seekDeltaMs = (dx / size.width * 180 * 1000).round(); // 全屏宽=180s
        final dur = _c!.value.duration.inMilliseconds;
        _seekPreviewMs =
            (_c!.value.position.inMilliseconds + _seekDeltaMs).clamp(0, dur);
        setState(() {});
      }
    }
  }

  Future<void> _onDragEnd(DragEndDetails d) async {
    if (_hSeek && _c != null) {
      await _c!.seekTo(Duration(milliseconds: _seekPreviewMs));
      _hSeek = false;
      _seekDeltaMs = 0;
      setState(() {});
    }
    _vBri = false;
    _vVol = false;
    if (mounted) setState(() {});
  }

  // ─── 全屏切换 ───
  Future<void> _toggleFull() async {
    _fullscreen = !_fullscreen;
    if (_fullscreen) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    if (mounted) setState(() {});
  }

  void _showSpeedSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: _isDarkSheet,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Padding(
                padding: EdgeInsets.all(14),
                child: Text('播放倍速',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800))),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0].map((s) {
                final sel = s == _speed;
                return GestureDetector(
                  onTap: () async {
                    _speed = s;
                    await _c?.setPlaybackSpeed(s);
                    if (mounted) setState(() {});
                    Get.back();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel
                          ? const Color(0xFF4B5EF5)
                          : Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${s}x',
                        style: TextStyle(
                            color: sel ? Colors.white : Colors.white70)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  Color get _isDarkSheet => const Color(0xE6222226);

  void _showEpisodesSheet() {
    if (widget.episodes.isEmpty) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.65),
        decoration: BoxDecoration(color: _isDarkSheet, borderRadius: const BorderRadius.vertical(top: Radius.circular(18))),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text('选集（共${widget.episodes.length}集）',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 2.2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8),
                itemCount: widget.episodes.length,
                itemBuilder: (_, i) {
                  final sel = i == widget.episodeIndex;
                  return GestureDetector(
                    onTap: () {
                      Get.back();
                      widget.onEpisodeChange?.call(i);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF4B5EF5)
                            : Colors.white.withAlpha(18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.episodes[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: sel ? Colors.white : Colors.white70),
                      ),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _posTimer?.cancel();
    _c?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    try {
      ScreenBrightness().resetScreenBrightness();
    } catch (_) {}
    try {
      VolumeController().removeListener();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _tapScreen,
        onDoubleTapDown: (d) => _doubleTapPos = d.localPosition,
        onDoubleTap: () => _onDoubleTap(_doubleTapPos ?? Offset.zero),
        onVerticalDragStart: (d) => _onDragStart(d, MediaQuery.of(context).size),
        onVerticalDragUpdate: (d) => _onDragUpdate(d, MediaQuery.of(context).size),
        onVerticalDragEnd: _onDragEnd,
        onHorizontalDragStart: (d) => _onDragStart(d, MediaQuery.of(context).size),
        onHorizontalDragUpdate: (d) => _onDragUpdate(d, MediaQuery.of(context).size),
        onHorizontalDragEnd: _onDragEnd,
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (_err != null) return _errView();
    if (!_ready || _c == null) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4));
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: _c!.value.aspectRatio == 0 ? 16 / 9 : _c!.value.aspectRatio,
            child: VideoPlayer(_c!),
          ),
        ),
        if (_locked) _lockView() else if (_showCtrl) _controls(),
        _gestureHud(),
      ],
    );
  }

  Widget _errView() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white54, size: 46),
          const SizedBox(height: 12),
          const Text('无法播放该视频', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _err = null;
                _ready = false;
              });
              _init();
            },
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('重试'),
          ),
        ]),
      );

  Widget _lockView() => Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 14),
          child: GestureDetector(
            onTap: () => setState(() => _locked = false),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  color: Colors.black45, shape: BoxShape.circle),
              child: const Icon(Icons.lock_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
      );

  Widget _gestureHud() {
    if (_locked) return const SizedBox.shrink();
    Widget? hud;
    if (_vBri) {
      hud = _hud('亮度', _briVal, Icons.brightness_6_rounded);
    } else if (_vVol) {
      hud = _hud('音量', _volVal, Icons.volume_up_rounded);
    } else if (_hSeek) {
      final fwd = _seekDeltaMs > 0;
      hud = Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
              color: Colors.black54, borderRadius: BorderRadius.circular(24)),
          child: Text(
            '${fwd ? "快进" : "快退"} ${(_seekDeltaMs.abs() / 1000).abs().toStringAsFixed(0)}s · ${_fmt(Duration(milliseconds: _seekPreviewMs))}',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      );
    }
    return hud ?? const SizedBox.shrink();
  }

  Widget _hud(String label, double v, IconData ic) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
              color: Colors.black54, borderRadius: BorderRadius.circular(14)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(ic, color: Colors.white, size: 22),
            const SizedBox(height: 8),
            SizedBox(
              width: 130,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 5,
                  backgroundColor: Colors.white24,
                  valueColor:
                      const AlwaysStoppedAnimation(Color(0xFF4B5EF5)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text('$label ${(v * 100).round()}%',
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ]),
        ),
      );

  Widget _controls() {
    final v = _c!.value;
    final pos = v.position;
    final dur = v.duration;
    final buffered = v.buffered.isNotEmpty ? v.buffered.last.end : Duration.zero;
    final epTxt = widget.episodes.isNotEmpty
        ? ' · 第${widget.episodeIndex + 1}集'
        : '';
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.transparent, Colors.black87])),
      child: Column(
        children: [
          // ── 顶栏
          SafeArea(
            bottom: false,
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
                onPressed: () => Get.back(),
              ),
              Expanded(
                child: Text('${widget.title}$epTxt',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
              IconButton(
                  icon: const Icon(Icons.lock_open_rounded,
                      color: Colors.white, size: 19),
                  onPressed: () => setState(() => _locked = true)),
              if (widget.episodes.isNotEmpty)
                TextButton(
                  onPressed: _showEpisodesSheet,
                  child: const Text('选集',
                      style: TextStyle(color: Colors.white, fontSize: 13)),
                ),
            ]),
          ),
          const Spacer(),
          // ── 中央
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.episodes.isNotEmpty && widget.episodeIndex > 0)
                _cBtn(Icons.skip_previous_rounded, () {
                  widget.onEpisodeChange?.call(widget.episodeIndex - 1);
                }),
              const SizedBox(width: 26),
              _cBtn(
                v.isPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_fill_rounded,
                () => setState(() {
                  v.isPlaying ? _c!.pause() : _c!.play();
                }),
                size: 58,
              ),
              const SizedBox(width: 26),
              if (widget.episodes.isNotEmpty &&
                  widget.episodeIndex < widget.episodes.length - 1)
                _cBtn(Icons.skip_next_rounded, () {
                  widget.onEpisodeChange?.call(widget.episodeIndex + 1);
                }),
            ],
          ),
          const Spacer(),
          // ── 底栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(children: [
              Row(children: [
                Text(_fmt(pos),
                    style: const TextStyle(color: Colors.white, fontSize: 11)),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 10),
                    ),
                    child: Slider(
                      value: dur.inMilliseconds > 0
                          ? pos.inMilliseconds / dur.inMilliseconds
                          : 0,
                      onChanged: (x) => _c!.seekTo(dur * x),
                    ),
                  ),
                ),
                Text(_fmt(dur),
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
              Row(children: [
                _txt(_c!.value.isPlaying ? '播放中' : '暂停'),
                _txt('${_speed}x', onTap: _showSpeedSheet),
                const Spacer(),
                Icon(Icons.bolt_rounded,
                    size: 13,
                    color: buffered > pos
                        ? const Color(0xFF10B981)
                        : Colors.white38),
                _txt('全屏', onTap: _toggleFull),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _cBtn(IconData ic, VoidCallback onTap, {double size = 34}) =>
      GestureDetector(
        onTap: onTap,
        child: Icon(ic, color: Colors.white, size: size),
      );

  Widget _txt(String s, {VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(s,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ),
      );
}
