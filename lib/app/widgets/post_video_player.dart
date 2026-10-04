import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../design/ui.dart';

/// 动态视频播放器
///
/// 两种来源：
///   file   —— 直链视频（本地上传 mp4 / m3u8），用 video_player 内嵌播放
///   iframe —— 分享链接解析后的播放页（B站/YouTube），用 WebView 内嵌
class PostVideoPlayer extends StatefulWidget {
  final String url;
  final String type;

  const PostVideoPlayer({
    super.key,
    required this.url,
    this.type = 'file',
  });

  @override
  State<PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<PostVideoPlayer> {
  VideoPlayerController? _controller;
  WebViewController? _web;
  bool _ready = false;
  bool _failed = false;
  String _err = '';

  @override
  void initState() {
    super.initState();
    if (widget.url.isEmpty) {
      _failed = true;
      return;
    }
    if (widget.type == 'iframe') {
      _initWeb();
    } else {
      _initFile();
    }
  }

  void _initWeb() {
    final c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _ready = true);
        },
        onWebResourceError: (e) {
          if (mounted) {
            setState(() {
              _failed = true;
              _err = e.description;
            });
          }
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
    _web = c;
  }

  Future<void> _initFile() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await c.initialize();
      if (!mounted) {
        c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _ready = true;
      });
      c.setLooping(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _failed = true;
          _err = '视频加载失败';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return _fallback();
    if (!_ready) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(R.sm),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
          ),
        ),
      );
    }

    if (widget.type == 'iframe') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(R.sm),
        child: SizedBox(
          height: 210,
          width: double.infinity,
          child: WebViewWidget(controller: _web!),
        ),
      );
    }

    final c = _controller!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(R.sm),
      child: AspectRatio(
        aspectRatio: c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(c),
            // 点击播放/暂停
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  c.value.isPlaying ? c.pause() : c.play();
                });
              },
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: c.value.isPlaying ? 0 : 1,
                child: Container(
                  color: Colors.black26,
                  alignment: Alignment.center,
                  child: const Icon(Icons.play_circle_fill_rounded,
                      size: 54, color: Colors.white),
                ),
              ),
            ),
            // 进度条
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                c,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Color(0xFF4B5EF5),
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 播放失败兜底：给出可点开的链接，不让用户看到空白
  Widget _fallback() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(20),
        borderRadius: BorderRadius.circular(R.sm),
        border: Border.all(color: C.stroke),
      ),
      child: Row(
        children: [
          const Icon(Icons.videocam_off_outlined, color: C.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('视频无法播放',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(_err.isEmpty ? '该链接可能已失效' : _err,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
