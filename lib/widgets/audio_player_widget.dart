import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Widget für Audio-Wiedergabe
class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;
  final bool showSpeedControl;
  final bool compact;

  const AudioPlayerWidget({
    super.key,
    required this.audioPath,
    this.showSpeedControl = true,
    this.compact = false,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _player;

  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackSpeed = 1.0;

  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _initPlayer() async {
    _player = AudioPlayer();

    // Stream-Listener
    _stateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
        });
      }
    });

    _durationSubscription = _player.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _positionSubscription = _player.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    // Audio-Source setzen: Web nutzt UrlSource (blob-URLs), Native DeviceFileSource
    final source = kIsWeb
        ? UrlSource(widget.audioPath)
        : DeviceFileSource(widget.audioPath);
    await _player.setSource(source);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactPlayer(context);
    }
    return _buildFullPlayer(context);
  }

  Widget _buildCompactPlayer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause
          _buildPlayPauseButton(size: 32),
          const SizedBox(width: 8),

          // Fortschritt
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: colorScheme.primary,
                    inactiveTrackColor: colorScheme.surfaceContainerHighest,
                    thumbColor: colorScheme.primary,
                  ),
                  child: Slider(
                    value: _position.inMilliseconds.toDouble(),
                    max: _duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                    onChanged: _seek,
                  ),
                ),
              ],
            ),
          ),

          // Zeit
          Text(
            '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullPlayer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fortschrittsanzeige
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: colorScheme.primary,
              inactiveTrackColor: colorScheme.surfaceContainerHighest,
              thumbColor: colorScheme.primary,
            ),
            child: Slider(
              value: _position.inMilliseconds.toDouble(),
              max: _duration.inMilliseconds.toDouble().clamp(1, double.infinity),
              onChanged: _seek,
            ),
          ),

          // Zeitanzeige
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_position),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
                Text(
                  _formatDuration(_duration),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Steuerung
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 10s zurück
              IconButton(
                onPressed: () => _seekRelative(-10),
                icon: const Icon(Icons.replay_10),
                tooltip: '10 Sekunden zurück',
              ),

              // Play/Pause
              _buildPlayPauseButton(size: 56),

              // 10s vor
              IconButton(
                onPressed: () => _seekRelative(10),
                icon: const Icon(Icons.forward_10),
                tooltip: '10 Sekunden vor',
              ),
            ],
          ),

          // Geschwindigkeitskontrolle
          if (widget.showSpeedControl) ...[
            const SizedBox(height: 16),
            _buildSpeedControl(context),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayPauseButton({double size = 56}) {
    final isPlaying = _playerState == PlayerState.playing;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: size,
      height: size,
      child: FloatingActionButton(
        onPressed: _togglePlayPause,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        child: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          size: size * 0.5,
        ),
      ),
    );
  }

  Widget _buildSpeedControl(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.center,
      children: speeds.map((speed) {
        final isSelected = _playbackSpeed == speed;
        return ChoiceChip(
          label: Text('${speed}x'),
          selected: isSelected,
          onSelected: (_) => _setSpeed(speed),
          selectedColor: colorScheme.primaryContainer,
          labelStyle: TextStyle(
            color: isSelected ? colorScheme.onPrimaryContainer : null,
            fontWeight: isSelected ? FontWeight.bold : null,
          ),
        );
      }).toList(),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _togglePlayPause() async {
    if (_playerState == PlayerState.playing) {
      await _player.pause();
    } else {
      await _player.resume();
    }
  }

  void _seek(double value) {
    _player.seek(Duration(milliseconds: value.toInt()));
  }

  void _seekRelative(int seconds) {
    final newPosition = _position + Duration(seconds: seconds);
    final clampedPosition = Duration(
      milliseconds: newPosition.inMilliseconds.clamp(0, _duration.inMilliseconds),
    );
    _player.seek(clampedPosition);
  }

  void _setSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    _player.setPlaybackRate(speed);
  }
}

/// Mini-Player für Notiz-Cards
class MiniAudioPlayer extends StatefulWidget {
  final String audioPath;
  final Duration? duration;

  const MiniAudioPlayer({
    super.key,
    required this.audioPath,
    this.duration,
  });

  @override
  State<MiniAudioPlayer> createState() => _MiniAudioPlayerState();
}

class _MiniAudioPlayerState extends State<MiniAudioPlayer> {
  late AudioPlayer _player;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              size: 20,
              color: colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.graphic_eq,
              size: 16,
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
            if (widget.duration != null) ...[
              const SizedBox(width: 8),
              Text(
                _formatDuration(widget.duration!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontFamily: 'monospace',
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      final source = kIsWeb
          ? UrlSource(widget.audioPath)
          : DeviceFileSource(widget.audioPath);
      await _player.play(source);
    }
  }
}
