import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String source;

  const AudioPlayerWidget({super.key, required this.source});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _player;
  PlayerState _state = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _state = s);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    await _player.play(DeviceFileSource(widget.source));
  }

  Future<void> _pause() async {
    await _player.pause();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(_state == PlayerState.playing ? Icons.pause : Icons.play_arrow),
              onPressed: _state == PlayerState.playing ? _pause : _play,
            ),
            Expanded(
              child: Slider(
                value: _position.inMilliseconds.toDouble(),
                max: _duration.inMilliseconds.toDouble(),
                onChanged: (v) {
                  _player.seek(Duration(milliseconds: v.toInt()));
                },
              ),
            ),
          ],
        ),
        Text('${_position.toString().split('.').first} / ${_duration.toString().split('.').first}'),
      ],
    );
  }
}
